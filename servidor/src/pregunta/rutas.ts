import type { FastifyInstance, FastifyRequest } from 'fastify';
import type { Pool } from '../base/conexion.js';
import { calcularCifras, type DatosEmpresa } from '../cifras/calcular.js';
import { bajar, empresaPedida } from '../datos/bajar.js';
import { autenticar } from '../datos/subir.js';
import { desfaseHorario } from '../pais/peru.js';
import { cobroParaElTelefono, type ConfigCobro } from '../cobro/rutas.js';
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

const meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
  'setiembre', 'octubre', 'noviembre', 'diciembre',
];
const fecha = (dia: string) =>
  `${Number(dia.slice(8, 10))} de ${meses[Number(dia.slice(5, 7)) - 1]} de ${dia.slice(0, 4)}`;
const nombrePlan: Record<string, string> = {
  basico: 'Básico mensual',
  basico_anual: 'Básico anual',
  normal: 'Full mensual',
  fundador: 'Full mensual',
  anual: 'Full anual',
};

/** El estado del plan de Moca, en palabras (entrega 75). */
async function planEnPalabras(
  pool: Pool,
  cobro: ConfigCobro,
  usuarioId: string,
  empresaId: string,
  ahora: Date,
): Promise<string | null> {
  try {
    const e = await cobroParaElTelefono(pool, cobro, usuarioId, empresaId, ahora);
    switch (e.estado) {
      case 'sin_cobro':
        return 'Moca todavía no se cobra: puedes usarlo sin pagar.';
      case 'prueba':
        return e.hasta
          ? `Estás en la prueba gratis, hasta el ${fecha(e.hasta)}.`
          : 'Estás en la prueba gratis: empieza a contar con tu primer registro.';
      case 'pagado':
        return `Tienes el plan ${nombrePlan[e.plan ?? ''] ?? 'pagado'}, pagado hasta el ${fecha(e.hasta!)}.`;
      case 'vencido':
        return `Tu plan venció el ${fecha(e.hasta!)}: puedes seguir anotando, pero hay que pagar para ver todo.`;
    }
  } catch {
    return null;
  }
}

export function rutasPregunta(
  app: FastifyInstance,
  pool: Pool,
  respondedor: Respondedor | null,
  ahora: () => Date,
  cobro: ConfigCobro,
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
        {
          usuarioId: quien.usuarioId,
          plan: await planEnPalabras(pool, cobro, quien.usuarioId, quien.empresaId, momento),
        },
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
