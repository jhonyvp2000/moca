import Anthropic from '@anthropic-ai/sdk';
import { tiposDeComprobante } from '../pais/peru.js';

// La lectura de una foto con Claude (entrega 14). El servidor decide con
// reglas si la lectura cuadra y si hace falta el modelo mayor (leer.ts).

export const modeloEconomico = 'claude-haiku-5-5';
export const modeloMayor = 'claude-sonnet-5-5';
export type Modelo = typeof modeloEconomico | typeof modeloMayor;

/** Dólares por millón de tokens (entrada, salida), para medir el costo. */
export const precios: Record<Modelo, { entrada: number; salida: number }> = {
  [modeloEconomico]: { entrada: 0.1, salida: 0.5 },
  [modeloMayor]: { entrada: 2, salida: 10 },
};

/** Lo que devuelve el modelo, con el formato de `esquema`. */
export interface RespuestaModelo {
  es_comprobante: boolean;
  legible: boolean;
  ruc: string | null;
  emisor: string | null;
  tipo: (typeof tiposDeComprobante)[number] | null;
  serie: string | null;
  numero: string | null;
  /** «2026-10-14». */
  fecha: string | null;
  /** Montos en soles, con céntimos. */
  subtotal: number | null;
  igv: number | null;
  total: number | null;
  cantidad_items: number | null;
  categoria: string | null;
}

export interface Lectura {
  /** Nula si el modelo se negó a leer. */
  respuesta: RespuestaModelo | null;
  tokensEntrada: number;
  tokensSalida: number;
}

export interface Lector {
  leer(imagen: Imagen, categorias: string[], modelo: Modelo): Promise<Lectura>;
}

export interface Imagen {
  /** En base64. */
  datos: string;
  tipo: 'image/jpeg' | 'image/png' | 'image/webp';
}

const texto = { type: 'string' };
const nulo = { type: 'null' };
const oNulo = (esquema: object) => ({ anyOf: [esquema, nulo] });

/** Igual para toda empresa, así la API lo compila una sola vez. */
const esquema = {
  type: 'object',
  properties: {
    es_comprobante: { type: 'boolean' },
    legible: { type: 'boolean' },
    ruc: oNulo(texto),
    emisor: oNulo(texto),
    tipo: oNulo({ type: 'string', enum: [...tiposDeComprobante] }),
    serie: oNulo(texto),
    numero: oNulo(texto),
    fecha: oNulo({ type: 'string', format: 'date' }),
    subtotal: oNulo({ type: 'number' }),
    igv: oNulo({ type: 'number' }),
    total: oNulo({ type: 'number' }),
    cantidad_items: oNulo({ type: 'integer' }),
    categoria: oNulo(texto),
  },
  required: [
    'es_comprobante', 'legible', 'ruc', 'emisor', 'tipo', 'serie', 'numero',
    'fecha', 'subtotal', 'igv', 'total', 'cantidad_items', 'categoria',
  ],
  additionalProperties: false,
};

const instrucciones = `Lees fotos de comprobantes de compra de pequeños negocios del Perú: facturas, boletas, tickets, recibos de luz, agua o teléfono y notas de venta.

Devuelve solo lo que se lee con seguridad en la foto. Si un dato no se ve o dudas, ponlo en null: nunca adivines un monto, una fecha ni un número. El dueño revisa todo antes de guardarlo.

- es_comprobante: false si la foto no es un comprobante de compra o pago.
- legible: false si la foto está borrosa, cortada o no deja leer el total.
- ruc: los 11 dígitos del RUC de quien emite el comprobante (no el del cliente).
- emisor: el nombre comercial o la razón social de quien emite.
- serie y numero: como aparecen (por ejemplo «F001» y «245»), sin ceros a la izquierda en el número.
- fecha: la de emisión, en formato AAAA-MM-DD.
- subtotal, igv y total: en soles, con céntimos (por ejemplo 98.5). total es el importe total a pagar.
- cantidad_items: cuántas líneas de productos o servicios tiene.
- categoria: la que mejor describe la compra, elegida solo de la lista que se te da; null si ninguna encaja.`;

/** El lector de verdad, con la llave de la API de Anthropic. */
export function lectorAnthropic(llave: string): Lector {
  const cliente = new Anthropic({ apiKey: llave, timeout: 60_000, maxRetries: 1 });
  return {
    async leer(imagen, categorias, modelo) {
      const contenido: Anthropic.ContentBlockParam[] = [
        { type: 'image', source: { type: 'base64', media_type: imagen.tipo, data: imagen.datos } },
        {
          type: 'text',
          text: `Categorías del negocio: ${categorias.join('; ') || 'ninguna'}.\nLee este comprobante.`,
        },
      ];
      const pedido = {
        model: modelo,
        max_tokens: 16000,
        system: instrucciones,
        messages: [{ role: 'user' as const, content: contenido }],
      };
      // El económico piensa poco; el mayor, cuando la lectura no cuadró,
      // un poco más. El mayor puede pasar a otro modelo si se niega.
      const respuesta =
        modelo === modeloEconomico
          ? await cliente.messages.create({
              ...pedido,
              output_config: { effort: 'low', format: { type: 'json_schema', schema: esquema } },
            })
          : await cliente.beta.messages.create({
              ...pedido,
              betas: ['server-side-fallback-2026-07-01'],
              fallbacks: 'default',
              output_config: { effort: 'medium', format: { type: 'json_schema', schema: esquema } },
            });
      const bloque = respuesta.content.find((b) => b.type === 'text');
      let leida: RespuestaModelo | null = null;
      if (respuesta.stop_reason !== 'refusal' && bloque?.type === 'text') {
        try {
          leida = JSON.parse(bloque.text) as RespuestaModelo;
        } catch {
          // Cortada (max_tokens): se trata como no leída.
        }
      }
      return {
        respuesta: leida,
        tokensEntrada: respuesta.usage.input_tokens,
        tokensSalida: respuesta.usage.output_tokens,
      };
    },
  };
}
