import type { FastifyInstance } from 'fastify';
import type { Pool } from '../base/conexion.js';
import { aInternacional, esCelularPeru } from './celular.js';
import { crearSesion } from './sesiones.js';
import type { Verificador } from './verificador.js';

/** Límites de códigos enviados en una hora. */
export const limites = { porCelular: 5, porConexion: 20 };

const esUuid = (v: string) =>
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);

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
  app.post<{ Body: { celular?: unknown } }>('/cuenta/codigo', async (peticion, respuesta) => {
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
    if ((await verificador.enviar(internacional)) === 'demasiados') {
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

  app.post<{ Body: { celular?: unknown; codigo?: unknown; usuarioId?: unknown } }>(
    '/cuenta/verificar',
    async (peticion, respuesta) => {
      if (!verificador) return respuesta.code(503).send({ error: 'sin_verificador' });
      const celular = String(peticion.body?.celular ?? '');
      const codigo = String(peticion.body?.codigo ?? '');
      const usuarioDelTelefono = String(peticion.body?.usuarioId ?? '');
      if (!esCelularPeru(celular) || !/^\d{6}$/.test(codigo) || !esUuid(usuarioDelTelefono)) {
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
          [internacional, usuarioDelTelefono],
        );
        const existente = await cliente.query<{ id: string }>(
          'SELECT id FROM usuarios WHERE celular = $1',
          [internacional],
        );
        if (existente.rows[0]) {
          usuarioId = existente.rows[0].id;
        } else {
          const ocupado = await cliente.query(
            'SELECT 1 FROM usuarios WHERE id = $1',
            [usuarioDelTelefono],
          );
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
            'SELECT empresa_id FROM membresias WHERE usuario_id = $1',
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

      return {
        llave: await crearSesion(pool, usuarioId),
        usuarioId,
        empresas,
        // El número ya tenía una cuenta creada desde otro teléfono: la app
        // no mezcla los datos (la recuperación llega en la entrega 12).
        cuentaExistente: usuarioId !== usuarioDelTelefono,
      };
    },
  );
}
