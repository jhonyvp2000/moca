import type { FastifyInstance } from 'fastify';
import type { Pool } from '../base/conexion.js';
import { timingSafeEqual } from 'node:crypto';
import {
  anularPago,
  cobroParaElTelefono,
  comoServidor,
  type ConfigCobro,
  ErrorDeCobro,
  registrarPago,
} from '../cobro/rutas.js';
import { diaEnLima } from '../cobro/estado.js';
import { empresaPedida } from '../datos/bajar.js';
import { autenticar } from '../datos/subir.js';
import { miembroDe } from '../equipo/miembros.js';
import { type GooglePlay, paquete, type SuscripcionGoogle } from './cliente.js';
import { planDelProducto } from './productos.js';

// Pagar Moca con Google Play (entrega 78), en la versión de Play Store:
//  - POST /cobro/google { token }: el teléfono compró; el servidor le pregunta
//    a Google, revisa que la compra sea de ese negocio, la registra y la
//    reconoce. Sin reconocerla, Google la devuelve sola a los 3 días: así se
//    devuelve lo que no se pudo aplicar (otro negocio, fundador sin cupo).
//  - POST /google/avisos?clave=…: los avisos en tiempo real de Google (entrega
//    79), por Pub/Sub: renovación, cancelación, pago con problemas, reembolso.
//    Lo que dice el aviso no es la verdad: con su token se le vuelve a
//    preguntar a Google.
// Una compra se aplica SOLO por `aplicar`, que recorren la app, los avisos y
// el repaso de cada 6 horas, a veces a la vez.

/** Los estados en que la compra da acceso a Moca. */
const vigentes = new Set(['SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD']);

export type AplicadaGoogle =
  | 'procesada'
  | 'ya_estaba'
  | 'no_vigente'
  | 'producto_desconocido'
  | 'otro_negocio'
  | 'revisar';

export interface CobradorGoogle {
  /**
   * Le pregunta a Google por una compra y la aplica. Si el servidor no la
   * conocía (la app se cerró antes de mandarla), la guarda a nombre del
   * titular del negocio que dice la compra.
   */
  aplicarCompra(token: string): Promise<AplicadaGoogle | 'desconocida'>;
  /** Anula el pago de una orden que Google devolvió (entrega 79). */
  anularOrden(orden: string): Promise<'anulado' | 'sin_pago' | 'revisar'>;
  /** Las compras que pueden haber cambiado, por el mismo camino (entrega 79). */
  repasar(): Promise<{ vistas: number; procesadas: number }>;
}

/** La clave de los avisos (GOOGLE_PLAY_AVISOS_CLAVE): va en la dirección que se le da a Pub/Sub. */
export function claveCorrecta(esperada: string | null, recibida: unknown): boolean {
  if (!esperada) return true;
  if (typeof recibida !== 'string') return false;
  const a = Buffer.from(esperada);
  const b = Buffer.from(recibida);
  return a.length === b.length && timingSafeEqual(a, b);
}

export function rutasGooglePlay(
  app: FastifyInstance,
  pool: Pool,
  cobro: ConfigCobro,
  google: GooglePlay | null,
  ahora: () => Date,
  claveAvisos: string | null = null,
): CobradorGoogle {
  /**
   * Aplica lo que Google dice de una compra ya guardada. Puede correr N veces
   * con la misma compra, incluso a la vez, y deja un pago por cada orden de
   * Google: la compra se bloquea y el número de orden es único.
   */
  async function aplicar(token: string, sub: SuscripcionGoogle): Promise<AplicadaGoogle> {
    const linea = sub.lineItems?.[0];
    const vence = linea?.expiryTime ? new Date(linea.expiryTime) : null;
    const producto = linea
      ? planDelProducto(
          linea.productId,
          linea.offerDetails?.basePlanId,
          linea.offerDetails?.offerId,
        )
      : null;
    const resultado = await comoServidor(pool, async (cliente) => {
      const compra = (
        await cliente.query<{ empresa_id: string; usuario_id: string }>(
          'SELECT empresa_id, usuario_id FROM compras_google WHERE token = $1 FOR UPDATE',
          [token],
        )
      ).rows[0];
      if (!compra) return 'otro_negocio' as const;
      const marcar = (motivo: string | null) =>
        cliente.query(
          `UPDATE compras_google
              SET producto = $2, plan_base = $3, oferta = $4, estado = $5, vence = $6,
                  ultima_orden = $7, prueba = $9, actualizado_en = now(),
                  -- Un reembolso por revisar queda hasta que Jhony lo vea.
                  motivo = CASE WHEN motivo = 'reembolso_por_revisar' THEN motivo ELSE $8 END
            WHERE token = $1`,
          [
            token,
            linea?.productId ?? '',
            linea?.offerDetails?.basePlanId ?? null,
            linea?.offerDetails?.offerId ?? null,
            sub.subscriptionState,
            vence,
            sub.latestOrderId ?? null,
            motivo,
            sub.testPurchase !== undefined,
          ],
        );
      // La app pone el id del negocio al comprar: una compra no sirve para otro.
      if (sub.externalAccountIdentifiers?.obfuscatedExternalAccountId !== compra.empresa_id) {
        await marcar('otro_negocio');
        return 'otro_negocio' as const;
      }
      if (!producto || !linea) {
        await marcar('producto_desconocido');
        return 'producto_desconocido' as const;
      }
      const hoy = diaEnLima(ahora());
      const hasta = vence ? diaEnLima(vence) : null;
      if (!vigentes.has(sub.subscriptionState) || !hasta || hasta < hoy || !sub.latestOrderId) {
        await marcar(null);
        return 'no_vigente' as const;
      }
      const ya = await cliente.query('SELECT 1 FROM pagos WHERE google_orden = $1', [
        sub.latestOrderId,
      ]);
      if (ya.rowCount) {
        await marcar(null);
        return 'ya_estaba' as const;
      }
      try {
        await registrarPago(cliente, cobro, {
          empresaId: compra.empresa_id,
          plan: producto.plan,
          personasExtra: producto.extras,
          nota: `Google Play · orden ${sub.latestOrderId}`,
          registradoPor: compra.usuario_id,
          hoy,
          origen: 'google',
          googleOrden: sub.latestOrderId,
          periodo: { desde: hoy, hasta },
        });
      } catch (error) {
        // Fundador sin cupo: no se reconoce y Google la devuelve sola.
        if (error instanceof ErrorDeCobro) {
          await marcar(error.clave);
          return 'revisar' as const;
        }
        throw error;
      }
      await marcar(null);
      return 'procesada' as const;
    });
    // Reconocer después de guardar: si falla, el próximo intento lo repite.
    if (
      (resultado === 'procesada' || resultado === 'ya_estaba') &&
      sub.acknowledgementState !== 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED' &&
      linea &&
      google
    ) {
      await google.reconocer(linea.productId, token);
    }
    return resultado;
  }

  async function aplicarCompra(token: string): Promise<AplicadaGoogle | 'desconocida'> {
    if (!google) throw new Error('Google Play no está configurado');
    const sub = await google.suscripcion(token);
    const empresa = sub.externalAccountIdentifiers?.obfuscatedExternalAccountId;
    const conocida = await comoServidor(pool, async (c) => {
      if ((await c.query('SELECT 1 FROM compras_google WHERE token = $1', [token])).rowCount) {
        return true;
      }
      if (!empresa || !/^[0-9a-f-]{36}$/i.test(empresa)) return false;
      const titular = (
        await c.query<{ usuario_id: string }>(
          'SELECT usuario_id FROM membresias WHERE empresa_id = $1 AND titular',
          [empresa],
        )
      ).rows[0];
      if (!titular) return false;
      await c.query(
        `INSERT INTO compras_google (token, empresa_id, usuario_id, producto, estado)
         VALUES ($1, $2, $3, $4, $5) ON CONFLICT (token) DO NOTHING`,
        [token, empresa, titular.usuario_id, sub.lineItems?.[0]?.productId ?? '', sub.subscriptionState],
      );
      return true;
    });
    if (!conocida) return 'desconocida';
    return aplicar(token, sub);
  }

  async function anularOrden(orden: string): Promise<'anulado' | 'sin_pago' | 'revisar'> {
    return comoServidor(pool, async (c) => {
      const pago = (
        await c.query<{ id: string }>(
          'SELECT id FROM pagos WHERE google_orden = $1 AND anulado_en IS NULL',
          [orden],
        )
      ).rows[0];
      if (!pago) return 'sin_pago';
      try {
        await anularPago(c, pago.id);
        return 'anulado';
      } catch (error) {
        // No es el último pago del negocio: lo resuelve Jhony a mano.
        if (error instanceof ErrorDeCobro) {
          await c.query(
            `UPDATE compras_google SET motivo = 'reembolso_por_revisar', actualizado_en = now()
              WHERE empresa_id = (SELECT empresa_id FROM pagos WHERE id = $1)`,
            [pago.id],
          );
          return 'revisar';
        }
        throw error;
      }
    });
  }

  async function repasar(): Promise<{ vistas: number; procesadas: number }> {
    if (!google) return { vistas: 0, procesadas: 0 };
    // Las que están vivas y vencen pronto, o que nadie miró en un día.
    const tokens = await comoServidor(pool, async (c) =>
      (
        await c.query<{ token: string }>(
          `SELECT token FROM compras_google
            WHERE estado IN ('SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
                             'SUBSCRIPTION_STATE_ON_HOLD', 'SUBSCRIPTION_STATE_PAUSED',
                             'SUBSCRIPTION_STATE_CANCELED')
              AND (vence IS NULL OR vence > $1::timestamptz - interval '7 days')
              AND (vence < $1::timestamptz + interval '2 days'
                   OR actualizado_en < now() - interval '1 day')
            ORDER BY actualizado_en LIMIT 200`,
          [ahora()],
        )
      ).rows.map((f) => f.token),
    );
    let procesadas = 0;
    for (const token of tokens) {
      try {
        if ((await aplicarCompra(token)) === 'procesada') procesadas += 1;
      } catch (error) {
        app.log.error({ error }, 'El repaso de Google Play no pudo revisar una compra');
      }
    }
    return { vistas: tokens.length, procesadas };
  }

  // Los avisos de Google, por Pub/Sub (push). Responder con error hace que
  // Pub/Sub lo reintente: solo cuando Google o la base fallaron.
  app.post<{ Querystring: { clave?: unknown } }>('/google/avisos', async (peticion, respuesta) => {
    if (!claveCorrecta(claveAvisos, peticion.query?.clave)) {
      return respuesta.code(401).send({ error: 'clave' });
    }
    if (!google) return respuesta.code(503).send({ error: 'sin_google' });
    const datos = (peticion.body as { message?: { data?: unknown } } | undefined)?.message?.data;
    let aviso: {
      packageName?: string;
      subscriptionNotification?: { purchaseToken?: string };
      voidedPurchaseNotification?: { purchaseToken?: string; orderId?: string };
    };
    try {
      aviso = JSON.parse(Buffer.from(String(datos), 'base64').toString('utf8'));
    } catch {
      return { ok: true, ignorado: true };
    }
    if (aviso?.packageName !== paquete) return { ok: true, ignorado: true };
    const devuelta = aviso.voidedPurchaseNotification;
    const token = aviso.subscriptionNotification?.purchaseToken ?? devuelta?.purchaseToken;
    if (typeof token !== 'string' || !token) return { ok: true, ignorado: true };
    try {
      const anulada = typeof devuelta?.orderId === 'string' ? await anularOrden(devuelta.orderId) : null;
      const aplicada = await aplicarCompra(token);
      return { ok: true, aplicada, ...(anulada ? { anulada } : {}) };
    } catch (error) {
      app.log.error({ error }, 'No se pudo atender el aviso de Google Play');
      return respuesta.code(500).send({ error: 'reintentar' });
    }
  });

  app.post<{ Body: { token?: unknown } }>('/cobro/google', async (peticion, respuesta) => {
    if (!google) return respuesta.code(503).send({ error: 'sin_google' });
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    const token = peticion.body?.token;
    if (typeof token !== 'string' || token.length < 10 || token.length > 4096) {
      return respuesta.code(400).send({ error: 'datos_invalidos' });
    }
    const cliente = await pool.connect();
    let empresaId: string;
    try {
      await cliente.query('BEGIN');
      const miembro = await miembroDe(cliente, usuarioId, empresaPedida(peticion.query));
      await cliente.query('COMMIT');
      if (!miembro) return respuesta.code(403).send({ error: 'sin_negocio' });
      if (miembro.rol !== 'dueno') return respuesta.code(403).send({ error: 'solo_duenos' });
      empresaId = miembro.empresaId;
    } catch (error) {
      await cliente.query('ROLLBACK');
      throw error;
    } finally {
      cliente.release();
    }

    let sub: SuscripcionGoogle;
    try {
      sub = await google.suscripcion(token);
    } catch (error) {
      app.log.error({ error }, 'Google no respondió por la compra');
      return respuesta.code(502).send({ error: 'google_fallo' });
    }
    const linea = sub.lineItems?.[0];
    // La compra queda guardada a nombre de quien la mandó primero.
    const guardada = await comoServidor(pool, async (c) => {
      await c.query(
        `INSERT INTO compras_google (token, empresa_id, usuario_id, producto, estado)
         VALUES ($1, $2, $3, $4, $5) ON CONFLICT (token) DO NOTHING`,
        [token, empresaId, usuarioId, linea?.productId ?? '', sub.subscriptionState],
      );
      return (
        await c.query<{ empresa_id: string }>(
          'SELECT empresa_id FROM compras_google WHERE token = $1',
          [token],
        )
      ).rows[0]!.empresa_id;
    });
    if (guardada !== empresaId) return respuesta.code(409).send({ error: 'otro_negocio' });

    let resultado: AplicadaGoogle;
    try {
      resultado = await aplicar(token, sub);
    } catch (error) {
      app.log.error({ error }, 'No se pudo aplicar la compra de Google');
      return respuesta.code(502).send({ error: 'google_fallo' });
    }
    if (resultado !== 'procesada' && resultado !== 'ya_estaba') {
      return respuesta.code(409).send({ error: resultado });
    }
    return {
      resultado,
      cobro: await cobroParaElTelefono(pool, cobro, usuarioId, empresaId, ahora()),
    };
  });

  return { aplicarCompra, anularOrden, repasar };
}
