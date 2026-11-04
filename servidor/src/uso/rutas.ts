import type { FastifyInstance } from 'fastify';
import type { Cliente, Pool } from '../base/conexion.js';
import { autenticar } from '../datos/subir.js';
import { miembroDe } from '../equipo/miembros.js';

// Lo que mide la app (entrega 28): el teléfono lo sube con su cuenta y Jhony
// lo ve resumido por negocio en «Cobros».

export const diasDeUso = 90;
const maximoPorEnvio = 500;

const esUuid = (v: unknown): v is string =>
  typeof v === 'string' &&
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);

interface EventoDelTelefono {
  id: string;
  nombre: string;
  fecha: string;
  datos?: Record<string, unknown> | null;
}

function valido(e: unknown): e is EventoDelTelefono {
  if (typeof e !== 'object' || e === null) return false;
  const x = e as Record<string, unknown>;
  return (
    esUuid(x.id) &&
    typeof x.nombre === 'string' &&
    x.nombre.length <= 40 &&
    typeof x.fecha === 'string' &&
    !Number.isNaN(Date.parse(x.fecha)) &&
    (x.datos === undefined ||
      x.datos === null ||
      (typeof x.datos === 'object' && JSON.stringify(x.datos).length <= 500))
  );
}

/** El uso de un negocio en los últimos 7 días, para las preguntas del piloto. */
export interface UsoDelNegocio {
  dias_que_abrio: number;
  dias_que_anoto: number;
  ventas_anotadas: number;
  /** La mediana de segundos para anotar la venta del día; nula sin ventas. */
  segundos_para_anotar: number | null;
  voz_con_duda: number;
  voz_corregida: number;
  fotos_ilegibles: number;
  avisos_respondidos: number;
  avisos_abiertos: number;
  arqueos_abiertos: number;
  informes_abiertos: number;
  /** La última vez que abrió Moca (cualquier día). */
  ultima_apertura: string | null;
}

/** Con `app.admin` o con el negocio en curso: las políticas dejan leer. */
export async function usoDe(cliente: Cliente, empresaId: string): Promise<UsoDelNegocio> {
  const { rows } = await cliente.query<{ nombre: string; n: number }>(
    `SELECT nombre, count(*)::int AS n FROM eventos_uso
      WHERE empresa_id = $1 AND fecha > now() - interval '7 days'
      GROUP BY nombre`,
    [empresaId],
  );
  const cuenta = (nombre: string) => rows.find((r) => r.nombre === nombre)?.n ?? 0;
  const dias = (
    await cliente.query<{ abrio: number; mediana: number | null; ultima: Date | null }>(
      `SELECT
         count(DISTINCT (fecha AT TIME ZONE 'America/Lima')::date)
           FILTER (WHERE nombre = 'appAbierta' AND fecha > now() - interval '7 days')::int AS abrio,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY (datos->>'segundos')::numeric)
           FILTER (WHERE nombre = 'ventaGuardada' AND datos ? 'segundos'
                   AND fecha > now() - interval '7 days') AS mediana,
         max(fecha) FILTER (WHERE nombre = 'appAbierta') AS ultima
       FROM eventos_uso WHERE empresa_id = $1`,
      [empresaId],
    )
  ).rows[0];
  const anoto = (
    await cliente.query<{ n: number }>(
      `SELECT count(DISTINCT (creado_en AT TIME ZONE 'America/Lima')::date)::int AS n
         FROM movimientos
        WHERE empresa_id = $1 AND creado_en > now() - interval '7 days'`,
      [empresaId],
    )
  ).rows[0];
  return {
    dias_que_abrio: dias?.abrio ?? 0,
    dias_que_anoto: anoto?.n ?? 0,
    ventas_anotadas: cuenta('ventaGuardada'),
    segundos_para_anotar: dias?.mediana == null ? null : Math.round(Number(dias.mediana)),
    voz_con_duda: cuenta('vozConDuda'),
    voz_corregida: cuenta('vozCorregida'),
    fotos_ilegibles: cuenta('fotoIlegible'),
    avisos_respondidos: cuenta('notificacionRespondida'),
    avisos_abiertos: cuenta('notificacionAbierta'),
    arqueos_abiertos: cuenta('arqueoAbierto'),
    informes_abiertos: cuenta('informeAbierto'),
    ultima_apertura: dias?.ultima ? new Date(dias.ultima).toISOString() : null,
  };
}

/** Lo de más de 90 días se va. Solo con `app.admin`. */
export async function limpiarUso(cliente: Cliente): Promise<void> {
  await cliente.query(`DELETE FROM eventos_uso WHERE fecha < now() - make_interval(days => $1)`, [
    diasDeUso,
  ]);
}

export function rutasUso(app: FastifyInstance, pool: Pool): void {
  app.post<{ Body: { eventos?: unknown } }>('/uso', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    const lista = peticion.body?.eventos;
    if (!Array.isArray(lista) || lista.length > maximoPorEnvio || !lista.every(valido)) {
      return respuesta.code(400).send({ error: 'datos_invalidos' });
    }
    const cliente = await pool.connect();
    try {
      await cliente.query('BEGIN');
      const miembro = await miembroDe(cliente, usuarioId);
      if (!miembro) {
        await cliente.query('ROLLBACK');
        return respuesta.code(403).send({ error: 'sin_negocio' });
      }
      await cliente.query(`SELECT set_config('app.empresa_id', $1, true)`, [miembro.empresaId]);
      for (const e of lista) {
        await cliente.query(
          `INSERT INTO eventos_uso (id, empresa_id, usuario_id, nombre, fecha, datos)
           VALUES ($1, $2, $3, $4, $5, $6)
           ON CONFLICT (id) DO NOTHING`,
          [e.id, miembro.empresaId, usuarioId, e.nombre, e.fecha, e.datos ?? null],
        );
      }
      await cliente.query('COMMIT');
      return { recibidos: lista.length };
    } catch (error) {
      await cliente.query('ROLLBACK');
      throw error;
    } finally {
      cliente.release();
    }
  });
}
