import Fastify, { type FastifyInstance } from 'fastify';
import { aislamientoActivo, type Pool } from './base/conexion.js';
import { rutasCuenta } from './cuenta/rutas.js';
import type { Verificador } from './cuenta/verificador.js';
import { rutasDatos } from './datos/subir.js';

export interface Dependencias {
  pool: Pool;
  version: string;
  /** Quien envía el código; nulo si Twilio no está configurado. */
  verificador?: Verificador | null;
  /** Escribe los errores en el registro (en Render; no en las pruebas). */
  registrar?: boolean;
}

/** El servidor HTTP, sin abrir el puerto: las pruebas lo usan con inject. */
export function crearApp({
  pool,
  version,
  verificador = null,
  registrar = false,
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

  rutasCuenta(app, pool, verificador);
  rutasDatos(app, pool);

  return app;
}
