import type { FastifyInstance } from 'fastify';

// «Hay una versión nueva de Moca» (entrega 26.3). La última versión sale de
// los Releases de GitHub, donde el flujo apk.yml publica cada APK: no hay que
// anotarla a mano en ningún lado.

/** Un release como lo devuelve la API de GitHub (solo lo que se usa). */
export interface Release {
  tag_name: string;
  draft: boolean;
  /** Las notas: «[obligatoria]» obliga a actualizar (entrega 34). */
  body?: string | null;
  assets: { name: string; browser_download_url: string }[];
}

export interface VersionPublicada {
  /** «piloto-3» o «entrega-26.3». */
  nombre: string;
  /** El número de armado de GitHub: crece con cada APK. */
  armado: number;
  arm64: string | null;
  v7a: string | null;
}

/** Lo que el servidor toma del entorno (Render). */
export interface ConfigVersion {
  /** MOCA_REPO: de dónde leer los Releases. */
  repo: string;
  /** MOCA_APP_MINIMA: con un armado menor, la app pide actualizar sí o sí. */
  minima: number | null;
}

export function leerConfigVersion(entorno: NodeJS.ProcessEnv = process.env): ConfigVersion {
  const minima = Number(entorno.MOCA_APP_MINIMA);
  return {
    repo: entorno.MOCA_REPO?.trim() || 'jhonyvp2000/moca',
    minima: Number.isSafeInteger(minima) && minima > 0 ? minima : null,
  };
}

const archivo = /-(\d+)-(arm64|armeabi-v7a)\.apk$/;

/** La versión más nueva: solo «piloto-N» para los pilotos; todas para Jhony. */
export function ultimaVersion(releases: Release[], todas: boolean): VersionPublicada | null {
  let ultima: VersionPublicada | null = null;
  for (const release of releases) {
    if (release.draft) continue;
    const esPiloto = release.tag_name.startsWith('piloto-');
    if (!esPiloto && !(todas && release.tag_name.startsWith('entrega-'))) continue;
    let armado = 0;
    let arm64: string | null = null;
    let v7a: string | null = null;
    for (const asset of release.assets) {
      const partes = archivo.exec(asset.name);
      if (!partes) continue;
      armado = Number(partes[1]);
      if (partes[2] === 'arm64') arm64 = asset.browser_download_url;
      else v7a = asset.browser_download_url;
    }
    if (armado && (!ultima || armado > ultima.armado)) {
      ultima = { nombre: release.tag_name, armado, arm64, v7a };
    }
  }
  return ultima;
}

/**
 * La versión mínima por los Releases marcados «[obligatoria]» (entrega 34):
 * el armado más alto entre los que ve ese canal. Así se obliga desde GitHub,
 * sin tocar Render.
 */
export function minimaObligatoria(releases: Release[], todas: boolean): number | null {
  let minima: number | null = null;
  for (const release of releases) {
    if (release.draft || !release.body?.includes('[obligatoria]')) continue;
    const esPiloto = release.tag_name.startsWith('piloto-');
    if (!esPiloto && !(todas && release.tag_name.startsWith('entrega-'))) continue;
    for (const asset of release.assets) {
      const armado = Number(archivo.exec(asset.name)?.[1] ?? 0);
      if (armado && (minima === null || armado > minima)) minima = armado;
    }
  }
  return minima;
}

/** Lee los Releases de GitHub; las pruebas lo reemplazan. */
export type BuscarReleases = (repo: string) => Promise<Release[]>;

export const releasesDeGitHub: BuscarReleases = async (repo) => {
  const respuesta = await fetch(`https://api.github.com/repos/${repo}/releases?per_page=50`, {
    headers: { accept: 'application/vnd.github+json', 'user-agent': 'moca-servidor' },
    signal: AbortSignal.timeout(10_000),
  });
  if (!respuesta.ok) throw new Error(`GitHub respondió ${respuesta.status}`);
  return (await respuesta.json()) as Release[];
};

/** Cada cuánto se vuelve a preguntar a GitHub. */
export const guardarPor = 15 * 60 * 1000;

export function rutasVersion(
  app: FastifyInstance,
  config: ConfigVersion,
  buscar: BuscarReleases,
  ahora: () => Date,
): void {
  let guardado: { releases: Release[]; en: number } | null = null;

  async function releases(): Promise<Release[] | null> {
    const momento = ahora().getTime();
    if (guardado && momento - guardado.en < guardarPor) return guardado.releases;
    try {
      guardado = { releases: await buscar(config.repo), en: momento };
      return guardado.releases;
    } catch {
      // Si GitHub no responde, sirve lo último que se supo.
      return guardado?.releases ?? null;
    }
  }

  // Sin llave: la app pregunta aunque todavía no tenga cuenta.
  app.get('/app/version', async (peticion) => {
    const todas = (peticion.query as { canal?: unknown } | undefined)?.canal === 'todas';
    const lista = await releases();
    // La mayor entre MOCA_APP_MINIMA y la última marcada «[obligatoria]».
    const marcada = lista ? minimaObligatoria(lista, todas) : null;
    const minimas = [config.minima, marcada].filter((m): m is number => m !== null);
    return {
      ultima: lista ? ultimaVersion(lista, todas) : null,
      minima: minimas.length ? Math.max(...minimas) : null,
    };
  });

  // El enlace fijo que va en la invitación por WhatsApp (entrega 30): lleva
  // al APK arm64 de la última «piloto-N» y, mientras no haya ninguna, al de
  // la última «entrega-N». Sin nada publicado, a la página de los Releases.
  app.get('/descargar', async (_peticion, respuesta) => {
    const lista = await releases();
    const ultima = lista ? (ultimaVersion(lista, false) ?? ultimaVersion(lista, true)) : null;
    return respuesta.redirect(ultima?.arm64 ?? `https://github.com/${config.repo}/releases`, 302);
  });
}
