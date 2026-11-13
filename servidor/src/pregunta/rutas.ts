import type { FastifyInstance, FastifyRequest } from 'fastify';
import type { Pool } from '../base/conexion.js';
import { calcularCifras, type DatosEmpresa } from '../cifras/calcular.js';
import { bajar, empresaPedida } from '../datos/bajar.js';
import { autenticar } from '../datos/subir.js';
import { desfaseHorario } from '../pais/peru.js';
import { hechosDelNegocio } from './hechos.js';
import type { Respondedor } from './respondedor.js';

/** Preguntas respondidas por negocio y día (entrega 74). */
export const topeDiario = 20;

/** Desde cuándo cuenta «hoy» en el Perú. */
function inicioDeHoy(ahora: Date): Date {
  const hoy = new Date(ahora.getTime() + desfaseHorario).toISOString().slice(0, 10);
  return new Date(Date.parse(hoy) - desfaseHorario);
}

async function quedanHoy(pool: Pool, empresaId: string, ahora: Date): Promise<number> {
  const { rows } = await pool.query<{ n: number }>(
    `SELECT count(*)::int AS n FROM preguntas
      WHERE empresa_id = $1 AND resultado = 'respondida' AND fecha >= $2`,
    [empresaId, inicioDeHoy(ahora)],
  );
  return Math.max(0, topeDiario - rows[0]!.n);
}

type Datos = Record<string, unknown>;

/** Los datos del negocio si quien pregunta es un dueño; si no, el error. */
async function delDueno(
  pool: Pool,
  peticion: FastifyRequest,
): Promise<{ usuarioId: string; datos: Datos; empresaId: string } | { codigo: number; error: string }> {
  const usuarioId = await autenticar(pool, peticion);
  if (!usuarioId) return { codigo: 401, error: 'sin_sesion' };
  const datos = await bajar(pool, usuarioId, empresaPedida(peticion.query));
  const membresia = datos?.membresia as { rol?: string; empresa_id?: string } | undefined;
  if (!datos || !membresia?.empresa_id) return { codigo: 403, error: 'sin_negocio' };
  if (membresia.rol !== 'dueno') return { codigo: 403, error: 'solo_duenos' };
  return { usuarioId, datos, empresaId: membresia.empresa_id };
}

export function rutasPregunta(
  app: FastifyInstance,
  pool: Pool,
  respondedor: Respondedor | null,
  ahora: () => Date,
): void {
  // Cuántas preguntas le quedan hoy al negocio.
  app.get('/pregunta', async (peticion, respuesta) => {
    const quien = await delDueno(pool, peticion);
    if ('codigo' in quien) return respuesta.code(quien.codigo).send({ error: quien.error });
    return { quedan: await quedanHoy(pool, quien.empresaId, ahora()), disponible: respondedor !== null };
  });

  // «Pregúntale a Moca»: la IA explica las cifras que el servidor ya
  // calculó. No se guarda el texto de la pregunta ni de la respuesta.
  app.post<{ Body: { pregunta: string } }>(
    '/pregunta',
    {
      schema: {
        body: {
          type: 'object',
          required: ['pregunta'],
          properties: { pregunta: { type: 'string', minLength: 1, maxLength: 300 } },
        },
      },
    },
    async (peticion, respuesta) => {
      const quien = await delDueno(pool, peticion);
      if ('codigo' in quien) return respuesta.code(quien.codigo).send({ error: quien.error });
      if (!respondedor) return respuesta.code(503).send({ error: 'sin_ia' });
      const momento = ahora();
      const quedan = await quedanHoy(pool, quien.empresaId, momento);
      if (quedan === 0) return respuesta.code(429).send({ error: 'tope_del_dia', quedan: 0 });
      const pregunta = peticion.body.pregunta.trim();
      if (!pregunta) return respuesta.code(400).send({ error: 'datos_invalidos' });

      const hechos = hechosDelNegocio(
        quien.datos,
        calcularCifras(quien.datos as unknown as DatosEmpresa, momento),
        momento,
      );
      const inicio = Date.now();
      try {
        const r = await respondedor.responder(hechos, pregunta);
        await pool.query(
          `INSERT INTO preguntas (empresa_id, usuario_id, resultado, modelo, tokens_entrada,
                                  tokens_salida, milisegundos)
           VALUES ($1, $2, 'respondida', $3, $4, $5, $6)`,
          [quien.empresaId, quien.usuarioId, r.modelo, r.tokensEntrada, r.tokensSalida, Date.now() - inicio],
        );
        return { respuesta: r.texto, enlace: r.enlace, quedan: quedan - 1 };
      } catch (error) {
        app.log.warn({ error: String(error) }, 'Pregúntale sin respuesta');
        await pool.query(
          `INSERT INTO preguntas (empresa_id, usuario_id, resultado, milisegundos)
           VALUES ($1, $2, 'error', $3)`,
          [quien.empresaId, quien.usuarioId, Date.now() - inicio],
        );
        return respuesta.code(502).send({ error: 'sin_respuesta', quedan });
      }
    },
  );
}
