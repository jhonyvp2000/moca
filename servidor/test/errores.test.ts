import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';

interface Persona {
  usuarioId: string;
  llave: string;
}

const error = (firma: string, veces = 1, extra: Record<string, unknown> = {}) => ({
  id: randomUUID(),
  firma,
  mensaje: `Bad state: ${firma}`,
  pila: '#0 main (package:moca/app.dart:10)',
  pantalla: '/inicio',
  entrega: 'piloto-1',
  armado: 120,
  veces,
  primera: '2026-11-04T15:00:00Z',
  ultima: '2026-11-04T15:05:00Z',
  ...extra,
});

describe('Los errores de la app (entrega 27)', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;
  let rosa: Persona;
  let pepe: Persona;
  let jhony: Persona;

  const verificar = async (celular: string): Promise<Persona> => {
    const usuarioId = randomUUID();
    const r = await app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular, codigo: '123456', usuarioId },
    });
    return { usuarioId, llave: r.json().llave };
  };
  const pedir = (persona: Persona | null, metodo: 'GET' | 'POST', url: string, payload?: object) =>
    app.inject({
      method: metodo,
      url,
      headers: persona ? { authorization: `Bearer ${persona.llave}` } : {},
      ...(payload ? { payload } : {}),
    });

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    app = crearApp({
      pool: base.pool,
      version: 'prueba',
      verificador: verificadorFalso(),
      cobro: { desde: null, admins: ['900000000'], yape: null },
    });
    rosa = await verificar('987000001');
    pepe = await verificar('987000002');
    jhony = await verificar('900000000');
  });
  afterAll(() => base.cerrar());

  it('Solo con la cuenta, y con lo que debe traer', async () => {
    expect((await pedir(null, 'POST', '/errores', { errores: [error('a')] })).statusCode).toBe(
      401,
    );
    expect(
      (await pedir(rosa, 'POST', '/errores', { errores: [{ ...error('a'), veces: 0 }] }))
        .statusCode,
    ).toBe(400);
    expect(
      (await pedir(rosa, 'POST', '/errores', { errores: Array(51).fill(error('a')) })).statusCode,
    ).toBe(400);
  });

  it('Jhony los ve agrupados: el mismo error de dos personas es una fila', async () => {
    const deRosa = error('pantalla-negra', 2);
    expect((await pedir(rosa, 'POST', '/errores', { errores: [deRosa] })).json()).toEqual({
      recibidos: 1,
    });
    // Reenviarlo con más veces no lo duplica.
    await pedir(rosa, 'POST', '/errores', {
      errores: [{ ...deRosa, veces: 3, ultima: '2026-11-04T16:00:00Z' }],
    });
    await pedir(pepe, 'POST', '/errores', { errores: [error('pantalla-negra', 1)] });
    await pedir(pepe, 'POST', '/errores', { errores: [error('otra')] });

    expect((await pedir(rosa, 'GET', '/errores')).statusCode).toBe(403);
    const lista = (await pedir(jhony, 'GET', '/errores')).json().errores;
    expect(lista[0]).toMatchObject({
      firma: 'pantalla-negra',
      veces: 4,
      personas: 2,
      pantalla: '/inicio',
      entrega: 'piloto-1',
      armado: 120,
    });
    expect(lista.map((e: { firma: string }) => e.firma).sort()).toEqual(['otra', 'pantalla-negra']);
  });

  it('A los 90 días se borran solos', async () => {
    await pedir(rosa, 'POST', '/errores', {
      errores: [error('viejo', 1, { ultima: '2026-01-01T00:00:00Z', primera: '2026-01-01T00:00:00Z' })],
    });
    const lista = (await pedir(jhony, 'GET', '/errores')).json().errores;
    expect(lista.map((e: { firma: string }) => e.firma)).not.toContain('viejo');
  });
});
