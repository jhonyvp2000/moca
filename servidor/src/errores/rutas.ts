import type { FastifyInstance } from 'fastify';
import type { Pool } from '../base/conexion.js';
import { type ConfigCobro, esAdmin } from '../cobro/rutas.js';
import { autenticar } from '../datos/subir.js';
import { miembroDe } from '../equipo/miembros.js';

// Los errores de la app (entrega 27): el teléfono los manda con su cuenta y
// solo los números de MOCA_ADMIN_CELULARES los leen, agrupados.

const esUuid = (v: unknown): v is string =>
  typeof v === 'string' &&
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);

/** Cuántos días se guardan. */
export const diasDeErrores = 90;
const maximoPorEnvio = 50;

interface ErrorDelTelefono {
  id: string;
  firma: string;
  mensaje: string;
  pila?: string | null;
  pantalla?: string | null;
  entrega?: string | null;
  armado?: number | null;
  veces: number;
  primera: string;
  ultima: string;
}

const texto = (valor: unknown, largo: number) =>
  typeof valor === 'string' ? valor.slice(0, largo) : null;

function valido(e: unknown): e is ErrorDelTelefono {
  if (typeof e !== 'object' || e === null) return false;
  const x = e as Record<string, unknown>;
  return (
    esUuid(x.id) &&
    typeof x.firma === 'string' &&
    typeof x.mensaje === 'string' &&
    Number.isSafeInteger(x.veces) &&
    (x.veces as number) > 0 &&
    typeof x.primera === 'string' &&
    !Number.isNaN(Date.parse(x.primera)) &&
    typeof x.ultima === 'string' &&
    !Number.isNaN(Date.parse(x.ultima))
  );
}

export function rutasErrores(app: FastifyInstance, pool: Pool, config: ConfigCobro): void {
  app.post<{ Body: { errores?: unknown } }>('/errores', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    const lista = peticion.body?.errores;
    if (!Array.isArray(lista) || lista.length > maximoPorEnvio || !lista.every(valido)) {
      return respuesta.code(400).send({ error: 'datos_invalidos' });
    }
    const cliente = await pool.connect();
    try {
      await cliente.query('BEGIN');
      const miembro = await miembroDe(cliente, usuarioId);
      for (const e of lista) {
        await cliente.query(
          `INSERT INTO errores_app
             (id, usuario_id, empresa_id, firma, mensaje, pila, pantalla, entrega, armado,
              veces, primera, ultima)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
           ON CONFLICT (id) DO UPDATE
             SET veces = greatest(errores_app.veces, excluded.veces),
                 ultima = greatest(errores_app.ultima, excluded.ultima)`,
          [
            e.id,
            usuarioId,
            miembro?.empresaId ?? null,
            e.firma.slice(0, 64),
            e.mensaje.slice(0, 300),
            texto(e.pila, 3000),
            texto(e.pantalla, 100),
            texto(e.entrega, 40),
            Number.isSafeInteger(e.armado) ? e.armado : null,
            e.veces,
            e.primera,
            e.ultima,
          ],
        );
      }
      await cliente.query('COMMIT');
      return { recibidos: lista.length };
    } catch (error) {
      await cliente.query('ROLLBACK');
      throw error;
    } finally {
      cliente.release();
    }
  });

  // Los de los últimos 90 días, agrupados por firma, los más recientes primero.
  app.get('/errores', async (peticion, respuesta) => {
    const usuarioId = await autenticar(pool, peticion);
    if (!usuarioId) return respuesta.code(401).send({ error: 'sin_sesion' });
    if (!(await esAdmin(pool, config, usuarioId))) {
      return respuesta.code(403).send({ error: 'sin_permiso' });
    }
    const cliente = await pool.connect();
    try {
      await cliente.query('BEGIN');
      await cliente.query(
        `SELECT set_config('app.admin', 'si', true), set_config('app.usuario_id', $1, true)`,
        [usuarioId],
      );
      // Lo de más de 90 días se va.
      await cliente.query(
        `DELETE FROM errores_app WHERE ultima < now() - make_interval(days => $1)`,
        [diasDeErrores],
      );
      const { rows } = await cliente.query(
        `SELECT firma,
                (array_agg(mensaje ORDER BY ultima DESC))[1] AS mensaje,
                (array_agg(pila ORDER BY ultima DESC))[1] AS pila,
                (array_agg(pantalla ORDER BY ultima DESC))[1] AS pantalla,
                (array_agg(entrega ORDER BY ultima DESC))[1] AS entrega,
                max(armado) AS armado,
                sum(veces)::int AS veces,
                count(DISTINCT empresa_id)::int AS negocios,
                count(DISTINCT usuario_id)::int AS personas,
                min(primera) AS primera,
                max(ultima) AS ultima
           FROM errores_app
          GROUP BY firma
          ORDER BY max(ultima) DESC
          LIMIT 100`,
      );
      await cliente.query('COMMIT');
      return { errores: rows };
    } catch (error) {
      await cliente.query('ROLLBACK');
      throw error;
    } finally {
      cliente.release();
    }
  });
}
