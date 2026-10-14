import { crearApp } from './app.js';
import { aislamientoActivo, crearPool } from './base/conexion.js';
import { migrar } from './base/migrar.js';
import { leerConfig } from './config.js';
import { leerConfigTwilio, verificadorTwilio } from './cuenta/verificador.js';

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
const app = crearApp({
  pool,
  version: config.version,
  verificador: twilio ? verificadorTwilio(twilio) : null,
  registrar: true,
});
await app.listen({ port: config.puerto, host: '0.0.0.0' });
console.log(`Moca ${config.version} escuchando en el puerto ${config.puerto}`);
