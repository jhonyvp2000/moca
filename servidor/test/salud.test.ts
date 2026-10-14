import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import { crearPool } from '../src/base/conexion.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';

describe('GET /salud', () => {
  let base: BaseDePrueba;
  beforeAll(async () => {
    base = await crearBaseDePrueba();
  });
  afterAll(() => base.cerrar());

  it('responde bien con un rol normal', async () => {
    const app = crearApp({ pool: base.pool, version: '0.10.0' });
    const respuesta = await app.inject({ method: 'GET', url: '/salud' });
    expect(respuesta.statusCode).toBe(200);
    expect(respuesta.json()).toEqual({
      estado: 'bien',
      version: '0.10.0',
      base: 'bien',
      aislamiento: 'activo',
    });
  });

  it('avisa si el rol se salta el aislamiento', async () => {
    const app = crearApp({ pool: base.poolAdmin, version: '0.10.0' });
    const respuesta = await app.inject({ method: 'GET', url: '/salud' });
    expect(respuesta.statusCode).toBe(503);
    expect(respuesta.json()).toMatchObject({ estado: 'mal', aislamiento: 'desactivado' });
  });

  it('avisa si no hay base', async () => {
    const sinBase = crearPool('postgres://nadie:nada@localhost:1/nada');
    const app = crearApp({ pool: sinBase, version: '0.10.0' });
    const respuesta = await app.inject({ method: 'GET', url: '/salud' });
    expect(respuesta.statusCode).toBe(503);
    expect(respuesta.json()).toMatchObject({ estado: 'mal', base: 'sin conexión' });
    await sinBase.end();
  });
});
