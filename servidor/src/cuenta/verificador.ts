/** Resultado de comprobar un código. */
export type Comprobacion = 'aprobado' | 'incorrecto' | 'vencido';

/**
 * Quien envía y comprueba el código de 6 dígitos. El código lo genera y lo
 * guarda el proveedor: el servidor de Moca nunca lo conoce.
 */
export interface Verificador {
  enviar(celularInternacional: string): Promise<'enviado' | 'demasiados'>;
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
    async enviar(celular) {
      const respuesta = await enviarFormulario('Verifications', {
        To: celular,
        Channel: 'sms',
      });
      if (respuesta.status === 429) return 'demasiados';
      if (!respuesta.ok) {
        throw new Error(`Twilio no envió el código: ${respuesta.status} ${await respuesta.text()}`);
      }
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
      if (!respuesta.ok) {
        throw new Error(`Twilio no comprobó el código: ${respuesta.status} ${await respuesta.text()}`);
      }
      const datos = (await respuesta.json()) as { status?: string };
      return datos.status === 'approved' ? 'aprobado' : 'incorrecto';
    },
  };
}
