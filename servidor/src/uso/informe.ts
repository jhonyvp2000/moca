import { readFileSync } from 'node:fs';
import pg from 'pg';

// El uso real de los pilotos (26-11-2026), para decidir con datos. Corre las
// consultas de `consultas/uso_pilotos.sql`, que solo leen y no muestran
// nombres, celulares ni montos. En el Shell de Render:   npm run uso-pilotos

/** Las consultas del archivo, cada una con su título («\echo '== … =='»). */
export function consultasDeUso(sql: string): { titulo: string; consulta: string }[] {
  const partes: { titulo: string; consulta: string }[] = [];
  let titulo: string | null = null;
  let lineas: string[] = [];
  const cerrar = () => {
    const consulta = lineas.join('\n').trim().replace(/;\s*$/, '');
    if (titulo && consulta) partes.push({ titulo, consulta });
    lineas = [];
  };
  for (const linea of sql.split('\n')) {
    const eco = /^\\echo '(.*)'\s*$/.exec(linea);
    if (eco) {
      cerrar();
      titulo = eco[1]!;
    } else if (/^\s*ROLLBACK;/.test(linea)) {
      cerrar();
      titulo = null;
    } else if (titulo) {
      lineas.push(linea);
    }
  }
  cerrar();
  return partes;
}

/** Una tabla de texto, para copiarla tal cual. */
export function comoTabla(filas: Record<string, unknown>[]): string {
  if (!filas.length) return '(sin filas)';
  const columnas = Object.keys(filas[0]!);
  const texto = (v: unknown) => (v == null ? '—' : v instanceof Date ? v.toISOString().slice(0, 10) : String(v));
  const anchos = columnas.map((c) => Math.max(c.length, ...filas.map((f) => texto(f[c]).length)));
  const fila = (valores: string[]) => valores.map((v, i) => v.padEnd(anchos[i]!)).join(' | ');
  return [fila(columnas), anchos.map((a) => '-'.repeat(a)).join('-+-'), ...filas.map((f) => fila(columnas.map((c) => texto(f[c]))))].join('\n');
}

export async function informeDeUso(pool: pg.Pool, sql: string): Promise<string> {
  const cliente = await pool.connect();
  const salida: string[] = [];
  try {
    // Solo lectura, y como administrador para ver todos los negocios.
    await cliente.query('BEGIN READ ONLY');
    await cliente.query("SET LOCAL app.admin = 'si'");
    for (const { titulo, consulta } of consultasDeUso(sql)) {
      const { rows } = await cliente.query(consulta);
      salida.push(titulo, comoTabla(rows), '');
    }
  } finally {
    await cliente.query('ROLLBACK');
    cliente.release();
  }
  return salida.join('\n');
}

// Solo al correrlo como programa, no al importarlo en las pruebas.
if (process.argv[1]?.endsWith('informe.js')) {
  const url = process.env.DATABASE_URL;
  if (!url) {
    console.error('Falta DATABASE_URL.');
    process.exit(1);
  }
  const pool = new pg.Pool({ connectionString: url });
  const sql = readFileSync(new URL('../../consultas/uso_pilotos.sql', import.meta.url), 'utf8');
  console.log(await informeDeUso(pool, sql));
  await pool.end();
}
