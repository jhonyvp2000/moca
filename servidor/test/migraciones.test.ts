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
