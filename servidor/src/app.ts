import Fastify, { type FastifyInstance } from 'fastify';
import { aislamientoActivo, type Pool } from './base/conexion.js';

export interface Dependencias {
  pool: Pool;
  version: string;
}

/** El servidor HTTP, sin abrir el puerto: las pruebas lo usan con inject. */
export function crearApp({ pool, version }: Dependencias): FastifyInstance {
  const app = Fastify({ logger: false });

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

  return app;
}
