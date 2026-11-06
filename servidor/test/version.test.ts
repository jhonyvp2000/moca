import { describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import type { Pool } from '../src/base/conexion.js';
import {
  leerConfigVersion,
  minimaObligatoria,
  type Release,
  ultimaVersion,
} from '../src/version/rutas.js';

const release = (tag: string, armado: number, draft = false): Release => ({
  tag_name: tag,
  draft,
  assets: [
    {
      name: `moca-${tag}-${armado}-arm64.apk`,
      browser_download_url: `https://x/${tag}/arm64.apk`,
    },
    {
      name: `moca-${tag}-${armado}-armeabi-v7a.apk`,
      browser_download_url: `https://x/${tag}/v7a.apk`,
    },
  ],
});

const releases = [
  release('entrega-26.3', 117),
  release('piloto-2', 110),
  release('piloto-3', 120, true),
  release('piloto-1', 90),
  { tag_name: 'otra-cosa', draft: false, assets: [] },
];

describe('«Hay una versión nueva de Moca» (entrega 26.3)', () => {
  it('Los pilotos ven solo «piloto-N»; Jhony, también las entregas', () => {
    expect(ultimaVersion(releases, false)).toEqual({
      nombre: 'piloto-2',
      armado: 110,
      arm64: 'https://x/piloto-2/arm64.apk',
      v7a: 'https://x/piloto-2/v7a.apk',
    });
    expect(ultimaVersion(releases, true)?.nombre).toBe('entrega-26.3');
    expect(ultimaVersion([], true)).toBeNull();
  });

  it('La mínima sale del entorno', () => {
    expect(leerConfigVersion({ MOCA_APP_MINIMA: '105' })).toEqual({
      repo: 'jhonyvp2000/moca',
      minima: 105,
    });
    expect(leerConfigVersion({ MOCA_APP_MINIMA: 'nada' }).minima).toBeNull();
  });

  it('Pregunta a GitHub cada 15 minutos y, si no responde, usa lo último', async () => {
    let ahora = new Date('2026-11-04T15:00:00Z');
    let pedidos = 0;
    let falla = false;
    const app = crearApp({
      pool: {} as Pool,
      version: 'prueba',
      ahora: () => ahora,
      versionApp: { repo: 'jhonyvp2000/moca', minima: 100 },
      buscarReleases: async () => {
        pedidos++;
        if (falla) throw new Error('sin red');
        return releases;
      },
    });
    const pedir = async (canal?: string) =>
      (await app.inject({ method: 'GET', url: `/app/version${canal ? `?canal=${canal}` : ''}` }))
        .json();

    expect(await pedir()).toMatchObject({ ultima: { nombre: 'piloto-2' }, minima: 100 });
    expect((await pedir('todas')).ultima.nombre).toBe('entrega-26.3');
    expect(pedidos).toBe(1);

    ahora = new Date('2026-11-04T15:16:00Z');
    falla = true;
    expect((await pedir()).ultima.armado).toBe(110);
    expect(pedidos).toBe(2);
  });

  it('«/descargar» lleva al APK del último piloto; sin pilotos, a la última entrega', async () => {
    let lista: Release[] = releases;
    const app = crearApp({
      pool: {} as Pool,
      version: 'prueba',
      versionApp: { repo: 'jhonyvp2000/moca', minima: null },
      buscarReleases: async () => lista,
    });
    const piloto = await app.inject({ method: 'GET', url: '/descargar' });
    expect(piloto.statusCode).toBe(302);
    expect(piloto.headers.location).toBe('https://x/piloto-2/arm64.apk');
    await app.close();

    lista = [release('entrega-29.1', 124), release('entrega-28', 120)];
    const app2 = crearApp({
      pool: {} as Pool,
      version: 'prueba',
      versionApp: { repo: 'jhonyvp2000/moca', minima: null },
      buscarReleases: async () => lista,
    });
    const entrega = await app2.inject({ method: 'GET', url: '/descargar' });
    expect(entrega.headers.location).toBe('https://x/entrega-29.1/arm64.apk');
    await app2.close();

    const app3 = crearApp({
      pool: {} as Pool,
      version: 'prueba',
      versionApp: { repo: 'jhonyvp2000/moca', minima: null },
      buscarReleases: async () => {
        throw new Error('sin red');
      },
    });
    const nada = await app3.inject({ method: 'GET', url: '/descargar' });
    expect(nada.statusCode).toBe(302);
    expect(nada.headers.location).toBe('https://github.com/jhonyvp2000/moca/releases');
    await app3.close();
  });

  it('Un Release marcado «[obligatoria]» sube la mínima (entrega 34)', async () => {
    const marcar = (r: Release): Release => ({ ...r, body: 'Arreglos.\n\n[obligatoria]' });
    expect(minimaObligatoria(releases, false)).toBeNull();
    const lista = [
      marcar(release('piloto-1', 90)),
      release('piloto-2', 110),
      marcar(release('entrega-26.3', 117)),
    ];
    // Los pilotos ven solo los pilotos marcados; Jhony, también las entregas.
    expect(minimaObligatoria(lista, false)).toBe(90);
    expect(minimaObligatoria(lista, true)).toBe(117);
    const app = crearApp({
      pool: {} as Pool,
      version: 'prueba',
      versionApp: { repo: 'jhonyvp2000/moca', minima: 50 },
      buscarReleases: async () => lista,
    });
    expect((await app.inject({ method: 'GET', url: '/app/version' })).json().minima).toBe(90);
    expect(
      (await app.inject({ method: 'GET', url: '/app/version?canal=todas' })).json().minima,
    ).toBe(117);
    await app.close();
  });
});
