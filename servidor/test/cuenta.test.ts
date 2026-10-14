import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import { limites } from '../src/cuenta/rutas.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';

describe('Cuenta con el celular', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;
  let verificador: ReturnType<typeof verificadorFalso>;

  const pedir = (celular: string, ip = '10.0.0.1') =>
    app.inject({
      method: 'POST',
      url: '/cuenta/codigo',
      payload: { celular },
      remoteAddress: ip,
    });
  const verificar = (celular: string, codigo: string, usuarioId: string) =>
    app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular, codigo, usuarioId },
    });

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    verificador = verificadorFalso();
    app = crearApp({ pool: base.pool, version: 'prueba', verificador });
  });
  afterAll(() => base.cerrar());

  it('sin Twilio configurado no da cuentas', async () => {
    const sinVerificador = crearApp({ pool: base.pool, version: 'prueba' });
    const respuesta = await sinVerificador.inject({
      method: 'POST',
      url: '/cuenta/codigo',
      payload: { celular: '987654321' },
    });
    expect(respuesta.statusCode).toBe(503);
  });

  it('envía el código a un celular de Perú', async () => {
    const respuesta = await pedir('987654321');
    expect(respuesta.statusCode).toBe(200);
    expect(respuesta.json()).toEqual({ canal: 'sms' });
    expect(verificador.enviados).toContain('+51987654321');
    expect((await pedir('887654321')).json()).toEqual({ error: 'celular_invalido' });
  });

  it('pone un límite de pedidos por número y por conexión', async () => {
    for (let i = 0; i < limites.porCelular; i++) await pedir('911111111', `10.1.0.${i}`);
    const otra = await pedir('911111111', '10.1.1.1');
    expect(otra.statusCode).toBe(429);
    for (let i = 0; i < limites.porConexion; i++) await pedir(`92222${String(i).padStart(4, '0')}`, '10.2.0.1');
    expect((await pedir('933333333', '10.2.0.1')).statusCode).toBe(429);
  });

  it('un envío que Twilio rechaza no cuenta para el límite', async () => {
    const rechaza = crearApp({
      pool: base.pool,
      version: 'prueba',
      verificador: {
        ...verificador,
        enviar: async () => {
          throw new Error('Twilio no envió el código (403) código 21608');
        },
      },
    });
    for (let i = 0; i < limites.porCelular + 1; i++) {
      const fallo = await rechaza.inject({
        method: 'POST',
        url: '/cuenta/codigo',
        payload: { celular: '999000111' },
        remoteAddress: '10.3.0.1',
      });
      expect(fallo.statusCode).toBe(500);
    }
    expect((await pedir('999000111', '10.3.0.2')).statusCode).toBe(200);
  });

  it('un código incorrecto o vencido no entra', async () => {
    const usuario = randomUUID();
    expect((await verificar('944444444', '111111', usuario)).json()).toEqual({
      error: 'codigo_incorrecto',
    });
    expect((await verificar('944444444', '000000', usuario)).json()).toEqual({
      error: 'codigo_vencido',
    });
  });

  it('un número nuevo crea la cuenta con el usuario del teléfono', async () => {
    const usuario = randomUUID();
    const respuesta = await verificar('955555555', '123456', usuario);
    expect(respuesta.statusCode).toBe(200);
    const cuerpo = respuesta.json();
    expect(cuerpo).toMatchObject({ usuarioId: usuario, empresas: [], cuentaExistente: false });
    expect(cuerpo.llave).toMatch(/^[\w-]{40,}$/);
    // Solo se guarda la huella de la llave.
    const { rows } = await base.poolAdmin.query('SELECT huella FROM sesiones');
    expect(rows.some((f) => f.huella.toString() === cuerpo.llave)).toBe(false);
  });

  it('el mismo número desde otro teléfono no mezcla cuentas', async () => {
    const primero = randomUUID();
    await verificar('966666666', '123456', primero);
    const otroTelefono = await verificar('966666666', '123456', randomUUID());
    expect(otroTelefono.json()).toMatchObject({
      usuarioId: primero,
      cuentaExistente: true,
    });
    // Sin llave: ese teléfono no puede tocar la cuenta.
    expect(otroTelefono.json().llave).toBeUndefined();
  });

  it('para entrar, un número sin cuenta no crea nada', async () => {
    const respuesta = await app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular: '901010101', codigo: '123456', modo: 'entrar' },
    });
    expect(respuesta.statusCode).toBe(404);
    expect(respuesta.json()).toEqual({ error: 'sin_cuenta' });
    const { rows } = await base.poolAdmin.query(
      `SELECT 1 FROM usuarios WHERE celular = '+51901010101'`,
    );
    expect(rows).toHaveLength(0);
  });

  it('para entrar, una cuenta sin datos tampoco tiene nada que bajar', async () => {
    await verificar('902020202', '123456', randomUUID());
    const respuesta = await app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular: '902020202', codigo: '123456', modo: 'entrar' },
    });
    expect(respuesta.statusCode).toBe(404);
  });

  it('un teléfono con cuenta no puede tomar otro número', async () => {
    const usuario = randomUUID();
    await verificar('977777777', '123456', usuario);
    const otroNumero = await verificar('988888888', '123456', usuario);
    expect(otroNumero.statusCode).toBe(409);
  });
});
