import { randomUUID } from 'node:crypto';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { conEmpresa } from '../src/base/conexion.js';
import {
  crearBaseDePrueba,
  crearEmpresa,
  type BaseDePrueba,
} from './base_de_prueba.js';

describe('Reglas que la base hace cumplir', () => {
  let base: BaseDePrueba;
  let lucho: Awaited<ReturnType<typeof crearEmpresa>>;
  let ventaId: string;

  const insertar = (
    id: string,
    campos: Partial<{ monto: number; cuenta: string; fuente: string }> = {},
  ) => ({
    texto: `INSERT INTO movimientos (id, empresa_id, tipo, cuenta_id,
              monto_centimos, fecha_movimiento, estado_pago,
              monto_pagado_centimos, nivel_confianza, fuente, autor_id, creado_en)
            VALUES ($1, $2, 'ingreso', $3, $4, now(), 'pagado', 0, 'd', $5, $6, now())`,
    valores: [
      id,
      lucho.empresaId,
      campos.cuenta ?? lucho.cuentaId,
      campos.monto ?? 12000,
      campos.fuente ?? 'texto',
      lucho.usuarioId,
    ],
  });

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    lucho = await crearEmpresa(base.pool, 'Bodega Don Lucho');
    ventaId = randomUUID();
    await conEmpresa(base.pool, lucho, async (c) => {
      const { texto, valores } = insertar(ventaId);
      await c.query(texto, valores);
      await c.query(
        `INSERT INTO bitacora (id, empresa_id, autor_id, entidad, entidad_id,
           accion, valor_nuevo, fecha)
         VALUES ($1, $2, $3, 'movimiento', $4, 'crear', '{}', now())`,
        [randomUUID(), lucho.empresaId, lucho.usuarioId, ventaId],
      );
    });
  });
  afterAll(() => base.cerrar());

  it('nada se borra: un movimiento se anula, no se elimina', async () => {
    await expect(
      conEmpresa(base.pool, lucho, (c) =>
        c.query('DELETE FROM movimientos WHERE id = $1', [ventaId]),
      ),
    ).rejects.toThrow(/nada se borra/);
    // Ni siquiera con el rol de administrador.
    await expect(
      base.poolAdmin.query('DELETE FROM movimientos WHERE id = $1', [ventaId]),
    ).rejects.toThrow(/nada se borra/);
    await conEmpresa(base.pool, lucho, (c) =>
      c.query(`UPDATE movimientos SET estado = 'anulado' WHERE id = $1`, [ventaId]),
    );
  });

  it('la bitácora no se modifica', async () => {
    await expect(
      conEmpresa(base.pool, lucho, (c) =>
        c.query(`UPDATE bitacora SET accion = 'editar'`),
      ),
    ).rejects.toThrow(/bitácora no se modifica/);
  });

  it('subir dos veces el mismo registro no lo duplica', async () => {
    await expect(
      conEmpresa(base.pool, lucho, async (c) => {
        const { texto, valores } = insertar(ventaId);
        await c.query(texto, valores);
      }),
    ).rejects.toThrow(/duplicate key/);
  });

  it('los montos son positivos y los valores fijos, los de la app', async () => {
    for (const campos of [{ monto: 0 }, { monto: -500 }, { fuente: 'whatsapp' }]) {
      await expect(
        conEmpresa(base.pool, lucho, async (c) => {
          const { texto, valores } = insertar(randomUUID(), campos);
          await c.query(texto, valores);
        }),
      ).rejects.toThrow(/check constraint/);
    }
  });

  it('acepta las billeteras de la app y una sola cuenta por tipo', async () => {
    await conEmpresa(base.pool, lucho, (c) =>
      c.query(
        `INSERT INTO cuentas (id, empresa_id, tipo, nombre, orden)
         VALUES ($1, $2, 'plin', 'Plin', 3)`,
        [randomUUID(), lucho.empresaId],
      ),
    );
    await expect(
      conEmpresa(base.pool, lucho, (c) =>
        c.query(
          `INSERT INTO cuentas (id, empresa_id, tipo, nombre, orden)
           VALUES ($1, $2, 'plin', 'Plin', 4)`,
          [randomUUID(), lucho.empresaId],
        ),
      ),
    ).rejects.toThrow(/duplicate key/);
  });
});
