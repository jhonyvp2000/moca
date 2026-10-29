import type { FastifyInstance } from 'fastify';
import type { Pool } from '../base/conexion.js';
import { enviarJson } from '../cifras/rutas.js';
import { miembroDe } from '../equipo/miembros.js';
import { empresaPedida, leerTabla, ultimoCambio } from './bajar.js';
import { autenticar, columnasEmpresa, tablas } from './subir.js';

/**
 * Lo nuevo de la empresa desde el cambio [desde] que el rol puede ver
 * (entrega 17): así cada teléfono baja lo que anotaron los demás sin bajar
 * todo. Nulo si el usuario ya no está en la empresa.
 */
export async function cambiosDesde(
  pool: Pool,
  usuarioId: string,
  desde: number,
  empresaId?: string,
): Promise<Record<string, unknown> | null> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    const miembro = await miembroDe(cliente, usuarioId, empresaId);
    if (!miembro) {
      await cliente.query('COMMIT');
      return null;
    }
    await cliente.query(`SELECT set_config('app.empresa_id', $1, true)`, [miembro.empresaId]);
    const hasta = await ultimoCambio(cliente, miembro.empresaId);
    const empresa = (
      await cliente.query(
        `SELECT ${columnasEmpresa.join(', ')} FROM empresas WHERE cambio > $1`,
        [desde],
      )
    ).rows[0];
    const cambios: Record<string, unknown> = {
      empresa_id: miembro.empresaId,
      rol: miembro.rol,
      titular: miembro.titular,
      hasta,
      ...(empresa ? { empresa } : {}),
    };
    for (const [tabla, columnas] of Object.entries(tablas)) {
      const filas = await leerTabla(cliente, tabla, columnas, miembro, usuarioId, desde);
      if (filas.length) cambios[tabla] = filas;
    }
    await cliente.query('COMMIT');
    return cambios;
  } catch (error) {
    await cliente.query('ROLLBACK');
    throw error;
  } finally {
    cliente.release();
  }
}

export function rutasCambios(app: FastifyInstance, pool: Pool): void {
  app.get('/datos/cambios', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    const desde = Number((peticion.query as { desde?: unknown } | undefined)?.desde ?? 0);
    if (!Number.isSafeInteger(desde) || desde < 0) {
      return respuesta.code(400).send({ error: 'datos_invalidos' });
    }
    const cambios = await cambiosDesde(pool, usuarioId, desde, empresaPedida(peticion.query));
    // Sin negocio activo: lo quitaron del equipo o nunca entró.
    if (!cambios) return respuesta.code(403).send({ error: 'sin_negocio' });
    return enviarJson(peticion, respuesta, cambios);
  });
}
