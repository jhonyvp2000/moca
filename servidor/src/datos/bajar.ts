import type { FastifyInstance } from 'fastify';
import type { Pool } from '../base/conexion.js';
import { calcularCifras, type DatosEmpresa } from '../cifras/calcular.js';
import { enviarJson } from '../cifras/rutas.js';
import { autenticar, columnasEmpresa, tablas } from './subir.js';

/**
 * Todo lo de la empresa del usuario, con las mismas tablas y columnas que
 * sube el teléfono, para «Ya tengo cuenta» (entrega 12). Nulo si el
 * usuario todavía no tiene empresa.
 */
export async function bajar(
  pool: Pool,
  usuarioId: string,
): Promise<Record<string, unknown> | null> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    await cliente.query(`SELECT set_config('app.usuario_id', $1, true)`, [usuarioId]);
    // En la V1 cada dueño tiene una sola empresa.
    const membresia = await cliente.query<{ id: string; empresa_id: string; rol: string }>(
      `SELECT id, empresa_id, rol FROM membresias WHERE usuario_id = $1
        ORDER BY creado_en LIMIT 1`,
      [usuarioId],
    );
    const propia = membresia.rows[0];
    if (!propia) {
      await cliente.query('COMMIT');
      return null;
    }
    await cliente.query(`SELECT set_config('app.empresa_id', $1, true)`, [propia.empresa_id]);
    const leer = async (tabla: string, columnas: readonly string[]) =>
      (await cliente.query(`SELECT ${columnas.join(', ')} FROM ${tabla} ORDER BY id`)).rows;

    const datos: Record<string, unknown> = {
      usuario: (
        await cliente.query('SELECT id, celular FROM usuarios WHERE id = $1', [usuarioId])
      ).rows[0],
      membresia: { id: propia.id, empresa_id: propia.empresa_id, rol: propia.rol },
      empresa: (await leer('empresas', columnasEmpresa))[0],
    };
    for (const [tabla, columnas] of Object.entries(tablas)) {
      datos[tabla] = await leer(tabla, columnas);
    }
    await cliente.query('COMMIT');
    return datos;
  } catch (error) {
    await cliente.query('ROLLBACK');
    throw error;
  } finally {
    cliente.release();
  }
}

export function rutasBajada(app: FastifyInstance, pool: Pool, ahora: () => Date): void {
  app.get('/datos/bajar', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    const datos = await bajar(pool, usuarioId);
    // Con las cifras ya calculadas (entrega 13). Comprimido: un año de
    // registros pesa menos que una foto.
    return enviarJson(peticion, respuesta, {
      datos,
      cifras: datos && calcularCifras(datos as unknown as DatosEmpresa, ahora()),
    });
  });
}
