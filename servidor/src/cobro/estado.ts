// El estado del cobro de un negocio (entrega 24; decisiones.md, 03-11-2026).
// Todo con fechas de Lima, como texto «2026-11-03».

export type Plan = 'normal' | 'fundador' | 'anual';

export const diasDePrueba = 14;
export const avisoAntesDe = 3;
export const maximoDeFundadores = 50;
/** Quien renueva hasta 30 días después de vencer conserva el fundador. */
export const graciaFundador = 30;

export const precios: Record<Plan, number> = {
  normal: 1990,
  fundador: 1490,
  anual: 19900,
};

export interface EstadoCobro {
  /** Sin MOCA_COBRO_DESDE el cobro no ha empezado: todo sigue abierto. */
  estado: 'sin_cobro' | 'prueba' | 'pagado' | 'vencido';
  /** El último día de la prueba o de lo pagado; nulo si la prueba no empezó. */
  hasta: string | null;
  /** Días que quedan después de hoy (0: hoy es el último). */
  dias: number | null;
  porVencer: boolean;
  plan: Plan | null;
  /** Lo que se cobraría ahora, en céntimos. */
  precio: number;
}

export function sumarDias(dia: string, dias: number): string {
  const fecha = new Date(`${dia}T00:00:00Z`);
  fecha.setUTCDate(fecha.getUTCDate() + dias);
  return fecha.toISOString().slice(0, 10);
}

/** «2026-01-31» + 1 mes = «2026-02-28»: el día se ajusta al mes. */
export function sumarMeses(dia: string, meses: number): string {
  const [a, m, d] = dia.split('-').map(Number) as [number, number, number];
  const destino = new Date(Date.UTC(a, m - 1 + meses, 1));
  const ultimo = new Date(
    Date.UTC(destino.getUTCFullYear(), destino.getUTCMonth() + 1, 0),
  ).getUTCDate();
  destino.setUTCDate(Math.min(d, ultimo));
  return destino.toISOString().slice(0, 10);
}

export function diasEntre(desde: string, hasta: string): number {
  return Math.round(
    (Date.parse(`${hasta}T00:00:00Z`) - Date.parse(`${desde}T00:00:00Z`)) / 86_400_000,
  );
}

export const diaEnLima = (fecha: Date): string =>
  new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Lima' }).format(fecha);

/** Si el negocio puede pagar como fundador hoy. */
export function puedeSerFundador({
  hoy,
  suscripcion,
  fundadores,
}: {
  hoy: string;
  suscripcion: { plan: Plan; pagadoHasta: string; fueFundador: boolean } | null;
  fundadores: number;
}): boolean {
  if (suscripcion?.fueFundador) {
    // Lo conserva si renueva a tiempo; si se le pasó, vuelve a S/ 19.90.
    return (
      suscripcion.plan === 'fundador' && diasEntre(suscripcion.pagadoHasta, hoy) <= graciaFundador
    );
  }
  return fundadores < maximoDeFundadores;
}

export function estadoDelCobro({
  hoy,
  cobroDesde,
  inicioPrueba,
  suscripcion,
  fundadores,
}: {
  hoy: string;
  cobroDesde: string | null;
  /** El día de su primer registro, o el que quedó para su número. */
  inicioPrueba: string | null;
  suscripcion: { plan: Plan; pagadoHasta: string; fueFundador: boolean } | null;
  fundadores: number;
}): EstadoCobro {
  const precio = puedeSerFundador({ hoy, suscripcion, fundadores })
    ? precios.fundador
    : precios.normal;
  const base = { porVencer: false, plan: suscripcion?.plan ?? null, precio };
  if (!cobroDesde) return { ...base, estado: 'sin_cobro', hasta: null, dias: null };

  if (suscripcion) {
    const dias = diasEntre(hoy, suscripcion.pagadoHasta);
    return dias >= 0
      ? {
          ...base,
          estado: 'pagado',
          hasta: suscripcion.pagadoHasta,
          dias,
          porVencer: dias <= avisoAntesDe,
        }
      : {
          ...base,
          estado: 'vencido',
          hasta: suscripcion.pagadoHasta,
          dias: null,
        };
  }

  // Nadie pierde la prueba por haber empezado antes del cobro.
  if (!inicioPrueba) return { ...base, estado: 'prueba', hasta: null, dias: diasDePrueba };
  const inicio = inicioPrueba > cobroDesde ? inicioPrueba : cobroDesde;
  const hasta = sumarDias(inicio, diasDePrueba - 1);
  const dias = diasEntre(hoy, hasta);
  return dias >= 0
    ? {
        ...base,
        estado: 'prueba',
        hasta,
        dias,
        porVencer: dias <= avisoAntesDe,
      }
    : { ...base, estado: 'vencido', hasta, dias: null };
}

/** El periodo que paga un pago nuevo: sigue al anterior si no venció. */
export function periodoDelPago({
  hoy,
  pagadoHasta,
  plan,
}: {
  hoy: string;
  pagadoHasta: string | null;
  plan: Plan;
}): { desde: string; hasta: string } {
  const desde = pagadoHasta && pagadoHasta >= hoy ? sumarDias(pagadoHasta, 1) : hoy;
  return {
    desde,
    hasta: sumarDias(sumarMeses(desde, plan === 'anual' ? 12 : 1), -1),
  };
}
