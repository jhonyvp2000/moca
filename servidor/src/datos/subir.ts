import type { FastifyInstance, FastifyRequest } from 'fastify';
import type { Cliente, Pool } from '../base/conexion.js';
import { cifrasDe, enviarJson } from '../cifras/rutas.js';
import { usuarioDeLlave } from '../cuenta/sesiones.js';
import { cajasDe, miembroDe, tiposDeCaja, type Miembro } from '../equipo/miembros.js';

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

/** La fecha en Lima («2026-10-29»): el ayudante deshace lo suyo del día. */
const diaEnLima = (fecha: Date) =>
  new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Lima' }).format(fecha);

/** Lo que cada rol puede crear o cambiar, además de lo suyo (entrega 17). */
const tablasPorRol: Record<Miembro['rol'], ReadonlySet<string>> = {
  dueno: new Set(Object.keys(tablas)),
  encargado: new Set([
    'contrapartes', 'comprobantes', 'items_comprobante', 'movimientos', 'arqueos',
    'arqueo_cuentas', 'dias_cerrados', 'alertas', 'videos_vistos', 'bitacora',
  ]),
  ayudante: new Set([
    'contrapartes', 'comprobantes', 'items_comprobante', 'movimientos', 'videos_vistos',
    'bitacora',
  ]),
  contador: new Set(),
};

/**
 * Las filas que de verdad son nuevas o cambian: lo que sube igual a lo que
 * ya está no cuenta. Para cada una, si es nueva y su autor antes y ahora.
 */
async function filasQueCambian(
  cliente: Cliente,
  tabla: string,
  columnas: readonly string[],
  filas: Fila[],
): Promise<
  {
    nueva: boolean;
    autor: unknown;
    autorAntes: unknown;
    creadaAntes: Date | null;
    cuenta: string | null;
  }[]
> {
  if (!filas.length) return [];
  const comparar = columnas.filter((c) => c !== 'empresa_id');
  const conAutor = columnas.includes('autor_id');
  const { rows } = await cliente.query(
    `SELECT o.id IS NULL AS nueva,
            ${columnas.includes('cuenta_id') ? 'n.cuenta_id' : 'NULL::uuid'} AS cuenta,
            ${conAutor ? 'n.autor_id AS autor, o.autor_id AS autor_antes' : 'NULL AS autor, NULL AS autor_antes'},
            ${columnas.includes('creado_en') ? 'o.creado_en' : 'NULL::timestamptz'} AS creada_antes
       FROM jsonb_populate_recordset(NULL::${tabla}, $1::jsonb) n
       LEFT JOIN ${tabla} o ON o.id = n.id
      WHERE o.id IS NULL
         OR (${comparar.map((c) => `n.${c}`).join(', ')})
            IS DISTINCT FROM (${comparar.map((c) => `o.${c}`).join(', ')})`,
    [JSON.stringify(filas)],
  );
  return rows.map((f) => ({
    nueva: f.nueva as boolean,
    autor: f.autor,
    autorAntes: f.autor_antes,
    creadaAntes: f.creada_antes as Date | null,
    cuenta: f.cuenta as string | null,
  }));
}

/**
 * Revisa que quien sube pueda crear o cambiar cada fila. Lo nuevo siempre
 * lleva como autor a quien sube. Corregir lo de otro, solo dueños y
 * encargado; el ayudante, solo lo suyo y del mismo día; el contador no sube.
 */
async function revisarPermisos(
  cliente: Cliente,
  miembro: Miembro,
  usuarioId: string,
  datos: Subida,
  ahora: Date,
): Promise<void> {
  const empresa = await filasQueCambian(cliente, 'empresas', columnasEmpresa, [datos.empresa]);
  if (empresa.length && miembro.rol !== 'dueno') throw new ErrorDeSubida(403, 'sin_permiso');

  // Las cajas de efectivo del negocio y las del miembro (entrega 21): el
  // encargado y el ayudante solo anotan en las suyas (y en Yape o banco).
  const cajas = await cajasDe(cliente, miembro);
  const todasLasCajas = new Set(
    (
      await cliente.query<{ id: string }>(
        'SELECT id FROM cuentas WHERE tipo = ANY($1)',
        [tiposDeCaja],
      )
    ).rows.map((f) => f.id),
  );
  const cajaAjena = (cuenta: string | null) =>
    cajas != null && cuenta != null && todasLasCajas.has(cuenta) && !cajas.includes(cuenta);

  for (const [tabla, columnas] of Object.entries(tablas) as [Tabla, readonly string[]][]) {
    const filas = ((datos[tabla] as Fila[] | undefined) ?? []).map((f) => ({
      ...f,
      empresa_id: miembro.empresaId,
    }));
    for (const fila of await filasQueCambian(cliente, tabla, columnas, filas)) {
      if (cajaAjena(fila.cuenta)) throw new ErrorDeSubida(403, 'sin_permiso');
      if (fila.nueva && fila.autor != null && fila.autor !== usuarioId) {
        throw new ErrorDeSubida(400, 'autor_distinto');
      }
      if (!fila.nueva && fila.autor !== fila.autorAntes) {
        throw new ErrorDeSubida(400, 'autor_distinto');
      }
      if (!tablasPorRol[miembro.rol].has(tabla)) throw new ErrorDeSubida(403, 'sin_permiso');
      if (fila.nueva) continue;
      // Cambiar algo que ya estaba.
      const deOtro = fila.autorAntes != null && fila.autorAntes !== usuarioId;
      if (miembro.rol === 'ayudante') {
        const delDia =
          fila.creadaAntes != null && diaEnLima(fila.creadaAntes) === diaEnLima(ahora);
        if (tabla !== 'movimientos' || deOtro || !delDia) {
          throw new ErrorDeSubida(403, 'sin_permiso');
        }
      } else if (deOtro && miembro.rol !== 'dueno' && miembro.rol !== 'encargado') {
        throw new ErrorDeSubida(403, 'sin_permiso');
      }
    }
  }
}

/**
 * Guarda lo que el teléfono tiene de su empresa, o solo lo que cambió.
 * Repetirlo no duplica nada. Si la empresa no existe, la crea con quien sube
 * como dueño titular; si existe, solo la puede tocar un miembro activo y
 * según su rol (entrega 17).
 */
export async function subir(
  pool: Pool,
  usuarioId: string,
  datos: Subida,
  ahora = new Date(),
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
    // Una subida a la vez por empresa: así «lo nuevo desde el cambio N» no
    // se salta nada.
    const existe = await cliente.query('SELECT 1 FROM empresas WHERE id = $1 FOR UPDATE', [
      empresaId,
    ]);
    // Solo los dueños cambian la empresa; lo demás se revisa fila por fila.
    let tocaLaEmpresa = true;
    if (existe.rowCount) {
      const miembro = await miembroDe(cliente, usuarioId, empresaId);
      if (!miembro) throw new ErrorDeSubida(403, 'no_es_tu_empresa');
      await revisarPermisos(cliente, miembro, usuarioId, datos, ahora);
      tocaLaEmpresa = miembro.rol === 'dueno';
    }
    if (tocaLaEmpresa) {
      await guardar(cliente, 'empresas', columnasEmpresa, [datos.empresa], false);
    }
    if (!existe.rowCount) {
      await cliente.query(
        `INSERT INTO membresias (id, empresa_id, usuario_id, rol, titular)
         VALUES (gen_random_uuid(), $1, $2, 'dueno', true)`,
        [empresaId, usuarioId],
      );
    }

    const recibidos: Record<string, number> = {};
    for (const [tabla, columnas] of Object.entries(tablas) as [Tabla, readonly string[]][]) {
      const filas = ((datos[tabla] as Fila[] | undefined) ?? []).map((f) => ({
        ...f,
        empresa_id: empresaId,
      }));
      if (!existe.rowCount && filas.some((f) => 'autor_id' in f && f.autor_id !== usuarioId)) {
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
        const recibidos = await subir(pool, usuarioId, peticion.body, ahora());
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
