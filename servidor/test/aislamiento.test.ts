import { randomUUID } from 'node:crypto';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { conEmpresa } from '../src/base/conexion.js';
import {
  crearBaseDePrueba,
  crearEmpresa,
  type BaseDePrueba,
} from './base_de_prueba.js';

describe('Aislamiento por empresa', () => {
  let base: BaseDePrueba;
  let lucho: Awaited<ReturnType<typeof crearEmpresa>>;
  let rosa: Awaited<ReturnType<typeof crearEmpresa>>;

  const venta = (e: typeof lucho, monto = 35000) => ({
    texto: `INSERT INTO movimientos (id, empresa_id, tipo, cuenta_id,
              monto_centimos, fecha_movimiento, estado_pago,
              monto_pagado_centimos, nivel_confianza, fuente, autor_id, creado_en)
            VALUES ($1, $2, 'ingreso', $3, $4, now(), 'pagado', $4, 'd', 'voz',
              $5, now())`,
    valores: [randomUUID(), e.empresaId, e.cuentaId, monto, e.usuarioId],
  });

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    lucho = await crearEmpresa(base.pool, 'Bodega Don Lucho');
    rosa = await crearEmpresa(base.pool, 'Restaurante Doña Rosa');
    for (const e of [lucho, rosa]) {
      await conEmpresa(base.pool, e, async (c) => {
        const { texto, valores } = venta(e);
        await c.query(texto, valores);
      });
    }
  });
  afterAll(() => base.cerrar());

  it('cada empresa ve solo lo suyo', async () => {
    const deLucho = await conEmpresa(base.pool, lucho, async (c) => ({
      empresas: (await c.query('SELECT nombre FROM empresas')).rows,
      cuentas: (await c.query('SELECT empresa_id FROM cuentas')).rows,
      movimientos: (await c.query('SELECT empresa_id FROM movimientos')).rows,
      usuarios: (await c.query('SELECT id FROM usuarios')).rows,
    }));
    expect(deLucho.empresas).toEqual([{ nombre: 'Bodega Don Lucho' }]);
    expect(deLucho.cuentas).toEqual([{ empresa_id: lucho.empresaId }]);
    expect(deLucho.movimientos).toEqual([{ empresa_id: lucho.empresaId }]);
    expect(deLucho.usuarios).toEqual([{ id: lucho.usuarioId }]);
  });

  it('sin empresa fijada no se ve nada', async () => {
    const { rows } = await base.pool.query('SELECT * FROM movimientos');
    expect(rows).toEqual([]);
    const empresas = await base.pool.query('SELECT * FROM empresas');
    expect(empresas.rows).toEqual([]);
  });

  it('no se puede guardar a nombre de otra empresa', async () => {
    await expect(
      conEmpresa(base.pool, lucho, async (c) => {
        const { texto, valores } = venta(rosa);
        await c.query(texto, valores);
      }),
    ).rejects.toThrow(/row-level security/);
  });

  it('no se puede usar la cuenta de otra empresa', async () => {
    await expect(
      conEmpresa(base.pool, lucho, async (c) => {
        const { texto, valores } = venta({ ...lucho, cuentaId: rosa.cuentaId });
        await c.query(texto, valores);
      }),
    ).rejects.toThrow(/foreign key/);
  });

  it('no se puede cambiar un registro de otra empresa', async () => {
    const cambiadas = await conEmpresa(base.pool, lucho, async (c) =>
      (await c.query(`UPDATE movimientos SET nota = 'x' WHERE empresa_id = $1`, [
        rosa.empresaId,
      ])).rowCount,
    );
    expect(cambiadas).toBe(0);
  });
});
