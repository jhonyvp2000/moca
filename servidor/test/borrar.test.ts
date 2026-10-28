import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import { conEmpresa } from '../src/base/conexion.js';
import { crearBaseDePrueba, crearEmpresa, type BaseDePrueba } from './base_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';

describe('Borrar todo, también en el servidor (entrega 14.8)', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;
  const usuarioId = randomUUID();
  const empresa = randomUUID();
  const efectivo = randomUUID();
  const venta = randomUUID();
  let llave: string;

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
      { id: randomUUID(), video: 2, desde: 'pasos', fecha: '2026-10-12T02:05:00.000Z' },
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

  const borrar = (conLlave: string, confirmacion: unknown = 'BORRAR') =>
    app.inject({
      method: 'POST',
      url: '/cuenta/borrar-datos',
      headers: { authorization: `Bearer ${conLlave}` },
      payload: { confirmacion },
    });

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    app = crearApp({ pool: base.pool, version: 'prueba', verificador: verificadorFalso() });
    const guardar = await app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular: '913131313', codigo: '123456', usuarioId },
    });
    llave = guardar.json().llave;
    const subida = await app.inject({
      method: 'POST',
      url: '/datos/subir',
      headers: { authorization: `Bearer ${llave}` },
      payload: datos(),
    });
    expect(subida.statusCode, subida.body).toBe(200);
    await base.pool.query(
      `INSERT INTO lecturas (usuario_id, resultado, milisegundos) VALUES ($1, 'leido', 900)`,
      [usuarioId],
    );
    await base.pool.query(
      `INSERT INTO lecturas (prueba_de, resultado, milisegundos) VALUES ($1, 'leido', 900)`,
      [usuarioId],
    );
  });
  afterAll(() => base.cerrar());

  it('sin escribir BORRAR no se borra nada', async () => {
    expect((await borrar(llave, 'borrar')).json()).toEqual({ error: 'sin_confirmacion' });
    expect((await borrar('otra-llave')).statusCode).toBe(401);
    const { rows } = await base.pool.query('SELECT 1 FROM borrados');
    expect(rows).toHaveLength(0);
  });

  it('un DELETE suelto sigue prohibido', async () => {
    const otra = await crearEmpresa(base.pool, 'Bodega Otra');
    await expect(
      conEmpresa(base.pool, otra, (c) =>
        c.query('DELETE FROM cuentas WHERE id = $1', [otra.cuentaId]),
      ),
    ).rejects.toThrow(/nada se borra/);
  });

  it('borra el negocio y sus fotos; el número queda sin datos', async () => {
    const otra = await crearEmpresa(base.pool, 'Bodega Vecina');
    const respuesta = await borrar(llave);
    expect(respuesta.statusCode, respuesta.body).toBe(200);
    expect(respuesta.json()).toEqual({ borradas: 1 });

    for (const tabla of ['empresas', 'cuentas', 'movimientos', 'bitacora', 'videos_vistos']) {
      const columna = tabla === 'empresas' ? 'id' : 'empresa_id';
      const { rows } = await base.pool.query(
        `SELECT 1 FROM ${tabla} WHERE ${columna} = $1`,
        [empresa],
      );
      expect(rows, tabla).toHaveLength(0);
    }
    const lecturas = await base.pool.query(
      'SELECT 1 FROM lecturas WHERE usuario_id = $1 OR prueba_de = $1',
      [usuarioId],
    );
    expect(lecturas.rows).toHaveLength(0);
    const cliente = await base.pool.connect();
    try {
      await cliente.query('BEGIN');
      await cliente.query(`SELECT set_config('app.usuario_id', $1, true)`, [usuarioId]);
      const usuario = await cliente.query('SELECT celular FROM usuarios WHERE id = $1', [
        usuarioId,
      ]);
      expect(usuario.rows).toEqual([{ celular: '+51913131313' }]);
    } finally {
      await cliente.query('ROLLBACK');
      cliente.release();
    }
    const borrados = await base.pool.query('SELECT usuario_id, empresa_id FROM borrados');
    expect(borrados.rows).toEqual([{ usuario_id: usuarioId, empresa_id: empresa }]);

    // Lo de otro negocio no se toca.
    const ajena = await conEmpresa(base.pool, otra, (c) =>
      c.query('SELECT 1 FROM cuentas WHERE id = $1', [otra.cuentaId]),
    );
    expect(ajena.rows).toHaveLength(1);

    // La llave ya no sirve, y «Ya tengo cuenta» no encuentra datos.
    expect((await borrar(llave)).statusCode).toBe(401);
    const entrar = await app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular: '913131313', codigo: '123456', modo: 'entrar' },
    });
    expect(entrar.statusCode).toBe(404);
    expect(entrar.json()).toEqual({ error: 'sin_cuenta' });
  });
});
