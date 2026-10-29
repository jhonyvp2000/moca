import type { FastifyInstance } from 'fastify';
import type { Cliente, Pool } from '../base/conexion.js';
import { calcularCifras, type DatosEmpresa } from '../cifras/calcular.js';
import { enviarJson } from '../cifras/rutas.js';
import {
  columnaParaRol,
  miembroDe,
  soloLoVisible,
  veCifras,
  type Miembro,
} from '../equipo/miembros.js';
import { autenticar, columnasEmpresa, tablas } from './subir.js';

const esUuid = (v: string) =>
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);

/**
 * Lee las filas de la empresa en curso que el rol puede ver, con las mismas
 * columnas que sube el teléfono; solo las de cambio mayor que [desde].
 */
export async function leerTabla(
  cliente: Cliente,
  tabla: string,
  columnas: readonly string[],
  miembro: Miembro,
  usuarioId: string,
  desde = 0,
): Promise<Record<string, unknown>[]> {
  const visible = soloLoVisible(tabla, miembro.rol);
  const lista = columnas.map((c) => columnaParaRol(tabla, c, miembro.rol)).join(', ');
  const { rows } = await cliente.query(
    `SELECT ${lista} FROM ${tabla}
      WHERE cambio > $2 AND (${visible ?? 'true'} OR $1::uuid IS NULL)
      ORDER BY cambio`,
    [usuarioId, desde],
  );
  return rows;
}

/**
 * El cambio más alto de la empresa en curso: desde ahí el teléfono pide lo
 * nuevo (entrega 17). Bloquea la empresa para lectura, así ninguna subida
 * de la misma empresa queda a medias entre lo leído y este número.
 */
export async function ultimoCambio(cliente: Cliente, empresaId: string): Promise<number> {
  await cliente.query('SELECT 1 FROM empresas WHERE id = $1 FOR SHARE', [empresaId]);
  const partes = ['empresas', 'membresias', ...Object.keys(tablas)].map(
    (t) => `SELECT max(cambio) AS c FROM ${t}`,
  );
  const { rows } = await cliente.query<{ c: number | null }>(
    `SELECT max(c) AS c FROM (${partes.join(' UNION ALL ')}) t`,
  );
  return rows[0]?.c ?? 0;
}

/**
 * Quiénes están en la empresa en curso, sin celulares: para que el teléfono
 * diga «Lo anotó Rosa» (entrega 20).
 */
export async function equipoVisible(cliente: Cliente, empresaId: string) {
  const { rows } = await cliente.query(
    `SELECT usuario_id, nombre, rol, titular FROM membresias
      WHERE quitada_en IS NULL AND empresa_id = $1
      ORDER BY titular DESC, creado_en`,
    [empresaId],
  );
  return rows;
}

/**
 * Todo lo de la empresa del usuario que su rol puede ver, para «Ya tengo
 * cuenta» (entrega 12). Con [empresaId], esa empresa (el contador puede
 * tener varias); si no, la primera. Nulo si no tiene ninguna activa.
 */
export async function bajar(
  pool: Pool,
  usuarioId: string,
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

    const datos: Record<string, unknown> = {
      usuario: (
        await cliente.query('SELECT id, celular FROM usuarios WHERE id = $1', [usuarioId])
      ).rows[0],
      membresia: {
        id: miembro.membresiaId,
        empresa_id: miembro.empresaId,
        rol: miembro.rol,
        titular: miembro.titular,
      },
      empresa: (
        await cliente.query(`SELECT ${columnasEmpresa.join(', ')} FROM empresas`)
      ).rows[0],
      hasta,
      equipo: await equipoVisible(cliente, miembro.empresaId),
    };
    for (const [tabla, columnas] of Object.entries(tablas)) {
      datos[tabla] = await leerTabla(cliente, tabla, columnas, miembro, usuarioId);
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

/** Las cifras solo para quien puede verlas (el ayudante no). */
export function cifrasPara(
  datos: Record<string, unknown> | null,
  ahora: Date,
): ReturnType<typeof calcularCifras> | null {
  const rol = (datos?.membresia as { rol?: string } | undefined)?.rol;
  if (!datos || rol === 'ayudante' || (rol && !veCifras(rol as Miembro['rol']))) return null;
  return calcularCifras(datos as unknown as DatosEmpresa, ahora);
}

/** La empresa pedida en «?empresa=»: nula si no viene o no es válida. */
export function empresaPedida(consulta: unknown): string | undefined {
  const valor = (consulta as { empresa?: unknown } | undefined)?.empresa;
  return typeof valor === 'string' && esUuid(valor) ? valor : undefined;
}

export function rutasBajada(app: FastifyInstance, pool: Pool, ahora: () => Date): void {
  app.get('/datos/bajar', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    const datos = await bajar(pool, usuarioId, empresaPedida(peticion.query));
    // Con las cifras ya calculadas (entrega 13). Comprimido: un año de
    // registros pesa menos que una foto.
    return enviarJson(peticion, respuesta, { datos, cifras: cifrasPara(datos, ahora()) });
  });
}
