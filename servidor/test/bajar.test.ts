import { randomUUID } from 'node:crypto';
import { gunzipSync, gzipSync } from 'node:zlib';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';

describe('«Ya tengo cuenta»: entrar desde otro teléfono y bajar todo', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;
  const usuarioId = randomUUID();
  const empresa = randomUUID();
  const efectivo = randomUUID();
  const venta = randomUUID();
  const videoVisto = randomUUID();
  let llaveVieja: string;

  const datos = () => ({
    empresa: {
      id: empresa,
      nombre: 'Bodega Don Lucho',
      tipo_negocio: 'bodega',
      modo: 'simple',
      pais: 'PE',
      moneda: 'PEN',
      hora_cierre_minutos: 1260,
      creado_en: '2026-10-12T02:00:00.000Z',
    },
    cuentas: [
      {
        id: efectivo,
        tipo: 'efectivo',
        nombre: 'Efectivo',
        orden: 0,
        saldo_inicial_centimos: 100000,
        fecha_saldo_inicial: '2026-10-12T05:00:00.000Z',
      },
    ],
    movimientos: [
      {
        id: venta,
        tipo: 'ingreso',
        cuenta_id: efectivo,
        monto_centimos: 35000,
        fecha_movimiento: '2026-10-12T02:00:00.000Z',
        estado_pago: 'pagado',
        monto_pagado_centimos: 35000,
        nivel_confianza: 'd',
        fuente: 'voz',
        autor_id: usuarioId,
        estado: 'vigente',
        creado_en: '2026-10-12T02:00:00.000Z',
      },
    ],
    dias_cerrados: [{ id: randomUUID(), dia: '2026-10-11' }],
    videos_vistos: [
      { id: videoVisto, video: 3, desde: 'pasos', fecha: '2026-10-12T02:05:00.000Z' },
    ],
    bitacora: [
      {
        id: randomUUID(),
        autor_id: usuarioId,
        entidad: 'movimiento',
        entidad_id: venta,
        accion: 'crear',
        valor_nuevo: { montoCentimos: 35000 },
        fecha: '2026-10-12T02:00:00.000Z',
      },
    ],
  });

  const subir = (llave: string, cuerpo: unknown) =>
    app.inject({
      method: 'POST',
      url: '/datos/subir',
      headers: { authorization: `Bearer ${llave}` },
      payload: cuerpo as object,
    });
  const entrar = () =>
    app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular: '912121212', codigo: '123456', modo: 'entrar' },
    });

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    app = crearApp({ pool: base.pool, version: 'prueba', verificador: verificadorFalso() });
    const guardar = await app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular: '912121212', codigo: '123456', usuarioId },
    });
    llaveVieja = guardar.json().llave;
    // El primer teléfono sube comprimido.
    const comprimido = await app.inject({
      method: 'POST',
      url: '/datos/subir',
      headers: {
        authorization: `Bearer ${llaveVieja}`,
        'content-type': 'application/json',
        'content-encoding': 'gzip',
      },
      payload: gzipSync(JSON.stringify(datos())),
    });
    expect(comprimido.statusCode, comprimido.body).toBe(200);
  });
  afterAll(() => base.cerrar());

  it('entra con el código y baja lo mismo que se subió', async () => {
    const entrada = await entrar();
    expect(entrada.statusCode).toBe(200);
    expect(entrada.json()).toMatchObject({ usuarioId, empresas: [empresa] });
    const llave = entrada.json().llave as string;

    const respuesta = await app.inject({
      method: 'GET',
      url: '/datos/bajar',
      headers: { authorization: `Bearer ${llave}`, 'accept-encoding': 'gzip' },
    });
    expect(respuesta.headers['content-encoding']).toBe('gzip');
    const { datos: bajados } = JSON.parse(gunzipSync(respuesta.rawPayload).toString());
    expect(bajados.usuario).toEqual({ id: usuarioId, celular: '+51912121212' });
    expect(bajados.membresia).toMatchObject({ empresa_id: empresa, rol: 'dueno' });
    expect(bajados.empresa).toMatchObject({ nombre: 'Bodega Don Lucho', hora_cierre_minutos: 1260 });
    // Montos como números, fechas en UTC y días sin hora.
    expect(bajados.movimientos).toEqual([
      expect.objectContaining({
        id: venta,
        monto_centimos: 35000,
        fecha_movimiento: '2026-10-12T02:00:00.000Z',
      }),
    ]);
    expect(bajados.cuentas[0].saldo_inicial_centimos).toBe(100000);
    expect(bajados.dias_cerrados).toEqual([expect.objectContaining({ dia: '2026-10-11' })]);
    expect(bajados.bitacora[0].valor_nuevo).toEqual({ montoCentimos: 35000 });
    expect(bajados.videos_vistos).toEqual([
      expect.objectContaining({ id: videoVisto, video: 3, desde: 'pasos' }),
    ]);
  });

  it('el teléfono anterior ya no puede subir: un teléfono por cuenta', async () => {
    const respuesta = await subir(llaveVieja, datos());
    expect(respuesta.statusCode).toBe(401);
    expect(respuesta.json()).toEqual({ error: 'sin_sesion' });
  });

  it('sin llave no se baja nada', async () => {
    const respuesta = await app.inject({ method: 'GET', url: '/datos/bajar' });
    expect(respuesta.statusCode).toBe(401);
  });
});
