import { createHmac, timingSafeEqual } from 'node:crypto';

// Mercado Pago, Checkout Pro (entrega 32). Lo mismo que hace TVSamGo
// (tvsamgo-api/src/utils/mercadopago.js): el dueño paga en la página de
// Mercado Pago (Yape, tarjeta, PagoEfectivo) y el aviso vuelve al servidor.
// Las credenciales van solo en Render: MP_ACCESS_TOKEN y MP_WEBHOOK_SECRET.

/** Un pago como lo devuelve la API (solo lo que se usa). */
export interface PagoMercadoPago {
  id: number | string;
  status: string;
  status_detail?: string;
  transaction_amount: number;
  currency_id?: string;
  external_reference?: string | null;
}

export interface Preferencia {
  id: string;
  /** La página de pago a la que va el dueño. */
  enlace: string;
}

/** Lo que el servidor usa de Mercado Pago; las pruebas lo reemplazan. */
export interface MercadoPago {
  crearPreferencia(datos: {
    titulo: string;
    centimos: number;
    referencia: string;
    avisos: string;
    retorno: string;
  }): Promise<Preferencia>;
  /** La única fuente de verdad: el aviso nunca se cree tal cual llega. */
  obtenerPago(id: string): Promise<PagoMercadoPago>;
  /** Los pagos de una orden, o los que cambiaron en las últimas horas. */
  buscarPagos(filtro: { referencia?: string; horas?: number }): Promise<PagoMercadoPago[]>;
}

export interface ConfigMercadoPago {
  /** MP_ACCESS_TOKEN. */
  token: string;
  /** MP_WEBHOOK_SECRET: la clave secreta del webhook, de la misma aplicación. */
  secreto: string | null;
  /** MOCA_URL_PUBLICA: a dónde vuelven el aviso y el dueño. */
  urlPublica: string;
}

export function leerConfigMercadoPago(
  entorno: NodeJS.ProcessEnv = process.env,
): ConfigMercadoPago | null {
  const token = entorno.MP_ACCESS_TOKEN?.trim();
  if (!token) return null;
  return {
    token,
    secreto: entorno.MP_WEBHOOK_SECRET?.trim() || null,
    urlPublica: (entorno.MOCA_URL_PUBLICA?.trim() || 'https://moca-servidor.onrender.com').replace(
      /\/+$/,
      '',
    ),
  };
}

const api = 'https://api.mercadopago.com';

export function mercadoPagoReal(token: string): MercadoPago {
  async function pedir<T>(
    metodo: 'GET' | 'POST',
    ruta: string,
    cuerpo?: object,
    extra: Record<string, string> = {},
  ): Promise<T> {
    const r = await fetch(`${api}${ruta}`, {
      method: metodo,
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
        ...extra,
      },
      ...(cuerpo ? { body: JSON.stringify(cuerpo) } : {}),
      signal: AbortSignal.timeout(10_000),
    });
    const datos = (await r.json().catch(() => ({}))) as T & { message?: string };
    if (!r.ok) throw new Error(`Mercado Pago respondió ${r.status}: ${datos.message ?? ''}`);
    return datos;
  }

  return {
    async crearPreferencia({ titulo, centimos, referencia, avisos, retorno }) {
      const p = await pedir<{ id: string; init_point: string }>(
        'POST',
        '/checkout/preferences',
        {
          items: [
            { title: titulo, quantity: 1, unit_price: centimos / 100, currency_id: 'PEN' },
          ],
          external_reference: referencia,
          notification_url: avisos,
          back_urls: {
            success: `${retorno}?estado=exito`,
            pending: `${retorno}?estado=pendiente`,
            failure: `${retorno}?estado=fallo`,
          },
          auto_return: 'approved',
          // Que no quede viva para siempre: dos días.
          expires: true,
          expiration_date_to: new Date(Date.now() + 2 * 24 * 3600 * 1000).toISOString(),
        },
        // Tocar dos veces «Pagar» no crea dos preferencias.
        { 'x-idempotency-key': `pref-${referencia}` },
      );
      return { id: p.id, enlace: p.init_point };
    },
    obtenerPago: (id) => pedir<PagoMercadoPago>('GET', `/v1/payments/${encodeURIComponent(id)}`),
    async buscarPagos({ referencia, horas = 6 }) {
      const q = new URLSearchParams({
        sort: 'date_last_updated',
        criteria: 'desc',
        limit: '50',
      });
      if (referencia) q.set('external_reference', referencia);
      else {
        q.set('range', 'date_last_updated');
        q.set('begin_date', `NOW-${horas}HOURS`);
        q.set('end_date', 'NOW');
      }
      const r = await pedir<{ results?: PagoMercadoPago[] }>('GET', `/v1/payments/search?${q}`);
      return r.results ?? [];
    },
  };
}

/**
 * La firma del aviso: `x-signature: ts=<segundos>,v1=<hmac>`, sobre
 * `id:<data.id>;request-id:<x-request-id>;ts:<ts>;` con la clave secreta.
 * El data.id sale de la dirección del aviso, no del cuerpo. Un aviso de más
 * de 5 minutos no vale.
 */
export function firmaValida({
  secreto,
  firma,
  pedido,
  dataId,
  ahora,
}: {
  secreto: string;
  firma: string | undefined;
  pedido: string | undefined;
  dataId: string;
  ahora: Date;
}): boolean {
  if (!firma || !dataId) return false;
  let ts: string | null = null;
  let v1: string | null = null;
  for (const parte of firma.split(',')) {
    const [clave, valor] = parte.split('=').map((s) => (s ?? '').trim());
    if (clave === 'ts') ts = valor ?? null;
    else if (clave === 'v1') v1 = valor ?? null;
  }
  if (!ts || !v1) return false;
  const numero = Number(ts);
  const ms = numero < 1e12 ? numero * 1000 : numero;
  if (!Number.isFinite(ms) || Math.abs(ahora.getTime() - ms) > 5 * 60 * 1000) return false;
  const id = /[a-zA-Z]/.test(dataId) ? dataId.toLowerCase() : dataId;
  const esperada = createHmac('sha256', secreto)
    .update(`id:${id};request-id:${pedido ?? ''};ts:${ts};`)
    .digest('hex');
  const a = Buffer.from(esperada);
  const b = Buffer.from(v1);
  return a.length === b.length && timingSafeEqual(a, b);
}
