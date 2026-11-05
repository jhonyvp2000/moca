import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import type { Pool } from '../base/conexion.js';
import {
  anularPago,
  cobroParaElTelefono,
  comoServidor,
  type ConfigCobro,
  datosDelCobro,
  ErrorDeCobro,
  registrarPago,
} from '../cobro/rutas.js';
import { diaEnLima, estadoDelCobro, type Plan, precios } from '../cobro/estado.js';
import { empresaPedida } from '../datos/bajar.js';
import { autenticar } from '../datos/subir.js';
import { miembroDe } from '../equipo/miembros.js';
import {
  type ConfigMercadoPago,
  firmaValida,
  type MercadoPago,
  type PagoMercadoPago,
} from './cliente.js';

// Pagar Moca con Mercado Pago (entrega 32), el mismo circuito de TVSamGo:
//  - POST /cobro/mercadopago      → el dueño pide pagar: orden + preferencia.
//  - POST /mercadopago/webhook    → el aviso de Mercado Pago (público).
//  - GET  /cobro/orden/:id        → la app pregunta al volver de pagar.
//  - GET  /pago/retorno           → la página a la que vuelve el dueño.
// Un pago se aplica SOLO por `aplicarPago`, que lo recorren el aviso, la
// pregunta de la app y el repaso de cada 5 minutos, a veces a la vez.

const esUuid = (v: string) =>
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);

export type Aplicado =
  | 'sin_referencia'
  | 'orden_desconocida'
  | 'procesado'
  | 'ya_estaba'
  | 'revisar'
  | 'devuelto'
  | 'rechazado'
  | 'sin_cambios';

export interface Cobrador {
  aplicarPago(pago: PagoMercadoPago): Promise<Aplicado>;
  /** Los pagos que cambiaron en las últimas horas, por el mismo camino. */
  repasar(horas?: number): Promise<{ vistos: number; procesados: number }>;
}

export function rutasMercadoPago(
  app: FastifyInstance,
  pool: Pool,
  cobro: ConfigCobro,
  config: ConfigMercadoPago | null,
  mp: MercadoPago | null,
  ahora: () => Date,
): Cobrador {
  /**
   * Aplica un pago que vino de la API de Mercado Pago, nunca del aviso. Puede
   * correr N veces con el mismo pago, incluso a la vez, y deja un solo pago:
   * la orden se bloquea y el número de operación es único.
   */
  async function aplicarPago(pago: PagoMercadoPago): Promise<Aplicado> {
    const referencia = pago.external_reference;
    // La cuenta también cobra a TVSamGo: lo que no es una orden de Moca, se deja.
    if (!referencia || !esUuid(String(referencia))) return 'sin_referencia';
    const mpId = String(pago.id);
    return comoServidor(pool, async (cliente) => {
      const orden = (
        await cliente.query<{
          id: string;
          empresa_id: string;
          usuario_id: string;
          plan: Plan;
          monto_centimos: number;
          estado: string;
        }>('SELECT * FROM ordenes_pago WHERE id = $1 FOR UPDATE', [referencia])
      ).rows[0];
      if (!orden) return 'orden_desconocida';
      const marcar = (estado: string, motivo: string | null = null) =>
        cliente.query(
          `UPDATE ordenes_pago SET estado = $2, motivo = $3, mp_pago_id = $4, actualizado_en = now()
            WHERE id = $1`,
          [orden.id, estado, motivo, mpId],
        );

      if (pago.status === 'approved') {
        const ya = await cliente.query('SELECT 1 FROM pagos WHERE mp_pago_id = $1', [mpId]);
        if (ya.rowCount) {
          if (orden.estado !== 'pagada' && orden.estado !== 'reembolsada') await marcar('pagada');
          return 'ya_estaba';
        }
        // Lo cobrado tiene que cubrir la orden, en soles.
        if (
          Math.round(Number(pago.transaction_amount) * 100) < orden.monto_centimos ||
          (pago.currency_id !== undefined && pago.currency_id !== 'PEN')
        ) {
          await marcar('revisar', 'monto');
          return 'revisar';
        }
        try {
          await registrarPago(cliente, cobro, {
            empresaId: orden.empresa_id,
            plan: orden.plan,
            nota: `Mercado Pago · operación ${mpId}`,
            registradoPor: orden.usuario_id,
            hoy: diaEnLima(ahora()),
            origen: 'mercadopago',
            mpPagoId: mpId,
          });
        } catch (error) {
          // Cobrado pero ya no le toca ese plan (se acabó el cupo de
          // fundador): lo resuelve Jhony a mano, con la devolución o el plan.
          if (error instanceof ErrorDeCobro) {
            await marcar('revisar', error.clave);
            return 'revisar';
          }
          throw error;
        }
        await marcar('pagada');
        return 'procesado';
      }

      // Un contracargo que el vendedor ganó vuelve como «reimbursed»: sigue valiendo.
      const devuelto =
        pago.status === 'refunded' ||
        (pago.status === 'charged_back' && pago.status_detail !== 'reimbursed');
      if (devuelto) {
        const local = (
          await cliente.query<{ id: string }>(
            'SELECT id FROM pagos WHERE mp_pago_id = $1 AND anulado_en IS NULL',
            [mpId],
          )
        ).rows[0];
        if (!local) return 'sin_cambios';
        try {
          await anularPago(cliente, local.id);
        } catch (error) {
          // Ya hay otro pago después: anularlo cruzaría las fechas.
          if (error instanceof ErrorDeCobro) {
            await marcar('revisar', 'devuelto');
            return 'revisar';
          }
          throw error;
        }
        await marcar('reembolsada');
        return 'devuelto';
      }

      if ((pago.status === 'rejected' || pago.status === 'cancelled') && orden.estado === 'pendiente') {
        await marcar('rechazada');
        return 'rechazado';
      }
      return 'sin_cambios';
    });
  }

  async function repasar(horas = 6) {
    if (!mp) return { vistos: 0, procesados: 0 };
    let procesados = 0;
    const pagos = await mp.buscarPagos({ horas });
    for (const pago of pagos) {
      // Uno que falla no frena a los demás: el próximo repaso lo vuelve a ver.
      try {
        const r = await aplicarPago(pago);
        if (r === 'procesado' || r === 'devuelto') procesados++;
      } catch (error) {
        app.log.error({ error, pago: pago.id }, 'el repaso no pudo aplicar un pago');
      }
    }
    return { vistos: pagos.length, procesados };
  }

  // El dueño pide pagar el mes: su orden y la página de Mercado Pago.
  app.post('/cobro/mercadopago', async (peticion, respuesta) => {
    if (!config || !mp) return respuesta.code(503).send({ error: 'sin_mercadopago' });
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    const cliente = await pool.connect();
    let empresaId: string;
    let nombre: string;
    let plan: Plan;
    let monto: number;
    try {
      await cliente.query('BEGIN');
      const miembro = await miembroDe(cliente, usuarioId, empresaPedida(peticion.query));
      if (!miembro) {
        await cliente.query('ROLLBACK');
        return respuesta.code(403).send({ error: 'sin_negocio' });
      }
      if (miembro.rol !== 'dueno') {
        await cliente.query('ROLLBACK');
        return respuesta.code(403).send({ error: 'solo_duenos' });
      }
      empresaId = miembro.empresaId;
      await cliente.query(`SELECT set_config('app.empresa_id', $1, true)`, [empresaId]);
      const estado = estadoDelCobro({
        hoy: diaEnLima(ahora()),
        cobroDesde: cobro.desde,
        ...(await datosDelCobro(cliente, empresaId)),
      });
      nombre =
        (
          await cliente.query<{ nombre: string }>('SELECT nombre FROM empresas WHERE id = $1', [
            empresaId,
          ])
        ).rows[0]?.nombre ?? 'tu negocio';
      await cliente.query('COMMIT');
      if (estado.estado === 'sin_cobro') return respuesta.code(409).send({ error: 'sin_cobro' });
      // Se paga el mes al precio que le toca: de fundador o normal.
      plan = estado.precio < precios.normal ? 'fundador' : 'normal';
      monto = estado.precio;
    } catch (error) {
      await cliente.query('ROLLBACK');
      throw error;
    } finally {
      cliente.release();
    }

    // Si ya hay una orden reciente del mismo plan, se reusa: entrar y salir
    // del pago varias veces no llena la tabla.
    const ordenId = await comoServidor(pool, async (c) => {
      const previa = (
        await c.query<{ id: string }>(
          `SELECT id FROM ordenes_pago
            WHERE empresa_id = $1 AND usuario_id = $2 AND plan = $3 AND estado = 'pendiente'
              AND creado_en > now() - interval '1 hour'
            ORDER BY creado_en DESC LIMIT 1`,
          [empresaId, usuarioId, plan],
        )
      ).rows[0];
      if (previa) return previa.id;
      const id = randomUUID();
      await c.query(
        `INSERT INTO ordenes_pago (id, empresa_id, usuario_id, plan, monto_centimos)
         VALUES ($1, $2, $3, $4, $5)`,
        [id, empresaId, usuarioId, plan, monto],
      );
      return id;
    });
    try {
      const preferencia = await mp.crearPreferencia({
        titulo: `Moca · 1 mes · ${nombre}`.slice(0, 120),
        centimos: monto,
        referencia: ordenId,
        avisos: `${config.urlPublica}/mercadopago/webhook`,
        retorno: `${config.urlPublica}/pago/retorno`,
      });
      await comoServidor(pool, (c) =>
        c.query(
          'UPDATE ordenes_pago SET mp_preferencia_id = $2, actualizado_en = now() WHERE id = $1',
          [ordenId, preferencia.id],
        ),
      );
      return { orden: ordenId, enlace: preferencia.enlace, monto_centimos: monto };
    } catch (error) {
      app.log.error({ error }, 'Mercado Pago no creó la preferencia');
      return respuesta.code(502).send({ error: 'mercadopago_fallo' });
    }
  });

  // El aviso de Mercado Pago: público. La regla de oro: lo que llega no es la
  // verdad; se comprueba la firma y se vuelve a consultar el pago.
  app.post('/mercadopago/webhook', async (peticion) => {
    const q = (peticion.query ?? {}) as Record<string, unknown>;
    const cuerpo = (peticion.body ?? {}) as { type?: unknown; data?: { id?: unknown } };
    const tipo = q.type ?? q.topic ?? cuerpo.type;
    const dataId = q['data.id'] ?? q.id ?? cuerpo.data?.id;
    if (tipo !== 'payment' || (typeof dataId !== 'string' && typeof dataId !== 'number')) {
      return { ok: true, ignorado: true };
    }
    if (!config || !mp) return { ok: true, ignorado: true };
    if (
      config.secreto &&
      !firmaValida({
        secreto: config.secreto,
        firma: peticion.headers['x-signature'] as string | undefined,
        pedido: peticion.headers['x-request-id'] as string | undefined,
        dataId: String(dataId),
        ahora: ahora(),
      })
    ) {
      // 200 igual: no darle pistas a quien falsifica ni reintentos a Mercado Pago.
      app.log.warn({ dataId }, 'aviso de Mercado Pago con firma inválida');
      return { ok: true, ignorado: true };
    }
    try {
      return { ok: true, resultado: await aplicarPago(await mp.obtenerPago(String(dataId))) };
    } catch (error) {
      // 200 igual: si era un pago bueno, lo levanta el repaso o la app.
      app.log.error({ error }, 'no se pudo aplicar el aviso de Mercado Pago');
      return { ok: false };
    }
  });

  // La app pregunta cada 3 segundos al volver de pagar; Mercado Pago se
  // consulta como mucho cada 15 segundos por orden.
  const consultadas = new Map<string, number>();
  app.get<{ Params: { id: string } }>('/cobro/orden/:id', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    const id = peticion.params.id;
    if (!esUuid(id)) return respuesta.code(404).send({ error: 'sin_orden' });
    const leer = () =>
      comoServidor(pool, async (c) =>
        (
          await c.query<{ estado: string; empresa_id: string }>(
            'SELECT estado, empresa_id FROM ordenes_pago WHERE id = $1 AND usuario_id = $2',
            [id, usuarioId],
          )
        ).rows[0],
      );
    let orden = await leer();
    if (!orden) return respuesta.code(404).send({ error: 'sin_orden' });
    if (mp && (orden.estado === 'pendiente' || orden.estado === 'rechazada')) {
      const momento = ahora().getTime();
      if (momento - (consultadas.get(id) ?? 0) >= 15_000) {
        consultadas.set(id, momento);
        try {
          for (const pago of await mp.buscarPagos({ referencia: id })) await aplicarPago(pago);
        } catch (error) {
          app.log.warn({ error }, 'no se pudo consultar la orden en Mercado Pago');
        }
        orden = (await leer()) ?? orden;
      }
    }
    return {
      // Un rechazo no es el final: en la misma página puede probar con otra
      // tarjeta. La app sigue esperando.
      estado: orden.estado === 'rechazada' ? 'pendiente' : orden.estado,
      ...(orden.estado === 'pagada'
        ? { cobro: await cobroParaElTelefono(pool, cobro, usuarioId, orden.empresa_id, ahora()) }
        : {}),
    };
  });

  // A donde vuelve el dueño al terminar en Mercado Pago.
  app.get('/pago/retorno', async (peticion, respuesta) => {
    const estado = String((peticion.query as { estado?: unknown }).estado ?? '');
    return respuesta.type('text/html; charset=utf-8').send(paginaDeRetorno(estado));
  });

  return { aplicarPago, repasar };
}

const mensajes: Record<string, [string, string]> = {
  exito: ['Pago recibido', 'Moca se activa en unos segundos.'],
  pendiente: ['Pago en proceso', 'Cuando se acredite, Moca se activa sola.'],
  fallo: ['El pago no se completó', 'No se cobró nada. Puedes intentar otra vez desde Moca.'],
};

export function paginaDeRetorno(estado: string): string {
  const [titulo, detalle] = mensajes[estado] ?? [
    'Listo',
    'Vuelve a Moca para ver cómo quedó tu pago.',
  ];
  // Como en TVSamGo, sin enlace a la app: con taskAffinity="" un enlace
  // podría abrir una segunda copia de Moca en vez de la que espera el pago.
  return `<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Moca · Pago</title>
<style>
body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
background:#F3F6FB;color:#0F1F3D;font-family:Roboto,'Segoe UI',Arial,sans-serif}
.caja{background:#FFFFFF;border:1px solid #D8E0EC;border-radius:16px;padding:28px 22px;
max-width:360px;margin:16px;text-align:center}
h1{font-size:22px;margin:0 0 8px}p{font-size:16px;color:#4B5A75;line-height:1.5;margin:0 0 20px}
strong{display:block;background:#E3ECFB;color:#1E3A8A;font-size:16px;padding:14px;
border-radius:12px}
.marca{margin-top:18px;font-size:14px;color:#1E3A8A;font-weight:700}
</style></head><body><div class="caja">
<h1>${titulo}</h1><p>${detalle}</p>
<strong>Ya puedes volver a Moca.</strong>
<div class="marca">Moca · Tú vendes. Moca hace las cuentas.</div>
</div></body></html>`;
}
