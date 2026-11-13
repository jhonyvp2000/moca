import { createHash, randomBytes } from 'node:crypto';
import type { Pool } from '../base/conexion.js';

const huella = (llave: string) => createHash('sha256').update(llave).digest();

/**
 * Crea la llave del teléfono. Solo se guarda su huella. Un teléfono por
 * cuenta (entrega 12): la llave de cualquier otro teléfono queda revocada,
 * así dos teléfonos no se pisan los datos.
 */
export async function crearSesion(pool: Pool, usuarioId: string): Promise<string> {
  const llave = randomBytes(32).toString('base64url');
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    await cliente.query(
      `UPDATE sesiones SET revocada_en = now()
        WHERE usuario_id = $1 AND revocada_en IS NULL`,
      [usuarioId],
    );
    await cliente.query('INSERT INTO sesiones (usuario_id, huella) VALUES ($1, $2)', [
      usuarioId,
      huella(llave),
    ]);
    await cliente.query('COMMIT');
  } catch (error) {
    await cliente.query('ROLLBACK');
    throw error;
  } finally {
    cliente.release();
  }
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
