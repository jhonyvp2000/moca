import { readdir, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { leerConfig } from '../config.js';
import { crearPool, type Pool } from './conexion.js';

const carpeta = fileURLToPath(new URL('../../migraciones/', import.meta.url));

/** Un número cualquiera, fijo: evita que dos arranques migren a la vez. */
const candado = 20261014;

/**
 * Aplica, en orden y una sola vez, los archivos de `migraciones/`. Cada
 * archivo va en su propia transacción: si falla, no queda a medias.
 * Devuelve los nombres de los que aplicó.
 */
export async function migrar(
  pool: Pool,
  // Solo para las pruebas: se detiene antes de este archivo, para probar una
  // migración sobre datos de antes (entrega 20).
  { antesDe }: { antesDe?: string } = {},
): Promise<string[]> {
  const cliente = await pool.connect();
  try {
    await cliente.query('SELECT pg_advisory_lock($1)', [candado]);
    await cliente.query(`
      CREATE TABLE IF NOT EXISTS esquema_migraciones (
        nombre      text PRIMARY KEY,
        aplicada_en timestamptz NOT NULL DEFAULT now()
      )`);
    const { rows } = await cliente.query<{ nombre: string }>(
      'SELECT nombre FROM esquema_migraciones',
    );
    const hechas = new Set(rows.map((f) => f.nombre));
    const archivos = (await readdir(carpeta))
      .filter((a) => a.endsWith('.sql'))
      .sort();
    const aplicadas: string[] = [];
    for (const archivo of archivos) {
      if (hechas.has(archivo)) continue;
      if (antesDe && archivo >= antesDe) break;
      const sql = await readFile(carpeta + archivo, 'utf8');
      await cliente.query('BEGIN');
      try {
        await cliente.query(sql);
        await cliente.query(
          'INSERT INTO esquema_migraciones (nombre) VALUES ($1)',
          [archivo],
        );
        await cliente.query('COMMIT');
      } catch (error) {
        await cliente.query('ROLLBACK');
        throw new Error(`Falló la migración ${archivo}: ${String(error)}`);
      }
      aplicadas.push(archivo);
    }
    return aplicadas;
  } finally {
    await cliente.query('SELECT pg_advisory_unlock($1)', [candado]);
    cliente.release();
  }
}

// `npm run migrar`: aplica las migraciones pendientes y termina.
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const pool = crearPool(leerConfig().baseDeDatos);
  migrar(pool)
    .then((aplicadas) => {
      console.log(
        aplicadas.length
          ? `Migraciones aplicadas: ${aplicadas.join(', ')}`
          : 'La base ya estaba al día.',
      );
    })
    .finally(() => pool.end());
}
