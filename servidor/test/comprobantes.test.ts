import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import { costoMicrodolares, leerComprobante, problemasDe } from '../src/comprobantes/leer.js';
import {
  modeloEconomico,
  modeloMayor,
  type Lector,
  type Modelo,
  type RespuestaModelo,
} from '../src/comprobantes/lector.js';
import { limiteDiario } from '../src/comprobantes/rutas.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';

/** Una factura que cuadra: RUC válido, 83.05 + 14.95 = 98.00. */
const factura: RespuestaModelo = {
  es_comprobante: true,
  legible: true,
  ruc: '20100070970',
  emisor: 'Distribuidora San Martín',
  tipo: 'Factura',
  serie: 'f001',
  numero: '000245',
  fecha: '2026-10-13',
  subtotal: 83.05,
  igv: 14.95,
  total: 98,
  cantidad_items: 12,
  categoria: 'Mercadería',
};

/** Responde lo que se le diga por modelo y anota a quién se le pidió. */
function lectorFalso(porModelo: Partial<Record<Modelo, RespuestaModelo | null | Error>>) {
  const pedidos: Modelo[] = [];
  const lector: Lector = {
    async leer(_imagen, _categorias, modelo) {
      pedidos.push(modelo);
      const r = porModelo[modelo];
      if (r instanceof Error) throw r;
      return { respuesta: r ?? null, tokensEntrada: 2000, tokensSalida: 300 };
    },
  };
  return { lector, pedidos };
}

const imagen = { datos: 'x'.repeat(200), tipo: 'image/jpeg' as const };
const categorias = ['Mercadería', 'Transporte'];
const hoy = '2026-10-14';

describe('Lectura: primero el económico, el mayor solo si no cuadra', () => {
  it('si el económico lee bien, no se llama al mayor', async () => {
    const { lector, pedidos } = lectorFalso({ [modeloEconomico]: factura });
    const leido = await leerComprobante(lector, imagen, categorias, hoy);
    expect(pedidos).toEqual([modeloEconomico]);
    expect(leido.resultado).toBe('leido');
    expect(leido.lectura).toEqual({
      emisor_identificacion: '20100070970',
      emisor_nombre: 'Distribuidora San Martín',
      tipo: 'Factura',
      serie: 'F001',
      numero: '245',
      fecha_emision: '2026-10-13',
      impuesto_centimos: 1495,
      total_centimos: 9800,
      cantidad_items: 12,
      categoria: 'Mercadería',
    });
  });

  it.each([
    ['un RUC que no pasa el dígito verificador', { ruc: '20100070971' }, 'ruc_invalido'],
    ['subtotal e IGV que no suman el total', { subtotal: 50 }, 'no_suma'],
    ['sin total', { total: null }, 'sin_total'],
    ['una fecha futura', { fecha: '2026-12-01' }, 'fecha_imposible'],
    ['una foto que el modelo marca ilegible', { legible: false }, 'ilegible'],
  ])('con %s, lee el mayor', async (_caso, cambio, problema) => {
    const dudosa = { ...factura, ...cambio };
    expect(problemasDe(dudosa, hoy)).toContain(problema);
    const { lector, pedidos } = lectorFalso({
      [modeloEconomico]: dudosa,
      [modeloMayor]: factura,
    });
    const leido = await leerComprobante(lector, imagen, categorias, hoy);
    expect(pedidos).toEqual([modeloEconomico, modeloMayor]);
    expect(leido.resultado).toBe('leido');
    expect(leido.lectura?.total_centimos).toBe(9800);
  });

  it('si el mayor tampoco cuadra, es ilegible y se quita lo imposible', async () => {
    const mala = { ...factura, ruc: '20100070971', total: null, legible: false };
    const { lector } = lectorFalso({ [modeloEconomico]: mala, [modeloMayor]: mala });
    const leido = await leerComprobante(lector, imagen, categorias, hoy);
    expect(leido.resultado).toBe('ilegible');
    expect(leido.lectura).toMatchObject({
      emisor_identificacion: null,
      total_centimos: null,
      emisor_nombre: 'Distribuidora San Martín',
    });
  });

  it('si el mayor falla, queda lo del económico como ilegible', async () => {
    const { lector } = lectorFalso({
      [modeloEconomico]: { ...factura, total: null },
      [modeloMayor]: new Error('sin respuesta'),
    });
    const leido = await leerComprobante(lector, imagen, categorias, hoy);
    expect(leido.resultado).toBe('ilegible');
    expect(leido.lectura?.emisor_nombre).toBe('Distribuidora San Martín');
  });

  it('lo que no es comprobante no pasa al mayor', async () => {
    const { lector, pedidos } = lectorFalso({
      [modeloEconomico]: { ...factura, es_comprobante: false },
    });
    const leido = await leerComprobante(lector, imagen, categorias, hoy);
    expect(pedidos).toEqual([modeloEconomico]);
    expect(leido).toMatchObject({ resultado: 'no_es_comprobante', lectura: null });
  });

  it('una categoría fuera de la lista del negocio no se sugiere', async () => {
    const { lector } = lectorFalso({ [modeloEconomico]: { ...factura, categoria: 'Joyas' } });
    const leido = await leerComprobante(lector, imagen, categorias, hoy);
    expect(leido.lectura?.categoria).toBeNull();
  });

  it('mide el costo con el precio de cada modelo', async () => {
    const { lector } = lectorFalso({
      [modeloEconomico]: { ...factura, total: null },
      [modeloMayor]: factura,
    });
    const { pasos } = await leerComprobante(lector, imagen, categorias, hoy);
    // Haiku: 2000 × 0.10 + 300 × 0.50; Sonnet: 2000 × 2 + 300 × 10.
    expect(costoMicrodolares(pasos)).toBe(200 + 150 + 4000 + 3000);
  });
});

describe('Lectura: la ruta', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;
  let llave: string;
  let falso = lectorFalso({ [modeloEconomico]: factura });

  const leer = (conLlave = llave) =>
    app.inject({
      method: 'POST',
      url: '/comprobantes/leer',
      headers: { authorization: `Bearer ${conLlave}` },
      payload: { imagen: imagen.datos, categorias },
    });

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    app = crearApp({
      pool: base.pool,
      version: 'prueba',
      verificador: verificadorFalso(),
      lector: { leer: (...a) => falso.lector.leer(...a) },
      ahora: () => new Date('2026-10-14T20:00:00Z'),
    });
    const cuenta = await app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: {
        celular: '914141414',
        codigo: '123456',
        usuarioId: '7c0e8a52-1111-4a6e-9c3b-0a8d5e6f7a01',
      },
    });
    llave = cuenta.json().llave;
  });
  beforeEach(() => {
    falso = lectorFalso({ [modeloEconomico]: factura });
  });
  afterAll(() => base.cerrar());

  it('sin cuenta, no lee', async () => {
    expect((await leer('otra')).statusCode).toBe(401);
  });

  it('lee y anota la lectura, sin guardar la foto', async () => {
    const respuesta = await leer();
    expect(respuesta.statusCode, respuesta.body).toBe(200);
    expect(respuesta.json()).toMatchObject({ resultado: 'leido', lectura: { total_centimos: 9800 } });
    const { rows } = await base.poolAdmin.query('SELECT * FROM lecturas');
    expect(rows).toEqual([
      expect.objectContaining({
        resultado: 'leido',
        modelo: modeloEconomico,
        escalo: false,
        costo_microdolares: 350,
      }),
    ]);
    expect(JSON.stringify(rows[0])).not.toContain(imagen.datos);
  });

  it('si la IA no responde, dice que no pudo y lo anota', async () => {
    falso = lectorFalso({ [modeloEconomico]: new Error('caída') });
    const respuesta = await leer();
    expect(respuesta.statusCode).toBe(502);
    expect(respuesta.json()).toEqual({ error: 'no_se_pudo_leer' });
  });

  it(`a las ${limiteDiario} fotos del día, para`, async () => {
    const { rows } = await base.poolAdmin.query<{ n: number }>(
      'SELECT count(*)::int AS n FROM lecturas',
    );
    for (let i = rows[0]!.n; i < limiteDiario; i++) {
      expect((await leer()).statusCode).toBe(200);
    }
    const respuesta = await leer();
    expect(respuesta.statusCode).toBe(429);
    expect(respuesta.json()).toEqual({ error: 'limite_diario' });
  });

  it('sin llave de Anthropic, avisa que no hay lector', async () => {
    const sinLector = crearApp({ pool: base.pool, version: 'prueba' });
    const respuesta = await sinLector.inject({
      method: 'POST',
      url: '/comprobantes/leer',
      headers: { authorization: `Bearer ${llave}` },
      payload: { imagen: imagen.datos },
    });
    expect(respuesta.statusCode).toBe(503);
  });
});
