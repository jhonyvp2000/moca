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
  // Entrega 94: a quién se le vendió y a quién se le compró esos días.
  ventasPorCliente: Monto[];
  comprasPorProveedor: Monto[];
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

/** Las fechas pedidas, ya revisadas: el final se recorta a hoy. */
function leerRango(
  desdeTexto: unknown,
  hastaTexto: unknown,
  ahora: Date,
): { desde: number; hasta: number; recortado: boolean } | { error: ErrorDePeriodo } {
  const desde = leerDia(desdeTexto);
  const hastaPedido = leerDia(hastaTexto);
  if (desde == null || hastaPedido == null) return { error: 'fecha_invalida' };
  if (hastaPedido < desde) return { error: 'rango_al_reves' };
  if ((hastaPedido - desde) / dia + 1 > diasMaximos) return { error: 'rango_muy_largo' };
  const hoy = diaDe(enPeru(ahora));
  if (desde > hoy) return { error: 'en_el_futuro' };
  return { desde, hasta: Math.min(hastaPedido, hoy), recortado: hastaPedido > hoy };
}

/** Los registros de un periodo, separados como en el Historial. */
function delPeriodo(datos: Fila, desde: number, hasta: number) {
  const dentro = (t: number) => t >= desde && t <= hasta;
  const filas = (k: string) => (datos[k] as Fila[] | undefined) ?? [];
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
  const movio = (tipo: string) =>
    vigentes.filter((m) => m.tipo === tipo && pagado(m) && dentro(diaPago(m)));
  const ventas = anotados('ingreso');
  const compras = anotados('egreso');
  const entro = movio('ingreso');
  const salio = movio('egreso');
  // Un pago de algo que se debía: una parte («Te pagó»), o la venta o
  // compra que se pagó otro día.
  const porId = new Map(vigentes.map((m) => [String(m.id), m]));
  const esPagoDeDeuda = (m: Fila) => m.abona_a != null || diaPago(m) !== diaAnotado(m);
  const contraparteDe = new Map(filas('contrapartes').map((c) => [String(c.id), String(c.nombre)]));
  /** El cliente o proveedor de un registro; el de la deuda, si es una parte. */
  const contraparteId = (m: Fila) => {
    const id = m.contraparte_id ?? porId.get(String(m.abona_a))?.contraparte_id;
    return id == null ? null : String(id);
  };
  const nombreDe = (m: Fila) => contraparteDe.get(contraparteId(m) ?? '') ?? 'Sin nombre';
  const suma = (lista: Fila[], valor: (m: Fila) => number = monto) =>
    lista.reduce((s, m) => s + valor(m), 0);
  const primero = vigentes
    .map((m) => diaAnotado(m))
    .reduce<number | null>((a, t) => (a == null || t < a ? t : a), null);

  return {
    filas,
    vigentes,
    dentro,
    diaAnotado,
    monto,
    original,
    suma,
    nombreDe,
    contraparteId,
    primero,
    ventas,
    alFiado: ventas.filter(quedoDebiendo),
    compras,
    alCredito: compras.filter(quedoDebiendo),
    entro,
    salio,
    retiros: movio('retiro'),
    aportes: movio('aporte'),
    cobrosDeFiado: entro.filter(esPagoDeDeuda),
    pagosDeDeuda: salio.filter(esPagoDeDeuda),
  };
}

type Periodo = ReturnType<typeof delPeriodo>;

/** Las sumas de un periodo, en céntimos, para compararlas. */
function totales(p: Periodo) {
  return {
    vendiste: p.suma(p.ventas, p.original),
    deEsoAlFiado: p.suma(p.alFiado, p.original),
    teEntro: p.suma(p.entro),
    salio: p.suma(p.salio),
    compraste: p.suma(p.compras, p.original),
    deEsoAlCredito: p.suma(p.alCredito, p.original),
    tePagaronDeFiados: p.suma(p.cobrosDeFiado),
    pagasteDeLoQueDebias: p.suma(p.pagosDeDeuda),
    retirasteParaTi: p.suma(p.retiros),
    pusisteDeTuBolsillo: p.suma(p.aportes),
  };
}

const conNombre = (pares: [string, number][]) => pares.filter(([n]) => n !== 'Sin nombre');

export function cifrasDelPeriodo(
  datos: Fila,
  desdeTexto: unknown,
  hastaTexto: unknown,
  ahora: Date,
): CifrasDelPeriodo | { error: ErrorDePeriodo } {
  const rango = leerRango(desdeTexto, hastaTexto, ahora);
  if ('error' in rango) return rango;
  const { desde, hasta } = rango;
  const p = delPeriodo(datos, desde, hasta);
  const t = totales(p);
  const cuentaDe = new Map(p.filas('cuentas').map((c) => [String(c.id), String(c.nombre)]));
  const categoriaDe = new Map(p.filas('categorias').map((c) => [String(c.id), String(c.nombre)]));

  return {
    desde: fechaLarga(new Date(desde)),
    hasta: fechaLarga(new Date(hasta)),
    empezoAAnotar: p.primero != null && desde < p.primero ? fechaLarga(new Date(p.primero)) : null,
    soloHastaHoy: rango.recortado,
    registros: p.vigentes.filter((m) => p.dentro(p.diaAnotado(m))).length,
    vendiste: soles(t.vendiste),
    deEsoAlFiado: soles(t.deEsoAlFiado),
    teEntro: soles(t.teEntro),
    salio: soles(t.salio),
    retirasteParaTi: soles(t.retirasteParaTi),
    pusisteDeTuBolsillo: soles(t.pusisteDeTuBolsillo),
    teEntroPorCuenta: sumarPor(p.entro.map((m) => [cuentaDe.get(String(m.cuenta_id)) ?? 'Otra cuenta', p.monto(m)])),
    ventasPorCategoria: sumarPor(
      p.ventas.map((m) => [categoriaDe.get(String(m.categoria_id)) ?? 'Sin categoría', p.original(m)]),
    ).slice(0, 5),
    gastosPorCategoria: sumarPor(
      p.salio.map((m) => [categoriaDe.get(String(m.categoria_id)) ?? 'Sin categoría', p.monto(m)]),
    ).slice(0, 5),
    tePagaronDeFiados: soles(t.tePagaronDeFiados),
    quienesTePagaron: sumarPor(p.cobrosDeFiado.map((m) => [p.nombreDe(m), p.monto(m)])).slice(0, 5),
    compraste: soles(t.compraste),
    deEsoAlCredito: soles(t.deEsoAlCredito),
    aQuienLeCompristeAlCredito: sumarPor(p.alCredito.map((m) => [p.nombreDe(m), p.original(m)])).slice(0, 5),
    pagasteDeLoQueDebias: soles(t.pagasteDeLoQueDebias),
    aQuienLePagaste: sumarPor(p.pagosDeDeuda.map((m) => [p.nombreDe(m), p.monto(m)])).slice(0, 5),
    ventasPorCliente: sumarPor(conNombre(p.ventas.map((m) => [p.nombreDe(m), p.original(m)]))).slice(0, 5),
    comprasPorProveedor: sumarPor(conNombre(p.compras.map((m) => [p.nombreDe(m), p.original(m)]))).slice(0, 5),
  };
}

// --- Comparar dos periodos (entrega 94) -----------------------------------

export interface Diferencia {
  primero: string;
  segundo: string;
  /** El primero respecto del segundo. */
  sentido: 'más' | 'menos' | 'igual';
  diferencia: string;
  /** «12 %»; nulo si el segundo es S/ 0. */
  porcentaje: string | null;
}

function diferencia(a: number, b: number): Diferencia {
  const d = a - b;
  return {
    primero: soles(a),
    segundo: soles(b),
    sentido: d > 0 ? 'más' : d < 0 ? 'menos' : 'igual',
    diferencia: soles(Math.abs(d)),
    porcentaje: b === 0 ? null : `${Math.round((Math.abs(d) / b) * 100)} %`,
  };
}

/**
 * Compara el primer periodo con el segundo. Si uno todavía no termina (se
 * recortó a hoy), el otro se corta a los mismos días desde su inicio, para
 * comparar igual con igual: del 1 al 21 de este mes con del 1 al 21 del
 * anterior (decisión de Jhony, entrega 94; como en los Informes).
 */
export function compararPeriodos(
  datos: Fila,
  primero: unknown,
  segundo: unknown,
  ahora: Date,
) {
  const leer = (x: unknown) => {
    const r = (x ?? {}) as { desde?: unknown; hasta?: unknown };
    return leerRango(r.desde, r.hasta, ahora);
  };
  const a = leer(primero);
  if ('error' in a) return { error: a.error, en: 'primero' };
  const b = leer(segundo);
  if ('error' in b) return { error: b.error, en: 'segundo' };
  const dias = (r: { desde: number; hasta: number }) => (r.hasta - r.desde) / dia + 1;
  let mismosDias = false;
  if (a.recortado && !b.recortado && dias(b) > dias(a)) {
    b.hasta = b.desde + (dias(a) - 1) * dia;
    mismosDias = true;
  } else if (b.recortado && !a.recortado && dias(a) > dias(b)) {
    a.hasta = a.desde + (dias(b) - 1) * dia;
    mismosDias = true;
  }
  const ta = totales(delPeriodo(datos, a.desde, a.hasta));
  const tb = totales(delPeriodo(datos, b.desde, b.hasta));
  const periodo = (r: { desde: number; hasta: number }) => ({
    desde: fechaLarga(new Date(r.desde)),
    hasta: fechaLarga(new Date(r.hasta)),
  });
  return {
    primero: periodo(a),
    segundo: periodo(b),
    mismosDias,
    comparacion: Object.fromEntries(
      (Object.keys(ta) as (keyof typeof ta)[]).map((k) => [k, diferencia(ta[k], tb[k])]),
    ) as Record<keyof ReturnType<typeof totales>, Diferencia>,
  };
}

// --- Una persona en un periodo (entrega 94) -------------------------------

/** «Doña Rosa» → «dona rosa»: sin mayúsculas ni tildes. */
const normal = (t: string) =>
  t.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase().replace(/\s+/g, ' ').trim();

/**
 * Lo que se le vendió o compró a un cliente o proveedor en un periodo, por
 * su nombre o una parte. Si coinciden varios, devuelve sus nombres para que
 * Moca pregunte cuál.
 */
export function cifrasDeUnaPersona(
  datos: Fila,
  nombre: unknown,
  desdeTexto: unknown,
  hastaTexto: unknown,
  ahora: Date,
) {
  if (typeof nombre !== 'string' || !normal(nombre)) return { error: 'sin_nombre' };
  const rango = leerRango(desdeTexto, hastaTexto, ahora);
  if ('error' in rango) return rango;
  const buscado = normal(nombre);
  const todas = ((datos.contrapartes as Fila[] | undefined) ?? []).map((c) => ({
    id: String(c.id),
    nombre: String(c.nombre),
  }));
  const exactas = todas.filter((c) => normal(c.nombre) === buscado);
  const coinciden = exactas.length ? exactas : todas.filter((c) => normal(c.nombre).includes(buscado));
  // Dos con el mismo nombre escrito igual son la misma persona para el dueño.
  const nombres = [...new Set(coinciden.map((c) => c.nombre))];
  if (!nombres.length) return { error: 'no_encontrado' };
  if (nombres.length > 1) return { error: 'varios', opciones: nombres.slice(0, 5) };

  const ids = new Set(coinciden.map((c) => c.id));
  const p = delPeriodo(datos, rango.desde, rango.hasta);
  const suyo = (lista: Fila[]) => lista.filter((m) => ids.has(p.contraparteId(m) ?? ''));
  return {
    persona: nombres[0],
    desde: fechaLarga(new Date(rango.desde)),
    hasta: fechaLarga(new Date(rango.hasta)),
    leVendiste: soles(p.suma(suyo(p.ventas), p.original)),
    deEsoAlFiado: soles(p.suma(suyo(p.alFiado), p.original)),
    tePago: soles(p.suma(suyo(p.entro))),
    leCompraste: soles(p.suma(suyo(p.compras), p.original)),
    deEsoAlCredito: soles(p.suma(suyo(p.alCredito), p.original)),
    lePagaste: soles(p.suma(suyo(p.salio))),
  };
}
