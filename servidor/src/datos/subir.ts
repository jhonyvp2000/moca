import type { FastifyInstance, FastifyRequest } from 'fastify';
import type { Cliente, Pool } from '../base/conexion.js';
import { cifrasDe, enviarJson } from '../cifras/rutas.js';
import { usuarioDeLlave } from '../cuenta/sesiones.js';

/**
 * Las tablas que sube el teléfono, con sus columnas, en el orden en que se
 * guardan. Las referencias se revisan al cerrar la transacción (migración
 * 002), así el orden no importa para la base.
 */
export const tablas = {
  cuentas: ['id', 'empresa_id', 'tipo', 'nombre', 'orden', 'saldo_inicial_centimos', 'fecha_saldo_inicial'],
  categorias: ['id', 'empresa_id', 'nombre', 'tipo_movimiento', 'orden', 'activa'],
  contrapartes: ['id', 'empresa_id', 'nombre', 'identificacion_fiscal', 'tipo'],
  comprobantes: [
    'id', 'empresa_id', 'emisor_identificacion', 'emisor_nombre', 'tipo', 'serie',
    'numero', 'fecha_emision', 'subtotal_centimos', 'impuesto_centimos',
    'total_centimos', 'origen_lectura', 'creado_en',
  ],
  items_comprobante: [
    'id', 'empresa_id', 'comprobante_id', 'descripcion', 'cantidad',
    'precio_unitario_centimos', 'importe_centimos',
  ],
  movimientos: [
    'id', 'empresa_id', 'tipo', 'cuenta_id', 'monto_centimos', 'fecha_movimiento',
    'fecha_comprobante', 'estado_pago', 'monto_pagado_centimos', 'fecha_vencimiento',
    'fecha_pago', 'categoria_id', 'contraparte_id', 'comprobante_id',
    'nivel_confianza', 'fuente', 'autor_id', 'nota', 'estado', 'reemplaza_a',
    'creado_en',
  ],
  arqueos: ['id', 'empresa_id', 'fecha', 'autor_id', 'creado_en'],
  arqueo_cuentas: [
    'id', 'empresa_id', 'arqueo_id', 'cuenta_id', 'saldo_calculado_centimos',
    'saldo_real_centimos', 'diferencia_centimos', 'motivo', 'movimiento_id',
  ],
  dias_cerrados: ['id', 'empresa_id', 'dia'],
  // Los avisos que el dueño marcó «Entendido» (entrega 13).
  alertas: ['id', 'empresa_id', 'clave', 'tipo', 'prioridad', 'estado', 'texto', 'datos', 'creado_en'],
  // Los videos de ayuda abiertos (entrega 14.6).
  videos_vistos: ['id', 'empresa_id', 'video', 'desde', 'fecha'],
  bitacora: [
    'id', 'empresa_id', 'autor_id', 'entidad', 'entidad_id', 'accion',
    'valor_anterior', 'valor_nuevo', 'fecha',
  ],
} as const;

type Tabla = keyof typeof tablas;
type Fila = Record<string, unknown>;

/** La bitácora y los videos vistos no se modifican: lo que ya está, se deja. */
const soloAgregar = new Set<Tabla>(['bitacora', 'videos_vistos']);

export const columnasEmpresa = [
  'id', 'nombre', 'tipo_negocio', 'modo', 'pais', 'moneda', 'regimen',
  'hora_cierre_minutos', 'identificacion_fiscal', 'creado_en',
];

export interface Subida {
  empresa: Fila;
  [tabla: string]: unknown;
}

/** Inserta o actualiza las filas, por su id. */
async function guardar(
  cliente: Cliente,
  tabla: string,
  columnas: readonly string[],
  filas: Fila[],
  agregarSolo: boolean,
): Promise<number> {
  if (!filas.length) return 0;
  const lista = columnas.join(', ');
  const cambios = columnas
    .filter((c) => c !== 'id' && c !== 'empresa_id')
    .map((c) => `${c} = EXCLUDED.${c}`)
    .join(', ');
  await cliente.query(
    `INSERT INTO ${tabla} (${lista})
     SELECT ${lista} FROM jsonb_populate_recordset(NULL::${tabla}, $1::jsonb)
     ON CONFLICT (id) DO ${agregarSolo ? 'NOTHING' : `UPDATE SET ${cambios}`}`,
    [JSON.stringify(filas)],
  );
  return filas.length;
}

class ErrorDeSubida extends Error {
  constructor(
    readonly codigo: number,
    readonly clave: string,
  ) {
    super(clave);
  }
}

/**
 * Guarda lo que el teléfono tiene de su empresa. Repetirlo no duplica nada.
 * Si la empresa no existe, la crea con quien sube como dueño; si existe,
 * solo la puede tocar alguien que sea miembro.
 */
export async function subir(
  pool: Pool,
  usuarioId: string,
  datos: Subida,
): Promise<Record<string, number>> {
  const empresaId = String(datos.empresa.id ?? '');
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    await cliente.query(
      `SELECT set_config('app.empresa_id', $1, true),
              set_config('app.usuario_id', $2, true)`,
      [empresaId, usuarioId],
    );
    const existe = await cliente.query('SELECT 1 FROM empresas WHERE id = $1', [empresaId]);
    if (existe.rowCount) {
      const miembro = await cliente.query(
        'SELECT 1 FROM membresias WHERE usuario_id = $1',
        [usuarioId],
      );
      if (!miembro.rowCount) throw new ErrorDeSubida(403, 'no_es_tu_empresa');
    }
    await guardar(cliente, 'empresas', columnasEmpresa, [datos.empresa], false);
    if (!existe.rowCount) {
      await cliente.query(
        `INSERT INTO membresias (id, empresa_id, usuario_id, rol)
         VALUES (gen_random_uuid(), $1, $2, 'dueno')`,
        [empresaId, usuarioId],
      );
    }

    const recibidos: Record<string, number> = {};
    for (const [tabla, columnas] of Object.entries(tablas) as [Tabla, readonly string[]][]) {
      const filas = ((datos[tabla] as Fila[] | undefined) ?? []).map((f) => ({
        ...f,
        empresa_id: empresaId,
      }));
      // En la V1 cada empresa tiene un solo usuario: todo lo anotó él.
      if (filas.some((f) => 'autor_id' in f && f.autor_id !== usuarioId)) {
        throw new ErrorDeSubida(400, 'autor_distinto');
      }
      recibidos[tabla] = await guardar(cliente, tabla, columnas, filas, soloAgregar.has(tabla));
    }
    await cliente.query('COMMIT');
    return recibidos;
  } catch (error) {
    await cliente.query('ROLLBACK');
    throw error;
  } finally {
    cliente.release();
  }
}

/** Lee la llave del teléfono («Authorization: Bearer …»). */
export async function autenticar(pool: Pool, peticion: FastifyRequest): Promise<string | null> {
  const [tipo, llave] = (peticion.headers.authorization ?? '').split(' ');
  if (tipo !== 'Bearer' || !llave) return null;
  return usuarioDeLlave(pool, llave);
}

const listaDeFilas = { type: 'array', items: { type: 'object' } } as const;

export function rutasDatos(app: FastifyInstance, pool: Pool, ahora: () => Date): void {
  app.post<{ Body: Subida }>(
    '/datos/subir',
    {
      bodyLimit: 20 * 1024 * 1024,
      schema: {
        body: {
          type: 'object',
          required: ['empresa'],
          properties: {
            empresa: {
              type: 'object',
              required: ['id'],
              properties: { id: { type: 'string', format: 'uuid' } },
            },
            ...Object.fromEntries(Object.keys(tablas).map((t) => [t, listaDeFilas])),
          },
        },
      },
    },
    async (peticion, respuesta) => {
      const usuarioId = await autenticar(pool, peticion);
      if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
      try {
        const recibidos = await subir(pool, usuarioId, peticion.body);
        // Las cifras con lo recién subido (entrega 13).
        return enviarJson(peticion, respuesta, {
          recibidos,
          cifras: await cifrasDe(pool, usuarioId, ahora()),
        });
      } catch (error) {
        if (error instanceof ErrorDeSubida) {
          return respuesta.code(error.codigo).send({ error: error.clave });
        }
        const codigoPg = (error as { code?: string }).code;
        // Datos que la base rechaza: un valor que no es de la app, una
        // referencia que no existe o un intento de tocar otra empresa.
        if (codigoPg === '42501') return respuesta.code(403).send({ error: 'no_es_tu_empresa' });
        if (codigoPg?.startsWith('22') || codigoPg?.startsWith('23')) {
          return respuesta.code(400).send({
            error: 'datos_invalidos',
            detalle: (error as Error).message,
          });
        }
        throw error;
      }
    },
  );
}
