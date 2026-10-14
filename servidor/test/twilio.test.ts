import { describe, expect, it } from 'vitest';
import { leerConfigTwilio, verificadorTwilio } from '../src/cuenta/verificador.js';

const config = { cuenta: 'AC1', clave: 'secreta', servicio: 'VA1' };

/** Un fetch que responde siempre lo mismo y anota lo que se le pidió. */
function fetchFalso(estado: number, cuerpo: unknown = {}) {
  const pedidos: { url: string; init: RequestInit }[] = [];
  const pedir = (async (url: string, init: RequestInit) => {
    pedidos.push({ url, init });
    return new Response(JSON.stringify(cuerpo), { status: estado });
  }) as unknown as typeof fetch;
  return { pedir, pedidos };
}

describe('Twilio Verify', () => {
  it('pide el código por SMS al servicio configurado', async () => {
    const { pedir, pedidos } = fetchFalso(201, { status: 'pending' });
    expect(await verificadorTwilio(config, pedir).enviar('+51987654321')).toBe('enviado');
    expect(pedidos[0]!.url).toBe('https://verify.twilio.com/v2/Services/VA1/Verifications');
    expect(String(pedidos[0]!.init.body)).toBe('To=%2B51987654321&Channel=sms');
    expect((pedidos[0]!.init.headers as Record<string, string>).Authorization).toBe(
      'Basic ' + Buffer.from('AC1:secreta').toString('base64'),
    );
  });

  it('demasiados envíos al mismo número', async () => {
    const { pedir } = fetchFalso(429);
    expect(await verificadorTwilio(config, pedir).enviar('+51987654321')).toBe('demasiados');
  });

  it('traduce la respuesta de la comprobación', async () => {
    const casos: [number, unknown, string][] = [
      [200, { status: 'approved' }, 'aprobado'],
      [200, { status: 'pending' }, 'incorrecto'],
      [404, {}, 'vencido'],
      [429, {}, 'vencido'],
    ];
    for (const [estado, cuerpo, esperado] of casos) {
      const { pedir } = fetchFalso(estado, cuerpo);
      expect(await verificadorTwilio(config, pedir).comprobar('+51987654321', '123456')).toBe(
        esperado,
      );
    }
  });

  it('un error de Twilio no se toma como código aprobado', async () => {
    const { pedir } = fetchFalso(500);
    await expect(
      verificadorTwilio(config, pedir).comprobar('+51987654321', '123456'),
    ).rejects.toThrow(/Twilio/);
  });

  it('sin los tres datos no hay configuración', () => {
    expect(leerConfigTwilio({ TWILIO_ACCOUNT_SID: 'AC1' })).toBeNull();
    expect(
      leerConfigTwilio({
        TWILIO_ACCOUNT_SID: 'AC1',
        TWILIO_AUTH_TOKEN: 'x',
        TWILIO_VERIFY_SID: 'VA1',
      }),
    ).toEqual({ cuenta: 'AC1', clave: 'x', servicio: 'VA1' });
  });
});
