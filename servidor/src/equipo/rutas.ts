import type { FastifyInstance, FastifyReply } from 'fastify';
import type { Cliente, Pool } from '../base/conexion.js';
import { aInternacional, esCelularPeru } from '../cuenta/celular.js';
import { empresaPedida } from '../datos/bajar.js';
import { autenticar } from '../datos/subir.js';
import {
  tiposDeCaja,
  diasDeLaInvitacion,
  maximoDePersonas,
  miembroDe,
  roles,
  type Miembro,
  type Rol,
} from './miembros.js';

const esUuid = (v: unknown): v is string =>
  typeof v === 'string' &&
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);

/** Una invitación que todavía vale. */
const vigente = `aceptada_en IS NULL AND anulada_en IS NULL
  AND creada_en > now() - make_interval(days => ${diasDeLaInvitacion})`;

class ErrorDeEquipo extends Error {
  constructor(
    readonly codigo: number,
    readonly clave: string,
  ) {
    super(clave);
  }
}

/** Las personas que cuentan para el límite: sin el contador. */
async function ocupados(cliente: Cliente): Promise<number> {
  const { rows } = await cliente.query<{ n: number }>(
    `SELECT (SELECT count(*) FROM membresias
              WHERE quitada_en IS NULL AND rol <> 'contador')
          + (SELECT count(*) FROM invitaciones
              WHERE ${vigente} AND rol <> 'contador') AS n`,
  );
  return Number(rows[0]?.n ?? 0);
}

/** Corre [trabajo] como miembro activo de la empresa; [soloDueno] lo exige. */
async function comoMiembro<T>(
  pool: Pool,
  usuarioId: string,
  empresaId: string | undefined,
  soloDueno: boolean,
  trabajo: (cliente: Cliente, miembro: Miembro) => Promise<T>,
): Promise<T> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    const miembro = await miembroDe(cliente, usuarioId, empresaId);
    if (!miembro) throw new ErrorDeEquipo(403, 'sin_negocio');
    if (soloDueno && miembro.rol !== 'dueno') throw new ErrorDeEquipo(403, 'sin_permiso');
    await cliente.query(`SELECT set_config('app.empresa_id', $1, true)`, [miembro.empresaId]);
    const resultado = await trabajo(cliente, miembro);
    await cliente.query('COMMIT');
    return resultado;
  } catch (error) {
    await cliente.query('ROLLBACK');
    throw error;
  } finally {
    cliente.release();
  }
}

function responderError(error: unknown, respuesta: FastifyReply) {
  if (error instanceof ErrorDeEquipo) {
    return respuesta.code(error.codigo).send({ error: error.clave });
  }
  throw error;
}

/**
 * El equipo de un negocio (entrega 17): quiénes están, con su rol, y las
 * invitaciones pendientes. Solo un dueño invita, anula y quita. Quitar no
 * borra nada: lo que la persona anotó se queda.
 */
export function rutasEquipo(app: FastifyInstance, pool: Pool): void {
  app.get('/equipo', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    try {
      return await comoMiembro(
        pool,
        usuarioId,
        empresaPedida(peticion.query),
        false,
        async (cliente, miembro) => {
          const esDueno = miembro.rol === 'dueno';
          const personas = await cliente.query(
            `SELECT m.id AS membresia_id, m.usuario_id, m.nombre, m.rol, m.titular, m.cajas,
                    ${esDueno ? 'u.celular' : 'NULL AS celular'}
               FROM membresias m JOIN usuarios u ON u.id = m.usuario_id
              WHERE m.quitada_en IS NULL
              ORDER BY m.titular DESC, m.creado_en`,
          );
          const invitaciones = esDueno
            ? (
                await cliente.query(
                  `SELECT id, celular, rol, nombre, creada_en,
                          creada_en + make_interval(days => ${diasDeLaInvitacion}) AS vence_en
                     FROM invitaciones WHERE ${vigente} ORDER BY creada_en`,
                )
              ).rows
            : [];
          return {
            empresa_id: miembro.empresaId,
            rol: miembro.rol,
            titular: miembro.titular,
            maximo: maximoDePersonas,
            personas: personas.rows,
            invitaciones,
          };
        },
      );
    } catch (error) {
      return responderError(error, respuesta);
    }
  });

  app.post<{ Body: { celular?: unknown; rol?: unknown; nombre?: unknown } }>(
    '/equipo/invitar',
    async (peticion, respuesta) => {
      const usuarioId = await autenticar(pool, peticion);
      if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
      const celular = String(peticion.body?.celular ?? '');
      const rol = peticion.body?.rol as Rol;
      const nombre = String(peticion.body?.nombre ?? '').trim().slice(0, 40) || null;
      if (!esCelularPeru(celular) || !roles.includes(rol)) {
        return respuesta.code(400).send({ error: 'datos_invalidos' });
      }
      const internacional = aInternacional(celular);
      try {
        return await comoMiembro(
          pool,
          usuarioId,
          empresaPedida(peticion.query),
          true,
          async (cliente, miembro) => {
            const yaEsta = await cliente.query(
              `SELECT 1 FROM membresias m JOIN usuarios u ON u.id = m.usuario_id
                WHERE m.quitada_en IS NULL AND u.celular = $1`,
              [internacional],
            );
            if (yaEsta.rowCount) throw new ErrorDeEquipo(409, 'ya_esta');
            // Invitar otra vez al mismo número reemplaza la anterior.
            await cliente.query(
              `UPDATE invitaciones SET anulada_en = now() WHERE ${vigente} AND celular = $1`,
              [internacional],
            );
            if (rol !== 'contador' && (await ocupados(cliente)) >= maximoDePersonas) {
              throw new ErrorDeEquipo(409, 'sin_lugar');
            }
            const { rows } = await cliente.query(
              `INSERT INTO invitaciones (empresa_id, celular, rol, nombre, invitada_por)
               VALUES ($1, $2, $3, $4, $5)
               RETURNING id, celular, rol, nombre, creada_en,
                         creada_en + make_interval(days => ${diasDeLaInvitacion}) AS vence_en`,
              [miembro.empresaId, internacional, rol, nombre, usuarioId],
            );
            return rows[0];
          },
        );
      } catch (error) {
        return responderError(error, respuesta);
      }
    },
  );

  app.post<{ Body: { invitacion?: unknown } }>('/equipo/anular', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    const invitacion = peticion.body?.invitacion;
    if (!esUuid(invitacion)) return respuesta.code(400).send({ error: 'datos_invalidos' });
    try {
      return await comoMiembro(
        pool,
        usuarioId,
        empresaPedida(peticion.query),
        true,
        async (cliente) => {
          const { rowCount } = await cliente.query(
            `UPDATE invitaciones SET anulada_en = now() WHERE id = $1 AND ${vigente}`,
            [invitacion],
          );
          if (!rowCount) throw new ErrorDeEquipo(404, 'sin_invitacion');
          return { anulada: true };
        },
      );
    } catch (error) {
      return responderError(error, respuesta);
    }
  });

  app.post<{ Body: { membresia?: unknown } }>('/equipo/quitar', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    const membresia = peticion.body?.membresia;
    if (!esUuid(membresia)) return respuesta.code(400).send({ error: 'datos_invalidos' });
    try {
      return await comoMiembro(
        pool,
        usuarioId,
        empresaPedida(peticion.query),
        true,
        async (cliente, miembro) => {
          // Al titular nadie lo quita, y uno no se quita a sí mismo aquí.
          const { rowCount } = await cliente.query(
            `UPDATE membresias SET quitada_en = now()
              WHERE id = $1 AND quitada_en IS NULL AND NOT titular AND id <> $2`,
            [membresia, miembro.membresiaId],
          );
          if (!rowCount) throw new ErrorDeEquipo(404, 'sin_persona');
          return { quitada: true };
        },
      );
    } catch (error) {
      return responderError(error, respuesta);
    }
  });

  // Las cajas a cargo de una persona (entrega 21): solo cajas de efectivo
  // del negocio. Vacío: la principal.
  app.post<{ Body: { membresia?: unknown; cajas?: unknown } }>(
    '/equipo/cajas',
    async (peticion, respuesta) => {
      const usuarioId = await autenticar(pool, peticion);
      if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
      const membresia = peticion.body?.membresia;
      const cajas = peticion.body?.cajas;
      if (!esUuid(membresia) || !Array.isArray(cajas) || !cajas.every(esUuid)) {
        return respuesta.code(400).send({ error: 'datos_invalidos' });
      }
      try {
        return await comoMiembro(
          pool,
          usuarioId,
          empresaPedida(peticion.query),
          true,
          async (cliente) => {
            const validas = await cliente.query(
              'SELECT 1 FROM cuentas WHERE id = ANY($1) AND tipo = ANY($2)',
              [cajas, tiposDeCaja],
            );
            if (validas.rowCount !== new Set(cajas).size) {
              throw new ErrorDeEquipo(400, 'datos_invalidos');
            }
            const { rowCount } = await cliente.query(
              `UPDATE membresias SET cajas = $2
                WHERE id = $1 AND quitada_en IS NULL`,
              [membresia, [...new Set(cajas)]],
            );
            if (!rowCount) throw new ErrorDeEquipo(404, 'sin_persona');
            return { cajas: [...new Set(cajas)] };
          },
        );
      } catch (error) {
        return responderError(error, respuesta);
      }
    },
  );

  // Las invitaciones que esperan a quien entró con su celular.
  app.get('/cuenta/invitaciones', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    return { invitaciones: await invitacionesPara(pool, usuarioId) };
  });

  app.post<{ Body: { invitacion?: unknown; consentimiento?: unknown } }>(
    '/cuenta/aceptar',
    async (peticion, respuesta) => {
      const usuarioId = await autenticar(pool, peticion);
      if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
      const invitacion = peticion.body?.invitacion;
      // Sin aceptar el uso de sus datos (Ley 29733), no entra.
      if (!esUuid(invitacion) || peticion.body?.consentimiento !== true) {
        return respuesta.code(400).send({ error: 'datos_invalidos' });
      }
      try {
        return await aceptar(pool, usuarioId, invitacion);
      } catch (error) {
        return responderError(error, respuesta);
      }
    },
  );
}

/** El celular de la cuenta, para buscar sus invitaciones. */
async function celularDe(cliente: Cliente, usuarioId: string): Promise<string | null> {
  await cliente.query(`SELECT set_config('app.usuario_id', $1, true)`, [usuarioId]);
  const { rows } = await cliente.query<{ celular: string | null }>(
    'SELECT celular FROM usuarios WHERE id = $1',
    [usuarioId],
  );
  return rows[0]?.celular ?? null;
}

/** Las invitaciones vigentes para el celular del usuario, con su negocio. */
export async function invitacionesPara(
  pool: Pool,
  usuarioId: string,
): Promise<Record<string, unknown>[]> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    const celular = await celularDe(cliente, usuarioId);
    if (!celular) {
      await cliente.query('COMMIT');
      return [];
    }
    await cliente.query(`SELECT set_config('app.celular', $1, true)`, [celular]);
    const { rows } = await cliente.query<{
      id: string;
      empresa_id: string;
      rol: Rol;
      nombre: string | null;
      vence_en: Date;
    }>(
      `SELECT id, empresa_id, rol, nombre,
              creada_en + make_interval(days => ${diasDeLaInvitacion}) AS vence_en
         FROM invitaciones WHERE ${vigente} AND celular = $1 ORDER BY creada_en`,
      [celular],
    );
    const resultado: Record<string, unknown>[] = [];
    for (const fila of rows) {
      await cliente.query(`SELECT set_config('app.empresa_id', $1, true)`, [fila.empresa_id]);
      const empresa = await cliente.query<{ nombre: string }>('SELECT nombre FROM empresas');
      resultado.push({ ...fila, negocio: empresa.rows[0]?.nombre ?? '' });
    }
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
 * Acepta la invitación: entra al negocio con su rol. Una persona está en un
 * solo negocio, salvo el contador, que puede estar en varios.
 */
async function aceptar(
  pool: Pool,
  usuarioId: string,
  invitacionId: string,
): Promise<{ empresa_id: string; rol: Rol }> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    const celular = await celularDe(cliente, usuarioId);
    await cliente.query(`SELECT set_config('app.celular', $1, true)`, [celular ?? '']);
    const { rows } = await cliente.query<{ empresa_id: string; rol: Rol; nombre: string | null }>(
      `SELECT empresa_id, rol, nombre FROM invitaciones
        WHERE id = $1 AND celular = $2 AND ${vigente}`,
      [invitacionId, celular],
    );
    const invitacion = rows[0];
    if (!invitacion) throw new ErrorDeEquipo(410, 'invitacion_vencida');

    const propias = await cliente.query<{ empresa_id: string; rol: Rol }>(
      'SELECT empresa_id, rol FROM membresias WHERE usuario_id = $1 AND quitada_en IS NULL',
      [usuarioId],
    );
    if (propias.rows.some((m) => m.empresa_id === invitacion.empresa_id)) {
      throw new ErrorDeEquipo(409, 'ya_esta');
    }
    if (invitacion.rol !== 'contador' && propias.rows.some((m) => m.rol !== 'contador')) {
      throw new ErrorDeEquipo(409, 'ya_tiene_negocio');
    }

    await cliente.query(`SELECT set_config('app.empresa_id', $1, true)`, [
      invitacion.empresa_id,
    ]);
    await cliente.query(
      `UPDATE invitaciones SET aceptada_en = now() WHERE id = $1`,
      [invitacionId],
    );
    // Ya aceptada, ella misma no cuenta en el límite: solo las personas.
    if (invitacion.rol !== 'contador' && (await ocupados(cliente)) >= maximoDePersonas) {
      throw new ErrorDeEquipo(409, 'sin_lugar');
    }
    await cliente.query(
      `INSERT INTO membresias (id, empresa_id, usuario_id, rol, nombre, consentimiento_en)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, now())`,
      [invitacion.empresa_id, usuarioId, invitacion.rol, invitacion.nombre],
    );
    await cliente.query('COMMIT');
    return { empresa_id: invitacion.empresa_id, rol: invitacion.rol };
  } catch (error) {
    await cliente.query('ROLLBACK');
    throw error;
  } finally {
    cliente.release();
  }
}

