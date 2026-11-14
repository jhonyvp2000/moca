import { precioDe, type Plan } from '../cobro/estado.js';
import { paquete } from './cliente.js';
import { maximoDeExtrasEnPlay } from './productos.js';

// Las 12 suscripciones de Moca en Google Play (entrega 81), armadas desde
// los mismos precios del servidor: nada se copia a mano en la consola.
// Solo para el Perú, en soles. Las crea `crear_suscripciones.ts`.

/** Un precio de Google: soles enteros y la parte decimal en nanos. */
export function precioDeGoogle(centimos: number) {
  return {
    currencyCode: 'PEN',
    units: String(Math.floor(centimos / 100)),
    nanos: (centimos % 100) * 10_000_000,
  };
}

const planBase = (id: string, plan: Plan, extras: number, periodo: 'P1M' | 'P1Y') => ({
  basePlanId: id,
  autoRenewingBasePlanType: {
    billingPeriodDuration: periodo,
    // Si la tarjeta falla: 7 días que sigue usando Moca, y 30 en espera.
    gracePeriodDuration: 'P7D',
    accountHoldDuration: 'P30D',
    resubscribeState: 'RESUBSCRIBE_STATE_ACTIVE',
    prorationMode: 'SUBSCRIPTION_PRORATION_MODE_CHARGE_ON_NEXT_BILLING_DATE',
    legacyCompatible: false,
  },
  regionalConfigs: [
    {
      regionCode: 'PE',
      newSubscriberAvailability: true,
      price: precioDeGoogle(precioDe(plan, extras)),
    },
  ],
});

const conPersonas = (extras: number) =>
  extras === 0 ? '' : ` + ${extras} ${extras === 1 ? 'persona' : 'personas'}`;

/** Una suscripción de Moca, como la pide la API (monetization.subscriptions). */
export function suscripcionDeMoca(nivel: 'full' | 'basico', extras: number) {
  const full = nivel === 'full';
  const personas = (full ? 3 : 1) + extras;
  return {
    packageName: paquete,
    productId: `${nivel}_${extras}`,
    listings: [
      {
        languageCode: 'es-419',
        title: `Moca ${full ? 'Full' : 'Básico'}${conPersonas(extras)}`,
        benefits: [
          'Tus cuentas, ventas y gastos al día',
          'Lo que te deben, sin olvidos',
          personas === 1 ? 'Para ti' : `Hasta ${personas} personas`,
          ...(full ? ['Flujo de caja para pedir un crédito'] : []),
        ],
        description: 'Tú vendes. Moca hace las cuentas.',
      },
    ],
    basePlans: [
      planBase('mes', full ? 'normal' : 'basico', extras, 'P1M'),
      planBase('anio', full ? 'anual' : 'basico_anual', extras, 'P1Y'),
      // El fundador: S/ 14.90 al mes para siempre (entrega 81).
      ...(full ? [planBase('fundador', 'fundador', extras, 'P1M')] : []),
    ],
  };
}

/** Las 12: full_0 a full_5 y basico_0 a basico_5. */
export function suscripcionesDeMoca() {
  const todas = [];
  for (const nivel of ['full', 'basico'] as const) {
    for (let extras = 0; extras <= maximoDeExtrasEnPlay; extras++) {
      todas.push(suscripcionDeMoca(nivel, extras));
    }
  }
  return todas;
}
