import { createVerify, generateKeyPairSync, randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { crearApp } from '../src/app.js';
import {
  type GooglePlay,
  googlePlayReal,
  leerCuentaDeServicio,
  type SuscripcionGoogle,
} from '../src/google/cliente.js';
import { planDelProducto, productoDelPlan } from '../src/google/productos.js';
import { crearBaseDePrueba, type BaseDePrueba } from './base_de_prueba.js';
import { negocio, type Persona } from './negocio_de_prueba.js';
import { verificadorFalso } from './verificador_falso.js';

/** Google Play de mentira: las compras que «existen» y las reconocidas. */
function googleFalso() {
  const compras = new Map<string, SuscripcionGoogle>();
  const reconocidas: string[] = [];
  let caido = false;
  const google: GooglePlay = {
    async suscripcion(token) {
      if (caido) throw new Error('Google no responde');
      const c = compras.get(token);
      if (!c) throw new Error('no existe');
      return c;
    },
    async reconocer(producto, token) {
      reconocidas.push(`${producto}:${token}`);
      const c = compras.get(token);
      if (c) c.acknowledgementState = 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED';
    },
  };
  return {
    google,
    compras,
    reconocidas,
    caer: (si: boolean) => {
      caido = si;
    },
  };
}

const suscripcion = (
  empresa: string,
  datos: {
    producto?: string;
    planBase?: string;
    oferta?: string;
    orden?: string;
    vence?: string;
    estado?: string;
  } = {},
): SuscripcionGoogle => ({
  subscriptionState: datos.estado ?? 'SUBSCRIPTION_STATE_ACTIVE',
  acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING',
  latestOrderId: datos.orden ?? 'GPA.0000-0000-0000-00001',
  externalAccountIdentifiers: { obfuscatedExternalAccountId: empresa },
  lineItems: [
    {
      productId: datos.producto ?? 'full_0',
      expiryTime: datos.vence ?? '2026-12-20T15:00:00Z',
      offerDetails: {
        basePlanId: datos.planBase ?? 'mes',
        ...(datos.oferta ? { offerId: datos.oferta } : {}),
      },
    },
  ],
});

describe('Los productos de Google Play (entrega 78)', () => {
  it('Cada producto es un plan con sus personas extra', () => {
    expect(planDelProducto('full_0', 'mes', undefined)).toEqual({ plan: 'normal', extras: 0 });
    expect(planDelProducto('full_2', 'anio', undefined)).toEqual({ plan: 'anual', extras: 2 });
    expect(planDelProducto('full_0', 'mes', 'fundador')).toEqual({ plan: 'fundador', extras: 0 });
    expect(planDelProducto('basico_1', 'mes', undefined)).toEqual({ plan: 'basico', extras: 1 });
    expect(planDelProducto('basico_0', 'anio', undefined)).toEqual({
      plan: 'basico_anual',
      extras: 0,
    });
    // Lo que no es de Moca, no.
    expect(planDelProducto('full_6', 'mes', undefined)).toBeNull();
    expect(planDelProducto('oro_0', 'mes', undefined)).toBeNull();
    expect(planDelProducto('full_0', 'semana', undefined)).toBeNull();
    // Ida y vuelta.
    expect(productoDelPlan('fundador', 0)).toEqual({
      producto: 'full_0',
      planBase: 'mes',
      oferta: 'fundador',
    });
    expect(productoDelPlan('basico_anual', 3)).toEqual({ producto: 'basico_3', planBase: 'anio' });
    expect(productoDelPlan('normal', 6)).toBeNull();
  });

  it('La cuenta de servicio sale de GOOGLE_PLAY_CUENTA_SERVICIO', () => {
    expect(leerCuentaDeServicio({})).toBeNull();
    expect(leerCuentaDeServicio({ GOOGLE_PLAY_CUENTA_SERVICIO: 'no es json' })).toBeNull();
    expect(leerCuentaDeServicio({ GOOGLE_PLAY_CUENTA_SERVICIO: '{"client_email":"x"}' })).toBeNull();
    const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
    const pem = privateKey.export({ type: 'pkcs8', format: 'pem' }).toString();
    expect(
      leerCuentaDeServicio({
        GOOGLE_PLAY_CUENTA_SERVICIO: JSON.stringify({
          type: 'service_account',
          client_email: 'moca@proyecto.iam.gserviceaccount.com',
          private_key: pem,
        }),
      }),
    ).toEqual({ client_email: 'moca@proyecto.iam.gserviceaccount.com', private_key: pem });
  });
});

describe('El cliente de Google Play (entrega 78)', () => {
  it('Se identifica con un JWT firmado por la cuenta de servicio y pregunta por la compra', async () => {
    const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
    const pem = privateKey.export({ type: 'pkcs8', format: 'pem' }).toString();
    const llamadas: { url: string; init?: RequestInit }[] = [];
    vi.stubGlobal('fetch', async (url: string, init?: RequestInit) => {
      llamadas.push({ url, ...(init ? { init } : {}) });
      if (url === 'https://oauth2.googleapis.com/token') {
        return new Response(JSON.stringify({ access_token: 'acceso-1', expires_in: 3600 }));
      }
      if (url.endsWith(':acknowledge')) return new Response('{}');
      return new Response(JSON.stringify({ subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE' }));
    });
    try {
      const google = googlePlayReal({ client_email: 'moca@p.iam.gserviceaccount.com', private_key: pem });
      expect((await google.suscripcion('tok/1')).subscriptionState).toBe('SUBSCRIPTION_STATE_ACTIVE');
      await google.reconocer('full_0', 'tok/1');
      // Un solo pedido de acceso: el segundo usa el mismo.
      expect(llamadas.map((l) => l.url)).toEqual([
        'https://oauth2.googleapis.com/token',
        'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/pe.moca.app/purchases/subscriptionsv2/tokens/tok%2F1',
        'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/pe.moca.app/purchases/subscriptions/full_0/tokens/tok%2F1:acknowledge',
      ]);
      expect(llamadas[1]!.init?.headers).toEqual({ authorization: 'Bearer acceso-1' });
      expect(llamadas[2]!.init?.method).toBe('POST');
      // El JWT: firmado con la llave, para la API de Play, por una hora.
      const assertion = new URLSearchParams(String(llamadas[0]!.init?.body)).get('assertion')!;
      const [cabecera, cuerpo, firma] = assertion.split('.');
      expect(
        createVerify('RSA-SHA256')
          .update(`${cabecera}.${cuerpo}`)
          .verify(publicKey, Buffer.from(firma!, 'base64url')),
      ).toBe(true);
      const claims = JSON.parse(Buffer.from(cuerpo!, 'base64url').toString());
      expect(claims).toMatchObject({
        iss: 'moca@p.iam.gserviceaccount.com',
        scope: 'https://www.googleapis.com/auth/androidpublisher',
        aud: 'https://oauth2.googleapis.com/token',
      });
      expect(claims.exp - claims.iat).toBe(3600);
    } finally {
      vi.unstubAllGlobals();
    }
  });
});

describe('Pagar Moca con Google Play (entrega 78)', () => {
  let base: BaseDePrueba;
  let app: FastifyInstance;
  const ahora = new Date('2026-11-20T15:00:00Z');
  const falso = googleFalso();
  let lucho: Persona;
  let rosa: Persona;
  let empresaDeLucho: string;
  let empresaDeRosa: string;

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
  const comprar = (persona: Persona, token: string) =>
    pedir(persona, 'POST', '/cobro/google', { token });
  const pagosDe = async (empresa: string) =>
    (
      await base.poolAdmin.query(
        `SELECT plan, personas_extra, desde::text, hasta::text, origen, google_orden
           FROM pagos WHERE empresa_id = $1 ORDER BY creado_en`,
        [empresa],
      )
    ).rows;
  const compra = async (token: string) =>
    (await base.poolAdmin.query('SELECT * FROM compras_google WHERE token = $1', [token])).rows[0];

  beforeAll(async () => {
    base = await crearBaseDePrueba();
    app = crearApp({
      pool: base.pool,
      version: 'prueba',
      verificador: verificadorFalso(),
      ahora: () => ahora,
      cobro: { desde: '2026-11-10', admins: ['900000000'], yape: null },
      googlePlay: falso.google,
    });
    lucho = await verificar('987000011');
    const datos = negocio('Bodega Don Lucho', lucho.usuarioId, '2026-11-12T14:00:00.000Z');
    empresaDeLucho = datos.empresa.id;
    expect((await pedir(lucho, 'POST', '/datos/subir', datos)).statusCode).toBe(200);
    rosa = await verificar('987000012');
    const deRosa = negocio('Puesto de Rosa', rosa.usuarioId, '2026-11-12T14:00:00.000Z');
    empresaDeRosa = deRosa.empresa.id;
    expect((await pedir(rosa, 'POST', '/datos/subir', deRosa)).statusCode).toBe(200);
  });
  afterAll(() => base.cerrar());

  it('El teléfono sabe que puede pagar con Google Play', async () => {
    const cobro = (await pedir(lucho, 'GET', '/datos/bajar')).json().cobro;
    expect(cobro).toMatchObject({ estado: 'prueba', google_play: true });
    expect(cobro.mercadopago).toBeUndefined();
  });

  it('Una compra válida: se registra hasta el día en que vence y se reconoce, una sola vez', async () => {
    falso.compras.set('token-lucho-1', suscripcion(empresaDeLucho, { producto: 'full_1' }));
    const r = await comprar(lucho, 'token-lucho-1');
    expect(r.statusCode).toBe(200);
    expect(r.json().resultado).toBe('procesada');
    expect(r.json().cobro).toMatchObject({ estado: 'pagado', hasta: '2026-12-20' });
    expect(await pagosDe(empresaDeLucho)).toEqual([
      {
        plan: 'normal',
        personas_extra: 1,
        desde: '2026-11-20',
        hasta: '2026-12-20',
        origen: 'google',
        google_orden: 'GPA.0000-0000-0000-00001',
      },
    ]);
    expect(falso.reconocidas).toEqual(['full_1:token-lucho-1']);
    expect(await compra('token-lucho-1')).toMatchObject({
      empresa_id: empresaDeLucho,
      producto: 'full_1',
      plan_base: 'mes',
      motivo: null,
    });
    // Mandarla otra vez (la app reintenta) no suma otro pago ni otro reconocimiento.
    const otra = await comprar(lucho, 'token-lucho-1');
    expect(otra.json().resultado).toBe('ya_estaba');
    expect(await pagosDe(empresaDeLucho)).toHaveLength(1);
    expect(falso.reconocidas).toHaveLength(1);
    // En «Mis pagos» sale como de Google.
    const mis = (await pedir(lucho, 'GET', '/cobro/mis-pagos')).json();
    expect(mis.pagos[0]).toMatchObject({ medio: 'google', personas_extra: 1 });
  });

  it('La compra de un negocio no sirve para otro', async () => {
    // Rosa manda la compra que ya es de Lucho.
    expect((await comprar(rosa, 'token-lucho-1')).statusCode).toBe(409);
    // Una compra hecha para el negocio de Lucho, mandada desde el de Rosa.
    falso.compras.set('token-cruzado', suscripcion(empresaDeLucho, { orden: 'GPA.cruzado' }));
    const r = await comprar(rosa, 'token-cruzado');
    expect(r.statusCode).toBe(409);
    expect(r.json().error).toBe('otro_negocio');
    expect(await pagosDe(empresaDeRosa)).toEqual([]);
    // No se reconoce: Google la devuelve sola.
    expect(falso.reconocidas).not.toContain('full_0:token-cruzado');
    expect(await compra('token-cruzado')).toMatchObject({ motivo: 'otro_negocio' });
  });

  it('Ni vencida, ni pendiente, ni de un producto que no es de Moca', async () => {
    falso.compras.set(
      'token-vencida',
      suscripcion(empresaDeRosa, {
        orden: 'GPA.vencida',
        estado: 'SUBSCRIPTION_STATE_EXPIRED',
        vence: '2026-11-01T00:00:00Z',
      }),
    );
    expect((await comprar(rosa, 'token-vencida')).json().error).toBe('no_vigente');
    falso.compras.set(
      'token-pendiente',
      suscripcion(empresaDeRosa, { orden: 'GPA.pend', estado: 'SUBSCRIPTION_STATE_PENDING' }),
    );
    expect((await comprar(rosa, 'token-pendiente')).json().error).toBe('no_vigente');
    falso.compras.set(
      'token-raro',
      suscripcion(empresaDeRosa, { orden: 'GPA.raro', producto: 'oro_0' }),
    );
    expect((await comprar(rosa, 'token-raro')).json().error).toBe('producto_desconocido');
    expect(await pagosDe(empresaDeRosa)).toEqual([]);
  });

  it('Solo un dueño con sesión; sin Google, 503; Google caído, 502', async () => {
    expect(
      (await app.inject({ method: 'POST', url: '/cobro/google', payload: { token: 'x'.repeat(20) } }))
        .statusCode,
    ).toBe(401);
    expect((await pedir(lucho, 'POST', '/cobro/google', { token: 1 })).statusCode).toBe(400);
    falso.caer(true);
    falso.compras.set('token-rosa', suscripcion(empresaDeRosa, { orden: 'GPA.rosa' }));
    expect((await comprar(rosa, 'token-rosa')).statusCode).toBe(502);
    falso.caer(false);
    // Al volver Google, la misma compra se aplica.
    expect((await comprar(rosa, 'token-rosa')).json().resultado).toBe('procesada');
    const sinGoogle = crearApp({ pool: base.pool, version: 'prueba', ahora: () => ahora });
    const r = await sinGoogle.inject({
      method: 'POST',
      url: '/cobro/google',
      headers: { authorization: `Bearer ${lucho.llave}` },
      payload: { token: 'token-lucho-1' },
    });
    expect(r.statusCode).toBe(503);
    await sinGoogle.close();
  });

  it('Un pago de Google no acorta lo ya pagado', async () => {
    // Lucho ya tiene hasta el 20-12; una compra anual de prueba vence antes de eso no la acorta.
    falso.compras.set(
      'token-lucho-2',
      suscripcion(empresaDeLucho, {
        orden: 'GPA.corta',
        vence: '2026-12-01T15:00:00Z',
      }),
    );
    expect((await comprar(lucho, 'token-lucho-2')).json().cobro).toMatchObject({
      hasta: '2026-12-20',
    });
  });
});
