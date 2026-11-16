import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';

describe('El consentimiento del dueño (entrega 83)', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;

  const verificar = (celular: string, extra: object = {}) =>
    app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular, codigo: '123456', usuarioId: randomUUID(), ...extra },
    });
  const consentimientoDe = async (celular: string) =>
    (
      await base.poolAdmin.query(
        `SELECT consentimiento_en IS NOT NULL AS acepto, consentimiento_version AS version
           FROM usuarios WHERE celular = $1`,
        [`+51${celular}`],
      )
    ).rows[0];

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    app = crearApp({ pool: base.pool, version: 'prueba', verificador: verificadorFalso() });
  });
  afterAll(() => base.cerrar());

  it('Al guardar su avance con «Acepto», se guarda cuándo y qué texto aceptó', async () => {
    expect((await verificar('987000041', { consentimiento: '2026-11-16' })).statusCode).toBe(200);
    expect(await consentimientoDe('987000041')).toEqual({ acepto: true, version: '2026-11-16' });
  });

  it('Una versión anterior de la app, sin consentimiento, entra igual y queda sin aceptar', async () => {
    expect((await verificar('987000042')).statusCode).toBe(200);
    expect(await consentimientoDe('987000042')).toEqual({ acepto: false, version: null });
    // Algo que no es una fecha no cuenta como aceptado.
    expect((await verificar('987000043', { consentimiento: true })).statusCode).toBe(200);
    expect(await consentimientoDe('987000043')).toEqual({ acepto: false, version: null });
  });

  it('Quien ya tenía cuenta lo acepta desde el Asistente, con su llave', async () => {
    const llave = (await verificar('987000044')).json().llave as string;
    const aceptar = (version: unknown, conLlave = true) =>
      app.inject({
        method: 'POST',
        url: '/cuenta/consentimiento',
        ...(conLlave ? { headers: { authorization: `Bearer ${llave}` } } : {}),
        payload: { version },
      });
    expect((await aceptar('2026-11-16', false)).statusCode).toBe(401);
    expect((await aceptar('ayer')).statusCode).toBe(400);
    expect((await aceptar('2026-11-16')).json()).toEqual({ ok: true });
    expect(await consentimientoDe('987000044')).toEqual({ acepto: true, version: '2026-11-16' });
  });
});
