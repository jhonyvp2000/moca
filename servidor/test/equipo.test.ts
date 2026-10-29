import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { crearApp } from '../src/app.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';

// Jueves 29 de octubre de 2026, 10 de la mañana en Lima.
const ahora = new Date('2026-10-29T15:00:00Z');
const hoy = '2026-10-29T14:00:00.000Z';
const ayer = '2026-10-28T14:00:00.000Z';

interface Persona {
  usuarioId: string;
  llave: string;
}

/** Un negocio recién subido por su dueño, con una venta suya. */
function negocio(nombre: string, duenoId: string) {
  const empresa = randomUUID();
  const efectivo = randomUUID();
  const venta = randomUUID();
  const ventaDelDueno = randomUUID();
  const yape = randomUUID();
  const ventaPorYape = randomUUID();
  return {
    ids: { empresa, efectivo, venta, ventaDelDueno, yape, ventaPorYape },
    datos: {
      empresa: {
        id: empresa,
        nombre,
        tipo_negocio: 'bodega',
        modo: 'simple',
        pais: 'PE',
        moneda: 'PEN',
        hora_cierre_minutos: 1260,
        creado_en: hoy,
      },
      cuentas: [
        {
          id: efectivo,
          tipo: 'efectivo',
          nombre: 'Efectivo',
          orden: 0,
          saldo_inicial_centimos: 100000,
          fecha_saldo_inicial: ayer,
        },
        {
          id: yape,
          tipo: 'yape',
          nombre: 'Yape',
          orden: 1,
          saldo_inicial_centimos: 50000,
          fecha_saldo_inicial: ayer,
        },
      ],
      categorias: [
        { id: venta, nombre: 'Venta del día', tipo_movimiento: 'ingreso', orden: 0, activa: true },
      ],
      movimientos: [
        movimiento(ventaDelDueno, duenoId, efectivo, venta),
        movimiento(ventaPorYape, duenoId, yape, venta),
      ],
    },
  };
}

function movimiento(
  id: string,
  autor: string,
  cuenta: string,
  categoria: string,
  extra: Record<string, unknown> = {},
) {
  return {
    id,
    tipo: 'ingreso',
    cuenta_id: cuenta,
    monto_centimos: 35000,
    fecha_movimiento: hoy,
    estado_pago: 'pagado',
    monto_pagado_centimos: 35000,
    fecha_pago: hoy,
    categoria_id: categoria,
    nivel_confianza: 'd',
    fuente: 'voz',
    autor_id: autor,
    estado: 'vigente',
    creado_en: hoy,
    ...extra,
  };
}

describe('Varias personas en un mismo negocio (entrega 17)', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;
  let lucho: Persona;
  let lucy: ReturnType<typeof negocio>;

  const pedir = (
    persona: Persona | null,
    metodo: 'GET' | 'POST',
    url: string,
    payload?: object,
  ) =>
    app.inject({
      method: metodo,
      url,
      headers: persona ? { authorization: `Bearer ${persona.llave}` } : {},
      ...(payload ? { payload } : {}),
    });

  /** Un dueño que guarda su avance (su teléfono ya tiene datos). */
  const dueno = async (celular: string): Promise<Persona> => {
    const usuarioId = randomUUID();
    const r = await app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular, codigo: '123456', usuarioId },
    });
    return { usuarioId, llave: r.json().llave };
  };

  /** Alguien invitado que entra con su número. */
  const invitado = async (celular: string) => {
    const usuarioId = randomUUID();
    const r = await app.inject({
      method: 'POST',
      url: '/cuenta/verificar',
      payload: { celular, codigo: '123456', usuarioId, modo: 'invitado' },
    });
    return { respuesta: r, persona: { usuarioId: r.json().usuarioId, llave: r.json().llave } };
  };

  const aceptarPrimera = async (persona: Persona) => {
    const { invitaciones } = (await pedir(persona, 'GET', '/cuenta/invitaciones')).json();
    return pedir(persona, 'POST', '/cuenta/aceptar', {
      invitacion: invitaciones[0].id,
      consentimiento: true,
    });
  };

  const bajar = async (persona: Persona, empresa?: string) =>
    (await pedir(persona, 'GET', `/datos/bajar${empresa ? `?empresa=${empresa}` : ''}`)).json();
  const cambios = (persona: Persona, desde: number) =>
    pedir(persona, 'GET', `/datos/cambios?desde=${desde}`);

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    app = crearApp({
      pool: base.pool,
      version: 'prueba',
      verificador: verificadorFalso(),
      ahora: () => ahora,
    });
    lucho = await dueno('987000001');
    lucy = negocio('Bodega Don Lucho', lucho.usuarioId);
    expect((await pedir(lucho, 'POST', '/datos/subir', lucy.datos)).statusCode).toBe(200);
  });
  afterAll(() => base.cerrar());

  // Pepe (ayudante), Rosa (dueña) y Carmen (contadora).
  let pepe: Persona;
  let rosa: Persona;
  let carmen: Persona;

  it('el titular invita hasta 3 personas; el contador no cuenta', async () => {
    const equipo = (await pedir(lucho, 'GET', '/equipo')).json();
    expect(equipo).toMatchObject({ rol: 'dueno', titular: true, maximo: 3 });
    expect(equipo.personas).toHaveLength(1);

    for (const [celular, rol, nombre] of [
      ['987000002', 'dueno', 'Rosa'],
      ['987000003', 'ayudante', 'Pepe'],
    ]) {
      const r = await pedir(lucho, 'POST', '/equipo/invitar', { celular, rol, nombre });
      expect(r.statusCode, celular).toBe(200);
      expect(r.json()).toMatchObject({ celular: `+51${celular}`, rol, nombre });
    }
    // Lucho, Rosa y Pepe: ya no hay lugar...
    const cuarta = await pedir(lucho, 'POST', '/equipo/invitar', {
      celular: '987000004',
      rol: 'encargado',
    });
    expect(cuarta.json()).toEqual({ error: 'sin_lugar' });
    // ...pero la contadora no cuenta.
    const contadora = await pedir(lucho, 'POST', '/equipo/invitar', {
      celular: '987000005',
      rol: 'contador',
      nombre: 'Carmen',
    });
    expect(contadora.statusCode).toBe(200);
    // Datos que no valen.
    expect(
      (await pedir(lucho, 'POST', '/equipo/invitar', { celular: '12', rol: 'dueno' })).statusCode,
    ).toBe(400);
    expect(
      (await pedir(lucho, 'POST', '/equipo/invitar', { celular: '987000006', rol: 'jefe' }))
        .statusCode,
    ).toBe(400);
    expect((await pedir(lucho, 'GET', '/equipo')).json().invitaciones).toHaveLength(3);
  });

  it('sin invitación no se entra por esa puerta; con ella, se acepta con consentimiento', async () => {
    const nadie = await invitado('987000009');
    expect(nadie.respuesta.statusCode).toBe(404);
    expect(nadie.respuesta.json()).toEqual({ error: 'sin_invitacion' });

    const entrada = await invitado('987000003');
    expect(entrada.respuesta.statusCode).toBe(200);
    pepe = entrada.persona;
    expect(entrada.respuesta.json().invitaciones).toMatchObject([
      { negocio: 'Bodega Don Lucho', rol: 'ayudante', nombre: 'Pepe' },
    ]);
    const { invitaciones } = (await pedir(pepe, 'GET', '/cuenta/invitaciones')).json();
    // Sin aceptar el uso de sus datos, no entra.
    const sin = await pedir(pepe, 'POST', '/cuenta/aceptar', { invitacion: invitaciones[0].id });
    expect(sin.statusCode).toBe(400);
    const con = await aceptarPrimera(pepe);
    expect(con.json()).toEqual({ empresa_id: lucy.ids.empresa, rol: 'ayudante' });
    // Una invitación se usa una vez.
    expect((await pedir(pepe, 'GET', '/cuenta/invitaciones')).json().invitaciones).toEqual([]);

    rosa = (await invitado('987000002')).persona;
    expect((await aceptarPrimera(rosa)).statusCode).toBe(200);
    carmen = (await invitado('987000005')).persona;
    expect((await aceptarPrimera(carmen)).statusCode).toBe(200);

    const equipo = (await pedir(lucho, 'GET', '/equipo')).json();
    expect(equipo.personas.map((p: { nombre: string | null; rol: string }) => [p.nombre, p.rol]))
      .toEqual([
        [null, 'dueno'],
        ['Pepe', 'ayudante'],
        ['Rosa', 'dueno'],
        ['Carmen', 'contador'],
      ]);
    expect(equipo.invitaciones).toEqual([]);
  });

  it('al ayudante le baja su caja, no Yape ni las cifras del negocio', async () => {
    const lo = await bajar(pepe);
    // Sin cajas asignadas, la suya es la principal (entrega 21).
    expect(lo.datos.membresia).toMatchObject({
      rol: 'ayudante',
      titular: false,
      cajas: [lucy.ids.efectivo],
    });
    expect(lo.datos.movimientos.map((m: { id: string }) => m.id)).toEqual([
      lucy.ids.ventaDelDueno,
    ]);
    const saldos = Object.fromEntries(
      lo.datos.cuentas.map((c: { id: string; saldo_inicial_centimos: number | null }) => [
        c.id,
        c.saldo_inicial_centimos,
      ]),
    );
    expect(saldos[lucy.ids.efectivo]).toBe(100000);
    expect(saldos[lucy.ids.yape]).toBeNull();
    expect(lo.datos.categorias).toHaveLength(1);
    expect(lo.cifras).toBeNull();
    // Los nombres de quienes anotan, para «Lo anotó Rosa» (entrega 20).
    expect(lo.datos.equipo.slice(0, 2)).toMatchObject([
      { usuario_id: lucho.usuarioId, nombre: null, rol: 'dueno', titular: true },
      { usuario_id: pepe.usuarioId, nombre: 'Pepe', rol: 'ayudante', titular: false },
    ]);
    expect(lo.datos.equipo[0]).not.toHaveProperty('celular');
    // Y el equipo, sin celulares.
    const equipo = (await pedir(pepe, 'GET', '/equipo')).json();
    expect(equipo.personas.every((p: { celular: string | null }) => p.celular === null)).toBe(true);
    expect(equipo.invitaciones).toEqual([]);
    // No invita.
    const r = await pedir(pepe, 'POST', '/equipo/invitar', { celular: '987000007', rol: 'ayudante' });
    expect(r.json()).toEqual({ error: 'sin_permiso' });
  });

  it('el ayudante anota lo suyo y solo deshace lo suyo del día', async () => {
    const { empresa, efectivo, venta, ventaDelDueno } = lucy.ids;
    const deHoy = randomUUID();
    const deAyer = randomUUID();
    const subida = (movimientos: object[], extra: object = {}) =>
      pedir(pepe, 'POST', '/datos/subir', {
        empresa: lucy.datos.empresa,
        movimientos,
        ...extra,
      });

    const nuevas = await subida([
      movimiento(deHoy, pepe.usuarioId, efectivo, venta),
      movimiento(deAyer, pepe.usuarioId, efectivo, venta, { creado_en: ayer }),
    ]);
    expect(nuevas.statusCode).toBe(200);
    // Lo nuevo lleva su nombre como autor.
    expect(
      (await subida([movimiento(randomUUID(), lucho.usuarioId, efectivo, venta)])).json(),
    ).toEqual({ error: 'autor_distinto' });
    // Deshacer lo suyo de hoy, sí; lo de ayer o lo del dueño, no.
    expect(
      (await subida([movimiento(deHoy, pepe.usuarioId, efectivo, venta, { estado: 'anulado' })]))
        .statusCode,
    ).toBe(200);
    expect(
      (
        await subida([
          movimiento(deAyer, pepe.usuarioId, efectivo, venta, {
            creado_en: ayer,
            estado: 'anulado',
          }),
        ])
      ).json(),
    ).toEqual({ error: 'sin_permiso' });
    expect(
      (
        await subida([
          movimiento(ventaDelDueno, lucho.usuarioId, efectivo, venta, { estado: 'anulado' }),
        ])
      ).json(),
    ).toEqual({ error: 'sin_permiso' });
    // Ni categorías nuevas ni cambiar la empresa.
    expect(
      (
        await subida([], {
          categorias: [
            { id: randomUUID(), nombre: 'Otros', tipo_movimiento: 'ingreso', orden: 1, activa: true },
          ],
        })
      ).json(),
    ).toEqual({ error: 'sin_permiso' });
    expect(
      (
        await pedir(pepe, 'POST', '/datos/subir', {
          empresa: { ...lucy.datos.empresa, nombre: 'Bodega de Pepe' },
        })
      ).json(),
    ).toEqual({ error: 'sin_permiso' });
    // Subir otra vez lo que ya bajó, igual, no cuenta como cambio.
    const lo = await bajar(pepe);
    const igual = await pedir(pepe, 'POST', '/datos/subir', {
      empresa: lo.datos.empresa,
      categorias: lo.datos.categorias,
    });
    expect(igual.statusCode).toBe(200);
    expect(lo.datos.movimientos.map((m: { id: string }) => m.id).sort()).toEqual(
      [deHoy, deAyer, ventaDelDueno].sort(),
    );
    expect(empresa).toBe(lo.datos.empresa.id);
  });

  it('cada teléfono baja solo lo nuevo de los demás, según su rol', async () => {
    const desdeLucho = (await bajar(lucho)).datos.hasta as number;
    const desdePepe = (await bajar(pepe)).datos.hasta as number;
    expect(desdeLucho).toBe(desdePepe);

    // Nada nuevo todavía.
    const nada = (await cambios(lucho, desdeLucho)).json();
    expect(nada).toMatchObject({ rol: 'dueno', hasta: desdeLucho, personas: 4 });
    expect(nada.movimientos).toBeUndefined();

    // Pepe anota una venta: Lucho la baja.
    const otra = randomUUID();
    await pedir(pepe, 'POST', '/datos/subir', {
      empresa: lucy.datos.empresa,
      movimientos: [movimiento(otra, pepe.usuarioId, lucy.ids.efectivo, lucy.ids.venta)],
    });
    const deLucho = (await cambios(lucho, desdeLucho)).json();
    expect(deLucho.movimientos.map((m: { id: string }) => m.id)).toEqual([otra]);
    expect(deLucho.hasta).toBeGreaterThan(desdeLucho);

    // Lucho corrige la venta de Pepe: Pepe ve su venta corregida...
    const corregida = await pedir(lucho, 'POST', '/datos/subir', {
      empresa: lucy.datos.empresa,
      movimientos: [
        movimiento(otra, pepe.usuarioId, lucy.ids.efectivo, lucy.ids.venta, {
          estado: 'anulado',
        }),
      ],
    });
    expect(corregida.statusCode).toBe(200);
    const dePepe = (await cambios(pepe, desdePepe)).json();
    expect(dePepe.movimientos.map((m: { id: string; estado: string }) => [m.id, m.estado]))
      .toEqual([[otra, 'anulado']]);
    // ...pero nunca lo de Yape, que no es su caja.
    const todoDePepe = (await cambios(pepe, 0)).json();
    expect(
      todoDePepe.movimientos.some((m: { id: string }) => m.id === lucy.ids.ventaPorYape),
    ).toBe(false);
    expect(todoDePepe.mis_cajas).toEqual([lucy.ids.efectivo]);

    expect((await cambios(lucho, -1)).statusCode).toBe(400);
  });

  it('con su propia caja, el ayudante ve y anota solo en ella (entrega 21)', async () => {
    // Lucho abre la «Caja delivery» y anota una venta en ella.
    const delivery = randomUUID();
    const enDelivery = randomUUID();
    const r = await pedir(lucho, 'POST', '/datos/subir', {
      empresa: lucy.datos.empresa,
      cuentas: [
        { id: delivery, tipo: 'caja2', nombre: 'Caja delivery', orden: 2, saldo_inicial_centimos: 20000 },
      ],
      movimientos: [movimiento(enDelivery, lucho.usuarioId, delivery, lucy.ids.venta)],
    });
    expect(r.statusCode).toBe(200);
    const equipo = (await pedir(lucho, 'GET', '/equipo')).json();
    const dePepe = equipo.personas.find((p: { nombre: string }) => p.nombre === 'Pepe');
    // Solo cajas de efectivo.
    expect(
      (
        await pedir(lucho, 'POST', '/equipo/cajas', {
          membresia: dePepe.membresia_id,
          cajas: [lucy.ids.yape],
        })
      ).statusCode,
    ).toBe(400);
    expect(
      (
        await pedir(lucho, 'POST', '/equipo/cajas', {
          membresia: dePepe.membresia_id,
          cajas: [delivery],
        })
      ).json(),
    ).toEqual({ cajas: [delivery] });
    // El ayudante no asigna cajas.
    expect(
      (
        await pedir(pepe, 'POST', '/equipo/cajas', {
          membresia: dePepe.membresia_id,
          cajas: [lucy.ids.efectivo],
        })
      ).json(),
    ).toEqual({ error: 'sin_permiso' });

    const lo = await bajar(pepe);
    expect(lo.datos.membresia.cajas).toEqual([delivery]);
    const ids = lo.datos.movimientos.map((m: { id: string }) => m.id);
    expect(ids).toContain(enDelivery);
    expect(ids).not.toContain(lucy.ids.ventaDelDueno);

    // Anota en su caja y en Yape, no en la caja principal.
    const anotar = (cuenta: string) =>
      pedir(pepe, 'POST', '/datos/subir', {
        empresa: lucy.datos.empresa,
        movimientos: [movimiento(randomUUID(), pepe.usuarioId, cuenta, lucy.ids.venta)],
      });
    expect((await anotar(delivery)).statusCode).toBe(200);
    expect((await anotar(lucy.ids.yape)).statusCode).toBe(200);
    expect((await anotar(lucy.ids.efectivo)).json()).toEqual({ error: 'sin_permiso' });
  });

  it('el ayudante pasa plata desde su caja, no desde la de otro (entrega 21.1)', async () => {
    const lo = await bajar(pepe);
    const delivery = lo.datos.membresia.cajas[0] as string;
    const pase = (id: string, de: string, a: string) => ({
      ...movimiento(id, pepe.usuarioId, de, lucy.ids.venta),
      tipo: 'transferencia',
      categoria_id: null,
      cuenta_destino_id: a,
    });
    const entrega = randomUUID();
    // Entrega lo de su caja a la principal del dueño.
    const r = await pedir(pepe, 'POST', '/datos/subir', {
      empresa: lucy.datos.empresa,
      movimientos: [pase(entrega, delivery, lucy.ids.efectivo)],
    });
    expect(r.statusCode).toBe(200);
    // Desde la caja principal, que no es suya, no.
    const ajena = await pedir(pepe, 'POST', '/datos/subir', {
      empresa: lucy.datos.empresa,
      movimientos: [pase(randomUUID(), lucy.ids.efectivo, delivery)],
    });
    expect(ajena.json()).toEqual({ error: 'sin_permiso' });
    // Un pase a la misma cuenta no vale.
    const mismo = await pedir(lucho, 'POST', '/datos/subir', {
      empresa: lucy.datos.empresa,
      movimientos: [{ ...pase(randomUUID(), delivery, delivery), autor_id: lucho.usuarioId }],
    });
    expect(mismo.statusCode).toBe(400);

    // El dueño lo ve: la plata cambia de caja, el total no.
    const deLucho = await bajar(lucho);
    expect(deLucho.datos.movimientos.some((m: { id: string }) => m.id === entrega)).toBe(true);
  });

  it('la otra dueña ve todo y corrige; solo el titular borra el negocio', async () => {
    const lo = await bajar(rosa);
    expect(lo.datos.membresia).toMatchObject({ rol: 'dueno', titular: false });
    expect(lo.cifras).not.toBeNull();
    expect(lo.datos.movimientos.length).toBeGreaterThan(1);

    const borrar = await pedir(rosa, 'POST', '/cuenta/borrar-datos', { confirmacion: 'BORRAR' });
    expect(borrar.json()).toEqual({ error: 'solo_titular' });
    // Su llave sigue valiendo.
    expect((await pedir(rosa, 'GET', '/equipo')).statusCode).toBe(200);
    // Y al titular nadie lo quita.
    const titular = (await pedir(rosa, 'GET', '/equipo')).json().personas[0];
    expect(
      (await pedir(rosa, 'POST', '/equipo/quitar', { membresia: titular.membresia_id })).json(),
    ).toEqual({ error: 'sin_persona' });
  });

  it('la contadora solo mira, y puede estar en varios negocios', async () => {
    const lo = await bajar(carmen);
    expect(lo.datos.membresia.rol).toBe('contador');
    expect(lo.cifras).not.toBeNull();
    const cambio = await pedir(carmen, 'POST', '/datos/subir', {
      empresa: lucy.datos.empresa,
      movimientos: [movimiento(randomUUID(), carmen.usuarioId, lucy.ids.efectivo, lucy.ids.venta)],
    });
    expect(cambio.json()).toEqual({ error: 'sin_permiso' });

    // Otro negocio la invita: entra a los dos.
    const marta = await dueno('987000011');
    const otro = negocio('Restaurante Marta', marta.usuarioId);
    await pedir(marta, 'POST', '/datos/subir', otro.datos);
    await pedir(marta, 'POST', '/equipo/invitar', { celular: '987000005', rol: 'contador' });
    expect((await aceptarPrimera(carmen)).statusCode).toBe(200);
    expect((await bajar(carmen, otro.ids.empresa)).datos.empresa.nombre).toBe('Restaurante Marta');
    expect((await bajar(carmen, lucy.ids.empresa)).datos.empresa.nombre).toBe('Bodega Don Lucho');
    // Sus negocios, para elegir cuál mirar (entrega 22).
    const { negocios } = (await pedir(carmen, 'GET', '/cuenta/negocios')).json();
    expect(negocios.map((n: { nombre: string; rol: string }) => [n.nombre, n.rol])).toEqual([
      ['Bodega Don Lucho', 'contador'],
      ['Restaurante Marta', 'contador'],
    ]);
    // Y lo nuevo de cada uno, aparte.
    const deMarta = (await pedir(carmen, 'GET', `/datos/cambios?desde=0&empresa=${otro.ids.empresa}`)).json();
    expect(deMarta.empresa_id).toBe(otro.ids.empresa);

    // Pepe, en cambio, ya tiene negocio.
    await pedir(marta, 'POST', '/equipo/invitar', { celular: '987000003', rol: 'ayudante' });
    expect((await aceptarPrimera(pepe)).json()).toEqual({ error: 'ya_tiene_negocio' });
  });

  it('una invitación vence a los 7 días y el dueño la puede anular', async () => {
    const r = await pedir(lucho, 'POST', '/equipo/invitar', {
      celular: '987000020',
      rol: 'contador',
    });
    const id = r.json().id as string;
    await base.poolAdmin.query(
      `UPDATE invitaciones SET creada_en = now() - interval '8 days' WHERE id = $1`,
      [id],
    );
    const tarde = await invitado('987000020');
    expect(tarde.respuesta.json()).toEqual({ error: 'sin_invitacion' });

    const otra = await pedir(lucho, 'POST', '/equipo/invitar', {
      celular: '987000021',
      rol: 'contador',
    });
    expect(
      (await pedir(lucho, 'POST', '/equipo/anular', { invitacion: otra.json().id })).json(),
    ).toEqual({ anulada: true });
    expect((await invitado('987000021')).respuesta.statusCode).toBe(404);
  });

  it('quitar a alguien no borra lo que anotó; su teléfono ya no entra', async () => {
    const equipo = (await pedir(lucho, 'GET', '/equipo')).json();
    const dePepe = equipo.personas.find((p: { nombre: string }) => p.nombre === 'Pepe');
    const r = await pedir(lucho, 'POST', '/equipo/quitar', { membresia: dePepe.membresia_id });
    expect(r.json()).toEqual({ quitada: true });

    expect((await cambios(pepe, 0)).json()).toEqual({ error: 'sin_negocio' });
    expect((await bajar(pepe)).datos).toBeNull();
    const subida = await pedir(pepe, 'POST', '/datos/subir', { empresa: lucy.datos.empresa });
    expect(subida.json()).toEqual({ error: 'no_es_tu_empresa' });
    // Lo que anotó se queda.
    const deLucho = await bajar(lucho);
    expect(
      deLucho.datos.movimientos.filter((m: { autor_id: string }) => m.autor_id === pepe.usuarioId),
    ).toHaveLength(6);
    // Y su lugar queda libre.
    const nueva = await pedir(lucho, 'POST', '/equipo/invitar', {
      celular: '987000004',
      rol: 'encargado',
    });
    expect(nueva.statusCode).toBe(200);
  });
});
