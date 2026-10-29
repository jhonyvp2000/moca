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
  /** Las cajas a su cargo, como se guardaron (entrega 21). */
  cajas: string[];
}

/** Los tipos de cuenta que son cajas de efectivo (entrega 21). */
export const tiposDeCaja = ['efectivo', 'caja2', 'caja3'];

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
    cajas: string[];
  }>(
    `SELECT id, empresa_id, rol, titular, cajas FROM membresias
      WHERE usuario_id = $1 AND quitada_en IS NULL
        AND ($2::uuid IS NULL OR empresa_id = $2::uuid)
      ORDER BY (rol = 'contador'), creado_en
      LIMIT 1`,
    [usuarioId, empresaId ?? null],
  );
  const fila = rows[0];
  return fila
    ? {
        membresiaId: fila.id,
        empresaId: fila.empresa_id,
        rol: fila.rol,
        titular: fila.titular,
        cajas: fila.cajas ?? [],
      }
    : null;
}

/**
 * Las cajas que cuentan para el miembro, con la empresa en curso: nulo para
 * dueños y contador (todas); para los demás, las suyas o, si no tiene
 * ninguna, la principal.
 */
export async function cajasDe(cliente: Cliente, miembro: Miembro): Promise<string[] | null> {
  if (miembro.rol === 'dueno' || miembro.rol === 'contador') return null;
  if (miembro.cajas.length) return miembro.cajas;
  const { rows } = await cliente.query<{ id: string }>(
    `SELECT id FROM cuentas WHERE tipo = 'efectivo'`,
  );
  return rows.map((f) => f.id);
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

/**
 * Quién recibe las cifras del negocio: dueños y contador. El encargado y el
 * ayudante ven solo sus cajas, y el teléfono las calcula con lo que le llega
 * (entrega 21).
 */
export const veCifras = (rol: Rol) => rol === 'dueno' || rol === 'contador';

/** Lo que es de las cajas del miembro ($3), o lo que anotó él ($1). */
const deSusCajas =
  '(autor_id = $1 OR cuenta_id = ANY($3::uuid[]) OR cuenta_destino_id = ANY($3::uuid[]))';

/**
 * Lo que cada rol puede tener en su teléfono: «lo que no puede ver no baja».
 * El encargado y el ayudante reciben las cuentas (con saldo inicial solo el
 * de sus cajas), las categorías, lo que anotaron y todo lo de sus cajas; el
 * encargado, además, los arqueos de sus cajas. Condición SQL sobre la
 * tabla, con $1 = el usuario y $3 = sus cajas. Nula: todo.
 */
export function soloLoVisible(tabla: string, rol: Rol): string | null {
  if (rol !== 'ayudante' && rol !== 'encargado') return null;
  switch (tabla) {
    case 'movimientos':
      return deSusCajas;
    case 'bitacora':
      return 'autor_id = $1';
    case 'comprobantes':
      return `id IN (SELECT comprobante_id FROM movimientos WHERE ${deSusCajas})`;
    case 'items_comprobante':
      return `comprobante_id IN (SELECT comprobante_id FROM movimientos WHERE ${deSusCajas})`;
    case 'arqueos':
      return rol === 'encargado'
        ? 'id IN (SELECT arqueo_id FROM arqueo_cuentas WHERE cuenta_id = ANY($3::uuid[]))'
        : 'false';
    case 'arqueo_cuentas':
      return rol === 'encargado' ? 'cuenta_id = ANY($3::uuid[])' : 'false';
    case 'alertas':
    case 'videos_vistos':
      return 'false';
    default:
      return null;
  }
}

/** Columnas que el encargado y el ayudante reciben vacías. */
export function columnaParaRol(tabla: string, columna: string, rol: Rol): string {
  if (
    (rol === 'ayudante' || rol === 'encargado') &&
    tabla === 'cuentas' &&
    columna === 'saldo_inicial_centimos'
  ) {
    return 'CASE WHEN id = ANY($3::uuid[]) THEN saldo_inicial_centimos END AS saldo_inicial_centimos';
  }
  return columna;
}
