import { createGunzip } from 'node:zlib';
import Fastify, { type FastifyInstance } from 'fastify';
import { aislamientoActivo, type Pool } from './base/conexion.js';
import { rutasBorrar } from './cuenta/borrar.js';
import { rutasCuenta } from './cuenta/rutas.js';
import type { Verificador } from './cuenta/verificador.js';
import { rutasCifras } from './cifras/rutas.js';
import type { Lector } from './comprobantes/lector.js';
import { rutasComprobantes } from './comprobantes/rutas.js';
import { rutasBajada } from './datos/bajar.js';
import { rutasDatos } from './datos/subir.js';

export interface Dependencias {
  pool: Pool;
  version: string;
  /** Quien envía el código; nulo si Twilio no está configurado. */
  verificador?: Verificador | null;
  /** Escribe los errores en el registro (en Render; no en las pruebas). */
  registrar?: boolean;
  /** El reloj de las cifras; las pruebas lo fijan. */
  ahora?: () => Date;
  /** Quien lee las fotos con IA; nulo si no hay llave de Anthropic. */
  lector?: Lector | null;
}

/** El servidor HTTP, sin abrir el puerto: las pruebas lo usan con inject. */
export function crearApp({
  pool,
  version,
  verificador = null,
  registrar = false,
  ahora = () => new Date(),
  lector = null,
}: Dependencias): FastifyInstance {
  // Render pasa la conexión del teléfono por un proxy. El registro guarda
  // solo avisos y errores: nunca el cuerpo de lo que manda el teléfono.
  const app = Fastify({
    logger: registrar ? { level: 'warn' } : false,
    trustProxy: true,
  });

  // Para Render y para quien quiera saber si el servidor está bien.
  app.get('/salud', async (_peticion, respuesta) => {
    let base: 'bien' | 'sin conexión' = 'bien';
    let aislamiento: 'activo' | 'desactivado' | 'desconocido' = 'desconocido';
    try {
      aislamiento = (await aislamientoActivo(pool)) ? 'activo' : 'desactivado';
    } catch {
      base = 'sin conexión';
    }
    const bien = base === 'bien' && aislamiento === 'activo';
    return respuesta.code(bien ? 200 : 503).send({
      estado: bien ? 'bien' : 'mal',
      version,
      base,
      aislamiento,
    });
  });

  // El teléfono sube comprimido (entrega 12). Fastify compara el largo
  // recibido con Content-Length: el flujo descomprimido lleva el largo
  // original.
  app.addHook('preParsing', async (peticion, _respuesta, cuerpo) => {
    if (peticion.headers['content-encoding'] !== 'gzip') return cuerpo;
    const descomprimido = Object.assign(createGunzip(), { receivedEncodedLength: 0 });
    cuerpo.on('data', (trozo: Buffer) => {
      descomprimido.receivedEncodedLength += trozo.length;
    });
    return cuerpo.pipe(descomprimido);
  });

  rutasCuenta(app, pool, verificador);
  rutasBorrar(app, pool);
  rutasDatos(app, pool, ahora);
  rutasBajada(app, pool, ahora);
  rutasCifras(app, pool, ahora);
  rutasComprobantes(app, pool, lector, ahora);

  return app;
}
