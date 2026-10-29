import {
  categoriaVentaDelDia,
  categoriasDeMercaderia,
  desfaseHorario,
} from '../pais/peru.js';

// Las cifras que muestra la app (entrega 13), con las mismas reglas que
// usaba el teléfono (app/lib/datos/repositorios). La prueba de paridad
// (test/cifras.test.ts) compara las dos con los datos de la Demo.
//
// Las horas se cuentan en la hora del Perú: cada instante se pasa a un
// número cuya fecha en UTC es la hora de Lima («hora local»).

type Fila = Record<string, unknown>;

/** Lo de una empresa, como lo guarda la base (o como lo sube el teléfono). */
export interface DatosEmpresa {
  cuentas: Fila[];
  categorias: Fila[];
  movimientos: Fila[];
  arqueos: Fila[];
  arqueo_cuentas: Fila[];
  dias_cerrados: Fila[];
  alertas?: Fila[];
}

export type EstadoArqueo = 'nada' | 'toca' | 'falta' | 'hecho';

export interface Aviso {
  clave: string;
  tipo: 'faltaArqueo' | 'diferenciaArqueo' | 'diasSinRegistrar' | 'gastoAtipico';
  prioridad: 'importante' | 'paraTenerEnCuenta';
  fecha: string;
  montoCentimos: number | null;
  cuenta: string | null;
  categoria: string | null;
  dias: number | null;
  destinoId: string | null;
}

export interface Informe {
  mes: string;
  enCurso: boolean;
  sinRegistros: boolean;
  desdeDia: number | null;
  mesAnterior: string | null;
  diferenciaConAnteriorCentimos: number | null;
  entroCentimos: number;
  salioCentimos: number;
  retirosCentimos: number;
  inicioCentimos: number;
  ajustesCentimos: number;
  gastos: { nombre: string | null; centimos: number }[];
  cambio: { nombre: string; centimos: number } | null;
  loQueDebesCentimos: number;
  confianza: { conComprobante: number; conFoto: number; sinPapel: number } | null;
  advertenciaMercaderia: boolean;
  mesPrevio: string | null;
  mesSiguiente: string | null;
}

export interface Cifras {
  /** El día (en el Perú) en que se calcularon. */
  dia: string;
  /** Saldo de cada cuenta, por su tipo (efectivo, yape…). */
  saldos: Record<string, number>;
  inicio: {
    semanaEntroCentimos: number;
    semanaSalioCentimos: number;
    semanaRetirosCentimos: number;
    semanaConMovimientos: boolean;
    diferenciaConSemanaAnteriorCentimos: number | null;
    ventaDeHoyCentimos: number;
    estadoArqueo: EstadoArqueo;
  };
  resumenSemana: {
    semanaPasada: boolean;
    conMovimientos: boolean;
    quedoCentimos: number;
    diferenciaCentimos: number | null;
    categoriaTop: string | null;
    categoriaTopCentimos: number | null;
  };
  /** Sin los que el dueño marcó «Entendido». */
  avisos: Aviso[];
  /** Un informe por mes, del primero con registros al actual. */
  informes: Informe[];
}

// --- Horas -------------------------------------------------------------------

const dia = 24 * 60 * 60 * 1000;
const hora = 60 * 60 * 1000;

const local = (v: unknown): number => new Date(v as string | Date).getTime() + desfaseHorario;
const localONulo = (v: unknown): number | null => (v == null ? null : local(v));
const real = (l: number): string => new Date(l - desfaseHorario).toISOString();

/** «2026-10-11» (un día sin hora) como medianoche en la hora local. */
function diaLocal(v: unknown): number {
  if (v instanceof Date) return Date.UTC(v.getFullYear(), v.getMonth(), v.getDate());
  const [anio, mes, d] = String(v).slice(0, 10).split('-').map(Number);
  return Date.UTC(anio!, mes! - 1, d!);
}

const fecha = (l: number) => new Date(l);
const inicioDelDia = (l: number) =>
  Date.UTC(fecha(l).getUTCFullYear(), fecha(l).getUTCMonth(), fecha(l).getUTCDate());
/** Lunes 1 … domingo 7. */
const diaDeSemana = (l: number) => ((fecha(l).getUTCDay() + 6) % 7) + 1;
/** La semana va de lunes a domingo. */
const inicioDeSemana = (l: number) => inicioDelDia(l) - (diaDeSemana(l) - 1) * dia;
const mesDe = (l: number) => Date.UTC(fecha(l).getUTCFullYear(), fecha(l).getUTCMonth(), 1);
/** El mes [n] meses después de [l] (n puede ser negativo). */
const sumarMeses = (l: number, n: number) =>
  Date.UTC(fecha(l).getUTCFullYear(), fecha(l).getUTCMonth() + n, 1);
const textoDia = (l: number) => fecha(l).toISOString().slice(0, 10);
const textoMes = (l: number) => fecha(l).toISOString().slice(0, 7);

/** El orden de los textos que usa la app (por unidades de código). */
const compararTexto = (a: string, b: string) => (a < b ? -1 : a > b ? 1 : 0);

// --- Movimientos -------------------------------------------------------------

interface Movimiento {
  id: string;
  tipo: 'ingreso' | 'egreso' | 'retiro';
  cuentaId: string;
  monto: number;
  fechaMovimiento: number;
  fechaComprobante: number | null;
  fechaPago: number | null;
  estadoPago: string;
  montoPagado: number;
  categoriaId: string | null;
  nivelConfianza: string;
  vigente: boolean;
}

/** Lo mínimo para calcular saldos: la fecha es la del pago. */
interface ParaSaldo {
  tipo: Movimiento['tipo'];
  monto: number;
  vigente: boolean;
  pagado: boolean;
  fecha: number;
}

const paraSaldo = (m: Movimiento): ParaSaldo => ({
  tipo: m.tipo,
  monto: m.monto,
  vigente: m.vigente,
  pagado: m.estadoPago === 'pagado',
  fecha: m.fechaPago ?? m.fechaMovimiento,
});

interface AjusteArqueo {
  id: string;
  cuentaId: string;
  fecha: number;
  centimos: number;
  motivo: string | null;
}

const ajusteParaSaldo = (a: AjusteArqueo): ParaSaldo => ({
  tipo: a.centimos > 0 ? 'ingreso' : 'egreso',
  monto: Math.abs(a.centimos),
  vigente: true,
  pagado: true,
  fecha: a.fecha,
});

/**
 * Saldo de una cuenta: el saldo inicial más lo que entró y menos lo que salió
 * desde la fecha del saldo inicial. No cuentan los anulados ni lo que se debe.
 */
function saldoDeCuenta(inicial: number | null, desde: number | null, ms: ParaSaldo[]): number {
  let saldo = inicial ?? 0;
  for (const m of ms) {
    if (!m.vigente || !m.pagado) continue;
    if (desde != null && m.fecha < desde) continue;
    saldo += m.tipo === 'ingreso' ? m.monto : -m.monto;
  }
  return saldo;
}

/**
 * Lo que entró y salió entre [desde] (incluido) y [hasta] (excluido). Los
 * retiros para el dueño no cuentan como «salió».
 */
function resumirPeriodo(ms: ParaSaldo[], desde: number, hasta: number) {
  let entro = 0;
  let salio = 0;
  let retiros = 0;
  let cantidad = 0;
  for (const m of ms) {
    if (!m.vigente || !m.pagado) continue;
    if (m.fecha < desde || m.fecha >= hasta) continue;
    if (m.tipo === 'ingreso') {
      entro += m.monto;
      cantidad++;
    } else if (m.tipo === 'egreso') {
      salio += m.monto;
      cantidad++;
    } else {
      retiros += m.monto;
    }
  }
  return { entro, salio, retiros, cantidad, quedo: entro - salio };
}

// --- Reglas ------------------------------------------------------------------

/** «Diferencia en el arqueo»: S/ 10 o más marcados «No lo sé». */
const diferenciaMinima = 1000;
/** «Gasto atípico»: S/ 100 o más, el doble del promedio de su categoría en
 * las 8 semanas anteriores, con al menos 3 gastos previos. */
const atipicoMinimo = 10000;
const atipicoVentana = 56 * dia;
const atipicoPrevios = 3;
/** Cuánto tiempo se muestra un gasto atípico. */
const atipicoVigencia = 14 * dia;
/** «Días sin registrar»: dos días seguidos. */
const diasSinRegistrarMinimo = 2;
/** Cambio mínimo de una categoría para mencionarlo: S/ 100 y 20 %. */
const cambioMinimoCentimos = 10000;
const cambioMinimoProporcion = 0.2;
/** La mercadería avisa desde 30 % sobre el promedio de hasta tres meses. */
const umbralMercaderia = 1.3;
const mesesParaPromedio = 3;
const filasDeGastos = 5;

/** Las cifras de la empresa en el instante [ahora]. */
export function calcularCifras(datos: DatosEmpresa, ahoraReal: Date): Cifras {
  const ahora = local(ahoraReal);
  const hoy = inicioDelDia(ahora);
  const manana = hoy + dia;
  const lunes = inicioDeSemana(ahora);
  const lunesPasado = lunes - 7 * dia;

  const movimientos: Movimiento[] = datos.movimientos.map((m) => ({
    id: String(m.id),
    tipo: m.tipo as Movimiento['tipo'],
    cuentaId: String(m.cuenta_id),
    monto: Number(m.monto_centimos),
    fechaMovimiento: local(m.fecha_movimiento),
    fechaComprobante: localONulo(m.fecha_comprobante),
    fechaPago: localONulo(m.fecha_pago),
    estadoPago: String(m.estado_pago),
    montoPagado: Number(m.monto_pagado_centimos),
    categoriaId: (m.categoria_id as string | null) ?? null,
    nivelConfianza: String(m.nivel_confianza),
    vigente: m.estado === 'vigente',
  }));
  const vigentes = movimientos.filter((m) => m.vigente);
  const todosParaSaldo = movimientos.map(paraSaldo);
  const categorias = new Map(datos.categorias.map((c) => [String(c.id), String(c.nombre)]));
  const nombreCategoria = (id: string | null) => (id == null ? undefined : categorias.get(id));
  const cuentas = datos.cuentas.map((c) => ({
    id: String(c.id),
    tipo: String(c.tipo),
    inicial: c.saldo_inicial_centimos == null ? null : Number(c.saldo_inicial_centimos),
    desde: localONulo(c.fecha_saldo_inicial),
  }));
  const tipoDeCuenta = new Map(cuentas.map((c) => [c.id, c.tipo]));
  const arqueos = datos.arqueos.map((a) => ({ id: String(a.id), fecha: local(a.fecha) }));
  const fechaDeArqueo = new Map(arqueos.map((a) => [a.id, a.fecha]));

  // Las diferencias del arqueo que ajustan el saldo (sin movimiento propio),
  // en el orden de sus arqueos.
  const ajustes: AjusteArqueo[] = datos.arqueo_cuentas
    .filter(
      (c) =>
        Number(c.diferencia_centimos) !== 0 &&
        c.movimiento_id == null &&
        fechaDeArqueo.has(String(c.arqueo_id)),
    )
    .map((c) => ({
      id: String(c.id),
      cuentaId: String(c.cuenta_id),
      fecha: fechaDeArqueo.get(String(c.arqueo_id))!,
      centimos: Number(c.diferencia_centimos),
      motivo: (c.motivo as string | null) ?? null,
    }))
    .sort((a, b) => a.fecha - b.fecha);

  // Saldos.
  const saldos: Record<string, number> = {};
  for (const c of cuentas) {
    saldos[c.tipo] = saldoDeCuenta(c.inicial, c.desde, [
      ...movimientos.filter((m) => m.cuentaId === c.id).map(paraSaldo),
      ...ajustes.filter((a) => a.cuentaId === c.id).map(ajusteParaSaldo),
    ]);
  }

  // Estado del arqueo: hecho si hay arqueo esta semana; falta desde el lunes
  // a las 8:00 a. m. si la semana anterior quedó sin arqueo; toca el domingo.
  // El pedido del operador vive solo en el teléfono.
  let estadoArqueo: EstadoArqueo = 'nada';
  if (arqueos.some((a) => a.fecha >= lunes)) {
    estadoArqueo = 'hecho';
  } else if (
    movimientos.some((m) => m.fechaMovimiento < lunes) &&
    !arqueos.some((a) => a.fecha >= lunesPasado) &&
    ahora >= lunes + 8 * hora
  ) {
    estadoArqueo = 'falta';
  } else if (diaDeSemana(ahora) === 7) {
    estadoArqueo = 'toca';
  }

  // Inicio: la semana hasta el final de hoy, frente a la semana pasada hasta
  // el mismo día.
  const semana = resumirPeriodo(todosParaSaldo, lunes, manana);
  const pasadaCompleta = resumirPeriodo(todosParaSaldo, lunesPasado, lunes);
  const pasadaHastaHoy = resumirPeriodo(todosParaSaldo, lunesPasado, manana - 7 * dia);
  const ventaDelDia = datos.categorias.find((c) => c.nombre === categoriaVentaDelDia);
  const ventaDeHoy = vigentes
    .filter(
      (m) =>
        ventaDelDia != null &&
        m.categoriaId === String(ventaDelDia.id) &&
        inicioDelDia(m.fechaMovimiento) === hoy,
    )
    .reduce((s, m) => s + m.monto, 0);

  return {
    dia: textoDia(hoy),
    saldos,
    inicio: {
      semanaEntroCentimos: semana.entro,
      semanaSalioCentimos: semana.salio,
      semanaRetirosCentimos: semana.retiros,
      semanaConMovimientos: semana.cantidad > 0,
      diferenciaConSemanaAnteriorCentimos:
        pasadaCompleta.cantidad > 0 ? semana.quedo - pasadaHastaHoy.quedo : null,
      ventaDeHoyCentimos: ventaDeHoy,
      estadoArqueo,
    },
    resumenSemana: resumenSemana(),
    avisos: avisos(),
    informes: informes(),
  };

  function resumenSemana(): Cifras['resumenSemana'] {
    const semanaPasada = vigentes.some((m) => m.fechaMovimiento < lunes);
    const desde = semanaPasada ? lunesPasado : lunes;
    const hasta = semanaPasada ? lunes : manana;
    const resumida = resumirPeriodo(todosParaSaldo, desde, hasta);
    let diferencia: number | null = null;
    if (semanaPasada) {
      const antes = resumirPeriodo(todosParaSaldo, desde - 7 * dia, desde);
      if (antes.cantidad > 0) diferencia = resumida.quedo - antes.quedo;
    }
    // Lo que más salió en la semana, por categoría.
    const porCategoria = new Map<string, number>();
    for (const m of movimientos) {
      const p = paraSaldo(m);
      if (m.tipo !== 'egreso' || !m.vigente || !p.pagado || p.fecha < desde || p.fecha >= hasta) {
        continue;
      }
      const nombre = nombreCategoria(m.categoriaId);
      if (nombre == null) continue;
      porCategoria.set(nombre, (porCategoria.get(nombre) ?? 0) + m.monto);
    }
    let top: [string, number] | null = null;
    for (const e of porCategoria) {
      if (top == null || e[1] > top[1] || (e[1] === top[1] && compararTexto(e[0], top[0]) < 0)) {
        top = e;
      }
    }
    return {
      semanaPasada,
      conMovimientos: resumida.cantidad > 0,
      quedoCentimos: resumida.quedo,
      diferenciaCentimos: diferencia,
      categoriaTop: top?.[0] ?? null,
      categoriaTopCentimos: top?.[1] ?? null,
    };
  }

  function avisos(): Aviso[] {
    const lista: Aviso[] = [];
    const aviso = (a: Partial<Aviso> & Pick<Aviso, 'clave' | 'tipo' | 'prioridad' | 'fecha'>) =>
      lista.push({
        montoCentimos: null,
        cuenta: null,
        categoria: null,
        dias: null,
        destinoId: null,
        ...a,
      });

    // Falta el arqueo.
    if (estadoArqueo === 'falta') {
      aviso({
        clave: `falta_arqueo:${textoLocal(lunes)}`,
        tipo: 'faltaArqueo',
        prioridad: 'importante',
        fecha: real(lunes + 8 * hora),
      });
    }

    // Diferencia en el arqueo marcada «No lo sé».
    for (const a of ajustes) {
      if (a.motivo !== 'noLoSe' || Math.abs(a.centimos) < diferenciaMinima) continue;
      aviso({
        clave: `diferencia:${a.id}`,
        tipo: 'diferenciaArqueo',
        prioridad: 'importante',
        fecha: real(a.fecha),
        montoCentimos: Math.abs(a.centimos),
        cuenta: tipoDeCuenta.get(a.cuentaId) ?? null,
        destinoId: a.id,
      });
    }

    // Días seguidos sin registrar, contados hasta ayer. «Hoy no abrí» cuenta
    // como día con registro.
    const dias = new Set([
      ...vigentes.map((m) => inicioDelDia(m.fechaMovimiento)),
      ...datos.dias_cerrados.map((d) => diaLocal(d.dia)),
    ]);
    if (dias.size > 0 && !dias.has(hoy)) {
      const primero = Math.min(...dias);
      let sinRegistrar = 0;
      let d = hoy - dia;
      while (d >= primero && !dias.has(d)) {
        sinRegistrar++;
        d -= dia;
      }
      if (sinRegistrar >= diasSinRegistrarMinimo) {
        aviso({
          clave: `dias:${textoLocal(hoy)}`,
          tipo: 'diasSinRegistrar',
          prioridad: 'importante',
          fecha: real(hoy),
          dias: sinRegistrar,
        });
      }
    }

    // Gastos atípicos de las últimas dos semanas.
    const egresos = vigentes.filter((m) => m.tipo === 'egreso');
    for (const m of egresos) {
      if (m.monto < atipicoMinimo) continue;
      if (m.fechaMovimiento < ahora - atipicoVigencia) continue;
      const desde = m.fechaMovimiento - atipicoVentana;
      const previos = egresos
        .filter(
          (p) =>
            p.id !== m.id &&
            p.categoriaId === m.categoriaId &&
            p.fechaMovimiento >= desde &&
            p.fechaMovimiento < m.fechaMovimiento,
        )
        .map((p) => p.monto);
      if (previos.length < atipicoPrevios) continue;
      const promedio = previos.reduce((a, b) => a + b, 0) / previos.length;
      if (m.monto < promedio * 2) continue;
      aviso({
        clave: `atipico:${m.id}`,
        tipo: 'gastoAtipico',
        prioridad: 'paraTenerEnCuenta',
        fecha: real(m.fechaMovimiento),
        montoCentimos: m.monto,
        categoria: nombreCategoria(m.categoriaId) ?? null,
        destinoId: m.id,
      });
    }

    const vistos = new Set(
      (datos.alertas ?? []).filter((a) => a.estado === 'vista').map((a) => String(a.clave)),
    );
    const prioridad = { importante: 0, paraTenerEnCuenta: 1 };
    return lista
      .filter((a) => !vistos.has(a.clave))
      .sort(
        (a, b) =>
          prioridad[a.prioridad] - prioridad[b.prioridad] ||
          compararTexto(b.fecha, a.fecha) ||
          compararTexto(a.clave, b.clave),
      );
  }

  function informes(): Informe[] {
    // El informe es el flujo de caja del mes (entrega 14.9): un movimiento
    // cuenta el día en que la plata se movió, igual que en el saldo.
    const fechaInforme = (m: Movimiento) => m.fechaPago ?? m.fechaMovimiento;
    const actual = mesDe(ahora);
    // Las mismas reglas que el saldo: solo lo pagado, y desde el saldo
    // inicial de su cuenta. Así el informe cuadra con «Tienes hoy».
    const desdeDe = new Map(cuentas.map((c) => [c.id, c.desde]));
    const cuentaParaSaldo = (cuentaId: string, f: number) => {
      const desde = desdeDe.get(cuentaId);
      return desde == null || f >= desde;
    };
    const pagados = vigentes.filter(
      (m) => m.estadoPago === 'pagado' && cuentaParaSaldo(m.cuentaId, fechaInforme(m)),
    );
    const ajustesDelInforme = ajustes.filter((a) => cuentaParaSaldo(a.cuentaId, a.fecha));
    const fechas = [
      ...pagados.map(fechaInforme),
      ...ajustesDelInforme.map((a) => a.fecha),
      ...cuentas.flatMap((c) => (c.desde == null ? [] : [c.desde])),
    ];
    const inicio = fechas.length ? Math.min(...fechas) : ahora;
    const primerMes = mesDe(inicio);

    const periodo = (desde: number, hasta: number) =>
      pagados.filter((m) => fechaInforme(m) >= desde && fechaInforme(m) < hasta);
    const ajustado = (desde: number, hasta: number) =>
      ajustesDelInforme
        .filter((a) => a.fecha >= desde && a.fecha < hasta)
        .reduce((s, a) => s + a.centimos, 0);
    const suma = (ms: Movimiento[], tipo: Movimiento['tipo']) =>
      ms.filter((m) => m.tipo === tipo).reduce((s, m) => s + m.monto, 0);
    // Cuánto creció la plata en el periodo.
    const crecio = (desde: number, hasta: number) => {
      const ms = periodo(desde, hasta);
      return (
        suma(ms, 'ingreso') - suma(ms, 'egreso') - suma(ms, 'retiro') + ajustado(desde, hasta)
      );
    };
    // La plata en [momento]: cada cuenta con su saldo de ese momento, o con
    // su saldo inicial si empezó después.
    const plataAl = (momento: number) => {
      let total = 0;
      for (const c of cuentas) {
        total += c.inicial ?? 0;
        if (c.desde != null && c.desde >= momento) continue;
        for (const m of pagados) {
          if (m.cuentaId !== c.id || fechaInforme(m) >= momento) continue;
          total += m.tipo === 'ingreso' ? m.monto : -m.monto;
        }
        for (const a of ajustesDelInforme) {
          if (a.cuentaId === c.id && a.fecha < momento) total += a.centimos;
        }
      }
      return total;
    };
    const porCategoria = (ms: Movimiento[]) => {
      const total = new Map<string, number>();
      for (const m of ms.filter((m) => m.tipo === 'egreso')) {
        const nombre = nombreCategoria(m.categoriaId) ?? 'Otros';
        total.set(nombre, (total.get(nombre) ?? 0) + m.monto);
      }
      return total;
    };
    const mercaderia = (ms: Movimiento[]) =>
      ms
        .filter(
          (m) =>
            m.tipo === 'egreso' && categoriasDeMercaderia.has(nombreCategoria(m.categoriaId) ?? ''),
        )
        .reduce((s, m) => s + m.monto, 0);
    const loQueDebes = vigentes
      .filter((m) => m.tipo === 'egreso' && m.estadoPago !== 'pagado')
      .reduce((s, m) => s + m.monto - m.montoPagado, 0);

    const lista: Informe[] = [];
    for (let mes = primerMes; mes <= actual; mes = sumarMeses(mes, 1)) {
      const enCurso = mes === actual;
      const hasta = enCurso ? manana : sumarMeses(mes, 1);
      const delMes = periodo(mes, hasta);
      const esPrimero = mes === primerMes;

      // Mes anterior: hasta el mismo día si el mes está en curso.
      let mesAnterior: number | null = null;
      let diferencia: number | null = null;
      let cambio: Informe['cambio'] = null;
      if (!esPrimero) {
        mesAnterior = sumarMeses(mes, -1);
        let hastaAnterior = mes;
        if (enCurso) {
          const mismoDia = Date.UTC(
            fecha(mesAnterior).getUTCFullYear(),
            fecha(mesAnterior).getUTCMonth(),
            fecha(ahora).getUTCDate() + 1,
          );
          if (mismoDia < mes) hastaAnterior = mismoDia;
        }
        const anterior = periodo(mesAnterior, hastaAnterior);
        diferencia = crecio(mes, hasta) - crecio(mesAnterior, hastaAnterior);

        const ahoraPorCategoria = porCategoria(delMes);
        const antesPorCategoria = porCategoria(anterior);
        let mayor: string | null = null;
        let mayorCambio = 0;
        for (const nombre of new Set([...ahoraPorCategoria.keys(), ...antesPorCategoria.keys()])) {
          const c = (ahoraPorCategoria.get(nombre) ?? 0) - (antesPorCategoria.get(nombre) ?? 0);
          if (
            Math.abs(c) > Math.abs(mayorCambio) ||
            (c !== 0 &&
              Math.abs(c) === Math.abs(mayorCambio) &&
              compararTexto(nombre, mayor!) < 0)
          ) {
            mayor = nombre;
            mayorCambio = c;
          }
        }
        if (mayor != null) {
          const antes = antesPorCategoria.get(mayor) ?? 0;
          if (
            Math.abs(mayorCambio) >= cambioMinimoCentimos &&
            (antes === 0 || Math.abs(mayorCambio) >= antes * cambioMinimoProporcion)
          ) {
            cambio = { nombre: mayor, centimos: mayorCambio };
          }
        }
      }

      // En qué se fue la plata: a lo más cinco filas.
      const ordenadas = [...porCategoria(delMes)].sort(
        (a, b) => b[1] - a[1] || compararTexto(a[0], b[0]),
      );
      const gastos =
        ordenadas.length <= filasDeGastos
          ? ordenadas.map(([nombre, centimos]) => ({ nombre, centimos }))
          : [
              ...ordenadas
                .slice(0, filasDeGastos - 1)
                .map(([nombre, centimos]) => ({ nombre, centimos })),
              {
                nombre: null,
                centimos: ordenadas.slice(filasDeGastos - 1).reduce((s, e) => s + e[1], 0),
              },
            ];

      // Mercadería frente al promedio de hasta tres meses anteriores.
      const anteriores: number[] = [];
      for (let i = 1; i <= mesesParaPromedio; i++) {
        const m = sumarMeses(mes, -i);
        if (m >= primerMes) anteriores.push(mercaderia(periodo(m, sumarMeses(mes, -i + 1))));
      }
      const promedio = anteriores.length
        ? anteriores.reduce((a, b) => a + b, 0) / anteriores.length
        : 0;

      lista.push({
        mes: textoMes(mes),
        enCurso,
        sinRegistros: delMes.length === 0 && ajustado(mes, hasta) === 0,
        desdeDia: esPrimero && fecha(inicio).getUTCDate() > 1 ? fecha(inicio).getUTCDate() : null,
        mesAnterior: mesAnterior == null ? null : textoMes(mesAnterior),
        diferenciaConAnteriorCentimos: diferencia,
        inicioCentimos: plataAl(mes),
        entroCentimos: suma(delMes, 'ingreso'),
        salioCentimos: suma(delMes, 'egreso'),
        retirosCentimos: suma(delMes, 'retiro'),
        ajustesCentimos: ajustado(mes, hasta),
        gastos,
        cambio,
        loQueDebesCentimos: loQueDebes,
        confianza: confianza(delMes),
        advertenciaMercaderia: promedio > 0 && mercaderia(delMes) >= promedio * umbralMercaderia,
        mesPrevio: esPrimero ? null : textoMes(sumarMeses(mes, -1)),
        mesSiguiente: enCurso ? null : textoMes(sumarMeses(mes, 1)),
      });
    }
    return lista;
  }
}

/**
 * La hora local como la escribe la app en las claves de los avisos
 * («2026-10-12T00:00:00.000»): así un aviso marcado «Entendido» en el
 * teléfono es el mismo que calcula el servidor.
 */
function textoLocal(l: number): string {
  return new Date(l).toISOString().slice(0, 23);
}

/** Porcentajes del monto por sustento, que suman 100 (resto mayor). */
function confianza(ms: Movimiento[]): Informe['confianza'] {
  const montos = [0, 0, 0];
  for (const m of ms) {
    const i = m.nivelConfianza === 'a' || m.nivelConfianza === 'b' ? 0 : m.nivelConfianza === 'c' ? 1 : 2;
    montos[i]! += m.monto;
  }
  const total = montos.reduce((s, x) => s + x, 0);
  if (total === 0) return null;
  const exactos = montos.map((x) => (x * 100) / total);
  const enteros = exactos.map(Math.floor);
  let falta = 100 - enteros.reduce((s, x) => s + x, 0);
  const porResto = [0, 1, 2].sort((a, b) => exactos[b]! - enteros[b]! - (exactos[a]! - enteros[a]!));
  for (const i of porResto) {
    if (falta === 0) break;
    enteros[i]!++;
    falta--;
  }
  return { conComprobante: enteros[0]!, conFoto: enteros[1]!, sinPapel: enteros[2]! };
}
