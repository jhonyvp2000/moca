import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import { conEmpresa } from '../src/base/conexion.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';

/** Lo que tendría el teléfono de Don Lucho tras unos días. */
function telefonoDeLucho(usuarioId: string) {
  const empresa = randomUUID();
  const efectivo = randomUUID();
  const venta = randomUUID();
  const original = randomUUID();
  const correccion = randomUUID();
  const arqueo = randomUUID();
  const comprobante = randomUUID();
  const hoy = '2026-10-12T02:00:00.000Z';
  const movimiento = (id: string, monto: number, extra = {}) => ({
    id,
    tipo: 'ingreso',
    cuenta_id: efectivo,
    monto_centimos: monto,
    fecha_movimiento: hoy,
    estado_pago: 'pagado',
    monto_pagado_centimos: monto,
    fecha_pago: hoy,
    categoria_id: venta,
    nivel_confianza: 'd',
    fuente: 'voz',
    autor_id: usuarioId,
    estado: 'vigente',
    creado_en: hoy,
    ...extra,
  });
  return {
    ids: { empresa, efectivo, original, correccion },
    datos: {
      empresa: {
        id: empresa,
        nombre: 'Bodega Don Lucho',
        tipo_negocio: 'bodega',
        modo: 'simple',
        pais: 'PE',
        moneda: 'PEN',
        hora_cierre_minutos: 1260,
        creado_en: hoy,
      },
      cuentas: [
        {
          id: efectivo,
          tipo: 'efectivo',
          nombre: 'Efectivo',
          orden: 0,
          saldo_inicial_centimos: 100000,
          fecha_saldo_inicial: hoy,
        },
      ],
      categorias: [
        { id: venta, nombre: 'Venta del día', tipo_movimiento: 'ingreso', orden: 0, activa: true },
      ],
      comprobantes: [
        {
          id: comprobante,
          emisor_identificacion: '20100070970',
          emisor_nombre: 'Distribuidora San Martín',
          tipo: 'Factura',
          serie: 'F001',
          numero: '3100',
          fecha_emision: '2026-10-11',
          total_centimos: 60000,
          origen_lectura: 'qr',
          creado_en: hoy,
        },
      ],
      items_comprobante: [
        { id: randomUUID(), comprobante_id: comprobante, descripcion: 'Arroz', importe_centimos: 60000 },
      ],
      // La corrección llega antes que el movimiento que reemplaza.
      movimientos: [
        movimiento(correccion, 36000, { reemplaza_a: original }),
        movimiento(original, 35000, { estado: 'anulado' }),
      ],
      arqueos: [{ id: arqueo, fecha: hoy, autor_id: usuarioId, creado_en: hoy }],
      arqueo_cuentas: [
        {
          id: randomUUID(),
          arqueo_id: arqueo,
          cuenta_id: efectivo,
          saldo_calculado_centimos: 136000,
          saldo_real_centimos: 133000,
          diferencia_centimos: -3000,
          motivo: 'noLoSe',
        },
      ],
      dias_cerrados: [{ id: randomUUID(), dia: '2026-10-11' }],
      bitacora: [
        {
          id: randomUUID(),
          autor_id: usuarioId,
          entidad: 'movimiento',
          entidad_id: original,
          accion: 'editar',
          valor_anterior: { montoCentimos: 35000 },
          valor_nuevo: { montoCentimos: 36000, reemplazadoPor: correccion },
          fecha: hoy,
        },
      ],
    },
  };
}

describe('Subir lo anotado en el teléfono', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;

  const cuenta = async (celular: string) => {
    const usuarioId = randomUUID();
    const respuesta = await app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular, codigo: '123456', usuarioId },
    });
    return { usuarioId, llave: respuesta.json().llave as string };
  };
  const subir = (llave: string | null, datos: unknown) =>
    app.inject({
      method: 'POST',
      url: '/datos/subir',
      headers: llave ? { authorization: `Bearer ${llave}` } : {},
      payload: datos as object,
    });

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    app = crearApp({ pool: base.pool, version: 'prueba', verificador: verificadorFalso() });
  });
  afterAll(() => base.cerrar());

  it('sin llave no se sube nada', async () => {
    const respuesta = await subir(null, telefonoDeLucho(randomUUID()).datos);
    expect(respuesta.statusCode).toBe(401);
    expect((await subir('otra', telefonoDeLucho(randomUUID()).datos)).statusCode).toBe(401);
  });

  it('sube todo, crea la empresa con su dueño y no duplica al repetir', async () => {
    const lucho = await cuenta('912345678');
    const { ids, datos } = telefonoDeLucho(lucho.usuarioId);
    const primera = await subir(lucho.llave, datos);
    expect(primera.statusCode, primera.body).toBe(200);
    expect(primera.json().recibidos).toMatchObject({ movimientos: 2, bitacora: 1 });

    // El teléfono sube de nuevo, con un cambio: la venta se pagó por Yape.
    datos.empresa.nombre = 'Bodega Don Lucho e Hijos';
    expect((await subir(lucho.llave, datos)).statusCode).toBe(200);

    const enLaBase = await conEmpresa(
      base.pool,
      { empresaId: ids.empresa, usuarioId: lucho.usuarioId },
      async (c) => ({
        empresa: (await c.query('SELECT nombre FROM empresas')).rows,
        dueno: (await c.query('SELECT usuario_id, rol FROM membresias')).rows,
        movimientos: (
          await c.query('SELECT id, estado, reemplaza_a FROM movimientos ORDER BY monto_centimos')
        ).rows,
        bitacora: (await c.query('SELECT valor_nuevo FROM bitacora')).rows,
        dias: (await c.query(`SELECT to_char(dia, 'YYYY-MM-DD') AS dia FROM dias_cerrados`)).rows,
      }),
    );
    expect(enLaBase.empresa).toEqual([{ nombre: 'Bodega Don Lucho e Hijos' }]);
    expect(enLaBase.dueno).toEqual([{ usuario_id: lucho.usuarioId, rol: 'dueno' }]);
    expect(enLaBase.movimientos).toEqual([
      { id: ids.original, estado: 'anulado', reemplaza_a: null },
      { id: ids.correccion, estado: 'vigente', reemplaza_a: ids.original },
    ]);
    expect(enLaBase.bitacora).toHaveLength(1);
    expect(enLaBase.bitacora[0].valor_nuevo).toEqual({
      montoCentimos: 36000,
      reemplazadoPor: ids.correccion,
    });
    expect(enLaBase.dias).toEqual([{ dia: '2026-10-11' }]);
  });

  it('nadie más puede subir a la empresa de otro', async () => {
    const lucho = await cuenta('923456789');
    const { datos } = telefonoDeLucho(lucho.usuarioId);
    await subir(lucho.llave, datos);
    const intruso = await cuenta('934567890');
    const intento = await subir(intruso.llave, {
      ...datos,
      movimientos: [],
      bitacora: [],
      arqueos: [],
    });
    expect(intento.statusCode).toBe(403);
    expect(intento.json()).toEqual({ error: 'no_es_tu_empresa' });
  });

  it('todo lo subido tiene que ser del dueño de la llave', async () => {
    const lucho = await cuenta('945678901');
    const { datos } = telefonoDeLucho(randomUUID());
    const respuesta = await subir(lucho.llave, datos);
    expect(respuesta.statusCode).toBe(400);
    expect(respuesta.json()).toEqual({ error: 'autor_distinto' });
  });

  it('rechaza valores que no son de la app sin guardar nada', async () => {
    const lucho = await cuenta('956789012');
    const { ids, datos } = telefonoDeLucho(lucho.usuarioId);
    datos.movimientos[0]!.fuente = 'whatsapp';
    const respuesta = await subir(lucho.llave, datos);
    expect(respuesta.statusCode).toBe(400);
    expect(respuesta.json().error).toBe('datos_invalidos');
    const empresas = await conEmpresa(
      base.pool,
      { empresaId: ids.empresa, usuarioId: lucho.usuarioId },
      (c) => c.query('SELECT 1 FROM empresas'),
    );
    expect(empresas.rowCount).toBe(0);
  });

  it('una empresa sin id válido no se acepta', async () => {
    const lucho = await cuenta('967890123');
    const respuesta = await subir(lucho.llave, { empresa: { id: 'no' } });
    expect(respuesta.statusCode).toBe(400);
  });
});
