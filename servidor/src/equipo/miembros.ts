import type { Cliente } from '../base/conexion.js';

/** Los roles de un negocio (decisiones.md, 29-10-2026). */
export type Rol = 'dueno' | 'encargado' | 'ayudante' | 'contador';
export const roles: readonly Rol[] = ['dueno', 'encargado', 'ayudante', 'contador'];

/** Hasta 3 personas por negocio, con el titular; el contador no cuenta. */
export const maximoDePersonas = 3;

/** Días que vale una invitación. */
export const diasDeLaInvitacion = 7;

export interface Miembro {
  membresiaId: string;
  empresaId: string;
  rol: Rol;
  titular: boolean;
}

/**
 * La membresía activa del usuario en una empresa, o en la primera que tenga
 * (antes la propia que la de contador). Nula si no tiene o se la quitaron.
 * Usa la regla «propias» de membresías: basta con `app.usuario_id`.
 */
export async function miembroDe(
  cliente: Cliente,
  usuarioId: string,
  empresaId?: string,
): Promise<Miembro | null> {
  await cliente.query(`SELECT set_config('app.usuario_id', $1, true)`, [usuarioId]);
  const { rows } = await cliente.query<{
    id: string;
    empresa_id: string;
    rol: Rol;
    titular: boolean;
  }>(
    `SELECT id, empresa_id, rol, titular FROM membresias
      WHERE usuario_id = $1 AND quitada_en IS NULL
        AND ($2::uuid IS NULL OR empresa_id = $2::uuid)
      ORDER BY (rol = 'contador'), creado_en
      LIMIT 1`,
    [usuarioId, empresaId ?? null],
  );
  const fila = rows[0];
  return fila
    ? { membresiaId: fila.id, empresaId: fila.empresa_id, rol: fila.rol, titular: fila.titular }
    : null;
}

/** Las empresas activas del usuario. */
export async function empresasActivas(cliente: Cliente, usuarioId: string): Promise<string[]> {
  await cliente.query(`SELECT set_config('app.usuario_id', $1, true)`, [usuarioId]);
  const { rows } = await cliente.query<{ empresa_id: string }>(
    `SELECT empresa_id FROM membresias
      WHERE usuario_id = $1 AND quitada_en IS NULL
      ORDER BY (rol = 'contador'), creado_en`,
    [usuarioId],
  );
  return rows.map((f) => f.empresa_id);
}

/** Quién ve las cifras y los informes: el ayudante no. */
export const veCifras = (rol: Rol) => rol !== 'ayudante';

/**
 * Lo que cada rol puede tener en su teléfono: «lo que no puede ver no baja».
 * El ayudante recibe las cuentas (sin saldo inicial), las categorías y lo
 * que él anotó; no lo del dueño. Condición SQL sobre la tabla, con $1 = el
 * usuario. Nula: todo.
 */
export function soloLoVisible(tabla: string, rol: Rol): string | null {
  if (rol !== 'ayudante') return null;
  switch (tabla) {
    case 'movimientos':
    case 'bitacora':
      return 'autor_id = $1';
    case 'comprobantes':
      return 'id IN (SELECT comprobante_id FROM movimientos WHERE autor_id = $1)';
    case 'items_comprobante':
      return 'comprobante_id IN (SELECT comprobante_id FROM movimientos WHERE autor_id = $1)';
    case 'arqueos':
    case 'arqueo_cuentas':
    case 'alertas':
    case 'videos_vistos':
      return 'false';
    default:
      return null;
  }
}

/** Columnas que el ayudante recibe vacías. */
export function columnaParaRol(tabla: string, columna: string, rol: Rol): string {
  if (rol === 'ayudante' && tabla === 'cuentas' && columna === 'saldo_inicial_centimos') {
    return 'NULL::bigint AS saldo_inicial_centimos';
  }
  return columna;
}
