import type { FastifyInstance } from 'fastify';
import type { Pool } from '../base/conexion.js';
import { autenticar } from '../datos/subir.js';

/** Las tablas de una empresa, de las hijas a la empresa misma. */
const tablasDeLaEmpresa = [
  'bitacora', 'videos_vistos', 'alertas', 'dias_cerrados', 'arqueo_cuentas', 'arqueos',
  'movimientos', 'items_comprobante', 'comprobantes', 'reglas_clasificacion', 'periodos',
  'contrapartes', 'categorias', 'cuentas', 'invitaciones', 'membresias', 'empresas',
];

/**
 * Borra para siempre el negocio del dueño y todo lo suyo, y las fotos que
 * leyó (entrega 14.8). El número queda, sin datos; las llaves se revocan.
 * Devuelve cuántas empresas se borraron.
 */
export async function borrarDatos(pool: Pool, usuarioId: string): Promise<number> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    await cliente.query(`SELECT set_config('app.usuario_id', $1, true)`, [usuarioId]);
    const { rows } = await cliente.query<{ empresa_id: string }>(
      // Solo el titular borra el negocio (entrega 17).
      `SELECT empresa_id FROM membresias
        WHERE usuario_id = $1 AND titular AND quitada_en IS NULL`,
      [usuarioId],
    );
    for (const { empresa_id: empresaId } of rows) {
      await cliente.query(
        `SELECT set_config('app.empresa_id', $1, true),
                set_config('app.borrando_empresa', $1, true)`,
        [empresaId],
      );
      for (const tabla of tablasDeLaEmpresa) {
        const columna = tabla === 'empresas' ? 'id' : 'empresa_id';
        await cliente.query(`DELETE FROM ${tabla} WHERE ${columna} = $1`, [empresaId]);
      }
      await cliente.query('INSERT INTO borrados (usuario_id, empresa_id) VALUES ($1, $2)', [
        usuarioId,
        empresaId,
      ]);
    }
    await cliente.query(`SELECT set_config('app.borrando_empresa', '', true)`);
    await cliente.query('DELETE FROM lecturas WHERE usuario_id = $1 OR prueba_de = $1', [
      usuarioId,
    ]);
    await cliente.query(
      'UPDATE sesiones SET revocada_en = now() WHERE usuario_id = $1 AND revocada_en IS NULL',
      [usuarioId],
    );
    await cliente.query('COMMIT');
    return rows.length;
  } catch (error) {
    await cliente.query('ROLLBACK');
    throw error;
  } finally {
    cliente.release();
  }
}

export function rutasBorrar(app: FastifyInstance, pool: Pool): void {
  app.post<{ Body: { confirmacion?: unknown } }>('/cuenta/borrar-datos', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    // Lo que el dueño escribió para confirmar: sin eso no se borra nada.
    if (peticion.body?.confirmacion !== 'BORRAR') {
      return respuesta.code(400).send({ error: 'sin_confirmacion' });
    }
    // Quien está en un negocio sin ser su titular no lo puede borrar.
    if (await soloEnNegocioDeOtro(pool, usuarioId)) {
      return respuesta.code(403).send({ error: 'solo_titular' });
    }
    return { borradas: await borrarDatos(pool, usuarioId) };
  });
}

/** Si el usuario está en algún negocio, pero en ninguno como titular. */
async function soloEnNegocioDeOtro(pool: Pool, usuarioId: string): Promise<boolean> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    await cliente.query(`SELECT set_config('app.usuario_id', $1, true)`, [usuarioId]);
    const { rows } = await cliente.query<{ titular: boolean }>(
      'SELECT titular FROM membresias WHERE usuario_id = $1 AND quitada_en IS NULL',
      [usuarioId],
    );
    await cliente.query('COMMIT');
    return rows.length > 0 && !rows.some((m) => m.titular);
  } finally {
    cliente.release();
  }
}
