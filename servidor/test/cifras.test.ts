import { readFileSync } from 'node:fs';
import { gunzipSync } from 'node:zlib';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import { calcularCifras, type DatosEmpresa } from '../src/cifras/calcular.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';

/**
 * La Demo de la app y las cifras que el teléfono calcula con ella en cinco
 * momentos (app/test/datos/paridad_servidor_test.dart). Incluye un aviso
 * marcado «Entendido».
 */
const demo = JSON.parse(
  readFileSync(new URL('./paridad/demo.json', import.meta.url), 'utf8'),
) as {
  datos: DatosEmpresa & { empresa: { id: string }; movimientos: { autor_id: string }[] };
  momentos: { ahora: string; cifras: unknown }[];
};

describe('Cifras: el servidor calcula lo mismo que el teléfono', () => {
  for (const { ahora, cifras } of demo.momentos) {
    it(`con la Demo, el ${ahora}`, () => {
      expect(calcularCifras(demo.datos, new Date(ahora))).toEqual(cifras);
    });
  }
});

describe('Cifras: rutas', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;
  let llave: string;
  let reloj = new Date(demo.momentos[0]!.ahora);
  const usuarioId = demo.datos.movimientos[0]!.autor_id;

  const pedir = (url: string, conLlave = llave) =>
    app.inject({ method: 'GET', url, headers: { authorization: `Bearer ${conLlave}` } });

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    app = crearApp({
      pool: base.pool,
      version: 'prueba',
      verificador: verificadorFalso(),
      ahora: () => reloj,
    });
    const cuenta = await app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular: '913131313', codigo: '123456', usuarioId },
    });
    llave = cuenta.json().llave;
  });
  afterAll(() => base.cerrar());

  it('sin empresa todavía, no hay cifras', async () => {
    const respuesta = await pedir('/cifras');
    expect(respuesta.statusCode).toBe(200);
    expect(respuesta.json()).toEqual({ cifras: null });
  });

  it('al subir, responde con las cifras de lo subido (pasando por la base)', async () => {
    const respuesta = await app.inject({
      method: 'POST',
      url: '/datos/subir',
      headers: { authorization: `Bearer ${llave}` },
      payload: demo.datos,
    });
    expect(respuesta.statusCode, respuesta.body).toBe(200);
    expect(respuesta.json().cifras).toEqual(demo.momentos[0]!.cifras);
  });

  it('las pide el teléfono, comprimidas, con la hora del servidor', async () => {
    reloj = new Date(demo.momentos[4]!.ahora);
    const respuesta = await app.inject({
      method: 'GET',
      url: '/cifras',
      headers: { authorization: `Bearer ${llave}`, 'accept-encoding': 'gzip' },
    });
    expect(respuesta.statusCode).toBe(200);
    expect(respuesta.headers['content-encoding']).toBe('gzip');
    expect(JSON.parse(gunzipSync(respuesta.rawPayload).toString()).cifras).toEqual(
      demo.momentos[4]!.cifras,
    );
  });

  it('bajan con los datos, y el aviso marcado «Entendido» baja con su clave', async () => {
    reloj = new Date(demo.momentos[1]!.ahora);
    const respuesta = await pedir('/datos/bajar');
    expect(respuesta.statusCode).toBe(200);
    const { datos, cifras } = respuesta.json();
    expect(cifras).toEqual(demo.momentos[1]!.cifras);
    expect(datos.alertas).toEqual([
      expect.objectContaining({ clave: demo.datos.alertas![0]!.clave, estado: 'vista' }),
    ]);
  });

  it('sin llave, no hay cifras', async () => {
    expect((await pedir('/cifras', 'otra')).statusCode).toBe(401);
  });
});

describe('Entrega 54: avisos de clientes por cobrar', () => {
  // Jueves 12 de noviembre de 2026, 10:00 a. m. en Lima (15:00 UTC).
  const ahora = new Date('2026-11-12T15:00:00Z');
  const venta = (id: string, cliente: string, fecha: string, monto: number, pagado = 0) => ({
    id,
    tipo: 'ingreso',
    cuenta_id: 'c1',
    cuenta_destino_id: null,
    monto_centimos: monto,
    fecha_movimiento: fecha,
    fecha_comprobante: null,
    fecha_pago: null,
    estado_pago: pagado > 0 ? 'parcial' : 'pendiente',
    monto_pagado_centimos: pagado,
    categoria_id: null,
    contraparte_id: cliente,
    nivel_confianza: 'd',
    estado: 'vigente',
  });
  const datos = (rol?: string, recordadoRosa: string | null = null): DatosEmpresa => ({
    cuentas: [{ id: 'c1', tipo: 'efectivo', saldo_inicial_centimos: 0, fecha_saldo_inicial: null }],
    categorias: [],
    movimientos: [
      // Doña Rosa: dos ventas, la más antigua del 3 de noviembre.
      venta('m1', 'rosa', '2026-11-03T15:00:00Z', 10000, 2500),
      venta('m2', 'rosa', '2026-11-10T15:00:00Z', 5000),
      // Don Pepe: fió hace 6 días, todavía no toca.
      venta('m3', 'pepe', '2026-11-06T15:00:00Z', 3000),
    ],
    arqueos: [],
    arqueo_cuentas: [],
    dias_cerrados: [],
    contrapartes: [
      { id: 'rosa', nombre: 'Doña Rosa', recordado_en: recordadoRosa },
      { id: 'pepe', nombre: 'Don Pepe', recordado_en: null },
    ],
    ...(rol ? { membresia: { rol } } : {}),
  });
  const cobros = (d: DatosEmpresa) =>
    calcularCifras(d, ahora).avisos.filter((a) => a.tipo === 'cobrarCliente');

  it('avisa del cliente que debe hace 7 días o más, con lo que falta', () => {
    expect(cobros(datos('dueno'))).toEqual([
      {
        clave: 'cobrar:rosa:2026-11-09T00:00:00.000',
        tipo: 'cobrarCliente',
        prioridad: 'paraTenerEnCuenta',
        fecha: '2026-11-03T15:00:00.000Z',
        montoCentimos: 12500,
        cuenta: null,
        categoria: null,
        dias: null,
        destinoId: 'rosa',
        cliente: 'Doña Rosa',
      },
    ]);
  });

  it('recordarle hace menos de 7 días lo calla; hace 7, vuelve', () => {
    expect(cobros(datos('dueno', '2026-11-06T20:00:00Z'))).toEqual([]);
    expect(cobros(datos('dueno', '2026-11-05T20:00:00Z'))).toHaveLength(1);
  });

  it('solo para los dueños', () => {
    expect(cobros(datos('encargado'))).toEqual([]);
    expect(cobros(datos('contador'))).toEqual([]);
  });
});
