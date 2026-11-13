import { gzipSync } from 'node:zlib';
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import type { Pool } from '../base/conexion.js';
import { bajar, cifrasPara, empresaPedida } from '../datos/bajar.js';
import { autenticar } from '../datos/subir.js';
import type { Cifras } from './calcular.js';

/** Las cifras de la empresa del usuario ahora; nulas si no tiene empresa. */
export async function cifrasDe(
  pool: Pool,
  usuarioId: string,
  ahora: Date,
  empresaId?: string,
): Promise<Cifras | null> {
  return cifrasPara(await bajar(pool, usuarioId, empresaId), ahora);
}

/** Responde en gzip si el teléfono lo acepta. */
export function enviarJson(peticion: FastifyRequest, respuesta: FastifyReply, cuerpo: unknown) {
  const texto = JSON.stringify(cuerpo);
  respuesta.header('content-type', 'application/json; charset=utf-8');
  if (/\bgzip\b/.test(String(peticion.headers['accept-encoding'] ?? ''))) {
    return respuesta.header('content-encoding', 'gzip').send(gzipSync(texto));
  }
  return respuesta.send(texto);
}

export function rutasCifras(app: FastifyInstance, pool: Pool, ahora: () => Date): void {
  // Las cifras de lo que el servidor ya tiene (entrega 13). El teléfono las
  // pide al abrir la app si no tiene nada por subir.
  app.get('/cifras', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    return enviarJson(peticion, respuesta, {
      cifras: await cifrasDe(pool, usuarioId, ahora(), empresaPedida(peticion.query)),
    });
  });
}
