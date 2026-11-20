import type Anthropic from '@anthropic-ai/sdk';
import { describe, expect, it } from 'vitest';
import { cifrasDelPeriodo, type CifrasDelPeriodo } from '../src/pregunta/periodo.js';
import type { Hechos } from '../src/pregunta/hechos.js';
import { respondedorAnthropic, type ClienteDeMensajes } from '../src/pregunta/respondedor.js';

// «Pregúntale a Moca» con cualquier fecha (entrega 89). Viernes 20 de
// noviembre de 2026, 10 de la mañana en Lima.
const ahora = new Date('2026-11-20T15:00:00Z');
const el = (dia: number) => `2026-11-${dia}T14:00:00.000Z`;

let siguiente = 0;
const mov = (extra: Record<string, unknown>) => ({
  id: `m${++siguiente}`,
  tipo: 'ingreso',
  cuenta_id: 'efectivo',
  categoria_id: 'venta',
  estado_pago: 'pagado',
  estado: 'vigente',
  ...extra,
});

const datos = {
  cuentas: [
    { id: 'efectivo', nombre: 'Efectivo' },
    { id: 'yape', nombre: 'BCP Yape' },
  ],
  categorias: [
    { id: 'venta', nombre: 'Venta del día' },
    { id: 'mercaderia', nombre: 'Mercadería' },
    { id: 'luz', nombre: 'Luz' },
  ],
  movimientos: [
    // El lunes 16, una venta al fiado que se cobró el miércoles 18.
    mov({ monto_centimos: 3000, fecha_movimiento: el(16), fecha_pago: el(18), cuenta_id: 'yape' }),
    // El miércoles 18.
    mov({ monto_centimos: 10000, fecha_movimiento: el(18), fecha_pago: el(18) }),
    mov({ monto_centimos: 4000, fecha_movimiento: el(18), fecha_pago: null, estado_pago: 'pendiente' }),
    // Una venta de S/ 50 que se pagó en partes: quedan S/ 30.
    mov({ id: 'partes', monto_centimos: 3000, fecha_movimiento: el(18), fecha_pago: null, estado_pago: 'pendiente' }),
    mov({ monto_centimos: 2000, fecha_movimiento: el(19), fecha_pago: el(19), abona_a: 'partes' }),
    // Una compra a crédito (no salió plata) y un gasto pagado.
    mov({ tipo: 'egreso', categoria_id: 'mercaderia', monto_centimos: 20000, fecha_movimiento: el(18), fecha_pago: null, estado_pago: 'pendiente' }),
    mov({ tipo: 'egreso', categoria_id: 'luz', monto_centimos: 1550, fecha_movimiento: el(18), fecha_pago: el(18) }),
    mov({ tipo: 'retiro', categoria_id: null, monto_centimos: 2500, fecha_movimiento: el(18), fecha_pago: el(18) }),
    mov({ tipo: 'aporte', categoria_id: null, monto_centimos: 1000, fecha_movimiento: el(18), fecha_pago: el(18) }),
    // Anulada: no cuenta.
    mov({ monto_centimos: 99900, fecha_movimiento: el(18), fecha_pago: el(18), estado: 'anulado' }),
  ],
};

const cifras = (desde: unknown, hasta: unknown) =>
  cifrasDelPeriodo(datos, desde, hasta, ahora) as CifrasDelPeriodo;

describe('Pregúntale a Moca con fechas (entrega 89)', () => {
  it('un día: lo vendido con su fiado, y la plata que entró y salió', () => {
    const c = cifras('2026-11-18', '2026-11-18');
    expect(c.desde).toBe('miércoles 18 de noviembre de 2026');
    expect(c.hasta).toBe('miércoles 18 de noviembre de 2026');
    expect(c.registros).toBe(7);
    // 100 cobrados + 40 al fiado + 50 de la venta en partes.
    expect(c.vendiste).toBe('S/ 190');
    expect(c.deEsoAlFiado).toBe('S/ 90');
    // 100 de la venta del día + 30 del fiado del lunes que se cobró ese día.
    expect(c.teEntro).toBe('S/ 130');
    expect(c.teEntroPorCuenta).toEqual([
      { nombre: 'Efectivo', monto: 'S/ 100' },
      { nombre: 'BCP Yape', monto: 'S/ 30' },
    ]);
    // La compra a crédito no movió plata.
    expect(c.salio).toBe('S/ 15.50');
    expect(c.gastosPorCategoria).toEqual([{ nombre: 'Luz', monto: 'S/ 15.50' }]);
    expect(c.retirasteParaTi).toBe('S/ 25');
    expect(c.pusisteDeTuBolsillo).toBe('S/ 10');
    expect(c.empezoAAnotar).toBeNull();
    expect(c.soloHastaHoy).toBe(false);
  });

  it('un rango: suma los días, y la parte cuenta el día que se pagó', () => {
    const c = cifras('2026-11-16', '2026-11-19');
    expect(c.vendiste).toBe('S/ 220');
    expect(c.deEsoAlFiado).toBe('S/ 120');
    expect(c.teEntro).toBe('S/ 150');
    expect(c.ventasPorCategoria).toEqual([{ nombre: 'Venta del día', monto: 'S/ 220' }]);
  });

  it('antes de empezar a anotar, o más allá de hoy, lo dice', () => {
    const c = cifras('2026-11-01', '2026-11-30');
    expect(c.empezoAAnotar).toBe('lunes 16 de noviembre de 2026');
    expect(c.soloHastaHoy).toBe(true);
    expect(c.hasta).toBe('viernes 20 de noviembre de 2026');
    const vacio = cifras('2026-11-20', '2026-11-20');
    expect(vacio.registros).toBe(0);
    expect(vacio.vendiste).toBe('S/ 0');
  });

  it('las fechas que no sirven vuelven como error, sin cifras', () => {
    const error = (d: unknown, h: unknown) => cifrasDelPeriodo(datos, d, h, ahora);
    expect(error('2026-02-30', '2026-02-30')).toEqual({ error: 'fecha_invalida' });
    expect(error('ayer', '2026-11-19')).toEqual({ error: 'fecha_invalida' });
    expect(error(undefined, 5)).toEqual({ error: 'fecha_invalida' });
    expect(error('2026-11-19', '2026-11-18')).toEqual({ error: 'rango_al_reves' });
    expect(error('2025-01-01', '2026-11-19')).toEqual({ error: 'rango_muy_largo' });
    expect(error('2026-11-21', '2026-11-21')).toEqual({ error: 'en_el_futuro' });
    // Un año entero sí.
    expect(error('2025-11-20', '2026-11-19')).not.toHaveProperty('error');
  });
});

describe('El respondedor pide las cifras y después responde (entrega 89)', () => {
  const hechos = { hoy: 'viernes 20 de noviembre de 2026' } as unknown as Hechos;
  const respuesta = (extra: Partial<Anthropic.Message>): Anthropic.Message =>
    ({
      id: 'r',
      type: 'message',
      role: 'assistant',
      model: 'claude-haiku-5-5',
      stop_reason: 'end_turn',
      usage: { input_tokens: 100, output_tokens: 10 },
      content: [],
      ...extra,
    }) as Anthropic.Message;
  const pide = (desde: string, hasta: string) =>
    respuesta({
      stop_reason: 'tool_use',
      content: [{ type: 'tool_use', id: `t-${desde}`, name: 'cifras_del_periodo', input: { desde, hasta } }],
    } as Partial<Anthropic.Message>);
  const responde = (texto: string) =>
    respuesta({
      content: [{ type: 'text', text: JSON.stringify({ respuesta: texto, enlace: null }) }],
    } as Partial<Anthropic.Message>);

  function clienteFalso(respuestas: Anthropic.Message[]) {
    const pedidos: Anthropic.MessageCreateParamsNonStreaming[] = [];
    const cliente: ClienteDeMensajes = {
      messages: {
        async create(p) {
          pedidos.push(structuredClone(p));
          return respuestas.shift()!;
        },
      },
    };
    return { cliente, pedidos };
  }

  it('pide un periodo, recibe las cifras y redacta con ellas', async () => {
    const { cliente, pedidos } = clienteFalso([
      pide('2026-11-18', '2026-11-18'),
      responde('El miércoles 18 vendiste S/ 190.'),
    ]);
    const pedidosDePeriodo: unknown[] = [];
    const r = await respondedorAnthropic('llave', cliente).responder(hechos, '¿cuánto vendí el 18?', (d, h) => {
      pedidosDePeriodo.push([d, h]);
      return cifras(d, h);
    });
    expect(r.texto).toBe('El miércoles 18 vendiste S/ 190.');
    expect(r.tokensEntrada).toBe(200);
    expect(r.tokensSalida).toBe(20);
    expect(pedidosDePeriodo).toEqual([['2026-11-18', '2026-11-18']]);
    expect(pedidos).toHaveLength(2);
    expect(pedidos[0]!.tools?.[0]).toMatchObject({ name: 'cifras_del_periodo' });
    expect(pedidos[0]!.tool_choice).toEqual({ type: 'auto' });
    const resultado = (pedidos[1]!.messages.at(-1)!.content as Anthropic.ToolResultBlockParam[])[0]!;
    expect(resultado.tool_use_id).toBe('t-2026-11-18');
    expect(JSON.parse(resultado.content as string).vendiste).toBe('S/ 190');
  });

  it('después de dos pedidos ya no deja pedir más: tiene que responder', async () => {
    const { cliente, pedidos } = clienteFalso([
      pide('2026-11-16', '2026-11-16'),
      pide('2026-11-18', '2026-11-18'),
      responde('Vendiste más el miércoles.'),
    ]);
    const r = await respondedorAnthropic('llave', cliente).responder(hechos, '¿lunes o miércoles?', cifras);
    expect(r.texto).toBe('Vendiste más el miércoles.');
    expect(pedidos.map((p) => p.tool_choice)).toEqual([{ type: 'auto' }, { type: 'auto' }, { type: 'none' }]);
    // La herramienta sigue declarada: la conversación trae sus pedidos.
    expect(pedidos[2]!.tools).toHaveLength(1);
  });

  it('sin periodo no se ofrece la herramienta', async () => {
    const { cliente, pedidos } = clienteFalso([responde('Hoy vendiste S/ 0.')]);
    await respondedorAnthropic('llave', cliente).responder(hechos, '¿cuánto vendí hoy?');
    expect(pedidos[0]!.tools).toBeUndefined();
    expect(pedidos[0]!.tool_choice).toBeUndefined();
  });
});
