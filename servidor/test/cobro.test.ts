import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import {
  estadoDelCobro,
  periodoDelPago,
  puedeSerFundador,
  sumarMeses,
} from '../src/cobro/estado.js';
import { leerConfigCobro } from '../src/cobro/rutas.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';
import { negocio, type Persona } from './negocio_de_prueba.js';

describe('El estado del cobro (entrega 24)', () => {
  const base = { cobroDesde: '2026-11-10', suscripcion: null, fundadores: 0 };

  it('Sin MOCA_COBRO_DESDE no se cobra', () => {
    expect(
      estadoDelCobro({
        ...base,
        hoy: '2026-12-30',
        cobroDesde: null,
        inicioPrueba: '2026-11-01',
      }).estado,
    ).toBe('sin_cobro');
  });

  it('14 días desde el primer registro, nunca antes de que empiece el cobro', () => {
    // Empezó antes del cobro: cuenta desde el 10.
    expect(
      estadoDelCobro({
        ...base,
        hoy: '2026-11-12',
        inicioPrueba: '2026-11-01',
      }),
    ).toMatchObject({
      estado: 'prueba',
      hasta: '2026-11-23',
      dias: 11,
      porVencer: false,
      precio: 1490,
    });
    // Empezó después: cuenta desde su primer registro.
    expect(
      estadoDelCobro({
        ...base,
        hoy: '2026-11-22',
        inicioPrueba: '2026-11-15',
      }),
    ).toMatchObject({ estado: 'prueba', hasta: '2026-11-28', dias: 6 });
    // Sin registros, la prueba no empezó.
    expect(estadoDelCobro({ ...base, hoy: '2026-11-22', inicioPrueba: null })).toMatchObject({
      estado: 'prueba',
      hasta: null,
      dias: 14,
    });
    // Tres días antes avisa; al día siguiente del último, vence.
    expect(
      estadoDelCobro({ ...base, hoy: '2026-11-20', inicioPrueba: '2026-11-01' }).porVencer,
    ).toBe(true);
    expect(
      estadoDelCobro({
        ...base,
        hoy: '2026-11-24',
        inicioPrueba: '2026-11-01',
      }),
    ).toMatchObject({ estado: 'vencido', hasta: '2026-11-23' });
  });

  it('Pagado hasta el día que dice, con su aviso', () => {
    const suscripcion = {
      plan: 'normal' as const,
      pagadoHasta: '2026-12-20',
      fueFundador: false,
    };
    expect(
      estadoDelCobro({
        ...base,
        suscripcion,
        hoy: '2026-12-17',
        inicioPrueba: '2026-11-10',
      }),
    ).toMatchObject({
      estado: 'pagado',
      hasta: '2026-12-20',
      dias: 3,
      porVencer: true,
    });
    expect(
      estadoDelCobro({
        ...base,
        suscripcion,
        hoy: '2026-12-21',
        inicioPrueba: '2026-11-10',
      }).estado,
    ).toBe('vencido');
  });

  it('El mes sigue al anterior y se ajusta a fin de mes', () => {
    expect(sumarMeses('2026-01-31', 1)).toBe('2026-02-28');
    expect(periodoDelPago({ hoy: '2026-11-21', pagadoHasta: null, plan: 'normal' })).toEqual({
      desde: '2026-11-21',
      hasta: '2026-12-20',
    });
    expect(
      periodoDelPago({
        hoy: '2026-12-15',
        pagadoHasta: '2026-12-20',
        plan: 'normal',
      }),
    ).toEqual({ desde: '2026-12-21', hasta: '2027-01-20' });
    expect(
      periodoDelPago({
        hoy: '2027-02-01',
        pagadoHasta: '2026-12-20',
        plan: 'anual',
      }),
    ).toEqual({ desde: '2027-02-01', hasta: '2028-01-31' });
  });

  it('El fundador: 50 cupos; lo pierde quien renueva más de 30 días tarde', () => {
    expect(
      puedeSerFundador({
        hoy: '2026-11-21',
        suscripcion: null,
        fundadores: 49,
      }),
    ).toBe(true);
    expect(
      puedeSerFundador({
        hoy: '2026-11-21',
        suscripcion: null,
        fundadores: 50,
      }),
    ).toBe(false);
    const fundador = {
      plan: 'fundador' as const,
      pagadoHasta: '2026-12-20',
      fueFundador: true,
    };
    expect(
      puedeSerFundador({
        hoy: '2027-01-19',
        suscripcion: fundador,
        fundadores: 50,
      }),
    ).toBe(true);
    expect(
      puedeSerFundador({
        hoy: '2027-01-20',
        suscripcion: fundador,
        fundadores: 0,
      }),
    ).toBe(false);
  });

  it('La configuración sale del entorno', () => {
    expect(
      leerConfigCobro({
        MOCA_COBRO_DESDE: '2026-11-10',
        MOCA_ADMIN_CELULARES: '+51 900 000 000, 911222333',
        MOCA_YAPE_NUMERO: '+51 911 111 111',
        MOCA_YAPE_NOMBRE: 'Moca',
      }),
    ).toEqual({
      desde: '2026-11-10',
      admins: ['900000000', '911222333'],
      yape: { numero: '911111111', nombre: 'Moca' },
    });
    expect(leerConfigCobro({ MOCA_COBRO_DESDE: 'mañana' }).desde).toBeNull();
  });
});

describe('El cobro manual por Yape en el servidor (entrega 24)', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;
  // 10 de la mañana en Lima del día indicado.
  let ahora = new Date('2026-11-12T15:00:00Z');
  const elDia = (dia: string) => {
    ahora = new Date(`${dia}T15:00:00Z`);
  };
  let lucho: Persona;
  let jhony: Persona;
  let empresaDeLucho: string;

  const verificar = async (celular: string, usuarioId: string = randomUUID()): Promise<Persona> => {
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
  const cobroDe = async (persona: Persona) =>
    (await pedir(persona, 'GET', '/datos/bajar')).json().cobro;

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    app = crearApp({
      pool: base.pool,
      version: 'prueba',
      verificador: verificadorFalso(),
      ahora: () => ahora,
      cobro: {
        desde: '2026-11-10',
        admins: ['900000000'],
        yape: { numero: '911111111', nombre: 'Moca' },
      },
    });
    lucho = await verificar('987000001');
    const datos = negocio('Bodega Don Lucho', lucho.usuarioId, '2026-11-01T14:00:00.000Z');
    empresaDeLucho = datos.empresa.id;
    expect((await pedir(lucho, 'POST', '/datos/subir', datos)).statusCode).toBe(200);
    jhony = await verificar('900000000');
  });
  afterAll(() => base.cerrar());

  it('El teléfono recibe su prueba y a dónde yapear', async () => {
    elDia('2026-11-12');
    expect(await cobroDe(lucho)).toEqual({
      estado: 'prueba',
      hasta: '2026-11-23',
      dias: 11,
      porVencer: false,
      plan: null,
      precio: 1490,
      pago: { yape: '911111111', nombre: 'Moca' },
      respondio: false,
    });
    elDia('2026-11-21');
    const cambios = (await pedir(lucho, 'GET', '/datos/cambios?desde=0')).json();
    expect(cambios.cobro).toMatchObject({
      estado: 'prueba',
      dias: 2,
      porVencer: true,
    });
  });

  it('Solo el número de Jhony registra pagos', async () => {
    expect((await pedir(lucho, 'GET', '/cobro/negocio?celular=987000001')).json()).toEqual({
      error: 'sin_permiso',
    });
    expect(
      (
        await pedir(lucho, 'POST', '/cobro/pago', {
          empresa: empresaDeLucho,
          plan: 'normal',
        })
      ).statusCode,
    ).toBe(403);
    expect((await pedir(jhony, 'GET', '/cobro/resumen')).statusCode).toBe(200);
  });

  it('Un pago en la prueba empieza cuando la prueba termina; el siguiente, a continuación', async () => {
    elDia('2026-11-21');
    const ficha = (await pedir(jhony, 'GET', '/cobro/negocio?celular=987 000 001')).json();
    expect(ficha).toMatchObject({
      empresa_id: empresaDeLucho,
      nombre: 'Bodega Don Lucho',
      celular: '987000001',
      cobro: { estado: 'prueba', hasta: '2026-11-23' },
      pagos: [],
    });

    const pago = await pedir(jhony, 'POST', '/cobro/pago', {
      empresa: empresaDeLucho,
      plan: 'fundador',
      nota: 'Yape op. 123',
    });
    expect(pago.json().cobro).toMatchObject({
      estado: 'pagado',
      hasta: '2026-12-23',
      plan: 'fundador',
      precio: 1490,
    });
    expect(await cobroDe(lucho)).toMatchObject({
      estado: 'pagado',
      hasta: '2026-12-23',
    });

    await pedir(jhony, 'POST', '/cobro/pago', {
      empresa: empresaDeLucho,
      plan: 'fundador',
    });
    const despues = (await pedir(jhony, 'GET', '/cobro/negocio?celular=987000001')).json();
    expect(despues.cobro.hasta).toBe('2027-01-23');
    expect(
      despues.pagos.map((p: { desde: string; monto_centimos: number }) => [
        p.desde,
        p.monto_centimos,
      ]),
    ).toEqual([
      ['2026-12-24', 1490],
      ['2026-11-24', 1490],
    ]);
    // Cuenta una sola vez para los 50.
    expect((await pedir(jhony, 'GET', '/cobro/resumen')).json().fundadores).toEqual({
      usados: 1,
      maximo: 50,
    });
  });

  it('Más de 30 días tarde pierde el fundador; paga S/ 19.90', async () => {
    elDia('2027-02-23');
    expect(await cobroDe(lucho)).toMatchObject({
      estado: 'vencido',
      precio: 1990,
    });
    const r = await pedir(jhony, 'POST', '/cobro/pago', {
      empresa: empresaDeLucho,
      plan: 'fundador',
    });
    expect(r.json()).toEqual({ error: 'perdio_fundador' });
    const normal = await pedir(jhony, 'POST', '/cobro/pago', {
      empresa: empresaDeLucho,
      plan: 'normal',
    });
    expect(normal.json().cobro).toMatchObject({
      estado: 'pagado',
      hasta: '2027-03-22',
    });
  });

  it('Lo vencido sale en el resumen; borrar y volver a empezar no da otra prueba', async () => {
    elDia('2026-11-12');
    const rosa = await verificar('987000002');
    expect(
      (
        await pedir(
          rosa,
          'POST',
          '/datos/subir',
          negocio('Pollería Rosa', rosa.usuarioId, '2026-11-12T14:00:00.000Z'),
        )
      ).statusCode,
    ).toBe(200);
    elDia('2026-11-26');
    expect(await cobroDe(rosa)).toMatchObject({
      estado: 'vencido',
      hasta: '2026-11-25',
    });
    const resumen = (await pedir(jhony, 'GET', '/cobro/resumen')).json();
    expect(resumen.negocios.map((n: { nombre: string }) => n.nombre)).toContain('Pollería Rosa');

    expect(
      (
        await pedir(rosa, 'POST', '/cuenta/borrar-datos', {
          confirmacion: 'BORRAR',
        })
      ).statusCode,
    ).toBe(200);
    const deNuevo = await verificar('987000002', rosa.usuarioId);
    await pedir(
      deNuevo,
      'POST',
      '/datos/subir',
      negocio('Pollería Rosa 2', rosa.usuarioId, '2026-11-26T14:00:00.000Z'),
    );
    expect(await cobroDe(deNuevo)).toMatchObject({
      estado: 'vencido',
      hasta: '2026-11-25',
    });
  });

  it('Entrega 25: la pregunta del día 10 se contesta una vez y Jhony la ve', async () => {
    elDia('2027-02-23');
    expect((await cobroDe(lucho)).respondio).toBe(false);
    expect(
      (await pedir(lucho, 'POST', '/cobro/respuesta', { respuesta: 'quizas' })).statusCode,
    ).toBe(400);
    expect(
      (
        await pedir(lucho, 'POST', '/cobro/respuesta', {
          respuesta: 'no_se',
          motivo: 'Depende de las ventas',
        })
      ).json(),
    ).toEqual({ recibida: true });
    expect((await cobroDe(lucho)).respondio).toBe(true);
    const ficha = (await pedir(jhony, 'GET', '/cobro/negocio?celular=987000001')).json();
    expect(ficha.respuestas).toMatchObject([
      { respuesta: 'no_se', motivo: 'Depende de las ventas', precio_centimos: 1990 },
    ]);
  });

  it('Entrega 26.1: anular el último pago lo deja como antes, con su cupo', async () => {
    elDia('2026-11-20');
    const carmen = await verificar('987000003');
    const datos = negocio('Bodega Carmen', carmen.usuarioId, '2026-11-20T14:00:00.000Z');
    await pedir(carmen, 'POST', '/datos/subir', datos);
    const empresa = datos.empresa.id;
    const cupo = async () =>
      (await pedir(jhony, 'GET', '/cobro/resumen')).json().fundadores.usados as number;
    const antes = await cupo();

    await pedir(jhony, 'POST', '/cobro/pago', { empresa, plan: 'fundador' });
    await pedir(jhony, 'POST', '/cobro/pago', { empresa, plan: 'fundador' });
    expect(await cupo()).toBe(antes + 1);
    const ficha = (await pedir(jhony, 'GET', '/cobro/negocio?celular=987000003')).json();
    const [ultimo, primero] = ficha.pagos as { id: string }[];
    // Solo el último.
    expect(
      (await pedir(jhony, 'POST', '/cobro/anular', { pago: primero!.id })).json(),
    ).toEqual({ error: 'no_es_el_ultimo' });

    const r = await pedir(jhony, 'POST', '/cobro/anular', { pago: ultimo!.id });
    expect(r.json().cobro).toMatchObject({ estado: 'pagado', hasta: '2027-01-03' });
    const r2 = await pedir(jhony, 'POST', '/cobro/anular', { pago: primero!.id });
    // Sin pagos, vuelve a su prueba y el cupo de fundador vuelve.
    expect(r2.json().cobro).toMatchObject({ estado: 'prueba', hasta: '2026-12-03' });
    expect(await cupo()).toBe(antes);
    expect((await cobroDe(carmen)).estado).toBe('prueba');
    // Quedan marcados, no borrados.
    const despues = (await pedir(jhony, 'GET', '/cobro/negocio?celular=987000003')).json();
    expect(despues.pagos.every((p: { anulado_en: string | null }) => p.anulado_en)).toBe(true);
    expect((await pedir(jhony, 'POST', '/cobro/anular', { pago: ultimo!.id })).statusCode).toBe(
      404,
    );
    expect(
      (await pedir(carmen, 'POST', '/cobro/anular', { pago: ultimo!.id })).statusCode,
    ).toBe(403);
  });

  it('Entrega 28: el uso del negocio llega y Jhony lo ve resumido', async () => {
    const hace = (horas: number) => new Date(Date.now() - horas * 3_600_000).toISOString();
    const evento = (nombre: string, horas: number, datos?: object) => ({
      id: randomUUID(),
      nombre,
      fecha: hace(horas),
      ...(datos ? { datos } : {}),
    });
    const eventos = [
      evento('appAbierta', 1),
      evento('appAbierta', 30),
      evento('ventaGuardada', 1, { modo: 'voz', segundos: 6 }),
      evento('ventaGuardada', 30, { modo: 'escrita', segundos: 12 }),
      evento('ventaGuardada', 31, { modo: 'voz', segundos: 8 }),
      evento('vozConDuda', 1),
      evento('notificacionRespondida', 2, { accion: 'decir' }),
      evento('informeAbierto', 2),
      // De hace más de una semana: no cuenta.
      evento('ventaGuardada', 24 * 10, { segundos: 90 }),
    ];
    expect((await pedir(lucho, 'POST', '/uso', { eventos })).json()).toEqual({ recibidos: 9 });
    // Reenviar no duplica.
    await pedir(lucho, 'POST', '/uso', { eventos });
    expect(
      (await pedir(lucho, 'POST', '/uso', { eventos: [{ id: 'x', nombre: 'a', fecha: hace(1) }] }))
        .statusCode,
    ).toBe(400);

    const ficha = (await pedir(jhony, 'GET', '/cobro/negocio?celular=987000001')).json();
    expect(ficha.uso).toMatchObject({
      dias_que_abrio: 2,
      ventas_anotadas: 3,
      segundos_para_anotar: 8,
      voz_con_duda: 1,
      avisos_respondidos: 1,
      informes_abiertos: 1,
    });
    expect(ficha.uso.ultima_apertura).not.toBeNull();
    // Abrió hace una hora: no está entre los que no abren.
    const resumen = (await pedir(jhony, 'GET', '/cobro/resumen')).json();
    expect(resumen.sin_abrir.map((n: { nombre: string }) => n.nombre)).not.toContain(
      'Bodega Don Lucho',
    );
  });

  it('Sin cobro configurado, todo sigue abierto', async () => {
    const sin = crearApp({
      pool: base.pool,
      version: 'prueba',
      ahora: () => ahora,
    });
    const r = await sin.inject({
      method: 'GET',
      url: '/datos/bajar',
      headers: { authorization: `Bearer ${lucho.llave}` },
    });
    expect(r.json().cobro).toMatchObject({ estado: 'sin_cobro' });
    expect(r.json().cobro.pago).toBeUndefined();
  });
});
