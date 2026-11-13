import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
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

/** Fotos de prueba sin cuenta (entrega 14.2): por teléfono, en total. */
export const pruebasPorTelefono = 3;
/** Topes para quien borre los datos de la app y vuelva a probar. */
export const pruebasPorConexionAlDia = 10;
export const pruebasAlDia = 200;

/** Quién pide la lectura: un usuario con cuenta o un teléfono de prueba. */
type Quien = { usuarioId: string } | { pruebaDe: string; ip: string };

/** Desde cuándo cuenta «hoy» en el Perú. */
const inicioDeHoy = (ahora: Date) => new Date(Date.parse(hoyEnPeru(ahora)) - desfaseHorario);

async function contar(pool: Pool, donde: string, valores: unknown[]): Promise<number> {
  const { rows } = await pool.query<{ n: number }>(
    `SELECT count(*)::int AS n FROM lecturas WHERE ${donde}`,
    valores,
  );
  return rows[0]!.n;
}

/** Cuántas fotos de prueba le quedan al teléfono. Las fallidas no cuentan. */
async function pruebasRestantes(pool: Pool, pruebaDe: string): Promise<number> {
  const usadas = await contar(pool, "prueba_de = $1 AND resultado <> 'error'", [pruebaDe]);
  return Math.max(0, pruebasPorTelefono - usadas);
}

/** Por qué no se lee ahora; nulo si se puede leer. */
async function tope(pool: Pool, quien: Quien, ahora: Date): Promise<string | null> {
  const hoy = inicioDeHoy(ahora);
  if ('usuarioId' in quien) {
    const hoyLeidas = await contar(pool, 'usuario_id = $1 AND fecha >= $2', [quien.usuarioId, hoy]);
    return hoyLeidas >= limiteDiario ? 'limite_diario' : null;
  }
  if ((await pruebasRestantes(pool, quien.pruebaDe)) === 0) return 'pruebas_agotadas';
  const deLaConexion = await contar(
    pool,
    "prueba_de IS NOT NULL AND resultado <> 'error' AND ip = $1 AND fecha >= $2",
    [quien.ip, hoy],
  );
  const todas = await contar(
    pool,
    "prueba_de IS NOT NULL AND resultado <> 'error' AND fecha >= $1",
    [hoy],
  );
  return deLaConexion >= pruebasPorConexionAlDia || todas >= pruebasAlDia
    ? 'pruebas_no_disponibles'
    : null;
}

interface Pedido {
  imagen: string;
  tipo?: Imagen['tipo'];
  categorias?: string[];
}

const propiedadesDeLaFoto = {
  imagen: { type: 'string', minLength: 100, maxLength: 8 * 1024 * 1024 },
  tipo: { type: 'string', enum: ['image/jpeg', 'image/png', 'image/webp'] },
  categorias: { type: 'array', maxItems: 50, items: { type: 'string', maxLength: 80 } },
} as const;

export function rutasComprobantes(
  app: FastifyInstance,
  pool: Pool,
  lector: Lector | null,
  ahora: () => Date,
): void {
  /** Lee la foto, la anota y responde. Lo mismo con cuenta o de prueba. */
  async function atender(
    peticion: FastifyRequest<{ Body: Pedido }>,
    respuesta: FastifyReply,
    quien: Quien,
  ) {
    if (!lector) return respuesta.code(503).send({ error: 'sin_lector' });
    const momento = ahora();
    const motivo = await tope(pool, quien, momento);
    if (motivo) return respuesta.code(429).send({ error: motivo });

    const inicio = Date.now();
    const { imagen, tipo = 'image/jpeg', categorias = [] } = peticion.body;
    let leido: Leido | null = null;
    try {
      leido = await leerComprobante(lector, { datos: imagen, tipo }, categorias, hoyEnPeru(momento));
    } catch (error) {
      peticion.log.error({ err: error }, 'No se pudo leer el comprobante');
    }
    const ultimo = leido?.pasos.at(-1);
    // Se registra también el error, para medir. Con cuenta cuenta para el
    // tope del día; una foto de prueba fallida no gasta una prueba.
    await pool.query(
      `INSERT INTO lecturas (usuario_id, prueba_de, ip, resultado, modelo, escalo, pasos,
                             costo_microdolares, milisegundos)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [
        'usuarioId' in quien ? quien.usuarioId : null,
        'pruebaDe' in quien ? quien.pruebaDe : null,
        'ip' in quien ? quien.ip : null,
        leido?.resultado ?? 'error',
        ultimo?.modelo ?? null,
        (leido?.pasos.length ?? 0) > 1,
        JSON.stringify(leido?.pasos ?? []),
        leido ? costoMicrodolares(leido.pasos) : 0,
        Date.now() - inicio,
      ],
    );
    if (!leido) return respuesta.code(502).send({ error: 'no_se_pudo_leer' });
    return {
      resultado: leido.resultado,
      lectura: leido.lectura,
      ...('pruebaDe' in quien && { pruebasRestantes: await pruebasRestantes(pool, quien.pruebaDe) }),
    };
  }

  // La foto de un comprobante (entrega 14). El teléfono busca antes el QR;
  // esta ruta es para lo que no lo tiene.
  app.post<{ Body: Pedido }>(
    '/comprobantes/leer',
    {
      bodyLimit: 10 * 1024 * 1024,
      schema: {
        body: { type: 'object', required: ['imagen'], properties: propiedadesDeLaFoto },
      },
    },
    async (peticion, respuesta) => {
      const usuarioId = await autenticar(pool, peticion);
      if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
      return atender(peticion, respuesta, { usuarioId });
    },
  );

  // Sin cuenta, 3 fotos de prueba por teléfono (entrega 14.2).
  app.post<{ Body: Pedido & { telefono: string } }>(
    '/comprobantes/leer-prueba',
    {
      bodyLimit: 10 * 1024 * 1024,
      schema: {
        body: {
          type: 'object',
          required: ['imagen', 'telefono'],
          properties: { ...propiedadesDeLaFoto, telefono: { type: 'string', format: 'uuid' } },
        },
      },
    },
    (peticion, respuesta) =>
      atender(peticion, respuesta, { pruebaDe: peticion.body.telefono, ip: peticion.ip }),
  );
}
