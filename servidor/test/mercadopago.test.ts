import { createHmac, randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import type { MercadoPago, PagoMercadoPago } from '../src/mercadopago/cliente.js';
import { firmaValida, leerConfigMercadoPago } from '../src/mercadopago/cliente.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';
import { negocio, type Persona } from './negocio_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';

const secreto = 'clave-secreta-de-prueba';

/** Mercado Pago de mentira: guarda las preferencias y los pagos. */
function mercadoPagoFalso() {
  const pagos = new Map<string, PagoMercadoPago>();
  const preferencias: Parameters<MercadoPago['crearPreferencia']>[0][] = [];
  const mp: MercadoPago = {
    async crearPreferencia(datos) {
      preferencias.push(datos);
      return { id: `pref-${datos.referencia}`, enlace: `https://mp.falso/pagar/${datos.referencia}` };
    },
    async obtenerPago(id) {
      const pago = pagos.get(id);
      if (!pago) throw new Error('no existe');
      return pago;
    },
    async buscarPagos({ referencia }) {
      return [...pagos.values()].filter((p) => !referencia || p.external_reference === referencia);
    },
  };
  return { mp, pagos, preferencias };
}

function firmar(dataId: string, ahora: Date, pedido = 'pedido-1') {
  const ts = Math.floor(ahora.getTime() / 1000);
  const v1 = createHmac('sha256', secreto)
    .update(`id:${dataId};request-id:${pedido};ts:${ts};`)
    .digest('hex');
  return { 'x-signature': `ts=${ts},v1=${v1}`, 'x-request-id': pedido };
}

describe('La firma del aviso de Mercado Pago (entrega 32)', () => {
  const ahora = new Date('2026-11-20T15:00:00Z');
  it('Vale la firma buena, de menos de 5 minutos', () => {
    const h = firmar('123', ahora);
    const base = { secreto, firma: h['x-signature'], pedido: h['x-request-id'], dataId: '123' };
    expect(firmaValida({ ...base, ahora })).toBe(true);
    expect(firmaValida({ ...base, dataId: '124', ahora })).toBe(false);
    expect(firmaValida({ ...base, secreto: 'otra', ahora })).toBe(false);
    expect(firmaValida({ ...base, ahora: new Date(ahora.getTime() + 6 * 60_000) })).toBe(false);
    expect(firmaValida({ ...base, firma: undefined, ahora })).toBe(false);
  });

  it('Sin MP_ACCESS_TOKEN no hay Mercado Pago', () => {
    expect(leerConfigMercadoPago({})).toBeNull();
    expect(
      leerConfigMercadoPago({ MP_ACCESS_TOKEN: 'APP_USR-x', MOCA_URL_PUBLICA: 'https://moca.pe/' }),
    ).toEqual({ token: 'APP_USR-x', secreto: null, urlPublica: 'https://moca.pe' });
  });
});

describe('Pagar Moca con Mercado Pago (entrega 32)', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;
  let ahora = new Date('2026-11-20T15:00:00Z');
  const falso = mercadoPagoFalso();
  let lucho: Persona;
  let rosa: Persona;
  let jhony: Persona;
  let empresaDeLucho: string;

  const verificar = async (celular: string): Promise<Persona> => {
    const usuarioId = randomUUID();
    const r = await app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular, codigo: '123456', usuarioId },
    });
    return { usuarioId, llave: r.json().llave };
  };
  const pedir = (persona: Persona, metodo: 'GET' | 'POST', url: string, payload?: object) =>
    app.inject({
      method: metodo,
      url,
      headers: { authorization: `Bearer ${persona.llave}` },
      ...(payload ? { payload } : {}),
    });
  const avisar = (dataId: string, cabeceras = firmar(dataId, ahora)) =>
    app.inject({
      method: 'POST',
      url: `/mercadopago/webhook?data.id=${dataId}&type=payment`,
      headers: cabeceras,
      payload: { type: 'payment', data: { id: dataId } },
    });
  const pagosDe = async (empresa: string) =>
    (
      await base.poolAdmin.query(
        `SELECT plan, monto_centimos, desde, hasta, origen, mp_pago_id, anulado_en, registrado_por
           FROM pagos WHERE empresa_id = $1 ORDER BY creado_en`,
        [empresa],
      )
    ).rows;
  const orden = async (id: string) =>
    (await base.poolAdmin.query('SELECT * FROM ordenes_pago WHERE id = $1', [id])).rows[0];
  const pagar = (id: string, referencia: string, extra: Partial<PagoMercadoPago> = {}) =>
    falso.pagos.set(id, {
      id: Number(id),
      status: 'approved',
      transaction_amount: 19.9,
      currency_id: 'PEN',
      external_reference: referencia,
      ...extra,
    });

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    app = crearApp({
      pool: base.pool,
      version: 'prueba',
      verificador: verificadorFalso(),
      ahora: () => ahora,
      cobro: { desde: '2026-11-10', admins: ['900000000'], yape: null },
      mercadoPago: {
        config: { token: 'APP_USR-prueba', secreto, urlPublica: 'https://moca.prueba' },
        cliente: falso.mp,
      },
    });
    lucho = await verificar('987000001');
    const datos = negocio('Bodega Don Lucho', lucho.usuarioId, '2026-11-12T14:00:00.000Z');
    empresaDeLucho = datos.empresa.id;
    expect((await pedir(lucho, 'POST', '/datos/subir', datos)).statusCode).toBe(200);
    rosa = await verificar('987000002');
    jhony = await verificar('900000000');
  });
  afterAll(() => base.cerrar());

  it('El teléfono sabe que puede pagar con Mercado Pago', async () => {
    const cobro = (await pedir(lucho, 'GET', '/datos/bajar')).json().cobro;
    expect(cobro).toMatchObject({ estado: 'prueba', precio: 1990, mercadopago: true });
  });

  it('El dueño pide pagar: orden y página de pago; tocar dos veces, la misma orden', async () => {
    const r = await pedir(lucho, 'POST', '/cobro/mercadopago');
    expect(r.statusCode).toBe(200);
    const { orden: id, enlace, monto_centimos } = r.json();
    expect(enlace).toBe(`https://mp.falso/pagar/${id}`);
    expect(monto_centimos).toBe(1990);
    expect(falso.preferencias.at(-1)).toEqual({
      titulo: 'Moca Full · 1 mes · Bodega Don Lucho',
      centimos: 1990,
      referencia: id,
      avisos: 'https://moca.prueba/mercadopago/webhook',
      retorno: 'https://moca.prueba/pago/retorno',
    });
    expect(await orden(id)).toMatchObject({
      empresa_id: empresaDeLucho,
      plan: 'normal',
      estado: 'pendiente',
      mp_preferencia_id: `pref-${id}`,
    });
    expect((await pedir(lucho, 'POST', '/cobro/mercadopago')).json().orden).toBe(id);
    // Quien no está en el negocio no paga por él.
    expect((await pedir(rosa, 'POST', '/cobro/mercadopago')).statusCode).toBe(403);
    // Un plan o un periodo que no existe, no.
    expect(
      (await pedir(lucho, 'POST', '/cobro/mercadopago', { plan: 'oro' })).statusCode,
    ).toBe(400);
    expect(
      (await pedir(lucho, 'POST', '/cobro/mercadopago', { plan: 'full', periodo: 'semana' }))
        .statusCode,
    ).toBe(400);
    expect(
      (await pedir(lucho, 'POST', '/cobro/mercadopago', { plan: 'full' })).json().orden,
    ).toBe(id);
    // Entrega 60: el anual del Full y el del Básico, por Mercado Pago.
    const anual = (
      await pedir(lucho, 'POST', '/cobro/mercadopago', { plan: 'full', periodo: 'anio' })
    ).json();
    expect(anual.monto_centimos).toBe(19900);
    expect(falso.preferencias.at(-1)?.titulo).toBe('Moca Full · 1 año · Bodega Don Lucho');
    expect(await orden(anual.orden)).toMatchObject({ plan: 'anual' });
    const basicoAnual = (
      await pedir(lucho, 'POST', '/cobro/mercadopago', { plan: 'basico', periodo: 'anio' })
    ).json();
    expect(basicoAnual.monto_centimos).toBe(14900);
    expect(falso.preferencias.at(-1)?.titulo).toBe('Moca Básico · 1 año · Bodega Don Lucho');
    expect(await orden(basicoAnual.orden)).toMatchObject({ plan: 'basico_anual' });
    expect(
      (await pedir(lucho, 'POST', '/cobro/mercadopago', { plan: 'basico' })).json()
        .monto_centimos,
    ).toBe(1490);
  });

  it('Con la firma mala no pasa nada; con la buena se registra una sola vez', async () => {
    const id = (await pedir(lucho, 'POST', '/cobro/mercadopago')).json().orden;
    pagar('5001', id);
    const mala = await avisar('5001', { 'x-signature': 'ts=1,v1=abc', 'x-request-id': 'x' });
    expect(mala.json()).toEqual({ ok: true, ignorado: true });
    expect(await pagosDe(empresaDeLucho)).toEqual([]);

    expect((await avisar('5001')).json()).toEqual({ ok: true, resultado: 'procesado' });
    // El mismo aviso otra vez, y tres a la vez: sigue habiendo un pago.
    await avisar('5001');
    await Promise.all([avisar('5001'), avisar('5001'), avisar('5001')]);
    const pagos = await pagosDe(empresaDeLucho);
    expect(pagos).toHaveLength(1);
    expect(pagos[0]).toMatchObject({
      plan: 'normal',
      monto_centimos: 1990,
      // La prueba terminaba el 25: el mes empieza el 26.
      desde: '2026-11-26',
      hasta: '2026-12-25',
      origen: 'mercadopago',
      mp_pago_id: '5001',
      anulado_en: null,
      registrado_por: lucho.usuarioId,
    });
    expect(await orden(id)).toMatchObject({ estado: 'pagada', mp_pago_id: '5001' });

    const consulta = (await pedir(lucho, 'GET', `/cobro/orden/${id}`)).json();
    expect(consulta).toMatchObject({
      estado: 'pagada',
      cobro: { estado: 'pagado', hasta: '2026-12-25', plan: 'normal' },
    });
    // Solo quien pagó ve su orden.
    expect((await pedir(rosa, 'GET', `/cobro/orden/${id}`)).statusCode).toBe(404);
  });

  it('Al volver de pagar, la app pregunta y el pago se aplica aunque el aviso no llegue', async () => {
    ahora = new Date('2026-11-20T16:00:00Z');
    const id = (await pedir(lucho, 'POST', '/cobro/mercadopago')).json().orden;
    expect((await pedir(lucho, 'GET', `/cobro/orden/${id}`)).json()).toEqual({
      estado: 'pendiente',
    });
    // Rechazado: la app sigue esperando, por si prueba con otra tarjeta.
    pagar('5002', id, { status: 'rejected' });
    ahora = new Date('2026-11-20T16:00:20Z');
    expect((await pedir(lucho, 'GET', `/cobro/orden/${id}`)).json()).toEqual({
      estado: 'pendiente',
    });
    expect((await orden(id)).estado).toBe('rechazada');
    pagar('5003', id);
    ahora = new Date('2026-11-20T16:00:40Z');
    expect((await pedir(lucho, 'GET', `/cobro/orden/${id}`)).json()).toMatchObject({
      estado: 'pagada',
      // El segundo mes sigue al primero.
      cobro: { hasta: '2027-01-25' },
    });
  });

  it('El repaso aplica el pago cuyo aviso se perdió', async () => {
    ahora = new Date('2026-11-21T16:00:00Z');
    const id = (await pedir(lucho, 'POST', '/cobro/mercadopago')).json().orden;
    pagar('5004', id);
    // Un pago de TVSamGo en la misma cuenta: no es de Moca.
    falso.pagos.set('9999', {
      id: 9999,
      status: 'approved',
      transaction_amount: 10,
      external_reference: 'tvsamgo-orden-1',
    });
    const r = await app.cobrador.repasar();
    expect(r.procesados).toBe(1);
    expect(await pagosDe(empresaDeLucho)).toHaveLength(3);
    expect((await app.cobrador.repasar()).procesados).toBe(0);
  });

  it('Si cobró menos de lo que vale, queda para revisar', async () => {
    ahora = new Date('2026-11-22T16:00:00Z');
    const id = (await pedir(lucho, 'POST', '/cobro/mercadopago')).json().orden;
    pagar('5005', id, { transaction_amount: 1 });
    expect((await avisar('5005')).json().resultado).toBe('revisar');
    expect(await orden(id)).toMatchObject({ estado: 'revisar', motivo: 'monto' });
    expect(await pagosDe(empresaDeLucho)).toHaveLength(3);
    // Jhony lo ve en «Cobros».
    const resumen = (await pedir(jhony, 'GET', '/cobro/resumen')).json();
    expect(resumen.revisar).toEqual([
      expect.objectContaining({
        id,
        nombre: 'Bodega Don Lucho',
        celular: '987000001',
        motivo: 'monto',
        mp_pago_id: '5005',
        monto_centimos: 1990,
      }),
    ]);
  });

  it('Una devolución anula el último pago; si no es el último, queda para revisar', async () => {
    falso.pagos.get('5004')!.status = 'refunded';
    expect((await avisar('5004')).json().resultado).toBe('devuelto');
    const pagos = await pagosDe(empresaDeLucho);
    expect(pagos[2].anulado_en).not.toBeNull();
    const cobro = (await pedir(lucho, 'GET', '/datos/bajar')).json().cobro;
    expect(cobro).toMatchObject({ estado: 'pagado', hasta: '2027-01-25' });

    falso.pagos.get('5001')!.status = 'refunded';
    expect((await avisar('5001')).json().resultado).toBe('revisar');
    expect(pagos[0].anulado_en).toBeNull();
  });

  it('«Mis pagos de Moca»: el dueño ve sus pagos, sin la nota del Yape (entrega 33)', async () => {
    expect(
      (
        await pedir(jhony, 'POST', '/cobro/pago', {
          empresa: empresaDeLucho,
          plan: 'normal',
          nota: 'op 777 · lo yapeó su hija',
        })
      ).statusCode,
    ).toBe(200);
    const r = await pedir(lucho, 'GET', '/cobro/mis-pagos');
    expect(r.statusCode).toBe(200);
    const { pagos, en_revision } = r.json();
    // Del más nuevo al más viejo: el Yape, 5004 (devuelto), 5003 y 5001.
    expect(pagos.map((p: { medio: string }) => p.medio)).toEqual([
      'yape',
      'mercadopago',
      'mercadopago',
      'mercadopago',
    ]);
    expect(pagos[0]).not.toHaveProperty('operacion');
    expect(JSON.stringify(r.json())).not.toContain('su hija');
    expect(pagos[1]).toMatchObject({ operacion: '5004', anulado: true, monto_centimos: 1990 });
    expect(pagos[3]).toMatchObject({
      operacion: '5001',
      anulado: false,
      plan: 'normal',
      desde: '2026-11-26',
      hasta: '2026-12-25',
    });
    // La fecha del pago es la del servidor (now()), no la del reloj de la prueba.
    expect(Number.isNaN(Date.parse(pagos[3].pagado_en))).toBe(false);
    // En revisión: la que cobró de menos y la devolución que no era la última.
    expect(en_revision).toHaveLength(2);
    expect(en_revision[0]).toMatchObject({ monto_centimos: 1990 });
    // Quien no es del negocio no ve nada.
    expect((await pedir(rosa, 'GET', '/cobro/mis-pagos')).statusCode).toBe(403);
  });

  it('La página de regreso dice cómo quedó y que vuelva a Moca', async () => {
    for (const [estado, titulo] of [
      ['exito', 'Pago recibido'],
      ['pendiente', 'Pago en proceso'],
      ['fallo', 'El pago no se completó'],
    ]) {
      const r = await app.inject({ method: 'GET', url: `/pago/retorno?estado=${estado}` });
      expect(r.statusCode).toBe(200);
      expect(r.headers['content-type']).toContain('text/html');
      expect(r.body).toContain(titulo);
      // El botón (entrega 32.1) y, por si el navegador no abre la app, el texto.
      expect(r.body).toContain(
        '<a href="intent://pago#Intent;scheme=moca;package=pe.moca.app;end">Volver a Moca</a>',
      );
      expect(r.body).toContain('Ya puedes volver a Moca.');
    }
  });

  it('Sin Mercado Pago configurado, no se ofrece', async () => {
    const sin = crearApp({
      pool: base.pool,
      version: 'prueba',
      ahora: () => ahora,
      cobro: { desde: '2026-11-10', admins: [], yape: null },
    });
    const r = await sin.inject({
      method: 'POST',
      url: '/cobro/mercadopago',
      headers: { authorization: `Bearer ${lucho.llave}` },
    });
    expect(r.statusCode).toBe(503);
    const cobro = (
      await sin.inject({
        method: 'GET',
        url: '/datos/bajar',
        headers: { authorization: `Bearer ${lucho.llave}` },
      })
    ).json().cobro;
    expect(cobro.mercadopago).toBeUndefined();
    await sin.close();
  });
});
