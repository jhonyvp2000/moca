import { type Plan } from '../cobro/estado.js';

// Las suscripciones de Moca en la Play Console (entrega 78). Google no deja
// sumarle un monto por persona a una suscripción, así que cada plan con sus
// personas extra es un producto, con sus planes base:
//   full_0 … full_5      el Full con 0 a 5 personas extra
//   basico_0 … basico_5  el Básico con 0 a 5 personas extra
//   planes base «mes» y «anio»; en full_N, también «fundador» (S/ 14.90 al
//   mes para siempre: una oferta de Google dura un tiempo y vuelve al
//   precio normal, un plan base no)
// Con más de 5 personas extra, se arregla por WhatsApp.

export const maximoDeExtrasEnPlay = 5;

export interface ProductoGoogle {
  plan: Plan;
  extras: number;
}

/** El plan de Moca de un producto de Google; nulo si no es uno de Moca. */
export function planDelProducto(
  producto: string,
  planBase: string | undefined,
): ProductoGoogle | null {
  const m = /^(full|basico)_([0-9])$/.exec(producto);
  if (!m) return null;
  const extras = Number(m[2]);
  if (extras > maximoDeExtrasEnPlay) return null;
  const basico = m[1] === 'basico';
  switch (planBase) {
    case 'mes':
      return { plan: basico ? 'basico' : 'normal', extras };
    case 'anio':
      return { plan: basico ? 'basico_anual' : 'anual', extras };
    case 'fundador':
      return basico ? null : { plan: 'fundador', extras };
    default:
      return null;
  }
}

/** El producto de Google de un plan de Moca (para la app, entrega 80). */
export function productoDelPlan(
  plan: Plan,
  extras: number,
): { producto: string; planBase: 'mes' | 'anio' | 'fundador' } | null {
  if (extras < 0 || extras > maximoDeExtrasEnPlay) return null;
  const nivel = plan === 'basico' || plan === 'basico_anual' ? 'basico' : 'full';
  const planBase =
    plan === 'fundador' ? 'fundador' : plan === 'anual' || plan === 'basico_anual' ? 'anio' : 'mes';
  return { producto: `${nivel}_${extras}`, planBase };
}
