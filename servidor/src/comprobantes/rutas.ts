import type { FastifyInstance } from 'fastify';
import type { Pool } from '../base/conexion.js';
import { autenticar } from '../datos/subir.js';
import { desfaseHorario } from '../pais/peru.js';
import { costoMicrodolares, leerComprobante, type Leido } from './leer.js';
import type { Imagen, Lector } from './lector.js';

/** Fotos leídas por la IA por usuario y día: ningún error dispara el costo. */
export const limiteDiario = 30;

/** El día de hoy en el Perú («2026-10-14»). */
const hoyEnPeru = (ahora: Date) =>
  new Date(ahora.getTime() + desfaseHorario).toISOString().slice(0, 10);

/** Cuántas fotos leyó la IA hoy (en el Perú) para el usuario. */
async function leidasHoy(pool: Pool, usuarioId: string, ahora: Date): Promise<number> {
  const desde = new Date(Date.parse(hoyEnPeru(ahora)) - desfaseHorario);
  const { rows } = await pool.query<{ n: number }>(
    'SELECT count(*)::int AS n FROM lecturas WHERE usuario_id = $1 AND fecha >= $2',
    [usuarioId, desde],
  );
  return rows[0]!.n;
}

interface Pedido {
  imagen: string;
  tipo?: Imagen['tipo'];
  categorias?: string[];
}

export function rutasComprobantes(
  app: FastifyInstance,
  pool: Pool,
  lector: Lector | null,
  ahora: () => Date,
): void {
  // La foto de un comprobante (entrega 14). El teléfono busca antes el QR;
  // esta ruta es para lo que no lo tiene.
  app.post<{ Body: Pedido }>(
    '/comprobantes/leer',
    {
      bodyLimit: 10 * 1024 * 1024,
      schema: {
        body: {
          type: 'object',
          required: ['imagen'],
          properties: {
            imagen: { type: 'string', minLength: 100, maxLength: 8 * 1024 * 1024 },
            tipo: { type: 'string', enum: ['image/jpeg', 'image/png', 'image/webp'] },
            categorias: { type: 'array', maxItems: 50, items: { type: 'string', maxLength: 80 } },
          },
        },
      },
    },
    async (peticion, respuesta) => {
      const usuarioId = await autenticar(pool, peticion);
      if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
      if (!lector) return respuesta.code(503).send({ error: 'sin_lector' });
      const momento = ahora();
      if ((await leidasHoy(pool, usuarioId, momento)) >= limiteDiario) {
        return respuesta.code(429).send({ error: 'limite_diario' });
      }

      const inicio = Date.now();
      const { imagen, tipo = 'image/jpeg', categorias = [] } = peticion.body;
      let leido: Leido | null = null;
      try {
        leido = await leerComprobante(lector, { datos: imagen, tipo }, categorias, hoyEnPeru(momento));
      } catch (error) {
        peticion.log.error({ err: error }, 'No se pudo leer el comprobante');
      }
      const ultimo = leido?.pasos.at(-1);
      // Se registra también el error: cuenta para el tope y para medir.
      await pool.query(
        `INSERT INTO lecturas (usuario_id, resultado, modelo, escalo, pasos, costo_microdolares, milisegundos)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          usuarioId,
          leido?.resultado ?? 'error',
          ultimo?.modelo ?? null,
          (leido?.pasos.length ?? 0) > 1,
          JSON.stringify(leido?.pasos ?? []),
          leido ? costoMicrodolares(leido.pasos) : 0,
          Date.now() - inicio,
        ],
      );
      if (!leido) return respuesta.code(502).send({ error: 'no_se_pudo_leer' });
      return { resultado: leido.resultado, lectura: leido.lectura };
    },
  );
}
