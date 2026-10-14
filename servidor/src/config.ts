import { readFileSync } from 'node:fs';

/** Lo que el servidor toma del entorno. En Render lo fija `render.yaml`. */
export interface Config {
  /** Conexión a PostgreSQL. Nunca con un rol que se salte el aislamiento. */
  baseDeDatos: string;
  puerto: number;
  version: string;
}

const paquete = JSON.parse(
  readFileSync(new URL('../package.json', import.meta.url), 'utf8'),
) as { version: string };

/** La versión del paquete y, en Render, el commit desplegado. */
export function version(): string {
  const commit = process.env.RENDER_GIT_COMMIT?.slice(0, 7);
  return commit ? `${paquete.version}+${commit}` : paquete.version;
}

export function leerConfig(entorno: NodeJS.ProcessEnv = process.env): Config {
  const baseDeDatos = entorno.DATABASE_URL;
  if (!baseDeDatos) {
    throw new Error('Falta DATABASE_URL: la dirección de la base de datos.');
  }
  return {
    baseDeDatos,
    puerto: Number(entorno.PORT ?? 3000),
    version: version(),
  };
}
