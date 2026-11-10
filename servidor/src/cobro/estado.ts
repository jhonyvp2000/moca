// El estado del cobro de un negocio (entrega 24; decisiones.md, 03-11-2026).
// Todo con fechas de Lima, como texto «2026-11-03».

/**
 * Los planes (entrega 43; decisiones.md, 09-11-2026): «basico» es el Básico
 * (1 persona, sin «Para pedir un crédito»); los otros tres son el Full (3
 * personas, con crédito): al mes, de fundador o al año.
 */
export type Plan = 'basico' | 'normal' | 'fundador' | 'anual';

/** Lo que el dueño elige: el Básico o el Full. */
export type Nivel = 'basico' | 'full';

export const diasDePrueba = 14;
export const avisoAntesDe = 3;
export const maximoDeFundadores = 50;
/** Quien renueva hasta 30 días después de vencer conserva el fundador. */
export const graciaFundador = 30;

export const precios: Record<Plan, number> = {
  basico: 1490,
  normal: 1990,
  fundador: 1490,
  anual: 19900,
};

/** Cada persona más: S/ 2.90 al mes, S/ 34.80 al año. */
export const precioPersonaExtra = 290;
export const precioPersonaExtraAnual = 3480;

/** Personas que incluye el plan, con el titular; el contador no cuenta. */
export const personasIncluidas = (plan: Plan): number => (plan === 'basico' ? 1 : 3);

export const nivelDe = (plan: Plan | null | undefined): Nivel =>
  plan === 'basico' ? 'basico' : 'full';

/** Las personas por encima de las que incluye el plan. */
export const extrasPara = (plan: Plan, personas: number): number =>
  Math.max(0, personas - personasIncluidas(plan));

/** Lo que cuesta el plan con sus personas extra, en céntimos. */
export const precioDe = (plan: Plan, extras: number): number =>
  precios[plan] + extras * (plan === 'anual' ? precioPersonaExtraAnual : precioPersonaExtra);

/** Lo que pagaría con un plan: el monto y cuántas personas extra lleva. */
export interface OpcionDePlan {
  plan: Plan;
  precio: number;
  extras: number;
}

export interface EstadoCobro {
  /** Sin MOCA_COBRO_DESDE el cobro no ha empezado: todo sigue abierto. */
  estado: 'sin_cobro' | 'prueba' | 'pagado' | 'vencido';
  /** El último día de la prueba o de lo pagado; nulo si la prueba no empezó. */
  hasta: string | null;
  /** Días que quedan después de hoy (0: hoy es el último). */
  dias: number | null;
  porVencer: boolean;
  plan: Plan | null;
  /** Lo que se cobraría ahora por el Full, con sus personas extra. */
  precio: number;
  /** El plan que tiene ahora: Full en la prueba y sin pagos (entrega 43). */
  nivel: Nivel;
  /** Personas del negocio sin el contador, y las que incluye su plan. */
  personas: number;
  incluidas: number;
  /** Puede armar «Para pedir un crédito»: solo el Full. */
  credito: boolean;
  /** Lo que pagaría con cada plan. Al fundador no se le ofrece el Básico. */
  opciones: { full: OpcionDePlan; basico?: OpcionDePlan };
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
  personas = 1,
  diasExtra = 0,
}: {
  hoy: string;
  cobroDesde: string | null;
  /** El día de su primer registro, o el que quedó para su número. */
  inicioPrueba: string | null;
  suscripcion: { plan: Plan; pagadoHasta: string; fueFundador: boolean } | null;
  fundadores: number;
  /** Personas del negocio sin el contador. */
  personas?: number;
  /** Días de prueba que regaló Jhony desde soporte (entrega 47). */
  diasExtra?: number;
}): EstadoCobro {
  const fundador = puedeSerFundador({ hoy, suscripcion, fundadores });
  const opcion = (plan: Plan): OpcionDePlan => {
    const extras = extrasPara(plan, personas);
    return { plan, precio: precioDe(plan, extras), extras };
  };
  const full = opcion(fundador ? 'fundador' : 'normal');
  const nivel = nivelDe(suscripcion?.plan);
  const base = {
    porVencer: false,
    plan: suscripcion?.plan ?? null,
    precio: full.precio,
    nivel,
    personas,
    incluidas: personasIncluidas(nivel === 'basico' ? 'basico' : 'normal'),
    credito: nivel === 'full',
    // El Básico cuesta lo mismo que el Full del fundador: no se le ofrece.
    opciones: fundador ? { full } : { full, basico: opcion('basico') },
  };
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
  if (!inicioPrueba) {
    return { ...base, estado: 'prueba', hasta: null, dias: diasDePrueba + diasExtra };
  }
  const inicio = inicioPrueba > cobroDesde ? inicioPrueba : cobroDesde;
  const hasta = sumarDias(inicio, diasDePrueba + diasExtra - 1);
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
