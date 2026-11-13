import { randomUUID } from 'node:crypto';
import pg from 'pg';
import { crearPool, type Pool } from '../src/base/conexion.js';
import { migrar } from '../src/base/migrar.js';

/**
 * Conexión de administrador, solo para crear y borrar bases de prueba. En
 * GitHub la fija el flujo; en local, la de `README.md`.
 */
export const administrador =
  process.env.MOCA_BASE_ADMIN ??
  'postgres://moca_admin:moca@localhost:5432/postgres';

/** Rol normal, como el de Render: no se salta el aislamiento. */
export const rol = 'moca_prueba';
export const clave = 'moca_prueba';

export interface BaseDePrueba {
  /** Conexión con el rol normal, la que usa el servidor. */
  pool: Pool;
  /** Conexión de superusuario a la misma base (se salta el aislamiento). */
  poolAdmin: Pool;
  cerrar: () => Promise<void>;
}

/** El rol se crea una vez, antes de todas las pruebas (`preparar.ts`). */
export async function crearRol(): Promise<void> {
  const admin = new pg.Client({ connectionString: administrador });
  await admin.connect();
  await admin.query(`
    DO $$ BEGIN
      IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${rol}') THEN
        CREATE ROLE ${rol} LOGIN PASSWORD '${clave}' NOSUPERUSER NOBYPASSRLS;
      END IF;
    END $$`);
  await admin.end();
}

/** Una base nueva y migrada para un archivo de pruebas. */
export async function crearBaseDePrueba({
  migrarAntesDe,
}: { migrarAntesDe?: string } = {}): Promise<BaseDePrueba> {
  const nombre = `moca_${randomUUID().replaceAll('-', '').slice(0, 12)}`;
  const admin = new pg.Client({ connectionString: administrador });
  await admin.connect();
  await admin.query(`CREATE DATABASE ${nombre} OWNER ${rol}`);
  await admin.end();

  const direccion = new URL(administrador);
  direccion.username = rol;
  direccion.password = clave;
  direccion.pathname = `/${nombre}`;
  const pool = crearPool(direccion.toString());
  await migrar(pool, { antesDe: migrarAntesDe });

  const directa = new URL(administrador);
  directa.pathname = `/${nombre}`;
  const poolAdmin = crearPool(directa.toString());

  return {
    pool,
    poolAdmin,
    cerrar: async () => {
      await pool.end();
      await poolAdmin.end();
      const fin = new pg.Client({ connectionString: administrador });
      await fin.connect();
      await fin.query(`DROP DATABASE ${nombre} WITH (FORCE)`);
      await fin.end();
    },
  };
}

/** Una empresa con su dueño y su cuenta de efectivo, como tras el alta. */
export async function crearEmpresa(pool: Pool, nombre: string) {
  const empresaId = randomUUID();
  const usuarioId = randomUUID();
  const cuentaId = randomUUID();
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    await cliente.query(
      `SELECT set_config('app.empresa_id', $1, true),
              set_config('app.usuario_id', $2, true)`,
      [empresaId, usuarioId],
    );
    await cliente.query('INSERT INTO usuarios (id, celular) VALUES ($1, $2)', [
      usuarioId,
      `9${Math.floor(Math.random() * 1e8)}`,
    ]);
    await cliente.query(
      `INSERT INTO empresas (id, nombre, tipo_negocio, hora_cierre_minutos)
       VALUES ($1, $2, 'bodega', 1260)`,
      [empresaId, nombre],
    );
    await cliente.query(
      `INSERT INTO membresias (id, empresa_id, usuario_id, rol)
       VALUES ($1, $2, $3, 'dueno')`,
      [randomUUID(), empresaId, usuarioId],
    );
    await cliente.query(
      `INSERT INTO cuentas (id, empresa_id, tipo, nombre, orden)
       VALUES ($1, $2, 'efectivo', 'Efectivo', 0)`,
      [cuentaId, empresaId],
    );
    await cliente.query('COMMIT');
  } finally {
    cliente.release();
  }
  return { empresaId, usuarioId, cuentaId };
}
