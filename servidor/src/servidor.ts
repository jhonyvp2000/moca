import { crearApp } from './app.js';
import { lectorAnthropic } from './comprobantes/lector.js';
import { respondedorAnthropic } from './pregunta/respondedor.js';
import { aislamientoActivo, crearPool } from './base/conexion.js';
import { migrar } from './base/migrar.js';
import { leerConfig } from './config.js';
import { leerConfigTwilio, verificadorTwilio } from './cuenta/verificador.js';
import { leerConfigCobro } from './cobro/rutas.js';
import { leerConfigVersion } from './version/rutas.js';
import { leerConfigMercadoPago, mercadoPagoReal } from './mercadopago/cliente.js';
import { googlePlayReal, leerCuentaDeServicio } from './google/cliente.js';

// Arranque en Render: migra la base, revisa el aislamiento y abre el puerto.
const config = leerConfig();
const pool = crearPool(config.baseDeDatos);

const aplicadas = await migrar(pool);
if (aplicadas.length) console.log(`Migraciones aplicadas: ${aplicadas.join(', ')}`);

if (!(await aislamientoActivo(pool))) {
  console.error(
    'El rol de la base se salta el aislamiento por empresa (superusuario o ' +
      'BYPASSRLS). Usa un rol normal en DATABASE_URL.',
  );
  process.exit(1);
}

const twilio = leerConfigTwilio();
if (!twilio) console.warn('Twilio no está configurado: no se pueden crear cuentas.');
// La lectura de fotos con IA (entrega 14).
const llaveAnthropic = process.env.ANTHROPIC_API_KEY;
if (!llaveAnthropic) console.warn('Falta ANTHROPIC_API_KEY: no se pueden leer fotos.');
// El cobro manual por Yape (entrega 24): sin MOCA_COBRO_DESDE no se cobra.
const cobro = leerConfigCobro();
if (!cobro.desde) console.warn('Sin MOCA_COBRO_DESDE: el cobro no ha empezado.');
// Mercado Pago (entrega 32): sin MP_ACCESS_TOKEN, solo el Yape manual.
const configMp = leerConfigMercadoPago();
if (!configMp) console.warn('Sin MP_ACCESS_TOKEN: no se puede pagar con Mercado Pago.');
else if (!configMp.secreto) {
  console.warn('Sin MP_WEBHOOK_SECRET: los avisos de Mercado Pago no se comprueban.');
}
// Google Play (entrega 78): sin GOOGLE_PLAY_CUENTA_SERVICIO, la versión de
// Play no puede pagar.
const cuentaGoogle = leerCuentaDeServicio();
if (!cuentaGoogle) console.warn('Sin GOOGLE_PLAY_CUENTA_SERVICIO: no se puede pagar con Google Play.');
else if (!process.env.GOOGLE_PLAY_AVISOS_CLAVE?.trim()) {
  console.warn('Sin GOOGLE_PLAY_AVISOS_CLAVE: los avisos de Google Play no piden clave.');
}
const app = crearApp({
  pool,
  version: config.version,
  verificador: twilio ? verificadorTwilio(twilio) : null,
  lector: llaveAnthropic ? lectorAnthropic(llaveAnthropic) : null,
  respondedor: llaveAnthropic ? respondedorAnthropic(llaveAnthropic) : null,
  registrar: true,
  cobro,
  versionApp: leerConfigVersion(),
  mercadoPago: configMp ? { config: configMp, cliente: mercadoPagoReal(configMp.token) } : null,
  googlePlay: cuentaGoogle ? googlePlayReal(cuentaGoogle) : null,
  claveAvisosGoogle: process.env.GOOGLE_PLAY_AVISOS_CLAVE?.trim() || null,
});
await app.listen({ port: config.puerto, host: '0.0.0.0' });

// El aviso que no llegó (entrega 32): cada 5 minutos se le pregunta a Mercado
// Pago qué pagos cambiaron y van por el mismo camino. Al arrancar, 72 horas.
if (configMp) {
  const repasar = (horas: number) =>
    app.cobrador
      .repasar(horas)
      .catch((error: unknown) => console.error('El repaso de Mercado Pago falló:', error));
  setTimeout(() => void repasar(72), 60_000).unref();
  setInterval(() => void repasar(6), 5 * 60_000).unref();
}
// El aviso de Google que no llegó (entrega 79): cada 6 horas se revisan las
// compras que vencen pronto o que nadie miró en un día. Al arrancar, también.
if (cuentaGoogle) {
  const repasarGoogle = () =>
    app.cobradorGoogle
      .repasar()
      .catch((error: unknown) => console.error('El repaso de Google Play falló:', error));
  setTimeout(() => void repasarGoogle(), 90_000).unref();
  setInterval(() => void repasarGoogle(), 6 * 60 * 60_000).unref();
}
console.log(`Moca ${config.version} escuchando en el puerto ${config.puerto}`);
