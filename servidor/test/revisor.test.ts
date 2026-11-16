import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import {
  bloqueoDelRevisorMs,
  conRevisor,
  fallosDelRevisor,
  leerConfigRevisor,
} from '../src/cuenta/verificador.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';

describe('La cuenta del revisor de Google Play (entrega 82)', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;
  let twilio: ReturnType<typeof verificadorFalso>;
  let ahora = Date.parse('2026-11-16T15:00:00Z');
  const revisor = { celular: '+51911000111', codigo: '482913' };

  const pedir = (celular: string) =>
    app.inject({ method: 'POST', url: '/cuenta/codigo', payload: { celular } });
  const verificar = (celular: string, codigo: string) =>
    app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular, codigo, usuarioId: randomUUID() },
    });

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    twilio = verificadorFalso();
    app = crearApp({
      pool: base.pool,
      version: 'prueba',
      verificador: conRevisor(twilio, revisor, () => ahora),
    });
  });
  afterAll(() => base.cerrar());

  it('Solo existe con las dos variables bien puestas', () => {
    expect(leerConfigRevisor({})).toBeNull();
    expect(leerConfigRevisor({ MOCA_REVISOR_CELULAR: '911000111' })).toBeNull();
    expect(
      leerConfigRevisor({ MOCA_REVISOR_CELULAR: '911000111', MOCA_REVISOR_CODIGO: '12345' }),
    ).toBeNull();
    expect(
      leerConfigRevisor({ MOCA_REVISOR_CELULAR: '811000111', MOCA_REVISOR_CODIGO: '123456' }),
    ).toBeNull();
    expect(
      leerConfigRevisor({ MOCA_REVISOR_CELULAR: ' 911000111 ', MOCA_REVISOR_CODIGO: '482913' }),
    ).toEqual(revisor);
    // Sin revisor, el verificador es el de siempre; sin Twilio, no hay cuentas.
    expect(conRevisor(twilio, null)).toBe(twilio);
    expect(conRevisor(null, revisor)).toBeNull();
  });

  it('El revisor entra con su código fijo, sin SMS', async () => {
    expect((await pedir('911000111')).json()).toEqual({ canal: 'sms' });
    expect(twilio.enviados).not.toContain('+51911000111');
    // El código de Twilio no le sirve; el suyo, sí.
    expect((await verificar('911000111', '123456')).json()).toEqual({ error: 'codigo_incorrecto' });
    const r = await verificar('911000111', '482913');
    expect(r.statusCode).toBe(200);
    expect(r.json().llave).toEqual(expect.any(String));
  });

  it('Cualquier otro número sigue con Twilio, y el código del revisor no le sirve', async () => {
    await pedir('987000031');
    expect(twilio.enviados).toContain('+51987000031');
    expect((await verificar('987000031', '482913')).json()).toEqual({ error: 'codigo_incorrecto' });
    expect((await verificar('987000031', '123456')).statusCode).toBe(200);
  });

  it('Con 5 códigos equivocados se bloquea una hora, aunque luego ponga el bueno', async () => {
    for (let i = 0; i < fallosDelRevisor; i++) {
      expect((await verificar('911000111', '000001')).json()).toEqual({
        error: 'codigo_incorrecto',
      });
    }
    expect((await verificar('911000111', '482913')).json()).toEqual({
      error: 'codigo_incorrecto',
    });
    // Pasada la hora, vuelve a entrar.
    ahora += bloqueoDelRevisorMs;
    expect((await verificar('911000111', '482913')).statusCode).toBe(200);
  });
});
