import pg from 'pg';

export type Pool = pg.Pool;
export type Cliente = pg.PoolClient;

export function crearPool(direccion: string): Pool {
  return new pg.Pool({ connectionString: direccion, max: 10 });
}

/**
 * Corre `trabajo` en una transacción que ve solo la empresa indicada. El
 * aislamiento lo aplica la base (RLS): fuera de esta función, las tablas de
 * negocio no devuelven nada.
 */
export async function conEmpresa<T>(
  pool: Pool,
  sesion: { empresaId: string; usuarioId: string },
  trabajo: (cliente: Cliente) => Promise<T>,
): Promise<T> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    await cliente.query(
      `SELECT set_config('app.empresa_id', $1, true),
              set_config('app.usuario_id', $2, true)`,
      [sesion.empresaId, sesion.usuarioId],
    );
    const resultado = await trabajo(cliente);
    await cliente.query('COMMIT');
    return resultado;
  } catch (error) {
    await cliente.query('ROLLBACK');
    throw error;
  } finally {
    cliente.release();
  }
}

/**
 * Si el rol de la conexión se salta el aislamiento (superusuario o
 * BYPASSRLS), las reglas por empresa no se aplican: el servidor no debe
 * arrancar así.
 */
export async function aislamientoActivo(pool: Pool): Promise<boolean> {
  const { rows } = await pool.query<{ salta: boolean }>(
    `SELECT rolsuper OR rolbypassrls AS salta
       FROM pg_roles WHERE rolname = current_user`,
  );
  return rows[0]?.salta === false;
}
