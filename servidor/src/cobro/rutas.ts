import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import type { Cliente, Pool } from '../base/conexion.js';
import { empresaPedida } from '../datos/bajar.js';
import { autenticar } from '../datos/subir.js';
import { borrarDatos } from '../cuenta/borrar.js';
import { miembroDe } from '../equipo/miembros.js';
import { limpiarUso, usoDe } from '../uso/rutas.js';
import {
  diaEnLima,
  estadoDelCobro,
  type EstadoCobro,
  extrasPara,
  maximoDeFundadores,
  periodoDelPago,
  type Plan,
  precioDe,
  puedeSerFundador,
} from './estado.js';

/** Lo que el cobro toma del entorno (Render). Nada de esto va al repositorio. */
export interface ConfigCobro {
  /** MOCA_COBRO_DESDE («2026-11-10»): desde ese día cuenta la prueba. Sin él, no se cobra. */
  desde: string | null;
  /** MOCA_ADMIN_CELULARES: los números que registran pagos, separados por comas. */
  admins: string[];
  /** MOCA_YAPE_NUMERO y MOCA_YAPE_NOMBRE: a dónde yapear. */
  yape: { numero: string; nombre: string } | null;
  /** Mercado Pago está configurado (entrega 32): la app ofrece pagar ahí. */
  mercadoPago?: boolean;
  /** Google Play está configurado (entrega 78): la versión de Play paga ahí. */
  googlePlay?: boolean;
}

export const sinCobro: ConfigCobro = { desde: null, admins: [], yape: null };

const nueveDigitos = (celular: string) => celular.replace(/\D/g, '').slice(-9);

export function leerConfigCobro(entorno: NodeJS.ProcessEnv = process.env): ConfigCobro {
  const desde = entorno.MOCA_COBRO_DESDE?.trim();
  const numero = entorno.MOCA_YAPE_NUMERO?.trim();
  const nombre = entorno.MOCA_YAPE_NOMBRE?.trim();
  return {
    desde: desde && /^\d{4}-\d{2}-\d{2}$/.test(desde) ? desde : null,
    admins: (entorno.MOCA_ADMIN_CELULARES ?? '')
      .split(',')
      .map(nueveDigitos)
      .filter((c) => c.length === 9),
    yape: numero && nombre ? { numero: nueveDigitos(numero), nombre } : null,
  };
}

type Suscripcion = { plan: Plan; pagadoHasta: string; fueFundador: boolean };

/** Lo que hace falta para el estado de un negocio, con el filtro explícito. */
export async function datosDelCobro(
  cliente: Cliente,
  empresaId: string,
): Promise<{
  suscripcion: Suscripcion | null;
  inicioPrueba: string | null;
  fundadores: number;
  respondio: boolean;
  personas: number;
  diasExtra: number;
}> {
  const suscripcion = (
    await cliente.query<{
      plan: Plan;
      pagado_hasta: string;
      fue_fundador: boolean;
    }>('SELECT plan, pagado_hasta, fue_fundador FROM suscripciones WHERE empresa_id = $1', [
      empresaId,
    ])
  ).rows[0];
  const titular = (
    await cliente.query<{ celular: string | null }>(
      `SELECT u.celular FROM membresias m JOIN usuarios u ON u.id = m.usuario_id
        WHERE m.empresa_id = $1 AND m.titular AND m.quitada_en IS NULL`,
      [empresaId],
    )
  ).rows[0];
  const guardada = titular?.celular
    ? (
        await cliente.query<{ inicio: string }>(
          'SELECT inicio FROM pruebas_por_celular WHERE celular = $1',
          [titular.celular],
        )
      ).rows[0]?.inicio
    : undefined;
  const primero = (
    await cliente.query<{ primero: Date | null }>(
      'SELECT min(creado_en) AS primero FROM movimientos WHERE empresa_id = $1',
      [empresaId],
    )
  ).rows[0]?.primero;
  const fundadores = (
    await cliente.query<{ usados: number }>('SELECT usados FROM cupo_fundadores WHERE id = 1')
  ).rows[0]?.usados;
  const respondio = (
    await cliente.query('SELECT 1 FROM respuestas_precio WHERE empresa_id = $1 LIMIT 1', [
      empresaId,
    ])
  ).rowCount;
  // Las personas del negocio sin el contador (entrega 43).
  const personas = (
    await cliente.query<{ n: string }>(
      `SELECT count(*) AS n FROM membresias
        WHERE empresa_id = $1 AND quitada_en IS NULL AND rol <> 'contador'`,
      [empresaId],
    )
  ).rows[0]?.n;
  // Los días de prueba que regaló Jhony (entrega 47).
  const diasExtra = (
    await cliente.query<{ dias: number }>('SELECT dias FROM pruebas_extra WHERE empresa_id = $1', [
      empresaId,
    ])
  ).rows[0]?.dias;
  return {
    diasExtra: diasExtra ?? 0,
    personas: Math.max(1, Number(personas ?? 1)),
    respondio: Boolean(respondio),
    suscripcion: suscripcion
      ? {
          plan: suscripcion.plan,
          pagadoHasta: suscripcion.pagado_hasta,
          fueFundador: suscripcion.fue_fundador,
        }
      : null,
    inicioPrueba: guardada ?? (primero ? diaEnLima(primero) : null),
    fundadores: fundadores ?? 0,
  };
}

async function celularDe(pool: Pool, usuarioId: string): Promise<string | null> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    await cliente.query(`SELECT set_config('app.usuario_id', $1, true)`, [usuarioId]);
    const { rows } = await cliente.query<{ celular: string | null }>(
      'SELECT celular FROM usuarios WHERE id = $1',
      [usuarioId],
    );
    await cliente.query('COMMIT');
    return rows[0]?.celular ?? null;
  } finally {
    cliente.release();
  }
}

export async function esAdmin(pool: Pool, config: ConfigCobro, usuarioId: string) {
  if (!config.admins.length) return false;
  const celular = await celularDe(pool, usuarioId);
  return celular !== null && config.admins.includes(nueveDigitos(celular));
}

/** El estado para el teléfono, con a dónde yapear y si quien pide es admin. */
export type CobroParaElTelefono = EstadoCobro & {
  pago?: { yape: string; nombre: string };
  /** Se puede pagar con Mercado Pago (entrega 32). */
  mercadopago?: true;
  /** La versión de Play paga con Google Play (entrega 78). */
  google_play?: true;
  /** Google no pudo cobrar la renovación (entrega 79). */
  google_problema?: true;
  admin?: true;
  /** Ya contestó la pregunta del día 10 (entrega 25). */
  respondio: boolean;
};

export async function cobroParaElTelefono(
  pool: Pool,
  config: ConfigCobro,
  usuarioId: string,
  empresaId: string,
  ahora: Date,
): Promise<CobroParaElTelefono> {
  const cliente = await pool.connect();
  let datos: Awaited<ReturnType<typeof datosDelCobro>>;
  let problemaEnGoogle = false;
  try {
    await cliente.query('BEGIN');
    await cliente.query(
      `SELECT set_config('app.empresa_id', $1, true), set_config('app.usuario_id', $2, true)`,
      [empresaId, usuarioId],
    );
    datos = await datosDelCobro(cliente, empresaId);
    // Google no pudo cobrar la renovación (entrega 79): el dueño tiene que
    // revisar su medio de pago en Google Play.
    if (config.googlePlay) {
      const ultima = (
        await cliente.query<{ estado: string }>(
          `SELECT estado FROM compras_google WHERE empresa_id = $1
            ORDER BY actualizado_en DESC LIMIT 1`,
          [empresaId],
        )
      ).rows[0];
      problemaEnGoogle =
        ultima?.estado === 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD' ||
        ultima?.estado === 'SUBSCRIPTION_STATE_ON_HOLD';
    }
    await cliente.query('COMMIT');
  } catch (error) {
    await cliente.query('ROLLBACK');
    throw error;
  } finally {
    cliente.release();
  }
  const estado = estadoDelCobro({
    hoy: diaEnLima(ahora),
    cobroDesde: config.desde,
    ...datos,
  });
  return {
    ...estado,
    respondio: datos.respondio,
    ...(config.yape && estado.estado !== 'sin_cobro'
      ? { pago: { yape: config.yape.numero, nombre: config.yape.nombre } }
      : {}),
    ...(config.mercadoPago && estado.estado !== 'sin_cobro' ? { mercadopago: true as const } : {}),
    ...(config.googlePlay && estado.estado !== 'sin_cobro' ? { google_play: true as const } : {}),
    ...(problemaEnGoogle ? { google_problema: true as const } : {}),
    ...((await esAdmin(pool, config, usuarioId)) ? { admin: true as const } : {}),
  };
}

/**
 * Deja guardado el día en que empezó la prueba del número del titular, para
 * que no vuelva a empezar si borra el negocio y abre otro. Se llama después
 * de cada subida, con el cobro ya empezado.
 */
export async function recordarPrueba(
  pool: Pool,
  config: ConfigCobro,
  usuarioId: string,
  empresaId: string,
): Promise<void> {
  if (!config.desde) return;
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    await cliente.query(
      `SELECT set_config('app.empresa_id', $1, true), set_config('app.usuario_id', $2, true)`,
      [empresaId, usuarioId],
    );
    await cliente.query(
      `INSERT INTO pruebas_por_celular (celular, inicio)
       SELECT u.celular,
              greatest((min(mv.creado_en) AT TIME ZONE 'America/Lima')::date, $2::date)
         FROM membresias m
         JOIN usuarios u ON u.id = m.usuario_id
         JOIN movimientos mv ON mv.empresa_id = m.empresa_id
        WHERE m.empresa_id = $1 AND m.titular AND m.quitada_en IS NULL
          AND u.celular IS NOT NULL
        GROUP BY u.celular
       ON CONFLICT (celular) DO NOTHING`,
      [empresaId, config.desde],
    );
    await cliente.query('COMMIT');
  } catch (error) {
    await cliente.query('ROLLBACK');
    throw error;
  } finally {
    cliente.release();
  }
}

export class ErrorDeCobro extends Error {
  constructor(
    readonly codigo: number,
    readonly clave: string,
  ) {
    super(clave);
  }
}

/** Una transacción que ve todos los negocios: solo para quien registra pagos. */
async function comoAdmin<T>(
  pool: Pool,
  usuarioId: string,
  trabajo: (cliente: Cliente) => Promise<T>,
): Promise<T> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    await cliente.query(
      `SELECT set_config('app.admin', 'si', true), set_config('app.usuario_id', $1, true)`,
      [usuarioId],
    );
    const resultado = await trabajo(cliente);
    await cliente.query('COMMIT');
    return resultado;
  } catch (error) {
    await cliente.query('ROLLBACK');
    throw error;
  } finally {
    cliente.release();
  }
}

/**
 * Una transacción del servidor mismo, sin persona (entrega 32): el aviso de
 * Mercado Pago no trae llave. Ve todos los negocios, como quien registra
 * pagos; quien la usa ya comprobó qué negocio toca.
 */
export async function comoServidor<T>(
  pool: Pool,
  trabajo: (cliente: Cliente) => Promise<T>,
): Promise<T> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    await cliente.query(`SELECT set_config('app.admin', 'si', true)`);
    const resultado = await trabajo(cliente);
    await cliente.query('COMMIT');
    return resultado;
  } catch (error) {
    await cliente.query('ROLLBACK');
    throw error;
  } finally {
    cliente.release();
  }
}

/**
 * Registra un pago: el periodo sigue al anterior si no venció, y quien paga
 * en la prueba no pierde los días que le quedan. El mismo camino para el Yape
 * que registra Jhony y para Mercado Pago (entrega 32). Va dentro de una
 * transacción que ve todos los negocios.
 */
export async function registrarPago(
  cliente: Cliente,
  config: ConfigCobro,
  {
    empresaId,
    plan,
    nota,
    registradoPor,
    hoy,
    origen = 'yape',
    mpPagoId = null,
    googleOrden = null,
    periodo: periodoFijo,
    personasExtra,
  }: {
    empresaId: string;
    plan: Plan;
    /** Las que se cobraron (la orden de Mercado Pago); si no, las de hoy. */
    personasExtra?: number;
    nota: string | null;
    registradoPor: string;
    hoy: string;
    origen?: 'yape' | 'mercadopago' | 'google';
    mpPagoId?: string | null;
    /** El número de orden de Google (entrega 78): un pago por orden. */
    googleOrden?: string | null;
    /**
     * Lo decide Google (entrega 78): desde el día del cobro hasta el día en
     * que vence. Lo ya pagado no se acorta.
     */
    periodo?: { desde: string; hasta: string };
  },
): Promise<void> {
  // Un pago a la vez: el cupo de fundadores no se pasa de 50.
  const cupo = (
    await cliente.query<{ usados: number }>(
      'SELECT usados FROM cupo_fundadores WHERE id = 1 FOR UPDATE',
    )
  ).rows[0]!.usados;
  const datos = await datosDelCobro(cliente, empresaId);
  const actual = datos.suscripcion;
  const ahoraMismo = estadoDelCobro({
    hoy,
    cobroDesde: config.desde,
    ...datos,
  });
  if (plan === 'fundador' && !puedeSerFundador({ hoy, suscripcion: actual, fundadores: cupo })) {
    throw new ErrorDeCobro(409, actual?.fueFundador ? 'perdio_fundador' : 'sin_cupo_fundador');
  }
  const extras = personasExtra ?? extrasPara(plan, datos.personas);
  const periodo =
    periodoFijo ??
    periodoDelPago({
      hoy,
      pagadoHasta:
        actual?.pagadoHasta ?? (ahoraMismo.estado === 'prueba' ? ahoraMismo.hasta : null),
      plan,
    });
  const pagadoHasta =
    periodoFijo && actual && actual.pagadoHasta > periodo.hasta ? actual.pagadoHasta : periodo.hasta;
  await cliente.query(
    `INSERT INTO pagos (id, empresa_id, plan, monto_centimos, desde, hasta, nota, registrado_por,
                        origen, mp_pago_id, personas_extra, google_orden)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
    [
      randomUUID(),
      empresaId,
      plan,
      precioDe(plan, extras),
      periodo.desde,
      periodo.hasta,
      nota,
      registradoPor,
      origen,
      mpPagoId,
      extras,
      googleOrden,
    ],
  );
  await cliente.query(
    `INSERT INTO suscripciones (empresa_id, plan, pagado_hasta, fue_fundador, personas_extra)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (empresa_id) DO UPDATE
       SET plan = $2, pagado_hasta = $3,
           fue_fundador = suscripciones.fue_fundador OR $4,
           personas_extra = $5,
           actualizado_en = now()`,
    [empresaId, plan, pagadoHasta, plan === 'fundador', extras],
  );
  if (plan === 'fundador' && !actual?.fueFundador) {
    await cliente.query('UPDATE cupo_fundadores SET usados = usados + 1 WHERE id = 1');
  }
}

/**
 * Anula un pago (entrega 26.1): solo el último del negocio, porque los demás
 * siguen a este y sus fechas se cruzarían. El negocio queda como antes de ese
 * pago y, si era su único pago de fundador, el cupo vuelve. Devuelve el
 * negocio. También lo usa la devolución de Mercado Pago (entrega 32).
 */
export async function anularPago(cliente: Cliente, pagoId: string): Promise<string> {
  await cliente.query('SELECT usados FROM cupo_fundadores WHERE id = 1 FOR UPDATE');
  const pago = (
    await cliente.query<{ empresa_id: string }>(
      'SELECT empresa_id FROM pagos WHERE id::text = $1 AND anulado_en IS NULL',
      [pagoId],
    )
  ).rows[0];
  if (!pago) throw new ErrorDeCobro(404, 'sin_pago');
  const vigentes = `SELECT id, plan, hasta, personas_extra FROM pagos
      WHERE empresa_id = $1 AND anulado_en IS NULL ORDER BY creado_en DESC`;
  const ultimo = (await cliente.query<{ id: string }>(vigentes, [pago.empresa_id])).rows[0];
  if (ultimo?.id !== pagoId) throw new ErrorDeCobro(409, 'no_es_el_ultimo');
  const antes = (await datosDelCobro(cliente, pago.empresa_id)).suscripcion;
  await cliente.query('UPDATE pagos SET anulado_en = now() WHERE id = $1', [pagoId]);

  const quedan = (
    await cliente.query<{ plan: Plan; hasta: string; personas_extra: number }>(vigentes, [
      pago.empresa_id,
    ])
  ).rows;
  const sigueFundador = quedan.some((p) => p.plan === 'fundador');
  const anterior = quedan[0];
  if (anterior) {
    await cliente.query(
      `UPDATE suscripciones SET plan = $2, pagado_hasta = $3, fue_fundador = $4,
              personas_extra = $5, actualizado_en = now()
        WHERE empresa_id = $1`,
      [pago.empresa_id, anterior.plan, anterior.hasta, sigueFundador, anterior.personas_extra],
    );
  } else {
    await cliente.query('DELETE FROM suscripciones WHERE empresa_id = $1', [pago.empresa_id]);
  }
  if (antes?.fueFundador && !sigueFundador) {
    await cliente.query('UPDATE cupo_fundadores SET usados = greatest(usados - 1, 0) WHERE id = 1');
  }
  return pago.empresa_id;
}

/**
 * Lo que la ficha de soporte suma (entrega 47): las personas con su versión
 * de Moca y su última subida, las invitaciones y cuántos registros hay. Sin
 * montos ni notas: lo que anotan sigue siendo suyo.
 */
async function soporteDe(cliente: Cliente, empresaId: string) {
  const personas = (
    await cliente.query(
      `SELECT m.nombre, m.rol, m.titular, right(u.celular, 9) AS celular,
              m.version_app, m.subio_en
         FROM membresias m JOIN usuarios u ON u.id = m.usuario_id
        WHERE m.empresa_id = $1 AND m.quitada_en IS NULL
        ORDER BY m.titular DESC, m.creado_en`,
      [empresaId],
    )
  ).rows;
  // Vigente, vencida, aceptada o anulada, con el reloj de la base, como en
  // «Mi equipo».
  const invitaciones = (
    await cliente.query(
      `SELECT right(celular, 9) AS celular, rol, nombre,
              creada_en + interval '7 days' AS vence_en,
              CASE WHEN aceptada_en IS NOT NULL THEN 'aceptada'
                   WHEN anulada_en IS NOT NULL THEN 'anulada'
                   WHEN creada_en + interval '7 days' < now() THEN 'vencida'
                   ELSE 'vigente' END AS estado
         FROM invitaciones WHERE empresa_id = $1
        ORDER BY creada_en DESC LIMIT 20`,
      [empresaId],
    )
  ).rows;
  const registros = Number(
    (
      await cliente.query<{ n: string }>(
        `SELECT count(*) AS n FROM movimientos WHERE empresa_id = $1 AND estado = 'vigente'`,
        [empresaId],
      )
    ).rows[0]?.n ?? 0,
  );
  return { personas, invitaciones, registros };
}

interface FichaDelNegocio {
  empresa_id: string;
  nombre: string;
  celular: string | null;
  cobro: EstadoCobro;
}

async function ficha(
  cliente: Cliente,
  config: ConfigCobro,
  empresa: { id: string; nombre: string; celular: string | null },
  hoy: string,
): Promise<FichaDelNegocio> {
  const datos = await datosDelCobro(cliente, empresa.id);
  return {
    empresa_id: empresa.id,
    nombre: empresa.nombre,
    celular: empresa.celular ? nueveDigitos(empresa.celular) : null,
    cobro: estadoDelCobro({ hoy, cobroDesde: config.desde, ...datos }),
  };
}

/** Los negocios activos con el número de su titular. */
export const empresasConTitular = `
  SELECT e.id, e.nombre, u.celular
    FROM empresas e
    JOIN membresias m ON m.empresa_id = e.id AND m.titular AND m.quitada_en IS NULL
    JOIN usuarios u ON u.id = m.usuario_id`;

export function rutasCobro(
  app: FastifyInstance,
  pool: Pool,
  config: ConfigCobro,
  ahora: () => Date,
): void {
  /** Solo los números de MOCA_ADMIN_CELULARES pasan. */
  async function admin(peticion: Parameters<typeof autenticar>[1]) {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) throw new ErrorDeCobro(401, 'sin_sesion');
    if (!(await esAdmin(pool, config, usuarioId))) throw new ErrorDeCobro(403, 'sin_permiso');
    return usuarioId;
  }

  function responder(
    error: unknown,
    respuesta: { code: (n: number) => { send: (c: object) => unknown } },
  ) {
    if (error instanceof ErrorDeCobro)
      return respuesta.code(error.codigo).send({ error: error.clave });
    throw error;
  }

  // La pregunta del día 10 (entrega 25): la contesta cualquiera del negocio.
  app.post<{ Body: { respuesta?: unknown; motivo?: unknown } }>(
    '/cobro/respuesta',
    async (peticion, respuesta) => {
      const usuarioId = await autenticar(pool, peticion);
      if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
      const { respuesta: dijo, motivo } = peticion.body ?? {};
      if (
        (dijo !== 'si' && dijo !== 'no_se' && dijo !== 'no') ||
        (motivo !== undefined && motivo !== null && typeof motivo !== 'string')
      ) {
        return respuesta.code(400).send({ error: 'datos_invalidos' });
      }
      const empresaId = empresaPedida(peticion.query);
      const cliente = await pool.connect();
      try {
        await cliente.query('BEGIN');
        const miembro = await miembroDe(cliente, usuarioId, empresaId);
        if (!miembro) {
          await cliente.query('ROLLBACK');
          return respuesta.code(403).send({ error: 'sin_negocio' });
        }
        await cliente.query(
          `SELECT set_config('app.empresa_id', $1, true), set_config('app.usuario_id', $2, true)`,
          [miembro.empresaId, usuarioId],
        );
        const datos = await datosDelCobro(cliente, miembro.empresaId);
        const { precio } = estadoDelCobro({
          hoy: diaEnLima(ahora()),
          cobroDesde: config.desde,
          ...datos,
        });
        await cliente.query(
          `INSERT INTO respuestas_precio (id, empresa_id, usuario_id, respuesta, motivo, precio_centimos)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [
            randomUUID(),
            miembro.empresaId,
            usuarioId,
            dijo,
            typeof motivo === 'string' && motivo.trim() ? motivo.trim().slice(0, 300) : null,
            precio,
          ],
        );
        await cliente.query('COMMIT');
        return { recibida: true };
      } catch (error) {
        await cliente.query('ROLLBACK');
        throw error;
      } finally {
        cliente.release();
      }
    },
  );

  // «Mis pagos de Moca» (entrega 33): los pagos del negocio, para sus dueños.
  // De un pago por Yape no va la nota: la escribe Jhony, para él.
  app.get('/cobro/mis-pagos', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    const cliente = await pool.connect();
    try {
      await cliente.query('BEGIN');
      const miembro = await miembroDe(cliente, usuarioId, empresaPedida(peticion.query));
      if (!miembro || miembro.rol !== 'dueno') {
        await cliente.query('ROLLBACK');
        return respuesta.code(403).send({ error: miembro ? 'solo_duenos' : 'sin_negocio' });
      }
      await cliente.query(`SELECT set_config('app.empresa_id', $1, true)`, [miembro.empresaId]);
      const pagos = (
        await cliente.query<{
          id: string;
          plan: Plan;
          monto_centimos: number;
          desde: string;
          hasta: string;
          creado_en: Date;
          origen: string;
          mp_pago_id: string | null;
          anulado_en: Date | null;
          personas_extra: number;
        }>(
          `SELECT id, plan, monto_centimos, desde, hasta, creado_en, origen, mp_pago_id, anulado_en,
                  personas_extra
             FROM pagos WHERE empresa_id = $1 ORDER BY creado_en DESC`,
          [miembro.empresaId],
        )
      ).rows;
      // Lo que Mercado Pago cobró y Jhony todavía tiene que revisar.
      const revisar = (
        await cliente.query<{ monto_centimos: number; actualizado_en: Date }>(
          `SELECT monto_centimos, actualizado_en FROM ordenes_pago
            WHERE empresa_id = $1 AND estado = 'revisar' ORDER BY actualizado_en DESC`,
          [miembro.empresaId],
        )
      ).rows;
      await cliente.query('COMMIT');
      return {
        pagos: pagos.map((p) => ({
          id: p.id,
          plan: p.plan,
          monto_centimos: p.monto_centimos,
          personas_extra: p.personas_extra,
          desde: p.desde,
          hasta: p.hasta,
          pagado_en: new Date(p.creado_en).toISOString(),
          medio: p.origen,
          ...(p.origen === 'mercadopago' && p.mp_pago_id ? { operacion: p.mp_pago_id } : {}),
          anulado: p.anulado_en !== null,
        })),
        en_revision: revisar.map((o) => ({
          monto_centimos: o.monto_centimos,
          desde_el: new Date(o.actualizado_en).toISOString(),
        })),
      };
    } catch (error) {
      await cliente.query('ROLLBACK');
      throw error;
    } finally {
      cliente.release();
    }
  });

  // Un negocio por el número de su dueño, con sus pagos.
  app.get('/cobro/negocio', async (peticion, respuesta) => {
    try {
      const usuarioId = await admin(peticion);
      const consulta = peticion.query as {
        celular?: unknown;
        empresa?: unknown;
      };
      // Por el celular del titular o, desde la búsqueda de soporte (entrega
      // 47), por el negocio.
      const porEmpresa = typeof consulta.empresa === 'string' ? consulta.empresa : null;
      const celular = nueveDigitos(String(consulta.celular ?? ''));
      if (!porEmpresa && celular.length !== 9) throw new ErrorDeCobro(400, 'datos_invalidos');
      return await comoAdmin(pool, usuarioId, async (cliente) => {
        const empresa = (
          await cliente.query<{ id: string; nombre: string; celular: string }>(
            porEmpresa
              ? `${empresasConTitular} WHERE e.id::text = $1`
              : `${empresasConTitular} WHERE right(u.celular, 9) = $1`,
            [porEmpresa ?? celular],
          )
        ).rows[0];
        if (!empresa) throw new ErrorDeCobro(404, 'sin_negocio');
        const pagos = (
          await cliente.query(
            `SELECT id, plan, monto_centimos, desde, hasta, nota, creado_en, anulado_en, origen,
                    personas_extra
               FROM pagos WHERE empresa_id = $1 ORDER BY creado_en DESC`,
            [empresa.id],
          )
        ).rows;
        const respuestas = (
          await cliente.query(
            `SELECT respuesta, motivo, precio_centimos, creado_en
               FROM respuestas_precio WHERE empresa_id = $1 ORDER BY creado_en DESC`,
            [empresa.id],
          )
        ).rows;
        await limpiarUso(cliente);
        return {
          ...(await soporteDe(cliente, empresa.id)),
          respuestas,
          // Lo que respondió el piloto con su uso (entrega 28).
          uso: await usoDe(cliente, empresa.id),
          ...(await ficha(cliente, config, empresa, diaEnLima(ahora()))),
          pagos,
        };
      });
    } catch (error) {
      return responder(error, respuesta);
    }
  });

  // Soporte (entrega 47): un número cualquiera, con sus negocios y su rol.
  app.get('/soporte/buscar', async (peticion, respuesta) => {
    try {
      const usuarioId = await admin(peticion);
      const celular = nueveDigitos(String((peticion.query as { celular?: unknown }).celular ?? ''));
      if (celular.length !== 9) throw new ErrorDeCobro(400, 'datos_invalidos');
      return await comoAdmin(pool, usuarioId, async (cliente) => {
        const usuario = (
          await cliente.query<{ id: string }>(
            'SELECT id FROM usuarios WHERE right(celular, 9) = $1 LIMIT 1',
            [celular],
          )
        ).rows[0];
        const negocios = usuario
          ? (
              await cliente.query(
                `SELECT e.id AS empresa_id, e.nombre, m.rol, m.titular
                   FROM membresias m JOIN empresas e ON e.id = m.empresa_id
                  WHERE m.usuario_id = $1 AND m.quitada_en IS NULL
                  ORDER BY m.titular DESC, m.creado_en`,
                [usuario.id],
              )
            ).rows
          : [];
        return { tiene_cuenta: Boolean(usuario), negocios };
      });
    } catch (error) {
      return responder(error, respuesta);
    }
  });

  // Días de prueba de regalo (entrega 47): solo a quien nunca pagó.
  app.post<{ Body: { empresa?: unknown; dias?: unknown } }>(
    '/soporte/dias-prueba',
    async (peticion, respuesta) => {
      try {
        const usuarioId = await admin(peticion);
        const { empresa, dias } = peticion.body ?? {};
        if (typeof empresa !== 'string' || (dias !== 7 && dias !== 14)) {
          throw new ErrorDeCobro(400, 'datos_invalidos');
        }
        const hoy = diaEnLima(ahora());
        return await comoAdmin(pool, usuarioId, async (cliente) => {
          const negocio = (
            await cliente.query<{
              id: string;
              nombre: string;
              celular: string;
            }>(`${empresasConTitular} WHERE e.id::text = $1`, [empresa])
          ).rows[0];
          if (!negocio) throw new ErrorDeCobro(404, 'sin_negocio');
          const datos = await datosDelCobro(cliente, negocio.id);
          if (datos.suscripcion) throw new ErrorDeCobro(409, 'ya_pago');
          const antes = datos.diasExtra;
          if (antes + dias > 60) throw new ErrorDeCobro(409, 'demasiados_dias');
          await cliente.query(
            `INSERT INTO pruebas_extra (empresa_id, dias) VALUES ($1, $2)
             ON CONFLICT (empresa_id) DO UPDATE
               SET dias = pruebas_extra.dias + $2, actualizado_en = now()`,
            [negocio.id, dias],
          );
          await cliente.query(
            `INSERT INTO acciones_soporte (id, admin_id, empresa_id, empresa_nombre, accion, detalle)
             VALUES ($1, $2, $3, $4, 'dias_prueba', $5)`,
            [randomUUID(), usuarioId, negocio.id, negocio.nombre, `+${dias} días`],
          );
          return await ficha(cliente, config, negocio, hoy);
        });
      } catch (error) {
        return responder(error, respuesta);
      }
    },
  );

  // Borrar un negocio a pedido de su titular (entrega 47): lo mismo que
  // «Borrar mi negocio», confirmado con el nombre del negocio.
  app.post<{ Body: { empresa?: unknown; confirmacion?: unknown } }>(
    '/soporte/borrar',
    async (peticion, respuesta) => {
      try {
        const usuarioId = await admin(peticion);
        const { empresa, confirmacion } = peticion.body ?? {};
        if (typeof empresa !== 'string' || typeof confirmacion !== 'string') {
          throw new ErrorDeCobro(400, 'datos_invalidos');
        }
        const negocio = await comoAdmin(pool, usuarioId, async (cliente) => {
          const fila = (
            await cliente.query<{
              id: string;
              nombre: string;
              titular_id: string;
            }>(
              `SELECT e.id, e.nombre, m.usuario_id AS titular_id
                 FROM empresas e
                 JOIN membresias m ON m.empresa_id = e.id AND m.titular AND m.quitada_en IS NULL
                WHERE e.id::text = $1`,
              [empresa],
            )
          ).rows[0];
          if (!fila) throw new ErrorDeCobro(404, 'sin_negocio');
          if (fila.nombre.trim().toLowerCase() !== confirmacion.trim().toLowerCase()) {
            throw new ErrorDeCobro(400, 'sin_confirmacion');
          }
          await cliente.query(
            `INSERT INTO acciones_soporte (id, admin_id, empresa_id, empresa_nombre, accion)
             VALUES ($1, $2, $3, $4, 'borrar')`,
            [randomUUID(), usuarioId, fila.id, fila.nombre],
          );
          return fila;
        });
        await borrarDatos(pool, negocio.titular_id);
        return { borrado: true };
      } catch (error) {
        return responder(error, respuesta);
      }
    },
  );

  // Registra un pago por Yape: el periodo sigue al anterior si no venció.
  app.post<{ Body: { empresa?: unknown; plan?: unknown; nota?: unknown } }>(
    '/cobro/pago',
    async (peticion, respuesta) => {
      try {
        const usuarioId = await admin(peticion);
        const { empresa, plan, nota } = peticion.body ?? {};
        if (
          typeof empresa !== 'string' ||
          (plan !== 'basico' &&
            plan !== 'basico_anual' &&
            plan !== 'normal' &&
            plan !== 'fundador' &&
            plan !== 'anual') ||
          (nota !== undefined && nota !== null && typeof nota !== 'string')
        ) {
          throw new ErrorDeCobro(400, 'datos_invalidos');
        }
        const hoy = diaEnLima(ahora());
        return await comoAdmin(pool, usuarioId, async (cliente) => {
          const negocio = (
            await cliente.query<{
              id: string;
              nombre: string;
              celular: string;
            }>(`${empresasConTitular} WHERE e.id::text = $1`, [empresa])
          ).rows[0];
          if (!negocio) throw new ErrorDeCobro(404, 'sin_negocio');
          await registrarPago(cliente, config, {
            empresaId: negocio.id,
            plan,
            nota: typeof nota === 'string' && nota.trim() ? nota.trim().slice(0, 200) : null,
            registradoPor: usuarioId,
            hoy,
          });
          return await ficha(cliente, config, negocio, hoy);
        });
      } catch (error) {
        return responder(error, respuesta);
      }
    },
  );

  // Anula el último pago de un negocio (entrega 26.1): queda como antes de
  // ese pago y, si era su único pago de fundador, el cupo vuelve.
  app.post<{ Body: { pago?: unknown } }>('/cobro/anular', async (peticion, respuesta) => {
    try {
      const usuarioId = await admin(peticion);
      const pagoId = peticion.body?.pago;
      if (typeof pagoId !== 'string') throw new ErrorDeCobro(400, 'datos_invalidos');
      const hoy = diaEnLima(ahora());
      return await comoAdmin(pool, usuarioId, async (cliente) => {
        const empresaId = await anularPago(cliente, pagoId);
        const negocio = (
          await cliente.query<{
            id: string;
            nombre: string;
            celular: string;
          }>(`${empresasConTitular} WHERE e.id = $1`, [empresaId])
        ).rows[0]!;
        return await ficha(cliente, config, negocio, hoy);
      });
    } catch (error) {
      return responder(error, respuesta);
    }
  });

  // Lo que vence pronto o ya venció (30 días), y cuántos fundadores van.
  app.get('/cobro/resumen', async (peticion, respuesta) => {
    try {
      const usuarioId = await admin(peticion);
      const hoy = diaEnLima(ahora());
      return await comoAdmin(pool, usuarioId, async (cliente) => {
        const negocios = (
          await cliente.query<{ id: string; nombre: string; celular: string }>(
            `${empresasConTitular} ORDER BY e.nombre`,
          )
        ).rows;
        const fichas: FichaDelNegocio[] = [];
        for (const negocio of negocios) fichas.push(await ficha(cliente, config, negocio, hoy));
        const fundadores = (
          await cliente.query<{ usados: number }>('SELECT usados FROM cupo_fundadores WHERE id = 1')
        ).rows[0]!.usados;
        // Los que no abren Moca hace 3 días o más (entrega 28).
        const sinAbrir = (
          await cliente.query<{ empresa_id: string; ultima: Date | null }>(
            `SELECT empresa_id, ultima FROM (
               SELECT e.id AS empresa_id,
                      (SELECT max(fecha) FROM eventos_uso u
                        WHERE u.empresa_id = e.id AND u.nombre = 'appAbierta') AS ultima
                 FROM empresas e) x
              WHERE ultima IS NULL OR ultima < now() - interval '3 days'`,
          )
        ).rows;
        const porId = new Map(fichas.map((f) => [f.empresa_id, f]));
        // Lo cobrado por Mercado Pago que no se pudo aplicar solo (entrega 32).
        const revisar = (
          await cliente.query(
            `SELECT o.id, e.nombre, right(u.celular, 9) AS celular, o.plan, o.monto_centimos,
                    o.motivo, o.mp_pago_id, o.actualizado_en
               FROM ordenes_pago o
               JOIN empresas e ON e.id = o.empresa_id
               JOIN usuarios u ON u.id = o.usuario_id
              WHERE o.estado = 'revisar'
              ORDER BY o.actualizado_en DESC`,
          )
        ).rows;
        // Google devolvió un pago que no era el último (entrega 79): Jhony
        // decide si anularlo a mano.
        const revisarGoogle = (
          await cliente.query(
            `SELECT c.token, e.nombre, right(u.celular, 9) AS celular, c.producto, c.ultima_orden,
                    c.actualizado_en
               FROM compras_google c
               JOIN empresas e ON e.id = c.empresa_id
               JOIN usuarios u ON u.id = c.usuario_id
              WHERE c.motivo = 'reembolso_por_revisar'
              ORDER BY c.actualizado_en DESC`,
          )
        ).rows;
        return {
          revisar,
          revisar_google: revisarGoogle,
          sin_abrir: sinAbrir.flatMap((s) => {
            const f = porId.get(s.empresa_id);
            return f
              ? [
                  {
                    ...f,
                    ultima_apertura: s.ultima ? new Date(s.ultima).toISOString() : null,
                  },
                ]
              : [];
          }),
          fundadores: { usados: fundadores, maximo: maximoDeFundadores },
          negocios: fichas.filter((f) => f.cobro.porVencer || f.cobro.estado === 'vencido'),
        };
      });
    } catch (error) {
      return responder(error, respuesta);
    }
  });
}
