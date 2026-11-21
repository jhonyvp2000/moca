import { diaDe, enPeru, fechaLarga, type Fila, type Monto, soles, sumarPor } from './hechos.js';

// «Pregúntale a Moca» con fechas (entrega 89): las cifras de cualquier día o
// rango, calculadas aquí con las reglas del Historial y los informes. La IA
// solo dice qué fechas necesita; el servidor calcula.

const dia = 24 * 60 * 60 * 1000;
/** Un periodo de hasta un año. */
export const diasMaximos = 366;

export interface CifrasDelPeriodo {
  desde: string;
  hasta: string;
  /** Si el periodo empieza antes del primer registro: desde cuándo anota. */
  empezoAAnotar: string | null;
  /** Si el periodo llega más allá de hoy: hasta hoy. */
  soloHastaHoy: boolean;
  registros: number;
  /** Las ventas de esos días, cobradas o al fiado, por lo que se vendió. */
  vendiste: string;
  /** De eso, lo que no se cobró en el momento. */
  deEsoAlFiado: string;
  /** La plata que entró esos días: ventas cobradas y cobros de fiados. */
  teEntro: string;
  /** La plata que salió esos días: gastos y compras pagadas. */
  salio: string;
  retirasteParaTi: string;
  pusisteDeTuBolsillo: string;
  teEntroPorCuenta: Monto[];
  ventasPorCategoria: Monto[];
  gastosPorCategoria: Monto[];
  // Entrega 93: los fiados y las compras al crédito del periodo.
  /** De «te entró», lo que te pagaron de fiados (de ese u otros días). */
  tePagaronDeFiados: string;
  quienesTePagaron: Monto[];
  /** Las compras y gastos de esos días, pagados o no, por lo que costaron. */
  compraste: string;
  /** De eso, lo que no se pagó en el momento. */
  deEsoAlCredito: string;
  aQuienLeCompristeAlCredito: Monto[];
  /** De «salió», lo que pagaste de compras al crédito (de ese u otros días). */
  pagasteDeLoQueDebias: string;
  aQuienLePagaste: Monto[];
}

export type ErrorDePeriodo = 'fecha_invalida' | 'rango_al_reves' | 'rango_muy_largo' | 'en_el_futuro';

const fecha = /^\d{4}-\d{2}-\d{2}$/;

/** «2026-11-19» como día (UTC a medianoche); nulo si no es una fecha real. */
function leerDia(texto: unknown): number | null {
  if (typeof texto !== 'string' || !fecha.test(texto)) return null;
  const t = Date.parse(`${texto}T00:00:00Z`);
  if (Number.isNaN(t) || new Date(t).toISOString().slice(0, 10) !== texto) return null;
  return t;
}

export function cifrasDelPeriodo(
  datos: Fila,
  desdeTexto: unknown,
  hastaTexto: unknown,
  ahora: Date,
): CifrasDelPeriodo | { error: ErrorDePeriodo } {
  const desde = leerDia(desdeTexto);
  const hastaPedido = leerDia(hastaTexto);
  if (desde == null || hastaPedido == null) return { error: 'fecha_invalida' };
  if (hastaPedido < desde) return { error: 'rango_al_reves' };
  if ((hastaPedido - desde) / dia + 1 > diasMaximos) return { error: 'rango_muy_largo' };
  const hoy = diaDe(enPeru(ahora));
  if (desde > hoy) return { error: 'en_el_futuro' };
  const hasta = Math.min(hastaPedido, hoy);
  const dentro = (t: number) => t >= desde && t <= hasta;

  const filas = (k: string) => (datos[k] as Fila[] | undefined) ?? [];
  const cuentaDe = new Map(filas('cuentas').map((c) => [String(c.id), String(c.nombre)]));
  const categoriaDe = new Map(filas('categorias').map((c) => [String(c.id), String(c.nombre)]));
  const vigentes = filas('movimientos').filter((m) => m.estado === 'vigente');
  const monto = (m: Fila) => Number(m.monto_centimos);
  const pagado = (m: Fila) => m.estado_pago === 'pagado';
  // La plata se mueve el día del pago; lo vendido o comprado, el día de la
  // venta o la compra (como en el Historial).
  const diaPago = (m: Fila) => diaDe(enPeru(m.fecha_pago ?? m.fecha_movimiento));
  const diaAnotado = (m: Fila) => diaDe(enPeru(m.fecha_comprobante ?? m.fecha_movimiento));
  // Una deuda con partes se queda con lo que falta (entrega 44): lo vendido
  // es lo que falta más las partes.
  const partes = new Map<string, number>();
  for (const m of vigentes) {
    if (m.abona_a != null) partes.set(String(m.abona_a), (partes.get(String(m.abona_a)) ?? 0) + monto(m));
  }
  const original = (m: Fila) => monto(m) + (partes.get(String(m.id)) ?? 0);

  // Lo vendido o comprado esos días, y la parte que quedó debiéndose.
  const anotados = (tipo: string) =>
    vigentes.filter((m) => m.tipo === tipo && m.abona_a == null && dentro(diaAnotado(m)));
  const quedoDebiendo = (m: Fila) =>
    !pagado(m) || partes.has(String(m.id)) || diaPago(m) !== diaAnotado(m);
  const ventas = anotados('ingreso');
  const alFiado = ventas.filter(quedoDebiendo);
  const compras = anotados('egreso');
  const alCredito = compras.filter(quedoDebiendo);
  const movio = (tipo: string) =>
    vigentes.filter((m) => m.tipo === tipo && pagado(m) && dentro(diaPago(m)));
  const entro = movio('ingreso');
  const salio = movio('egreso');
  // Un pago de algo que se debía: una parte («Te pagó»), o la venta o
  // compra que se pagó otro día.
  const porId = new Map(vigentes.map((m) => [String(m.id), m]));
  const esPagoDeDeuda = (m: Fila) => m.abona_a != null || diaPago(m) !== diaAnotado(m);
  const contraparteDe = new Map(filas('contrapartes').map((c) => [String(c.id), String(c.nombre)]));
  const nombreDe = (m: Fila) => {
    const id = m.contraparte_id ?? porId.get(String(m.abona_a))?.contraparte_id;
    return (id != null && contraparteDe.get(String(id))) || 'Sin nombre';
  };
  const cobrosDeFiado = entro.filter(esPagoDeDeuda);
  const pagosDeDeuda = salio.filter(esPagoDeDeuda);
  const suma = (lista: Fila[], valor: (m: Fila) => number = monto) =>
    lista.reduce((s, m) => s + valor(m), 0);

  const primero = vigentes
    .map((m) => diaAnotado(m))
    .reduce<number | null>((a, t) => (a == null || t < a ? t : a), null);

  return {
    desde: fechaLarga(new Date(desde)),
    hasta: fechaLarga(new Date(hasta)),
    empezoAAnotar: primero != null && desde < primero ? fechaLarga(new Date(primero)) : null,
    soloHastaHoy: hastaPedido > hoy,
    registros: vigentes.filter((m) => dentro(diaAnotado(m))).length,
    vendiste: soles(suma(ventas, original)),
    deEsoAlFiado: soles(suma(alFiado, original)),
    teEntro: soles(suma(entro)),
    salio: soles(suma(salio)),
    retirasteParaTi: soles(suma(movio('retiro'))),
    pusisteDeTuBolsillo: soles(suma(movio('aporte'))),
    teEntroPorCuenta: sumarPor(entro.map((m) => [cuentaDe.get(String(m.cuenta_id)) ?? 'Otra cuenta', monto(m)])),
    ventasPorCategoria: sumarPor(
      ventas.map((m) => [categoriaDe.get(String(m.categoria_id)) ?? 'Sin categoría', original(m)]),
    ).slice(0, 5),
    gastosPorCategoria: sumarPor(
      salio.map((m) => [categoriaDe.get(String(m.categoria_id)) ?? 'Sin categoría', monto(m)]),
    ).slice(0, 5),
    tePagaronDeFiados: soles(suma(cobrosDeFiado)),
    quienesTePagaron: sumarPor(cobrosDeFiado.map((m) => [nombreDe(m), monto(m)])).slice(0, 5),
    compraste: soles(suma(compras, original)),
    deEsoAlCredito: soles(suma(alCredito, original)),
    aQuienLeCompristeAlCredito: sumarPor(alCredito.map((m) => [nombreDe(m), original(m)])).slice(0, 5),
    pagasteDeLoQueDebias: soles(suma(pagosDeDeuda)),
    aQuienLePagaste: sumarPor(pagosDeDeuda.map((m) => [nombreDe(m), monto(m)])).slice(0, 5),
  };
}
