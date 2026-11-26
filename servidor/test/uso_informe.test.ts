import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { comoTabla, consultasDeUso, informeDeUso } from '../src/uso/informe.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';

// El informe de uso de los pilotos (26-11-2026): todas sus consultas corren
// sobre el esquema de hoy, solo leen y no traen nombres ni celulares.
const sql = readFileSync(new URL('../consultas/uso_pilotos.sql', import.meta.url), 'utf8');

describe('Informe de uso de los pilotos', () => {
  let base: BaseDePrueba;
  beforeAll(async () => {
    base = await crearBaseDePrueba();
  });
  afterAll(() => base.cerrar());

  it('separa las consultas con su título', () => {
    const consultas = consultasDeUso(sql);
    expect(consultas).toHaveLength(11);
    expect(consultas[0]!.titulo).toContain('1. Negocios');
    expect(consultas.every((c) => /^(WITH|SELECT)/.test(c.consulta))).toBe(true);
    // Nada que escriba, y sin datos personales.
    const sinComentarios = sql.replace(/^--.*$/gm, '');
    expect(sinComentarios).not.toMatch(/\b(INSERT|UPDATE|DELETE|DROP|ALTER)\b/);
    expect(sinComentarios).not.toMatch(/celular|e\.nombre|c\.nombre|monto_centimos/);
  });

  it('corre entero sobre la base, también vacía', async () => {
    const informe = await informeDeUso(base.poolAdmin, sql);
    for (let n = 1; n <= 11; n++) expect(informe).toContain(`== ${n}. `);
    expect(informe).toContain('negocios');
  });

  it('arma una tabla que se puede copiar', () => {
    expect(comoTabla([{ fuente: 'voz', registros: 12 }])).toBe('fuente | registros\n-------+----------\nvoz    | 12       ');
    expect(comoTabla([])).toBe('(sin filas)');
  });
});
