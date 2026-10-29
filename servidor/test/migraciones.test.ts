import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { migrar } from '../src/base/migrar.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';

const tablasDeNegocio = [
  'usuarios', 'empresas', 'membresias', 'cuentas', 'categorias',
  'contrapartes', 'comprobantes', 'items_comprobante', 'movimientos',
  'arqueos', 'arqueo_cuentas', 'alertas', 'dias_cerrados', 'periodos',
  'reglas_clasificacion', 'bitacora', 'videos_vistos', 'invitaciones',
];

describe('Migraciones', () => {
  let base: BaseDePrueba;
  beforeAll(async () => {
    base = await crearBaseDePrueba();
  });
  afterAll(() => base.cerrar());

  it('crea todas las tablas del modelo de datos', async () => {
    const { rows } = await base.pool.query<{ tablename: string }>(
      `SELECT tablename FROM pg_tables WHERE schemaname = 'public'`,
    );
    const tablas = rows.map((f) => f.tablename);
    for (const tabla of tablasDeNegocio) expect(tablas).toContain(tabla);
  });

  it('aplicarlas otra vez no hace nada', async () => {
    expect(await migrar(base.pool)).toEqual([]);
  });

  it('todas las tablas de negocio tienen el aislamiento activo y forzado', async () => {
    const { rows } = await base.pool.query<{
      relname: string;
      relrowsecurity: boolean;
      relforcerowsecurity: boolean;
    }>(
      `SELECT relname, relrowsecurity, relforcerowsecurity
         FROM pg_class WHERE relname = ANY($1)`,
      [tablasDeNegocio],
    );
    expect(rows).toHaveLength(tablasDeNegocio.length);
    for (const fila of rows) {
      expect(fila, fila.relname).toMatchObject({
        relrowsecurity: true,
        relforcerowsecurity: true,
      });
    }
  });
});

describe('Migraciones sobre datos de antes', () => {
  let base: BaseDePrueba;
  beforeAll(async () => {
    base = await crearBaseDePrueba({ migrarAntesDe: '011' });
  });
  afterAll(() => base.cerrar());

  it('la 011 (equipo) se aplica a un negocio que ya tiene datos', async () => {
    // Un negocio como el de un piloto, cargado antes de la entrega 17. En
    // Render, con datos, la 011 fallaba por las referencias diferidas.
    const u = '00000000-0000-4000-8000-000000000001';
    const e = '00000000-0000-4000-8000-000000000002';
    const cu = '00000000-0000-4000-8000-000000000003';
    const ca = '00000000-0000-4000-8000-000000000004';
    const m = '00000000-0000-4000-8000-000000000005';
    const admin = base.poolAdmin;
    await admin.query(`INSERT INTO usuarios (id, celular) VALUES ($1, '+51987654321')`, [u]);
    await admin.query(
      `INSERT INTO empresas (id, nombre, tipo_negocio, hora_cierre_minutos)
       VALUES ($1, 'Bodega', 'bodega', 1260)`,
      [e],
    );
    await admin.query(
      `INSERT INTO membresias (id, empresa_id, usuario_id, rol)
       VALUES (gen_random_uuid(), $1, $2, 'dueno')`,
      [e, u],
    );
    await admin.query(
      `INSERT INTO cuentas (id, empresa_id, tipo, nombre, orden)
       VALUES ($1, $2, 'efectivo', 'Efectivo', 0)`,
      [cu, e],
    );
    await admin.query(
      `INSERT INTO categorias (id, empresa_id, nombre, tipo_movimiento, orden)
       VALUES ($1, $2, 'Venta del día', 'ingreso', 0)`,
      [ca, e],
    );
    await admin.query(
      `INSERT INTO movimientos (id, empresa_id, tipo, cuenta_id, monto_centimos,
         fecha_movimiento, estado_pago, monto_pagado_centimos, categoria_id,
         nivel_confianza, fuente, autor_id, estado, creado_en)
       VALUES ($1, $2, 'ingreso', $3, 35000, now(), 'pagado', 35000, $4, 'd',
         'voz', $5, 'vigente', now())`,
      [m, e, cu, ca, u],
    );
    await admin.query(
      `INSERT INTO bitacora (id, empresa_id, autor_id, entidad, entidad_id, accion, fecha)
       VALUES (gen_random_uuid(), $1, $2, 'movimiento', $3, 'crear', now())`,
      [e, u, m],
    );

    const aplicadas = await migrar(base.pool);
    expect(aplicadas).toContain('011_equipo.sql');
    const { rows } = await admin.query<{ titular: boolean }>(
      'SELECT titular FROM membresias',
    );
    expect(rows).toEqual([{ titular: true }]);
    const cambios = await admin.query<{ cambio: number }>(
      'SELECT cambio FROM movimientos',
    );
    expect(cambios.rows[0]!.cambio).toBeGreaterThan(0);
  });
});
