import { timingSafeEqual } from 'node:crypto';
import { aInternacional, esCelularPeru } from './celular.js';

/** Resultado de comprobar un código. */
export type Comprobacion = 'aprobado' | 'incorrecto' | 'vencido';

/**
 * Quien envía y comprueba el código de 6 dígitos. El código lo genera y lo
 * guarda el proveedor: el servidor de Moca nunca lo conoce.
 */
export interface Verificador {
  /**
   * [marcaApp]: la marca de 11 caracteres de la app Android. Va al final
   * del SMS para que el teléfono lo lea solo (SMS Retriever, entrega 14.7).
   */
  enviar(
    celularInternacional: string,
    marcaApp?: string,
  ): Promise<'enviado' | 'demasiados'>;
  comprobar(celularInternacional: string, codigo: string): Promise<Comprobacion>;
}

export interface ConfigTwilio {
  cuenta: string;
  clave: string;
  servicio: string;
}

/** Lee la configuración de Twilio; nula si falta algún dato. */
export function leerConfigTwilio(
  entorno: NodeJS.ProcessEnv = process.env,
): ConfigTwilio | null {
  const cuenta = entorno.TWILIO_ACCOUNT_SID;
  const clave = entorno.TWILIO_AUTH_TOKEN;
  const servicio = entorno.TWILIO_VERIFY_SID;
  return cuenta && clave && servicio ? { cuenta, clave, servicio } : null;
}

/**
 * Twilio Verify. Por ahora solo SMS: WhatsApp se suma cuando Meta apruebe a
 * Moca como remitente (decisiones.md, 14-10-2026).
 */
/**
 * El error de Twilio, con su código (por ejemplo 21608: número no
 * verificado en una cuenta de prueba; 60605: país no habilitado). Las
 * claves nunca van en el mensaje.
 */
async function errorDeTwilio(accion: string, respuesta: Response): Promise<Error> {
  let detalle = '';
  try {
    const cuerpo = (await respuesta.json()) as { code?: number; message?: string };
    detalle = ` código ${cuerpo.code ?? '?'}: ${cuerpo.message ?? ''}`;
  } catch {
    // Sin cuerpo JSON: basta con el estado.
  }
  return new Error(`Twilio no ${accion} (${respuesta.status})${detalle}`);
}

export function verificadorTwilio(
  config: ConfigTwilio,
  pedir: typeof fetch = fetch,
): Verificador {
  const base = `https://verify.twilio.com/v2/Services/${config.servicio}`;
  const autorizacion =
    'Basic ' + Buffer.from(`${config.cuenta}:${config.clave}`).toString('base64');
  const enviarFormulario = (ruta: string, campos: Record<string, string>) =>
    pedir(`${base}/${ruta}`, {
      method: 'POST',
      headers: {
        Authorization: autorizacion,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams(campos),
    });

  return {
    async enviar(celular, marcaApp) {
      const respuesta = await enviarFormulario('Verifications', {
        To: celular,
        Channel: 'sms',
        ...(marcaApp ? { AppHash: marcaApp } : {}),
      });
      if (respuesta.status === 429) return 'demasiados';
      if (!respuesta.ok) throw await errorDeTwilio('envió el código', respuesta);
      return 'enviado';
    },

    async comprobar(celular, codigo) {
      const respuesta = await enviarFormulario('VerificationCheck', {
        To: celular,
        Code: codigo,
      });
      // 404: no hay un código pendiente (venció, ya se usó o se agotaron
      // los intentos). 429: demasiados intentos con este código.
      if (respuesta.status === 404 || respuesta.status === 429) return 'vencido';
      if (!respuesta.ok) throw await errorDeTwilio('comprobó el código', respuesta);
      const datos = (await respuesta.json()) as { status?: string };
      return datos.status === 'approved' ? 'aprobado' : 'incorrecto';
    },
  };
}

/**
 * La cuenta del revisor de Google Play (entrega 82): un número con un código
 * fijo, para que quien revisa la app pueda entrar sin recibir el SMS. Va
 * solo en Render (MOCA_REVISOR_CELULAR y MOCA_REVISOR_CODIGO); sin las dos,
 * no existe.
 */
export interface ConfigRevisor {
  /** En formato internacional: +51987654321. */
  celular: string;
  codigo: string;
}

export function leerConfigRevisor(
  entorno: NodeJS.ProcessEnv = process.env,
): ConfigRevisor | null {
  const celular = entorno.MOCA_REVISOR_CELULAR?.trim() ?? '';
  const codigo = entorno.MOCA_REVISOR_CODIGO?.trim() ?? '';
  if (!esCelularPeru(celular) || !/^\d{6}$/.test(codigo)) return null;
  return { celular: aInternacional(celular), codigo };
}

/** Códigos equivocados que bloquean al revisor, y por cuánto tiempo. */
export const fallosDelRevisor = 5;
export const bloqueoDelRevisorMs = 60 * 60_000;

/**
 * El verificador de siempre, salvo para el número del revisor: no se manda
 * SMS y se compara con su código fijo. Tras 5 códigos equivocados en una
 * hora, ese número no entra durante una hora, ni con el código bueno.
 */
export function conRevisor(
  base: Verificador | null,
  revisor: ConfigRevisor | null,
  ahora: () => number = Date.now,
): Verificador | null {
  if (!base || !revisor) return base;
  let fallos: number[] = [];
  const codigoBueno = Buffer.from(revisor.codigo);
  return {
    async enviar(celular, marcaApp) {
      if (celular === revisor.celular) return 'enviado';
      return base.enviar(celular, marcaApp);
    },
    async comprobar(celular, codigo) {
      if (celular !== revisor.celular) return base.comprobar(celular, codigo);
      const momento = ahora();
      fallos = fallos.filter((f) => momento - f < bloqueoDelRevisorMs);
      if (fallos.length >= fallosDelRevisor) return 'incorrecto';
      const dado = Buffer.from(codigo);
      if (dado.length === codigoBueno.length && timingSafeEqual(dado, codigoBueno)) {
        return 'aprobado';
      }
      fallos.push(momento);
      return 'incorrecto';
    },
  };
}
