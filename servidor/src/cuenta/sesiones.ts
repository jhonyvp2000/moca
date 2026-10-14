import { createHash, randomBytes } from 'node:crypto';
import type { Pool } from '../base/conexion.js';

const huella = (llave: string) => createHash('sha256').update(llave).digest();

/** Crea la llave del teléfono. Solo se guarda su huella. */
export async function crearSesion(pool: Pool, usuarioId: string): Promise<string> {
  const llave = randomBytes(32).toString('base64url');
  await pool.query('INSERT INTO sesiones (usuario_id, huella) VALUES ($1, $2)', [
    usuarioId,
    huella(llave),
  ]);
  return llave;
}

/** El usuario dueño de la llave, o nulo si no existe o se revocó. */
export async function usuarioDeLlave(
  pool: Pool,
  llave: string,
): Promise<string | null> {
  const { rows } = await pool.query<{ usuario_id: string }>(
    `UPDATE sesiones SET usado_en = now()
      WHERE huella = $1 AND revocada_en IS NULL
      RETURNING usuario_id`,
    [huella(llave)],
  );
  return rows[0]?.usuario_id ?? null;
}
