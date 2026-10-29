import { createHash, randomBytes } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import type { Pool } from '../base/conexion.js';
import { aInternacional, esCelularPeru } from './celular.js';
import { crearSesion } from './sesiones.js';
import { diasDeLaInvitacion } from '../equipo/miembros.js';
import { invitacionesPara } from '../equipo/rutas.js';
import type { Verificador } from './verificador.js';

/** Límites de códigos enviados en una hora. */
export const limites = { porCelular: 5, porConexion: 20 };

const esUuid = (v: string) =>
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);

/** La marca de una app Android para SMS Retriever: 11 caracteres de base64. */
const marcaValida = /^[A-Za-z0-9+/]{11}$/;

/**
 * La cuenta del dueño: pedir el código por SMS y verificarlo. Sin
 * verificador configurado no se da ninguna cuenta: nunca hay un «código de
 * prueba» que abra cualquier cuenta.
 */
export function rutasCuenta(
  app: FastifyInstance,
  pool: Pool,
  verificador: Verificador | null,
): void {
  app.post<{ Body: { celular?: unknown; marcaApp?: unknown } }>('/cuenta/codigo', async (peticion, respuesta) => {
    if (!verificador) return respuesta.code(503).send({ error: 'sin_verificador' });
    const celular = String(peticion.body?.celular ?? '');
    if (!esCelularPeru(celular)) {
      return respuesta.code(400).send({ error: 'celular_invalido' });
    }
    const internacional = aInternacional(celular);
    const { rows } = await pool.query<{ por_celular: string; por_conexion: string }>(
      `SELECT count(*) FILTER (WHERE celular = $1) AS por_celular,
              count(*) FILTER (WHERE ip = $2) AS por_conexion
         FROM pedidos_codigo WHERE fecha > now() - interval '1 hour'`,
      [internacional, peticion.ip],
    );
    const cuenta = rows[0]!;
    if (
      Number(cuenta.por_celular) >= limites.porCelular ||
      Number(cuenta.por_conexion) >= limites.porConexion
    ) {
      return respuesta.code(429).send({ error: 'demasiados_pedidos' });
    }
    // La marca de la app (entrega 14.7): si no tiene el formato, el SMS sale
    // sin ella y el dueño escribe el código.
    const marca = peticion.body?.marcaApp;
    const marcaApp = typeof marca === 'string' && marcaValida.test(marca) ? marca : undefined;
    if ((await verificador.enviar(internacional, marcaApp)) === 'demasiados') {
      return respuesta.code(429).send({ error: 'demasiados_pedidos' });
    }
    // Solo cuenta lo que de verdad se envió: un intento que Twilio rechazó
    // no le quita pedidos al dueño.
    await pool.query('INSERT INTO pedidos_codigo (celular, ip) VALUES ($1, $2)', [
      internacional,
      peticion.ip,
    ]);
    return { canal: 'sms' };
  });

  app.post<{
    Body: { celular?: unknown; codigo?: unknown; usuarioId?: unknown; modo?: unknown };
  }>('/cuenta/verificar', async (peticion, respuesta) => {
    if (!verificador) return respuesta.code(503).send({ error: 'sin_verificador' });
    const celular = String(peticion.body?.celular ?? '');
    const codigo = String(peticion.body?.codigo ?? '');
    // «guardar»: el teléfono guarda su avance (S01). «entrar»: «Ya tengo
    // cuenta», desde un teléfono sin datos (entrega 12). «invitado»: alguien
    // a quien un dueño invitó a su negocio (entrega 17).
    const entrar = peticion.body?.modo === 'entrar';
    const invitado = peticion.body?.modo === 'invitado';
    const usuarioDelTelefono = String(peticion.body?.usuarioId ?? '');
    if (
      !esCelularPeru(celular) ||
      !/^\d{6}$/.test(codigo) ||
      (!entrar && !esUuid(usuarioDelTelefono))
    ) {
      return respuesta.code(400).send({ error: 'datos_invalidos' });
    }
    const internacional = aInternacional(celular);
    const comprobacion = await verificador.comprobar(internacional, codigo);
    if (comprobacion !== 'aprobado') {
      return respuesta.code(400).send({
        error: comprobacion === 'vencido' ? 'codigo_vencido' : 'codigo_incorrecto',
      });
    }

    const cliente = await pool.connect();
    let usuarioId: string;
    let empresas: string[];
    try {
      await cliente.query('BEGIN');
      await cliente.query(
        `SELECT set_config('app.celular', $1, true),
                set_config('app.usuario_id', $2, true)`,
        [internacional, entrar ? '' : usuarioDelTelefono],
      );
      const existente = await cliente.query<{ id: string }>(
        'SELECT id FROM usuarios WHERE celular = $1',
        [internacional],
      );
      if (existente.rows[0]) {
        usuarioId = existente.rows[0].id;
      } else if (entrar) {
        // Entrar no crea cuentas.
        await cliente.query('ROLLBACK');
        return respuesta.code(404).send({ error: 'sin_cuenta' });
      } else if (
        invitado &&
        !(
          await cliente.query(
            `SELECT 1 FROM invitaciones
              WHERE celular = $1 AND aceptada_en IS NULL AND anulada_en IS NULL
                AND creada_en > now() - make_interval(days => ${diasDeLaInvitacion})`,
            [internacional],
          )
        ).rowCount
      ) {
        // Sin invitación no se crea una cuenta por esta puerta.
        await cliente.query('ROLLBACK');
        return respuesta.code(404).send({ error: 'sin_invitacion' });
      } else {
        const ocupado = await cliente.query('SELECT 1 FROM usuarios WHERE id = $1', [
          usuarioDelTelefono,
        ]);
        if (ocupado.rowCount) {
          // El teléfono ya tiene cuenta con otro número.
          await cliente.query('ROLLBACK');
          return respuesta.code(409).send({ error: 'usuario_con_otro_celular' });
        }
        await cliente.query('INSERT INTO usuarios (id, celular) VALUES ($1, $2)', [
          usuarioDelTelefono,
          internacional,
        ]);
        usuarioId = usuarioDelTelefono;
      }
      await cliente.query(`SELECT set_config('app.usuario_id', $1, true)`, [usuarioId]);
      empresas = (
        await cliente.query<{ empresa_id: string }>(
          'SELECT empresa_id FROM membresias WHERE usuario_id = $1 AND quitada_en IS NULL',
          [usuarioId],
        )
      ).rows.map((f) => f.empresa_id);
      await cliente.query('COMMIT');
    } catch (error) {
      await cliente.query('ROLLBACK');
      throw error;
    } finally {
      cliente.release();
    }

    if (entrar && !empresas.length) {
      // Una cuenta sin datos todavía: para entrar no hay nada que bajar.
      return respuesta.code(404).send({ error: 'sin_cuenta' });
    }
    if (invitado) {
      // El invitado entra con su llave y ve sus invitaciones para aceptar.
      return {
        llave: await crearSesion(pool, usuarioId),
        usuarioId,
        empresas,
        cuentaExistente: usuarioId !== usuarioDelTelefono,
        invitaciones: await invitacionesPara(pool, usuarioId),
      };
    }
    if (!entrar && usuarioId !== usuarioDelTelefono) {
      // El número ya tenía una cuenta en otro teléfono, y este teléfono
      // tiene sus propios datos: no se mezclan ni se le da llave todavía.
      // El pase deja elegir sin otro SMS (entrega 14.4).
      return {
        usuarioId,
        empresas,
        cuentaExistente: true,
        pase: await crearPase(pool, internacional, usuarioId),
      };
    }
    return {
      llave: await crearSesion(pool, usuarioId),
      usuarioId,
      empresas,
      cuentaExistente: false,
    };
  });

  // Con el pase (entrega 14.4): entrar a la cuenta que ya tenía el número,
  // o empezar de cero con este teléfono. La cuenta anterior no se borra: se
  // archiva y el número queda libre.
  app.post<{ Body: { pase?: unknown; accion?: unknown; usuarioId?: unknown } }>(
    '/cuenta/con-pase',
    async (peticion, respuesta) => {
      const accion = peticion.body?.accion;
      const usuarioDelTelefono = String(peticion.body?.usuarioId ?? '');
      if (
        (accion !== 'entrar' && accion !== 'empezar_de_cero') ||
        (accion === 'empezar_de_cero' && !esUuid(usuarioDelTelefono))
      ) {
        return respuesta.code(400).send({ error: 'datos_invalidos' });
      }
      const pase = await usarPase(pool, String(peticion.body?.pase ?? ''));
      if (!pase) return respuesta.code(410).send({ error: 'pase_vencido' });

      if (accion === 'entrar') {
        const empresas = await empresasDe(pool, pase.usuarioId);
        return {
          llave: await crearSesion(pool, pase.usuarioId),
          usuarioId: pase.usuarioId,
          empresas,
        };
      }

      const cliente = await pool.connect();
      try {
        await cliente.query('BEGIN');
        await cliente.query(
          `SELECT set_config('app.celular', $1, true), set_config('app.usuario_id', $2, true)`,
          [pase.celular, pase.usuarioId],
        );
        await cliente.query(
          `UPDATE usuarios SET celular_archivado = celular, celular = NULL, archivado_en = now()
            WHERE id = $1 AND celular = $2`,
          [pase.usuarioId, pase.celular],
        );
        // El teléfono anterior ya no entra.
        await cliente.query(
          'UPDATE sesiones SET revocada_en = now() WHERE usuario_id = $1 AND revocada_en IS NULL',
          [pase.usuarioId],
        );
        await cliente.query(`SELECT set_config('app.usuario_id', $1, true)`, [
          usuarioDelTelefono,
        ]);
        const ocupado = await cliente.query('SELECT 1 FROM usuarios WHERE id = $1', [
          usuarioDelTelefono,
        ]);
        if (ocupado.rowCount) {
          await cliente.query('ROLLBACK');
          return respuesta.code(409).send({ error: 'usuario_con_otro_celular' });
        }
        await cliente.query('INSERT INTO usuarios (id, celular) VALUES ($1, $2)', [
          usuarioDelTelefono,
          pase.celular,
        ]);
        await cliente.query('COMMIT');
      } catch (error) {
        await cliente.query('ROLLBACK');
        throw error;
      } finally {
        cliente.release();
      }
      return {
        llave: await crearSesion(pool, usuarioDelTelefono),
        usuarioId: usuarioDelTelefono,
        empresas: [],
      };
    },
  );
}

/** Cuánto vale un pase: lo justo para elegir en la pantalla. */
export const minutosDelPase = 15;

const huellaDe = (texto: string) => createHash('sha256').update(texto).digest();

async function crearPase(pool: Pool, celular: string, usuarioId: string): Promise<string> {
  const pase = randomBytes(32).toString('base64url');
  await pool.query('INSERT INTO pases (huella, celular, usuario_id) VALUES ($1, $2, $3)', [
    huellaDe(pase),
    celular,
    usuarioId,
  ]);
  return pase;
}

/** Marca el pase como usado; nulo si no existe, ya se usó o venció. */
async function usarPase(
  pool: Pool,
  pase: string,
): Promise<{ celular: string; usuarioId: string } | null> {
  if (!pase) return null;
  const { rows } = await pool.query<{ celular: string; usuario_id: string }>(
    `UPDATE pases SET usado_en = now()
      WHERE huella = $1 AND usado_en IS NULL
        AND creado_en > now() - make_interval(mins => $2)
      RETURNING celular, usuario_id`,
    [huellaDe(pase), minutosDelPase],
  );
  const fila = rows[0];
  return fila ? { celular: fila.celular, usuarioId: fila.usuario_id } : null;
}

async function empresasDe(pool: Pool, usuarioId: string): Promise<string[]> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    await cliente.query(`SELECT set_config('app.usuario_id', $1, true)`, [usuarioId]);
    const { rows } = await cliente.query<{ empresa_id: string }>(
      'SELECT empresa_id FROM membresias WHERE usuario_id = $1 AND quitada_en IS NULL',
      [usuarioId],
    );
    await cliente.query('COMMIT');
    return rows.map((f) => f.empresa_id);
  } finally {
    cliente.release();
  }
}
