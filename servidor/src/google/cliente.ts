import { createSign } from 'node:crypto';

// Google Play (entrega 78): el servidor le pregunta a Google por cada compra
// de la versión de Play Store, con una cuenta de servicio de Google Cloud.
// Su llave (el JSON entero) va solo en Render, en GOOGLE_PLAY_CUENTA_SERVICIO.
// Nunca se le cree al teléfono: la compra vale si Google dice que vale.

export const paquete = 'pe.moca.app';

/** Una suscripción como la devuelve Google (purchases.subscriptionsv2; solo lo que se usa). */
export interface SuscripcionGoogle {
  /** SUBSCRIPTION_STATE_ACTIVE, …_IN_GRACE_PERIOD, …_ON_HOLD, …_PAUSED, …_CANCELED, …_EXPIRED, …_PENDING */
  subscriptionState: string;
  /** ACKNOWLEDGEMENT_STATE_PENDING o …_ACKNOWLEDGED. */
  acknowledgementState?: string;
  latestOrderId?: string;
  /** Lo que la app puso al comprar: el id del negocio. */
  externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string };
  /** Presente si la compró una cuenta de prueba de Google. */
  testPurchase?: object;
  lineItems?: {
    productId: string;
    expiryTime?: string;
    offerDetails?: { basePlanId?: string; offerId?: string };
  }[];
}

/** Lo que el servidor usa de Google Play; las pruebas lo reemplazan. */
export interface GooglePlay {
  suscripcion(token: string): Promise<SuscripcionGoogle>;
  /** Le dice a Google que la compra se entregó: sin esto, la devuelve a los 3 días. */
  reconocer(producto: string, token: string): Promise<void>;
}

export interface CuentaDeServicio {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

/** La cuenta de servicio de GOOGLE_PLAY_CUENTA_SERVICIO; nula si falta o no se lee. */
export function leerCuentaDeServicio(
  env: Record<string, string | undefined> = process.env,
): CuentaDeServicio | null {
  const crudo = env.GOOGLE_PLAY_CUENTA_SERVICIO?.trim();
  if (!crudo) return null;
  try {
    const cuenta = JSON.parse(crudo) as Partial<CuentaDeServicio>;
    if (typeof cuenta.client_email !== 'string' || typeof cuenta.private_key !== 'string') {
      return null;
    }
    return {
      client_email: cuenta.client_email,
      private_key: cuenta.private_key,
      ...(typeof cuenta.token_uri === 'string' ? { token_uri: cuenta.token_uri } : {}),
    };
  } catch {
    return null;
  }
}

const api = 'https://androidpublisher.googleapis.com/androidpublisher/v3';
const alcance = 'https://www.googleapis.com/auth/androidpublisher';

export class ErrorDeGoogle extends Error {
  constructor(
    readonly estado: number,
    mensaje: string,
  ) {
    super(mensaje);
  }
}

/** El cliente real: se identifica con la cuenta de servicio (JWT firmado). */
export function googlePlayReal(cuenta: CuentaDeServicio): GooglePlay {
  const tokenUri = cuenta.token_uri ?? 'https://oauth2.googleapis.com/token';
  let acceso: { token: string; vence: number } | null = null;

  async function token(): Promise<string> {
    const ahora = Math.floor(Date.now() / 1000);
    if (acceso && acceso.vence - 60 > ahora) return acceso.token;
    const b64 = (v: string) => Buffer.from(v).toString('base64url');
    const sinFirma = `${b64(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))}.${b64(
      JSON.stringify({
        iss: cuenta.client_email,
        scope: alcance,
        aud: tokenUri,
        iat: ahora,
        exp: ahora + 3600,
      }),
    )}`;
    const firma = createSign('RSA-SHA256').update(sinFirma).sign(cuenta.private_key, 'base64url');
    const r = await fetch(tokenUri, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: `${sinFirma}.${firma}`,
      }),
    });
    if (!r.ok) throw new ErrorDeGoogle(r.status, 'Google no dio acceso a la cuenta de servicio');
    const cuerpo = (await r.json()) as { access_token: string; expires_in?: number };
    acceso = { token: cuerpo.access_token, vence: ahora + (cuerpo.expires_in ?? 3600) };
    return acceso.token;
  }

  async function pedir(ruta: string, metodo: 'GET' | 'POST' = 'GET'): Promise<Response> {
    const r = await fetch(`${api}/applications/${paquete}${ruta}`, {
      method: metodo,
      headers: { authorization: `Bearer ${await token()}` },
    });
    if (!r.ok) throw new ErrorDeGoogle(r.status, `Google respondió ${r.status} a ${metodo}`);
    return r;
  }

  return {
    async suscripcion(t) {
      const r = await pedir(`/purchases/subscriptionsv2/tokens/${encodeURIComponent(t)}`);
      return (await r.json()) as SuscripcionGoogle;
    },
    async reconocer(producto, t) {
      await pedir(
        `/purchases/subscriptions/${encodeURIComponent(producto)}/tokens/${encodeURIComponent(t)}:acknowledge`,
        'POST',
      );
    },
  };
}
