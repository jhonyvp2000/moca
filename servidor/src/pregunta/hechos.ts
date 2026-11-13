import type { Cifras } from '../cifras/calcular.js';
import { desfaseHorario } from '../pais/peru.js';

/**
 * Lo que Moca sabe del negocio para responder una pregunta (entrega 74),
 * con las cifras YA calculadas y escritas como se dicen: la IA solo las
 * cita, no calcula nada. Lo que no está aquí, Moca no lo sabe.
 */
export interface Hechos {
  hoy: string;
  negocio: string | null;
  cuentas: { cuenta: string; tienes: string }[];
  totalEnCuentas: string;
  estaSemana: {
    desde: string;
    entro: string;
    salio: string;
    teQueda: string;
    comparadoConLaSemanaPasada: string | null;
    ventaDeHoy: string;
  };
  meses: {
    mes: string;
    enCurso: boolean;
    entro: string;
    salio: string;
    teQuedo: string;
    retirasteParaTi: string;
    gastosPorCategoria: { categoria: string; monto: string; porcentaje: string }[];
    entradasPorCategoria: { categoria: string; monto: string; porcentaje: string }[];
  }[];
  teDeben: { total: string; cuantos: number; clientes: DeudaDeCliente[] };
  debes: { total: string; cuantos: number; proveedores: Deuda[] };
  // Entrega 75: más cifras, todas ya calculadas.
  /** Lo que entró cada día (ventas y cobros), este mes y el anterior. */
  entroPorDia: { mes: string; dias: { dia: string; entro: string }[]; mejorDia: string | null; promedioPorDia: string }[];
  /** Lo que entró por cuenta (Yape, efectivo…). */
  entroPorCuenta: { estaSemana: Monto[]; esteMes: Monto[] };
  /** Lo comprado o pagado a cada proveedor, este mes y el anterior. */
  comprasPorProveedor: { mes: string; proveedores: Monto[] }[];
  gastosMasGrandesDelMes: { fecha: string; monto: string; categoria: string; proveedor: string | null }[];
  documentosDelMes: { fecha: string; documento: string; deQuien: string | null; monto: string; fue: 'entró' | 'salió' }[];
  cobradoDeFiado: { estaSemana: string; esteMes: string; quienesPagaron: Monto[] };
  elAnio: {
    anio: number;
    entro: string;
    salio: string;
    teQuedo: string;
    porMes: { mes: string; entro: string; salio: string; teQuedo: string }[];
    mesQueMasEntro: string | null;
    mesQueMasTeQuedo: string | null;
  };
  ultimoArqueo: { fecha: string; cuentas: { cuenta: string; resultado: string }[] } | null;
  avisos: string[];
  porPersona: { persona: string; hoy: Anotado; estaSemana: Anotado }[];
  plan: string | null;
}

interface Deuda {
  nombre: string;
  monto: string;
  desde: string;
}

interface DeudaDeCliente extends Deuda {
  diasQueDebe: number;
  ultimoRecordatorio: string;
}

interface Monto {
  nombre: string;
  monto: string;
}

interface Anotado {
  registros: number;
  entro: string;
  salio: string;
}

/** Lo que necesita el servidor además de los datos (entrega 75). */
export interface Extra {
  /** Quién pregunta: en «por persona» es «tú». */
  usuarioId: string;
  /** El estado del plan, ya en palabras. */
  plan: string | null;
}

type Fila = Record<string, unknown>;

const meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
  'setiembre', 'octubre', 'noviembre', 'diciembre',
];
const dias = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];

/** «S/ 1,350» o «S/ 3.40», como en la app. */
export function soles(centimos: number): string {
  const signo = centimos < 0 ? '−' : '';
  const abs = Math.abs(Math.round(centimos));
  const enteros = Math.floor(abs / 100).toLocaleString('en-US');
  const resto = abs % 100;
  return `${signo}S/ ${enteros}${resto === 0 ? '' : `.${String(resto).padStart(2, '0')}`}`;
}

/** La fecha en el Perú, como texto: «viernes 13 de noviembre de 2026». */
function fechaLarga(d: Date): string {
  return `${dias[d.getUTCDay()]} ${d.getUTCDate()} de ${meses[d.getUTCMonth()]} de ${d.getUTCFullYear()}`;
}

const enPeru = (v: unknown) => new Date(new Date(v as string | Date).getTime() + desfaseHorario);

/** El día en el Perú, a medianoche (UTC como reloj local). */
const diaDe = (d: Date) => Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
const diaCorto = (t: number) => {
  const f = new Date(t);
  return `${dias[f.getUTCDay()]} ${f.getUTCDate()} de ${meses[f.getUTCMonth()]}`;
};
const nombreDelMes = (anio: number, mes: number) => `${meses[mes]} de ${anio}`;

/** Suma por clave y la deja de mayor a menor. */
function sumarPor(pares: [string, number][]): Monto[] {
  const total = new Map<string, number>();
  for (const [k, v] of pares) total.set(k, (total.get(k) ?? 0) + v);
  return [...total.entries()]
    .filter(([, v]) => v > 0)
    .sort((a, b) => b[1] - a[1])
    .map(([nombre, v]) => ({ nombre, monto: soles(v) }));
}

function porcentajes(lista: { nombre: string | null; centimos: number }[]) {
  const total = lista.reduce((s, x) => s + x.centimos, 0);
  return lista
    .filter((x) => x.centimos > 0)
    .map((x) => ({
      categoria: x.nombre ?? 'Sin categoría',
      monto: soles(x.centimos),
      porcentaje: total > 0 ? `${Math.round((x.centimos * 100) / total)}%` : '0%',
    }));
}

/** Lo pendiente de cada cliente o proveedor, de mayor a menor. */
function deudas(datos: Fila, tipo: 'ingreso' | 'egreso'): { total: number; lista: (Deuda & { desdeT: number })[] } {
  const nombres = new Map(
    ((datos.contrapartes as Fila[] | undefined) ?? []).map((c) => [String(c.id), String(c.nombre)]),
  );
  const porNombre = new Map<string, { centimos: number; desde: number }>();
  let total = 0;
  for (const m of (datos.movimientos as Fila[] | undefined) ?? []) {
    if (m.estado !== 'vigente' || m.tipo !== tipo || m.estado_pago === 'pagado') continue;
    const falta = Number(m.monto_centimos) - Number(m.monto_pagado_centimos);
    if (falta <= 0) continue;
    total += falta;
    const nombre = nombres.get(String(m.contraparte_id)) ?? 'Sin nombre';
    const fecha = enPeru(m.fecha_comprobante ?? m.fecha_movimiento).getTime();
    const previo = porNombre.get(nombre);
    porNombre.set(nombre, {
      centimos: (previo?.centimos ?? 0) + falta,
      desde: Math.min(previo?.desde ?? fecha, fecha),
    });
  }
  const lista = [...porNombre.entries()]
    .sort((a, b) => b[1].centimos - a[1].centimos)
    .map(([nombre, d]) => {
      const f = new Date(d.desde);
      return {
        nombre,
        monto: soles(d.centimos),
        desde: `${f.getUTCDate()} de ${meses[f.getUTCMonth()]}`,
        desdeT: d.desde,
      };
    });
  return { total, lista };
}

export function hechosDelNegocio(datos: Fila, cifras: Cifras, ahora: Date, extra: Extra): Hechos {
  const hoy = enPeru(ahora);
  const mas = masCifras(datos, cifras, hoy, extra);
  const cuentas = ((datos.cuentas as Fila[] | undefined) ?? [])
    .filter((c) => c.en_uso !== false)
    .map((c) => ({ cuenta: String(c.nombre), tienes: soles(cifras.saldos[String(c.tipo)] ?? 0) }));
  const total = Object.values(cifras.saldos).reduce((s, v) => s + v, 0);
  const i = cifras.inicio;
  const lunes = new Date(Date.UTC(hoy.getUTCFullYear(), hoy.getUTCMonth(), hoy.getUTCDate()));
  lunes.setUTCDate(lunes.getUTCDate() - ((lunes.getUTCDay() + 6) % 7));
  const diferencia = i.diferenciaConSemanaAnteriorCentimos;
  const teDeben = deudas(datos, 'ingreso');
  const debes = deudas(datos, 'egreso');
  return {
    hoy: `${fechaLarga(hoy)}, ${String(hoy.getUTCHours() % 12 || 12)}:${String(hoy.getUTCMinutes()).padStart(2, '0')} ${hoy.getUTCHours() < 12 ? 'a. m.' : 'p. m.'}`,
    negocio: ((datos.empresa as Fila | undefined)?.nombre as string | undefined) ?? null,
    cuentas,
    totalEnCuentas: soles(total),
    estaSemana: {
      desde: `lunes ${lunes.getUTCDate()} de ${meses[lunes.getUTCMonth()]}`,
      entro: soles(i.semanaEntroCentimos),
      salio: soles(i.semanaSalioCentimos),
      teQueda: soles(i.semanaEntroCentimos - i.semanaSalioCentimos),
      comparadoConLaSemanaPasada:
        diferencia == null
          ? null
          : diferencia === 0
            ? 'te queda lo mismo que la semana pasada hasta el mismo día'
            : `te queda ${soles(Math.abs(diferencia))} ${diferencia > 0 ? 'más' : 'menos'} que la semana pasada hasta el mismo día`,
      ventaDeHoy: soles(i.ventaDeHoyCentimos),
    },
    // Los dos últimos meses: el que va y el anterior.
    meses: cifras.informes
      .filter((x) => !x.sinRegistros)
      .slice(-2)
      .reverse()
      .map((x) => {
        const [anio, mes] = x.mes.slice(0, 7).split('-').map(Number);
        return {
          mes: `${meses[(mes ?? 1) - 1]} de ${anio}`,
          enCurso: x.enCurso,
          entro: soles(x.entroCentimos),
          salio: soles(x.salioCentimos),
          teQuedo: soles(x.entroCentimos - x.salioCentimos),
          retirasteParaTi: soles(x.retirosCentimos),
          gastosPorCategoria: porcentajes(x.gastos),
          entradasPorCategoria: porcentajes(x.ingresos),
        };
      }),
    teDeben: {
      total: soles(teDeben.total),
      cuantos: teDeben.lista.length,
      clientes: teDeben.lista.map(({ desdeT, ...d }) => ({
        ...d,
        diasQueDebe: Math.round((diaDe(hoy) - desdeT) / dia),
        ultimoRecordatorio: mas.recordatorios.get(d.nombre) ?? 'nunca',
      })),
    },
    debes: {
      total: soles(debes.total),
      cuantos: debes.lista.length,
      proveedores: debes.lista.map(({ desdeT: _, ...d }) => d),
    },
    entroPorDia: mas.entroPorDia,
    entroPorCuenta: mas.entroPorCuenta,
    comprasPorProveedor: mas.comprasPorProveedor,
    gastosMasGrandesDelMes: mas.gastosMasGrandesDelMes,
    documentosDelMes: mas.documentosDelMes,
    cobradoDeFiado: mas.cobradoDeFiado,
    elAnio: mas.elAnio,
    ultimoArqueo: mas.ultimoArqueo,
    avisos: mas.avisos,
    porPersona: mas.porPersona,
    plan: extra.plan,
  };
}

const dia = 24 * 60 * 60 * 1000;

/** Las cifras de la entrega 75, desde los registros vigentes. */
function masCifras(datos: Fila, cifras: Cifras, hoy: Date, extra: Extra) {
  const filas = (k: string) => (datos[k] as Fila[] | undefined) ?? [];
  const nombreDe = new Map(filas('contrapartes').map((c) => [String(c.id), String(c.nombre)]));
  const recordatorios = new Map(
    filas('contrapartes').map((c) => [
      String(c.nombre),
      c.recordado_en ? `${enPeru(c.recordado_en).getUTCDate()} de ${meses[enPeru(c.recordado_en).getUTCMonth()]}` : 'nunca',
    ]),
  );
  const cuentaDe = new Map(filas('cuentas').map((c) => [String(c.id), String(c.nombre)]));
  const categoriaDe = new Map(filas('categorias').map((c) => [String(c.id), String(c.nombre)]));
  const vigentes = filas('movimientos').filter((m) => m.estado === 'vigente');
  const monto = (m: Fila) => Number(m.monto_centimos);
  const pagado = (m: Fila) => m.estado_pago === 'pagado';
  // La plata se mueve el día del pago; lo comprado, el día de la compra.
  const diaPago = (m: Fila) => diaDe(enPeru(m.fecha_pago ?? m.fecha_movimiento));
  const diaAnotado = (m: Fila) => diaDe(enPeru(m.fecha_comprobante ?? m.fecha_movimiento));
  const hoyT = diaDe(hoy);
  const lunesT = hoyT - ((hoy.getUTCDay() + 6) % 7) * dia;
  const anio = hoy.getUTCFullYear();
  const mes = hoy.getUTCMonth();
  const inicioMes = (a: number, m: number) => Date.UTC(a, m, 1);
  const esteMes = inicioMes(anio, mes);
  const mesAnterior = inicioMes(anio, mes - 1);
  const manana = hoyT + dia;
  const entre = (t: number, desde: number, hasta: number) => t >= desde && t < hasta;
  const entradas = vigentes.filter((m) => m.tipo === 'ingreso' && pagado(m));
  const salidas = vigentes.filter((m) => m.tipo === 'egreso' && m.abona_a == null);

  // 1, 2 y 4: lo que entró cada día y el promedio.
  const entroPorDia = [
    [esteMes, manana],
    [mesAnterior, esteMes],
  ].map(([desde, hasta]) => {
    const porDia = new Map<number, number>();
    for (const m of entradas) {
      const t = diaPago(m);
      if (entre(t, desde!, hasta!)) porDia.set(t, (porDia.get(t) ?? 0) + monto(m));
    }
    const lista = [...porDia.entries()].sort((a, b) => a[0] - b[0]);
    const mejor = [...lista].sort((a, b) => b[1] - a[1])[0];
    const total = lista.reduce((s, [, v]) => s + v, 0);
    const diasDelPeriodo = Math.max(1, Math.round((hasta! - desde!) / dia));
    const f = new Date(desde!);
    return {
      mes: nombreDelMes(f.getUTCFullYear(), f.getUTCMonth()),
      dias: lista.map(([t, v]) => ({ dia: diaCorto(t), entro: soles(v) })),
      mejorDia: mejor ? `${diaCorto(mejor[0])}, con ${soles(mejor[1])}` : null,
      promedioPorDia: soles(Math.round(total / diasDelPeriodo)),
    };
  });

  // 3: por cuenta.
  const porCuenta = (desde: number) =>
    sumarPor(
      entradas
        .filter((m) => entre(diaPago(m), desde, manana))
        .map((m) => [cuentaDe.get(String(m.cuenta_id)) ?? 'Otra cuenta', monto(m)]),
    );

  // 5: por proveedor.
  const comprasPorProveedor = [
    [esteMes, manana],
    [mesAnterior, esteMes],
  ].map(([desde, hasta]) => {
    const f = new Date(desde!);
    return {
      mes: nombreDelMes(f.getUTCFullYear(), f.getUTCMonth()),
      proveedores: sumarPor(
        salidas
          .filter((m) => m.contraparte_id != null && entre(diaAnotado(m), desde!, hasta!))
          .map((m) => [nombreDe.get(String(m.contraparte_id)) ?? 'Sin nombre', monto(m)]),
      ),
    };
  });

  // 6: los gastos más grandes del mes.
  const gastosMasGrandesDelMes = salidas
    .filter((m) => entre(diaAnotado(m), esteMes, manana))
    .sort((a, b) => monto(b) - monto(a))
    .slice(0, 3)
    .map((m) => ({
      fecha: diaCorto(diaAnotado(m)),
      monto: soles(monto(m)),
      categoria: categoriaDe.get(String(m.categoria_id)) ?? 'Sin categoría',
      proveedor: m.contraparte_id == null ? null : (nombreDe.get(String(m.contraparte_id)) ?? null),
    }));

  // 8: los documentos del mes.
  const documentosDelMes = vigentes
    .filter(
      (m) =>
        (m.documento_tipo != null || m.documento_numero != null) &&
        entre(diaAnotado(m), esteMes, manana),
    )
    .sort((a, b) => diaAnotado(b) - diaAnotado(a))
    .slice(0, 30)
    .map((m) => ({
      fecha: diaCorto(diaAnotado(m)),
      documento: [m.documento_tipo, m.documento_numero].filter((x) => x != null).join(' '),
      deQuien: m.contraparte_id == null ? null : (nombreDe.get(String(m.contraparte_id)) ?? null),
      monto: soles(monto(m)),
      fue: (m.tipo === 'ingreso' ? 'entró' : 'salió') as 'entró' | 'salió',
    }));

  // 10: lo cobrado de un fiado: un pago en parte, o una venta que se pagó
  // otro día.
  const cobros = entradas.filter(
    (m) => m.abona_a != null || (m.contraparte_id != null && diaPago(m) > diaAnotado(m)),
  );
  const sumaDesde = (ms: Fila[], desde: number) =>
    ms.filter((m) => entre(diaPago(m), desde, manana)).reduce((s, m) => s + monto(m), 0);
  const deudaDe = new Map(vigentes.map((m) => [String(m.id), m]));
  const clienteDelCobro = (m: Fila) => {
    const id = m.contraparte_id ?? deudaDe.get(String(m.abona_a))?.contraparte_id;
    return id == null ? 'Sin nombre' : (nombreDe.get(String(id)) ?? 'Sin nombre');
  };

  // 12 y 13: el año.
  const delAnio = cifras.informes.filter(
    (x) => !x.sinRegistros && Number(x.mes.slice(0, 4)) === anio,
  );
  const porMes = delAnio.map((x) => ({
    mes: meses[Number(x.mes.slice(5, 7)) - 1]!,
    entro: x.entroCentimos,
    salio: x.salioCentimos,
  }));
  const maximo = (k: (x: (typeof porMes)[number]) => number) =>
    porMes.length ? [...porMes].sort((a, b) => k(b) - k(a))[0]!.mes : null;
  const entroAnio = porMes.reduce((s, x) => s + x.entro, 0);
  const salioAnio = porMes.reduce((s, x) => s + x.salio, 0);

  // 14: el último arqueo.
  const arqueos = [...filas('arqueos')].sort(
    (a, b) => new Date(String(b.fecha)).getTime() - new Date(String(a.fecha)).getTime(),
  );
  const ultimo = arqueos[0];
  const ultimoArqueo = ultimo
    ? {
        fecha: diaCorto(diaDe(enPeru(ultimo.fecha))),
        cuentas: filas('arqueo_cuentas')
          .filter((c) => c.arqueo_id === ultimo.id)
          .map((c) => {
            const d = Number(c.diferencia_centimos);
            return {
              cuenta: cuentaDe.get(String(c.cuenta_id)) ?? 'Otra cuenta',
              resultado: d === 0 ? 'cuadró' : d > 0 ? `sobró ${soles(d)}` : `faltó ${soles(-d)}`,
            };
          }),
      }
    : null;

  // 15: los avisos, en palabras.
  const avisos = cifras.avisos.map((a) => {
    const m = a.montoCentimos == null ? '' : soles(a.montoCentimos);
    switch (a.tipo) {
      case 'faltaArqueo':
        return 'Falta hacer el arqueo de esta semana.';
      case 'diferenciaArqueo':
        return `En un arqueo la cuenta no cuadró por ${m}.`;
      case 'diasSinRegistrar':
        return `Hace ${a.dias ?? 2} días que no se anota nada.`;
      case 'gastoAtipico':
        return `Un gasto más alto de lo habitual: ${m} en ${a.categoria ?? 'otra categoría'}.`;
      case 'cobrarCliente':
        return `${a.cliente ?? 'Un cliente'} te debe ${m} hace tiempo.`;
    }
  });

  // 16: lo anotado por persona.
  const personas = filas('equipo');
  const anotado = (autor: string, desde: number): Anotado => {
    const suyos = vigentes.filter(
      (m) => String(m.autor_id) === autor && entre(diaDe(enPeru(m.creado_en ?? m.fecha_movimiento)), desde, manana),
    );
    return {
      registros: suyos.length,
      entro: soles(suyos.filter((m) => m.tipo === 'ingreso').reduce((s, m) => s + monto(m), 0)),
      salio: soles(suyos.filter((m) => m.tipo === 'egreso').reduce((s, m) => s + monto(m), 0)),
    };
  };
  const porPersona =
    personas.length > 1
      ? personas.map((p) => ({
          persona:
            String(p.usuario_id) === extra.usuarioId ? 'tú' : String(p.nombre ?? 'Otra persona'),
          hoy: anotado(String(p.usuario_id), hoyT),
          estaSemana: anotado(String(p.usuario_id), lunesT),
        }))
      : [];

  return {
    recordatorios,
    entroPorDia,
    entroPorCuenta: { estaSemana: porCuenta(lunesT), esteMes: porCuenta(esteMes) },
    comprasPorProveedor,
    gastosMasGrandesDelMes,
    documentosDelMes,
    cobradoDeFiado: {
      estaSemana: soles(sumaDesde(cobros, lunesT)),
      esteMes: soles(sumaDesde(cobros, esteMes)),
      quienesPagaron: sumarPor(
        cobros.filter((m) => entre(diaPago(m), esteMes, manana)).map((m) => [clienteDelCobro(m), monto(m)]),
      ),
    },
    elAnio: {
      anio,
      entro: soles(entroAnio),
      salio: soles(salioAnio),
      teQuedo: soles(entroAnio - salioAnio),
      porMes: porMes.map((x) => ({
        mes: x.mes,
        entro: soles(x.entro),
        salio: soles(x.salio),
        teQuedo: soles(x.entro - x.salio),
      })),
      mesQueMasEntro: maximo((x) => x.entro),
      mesQueMasTeQuedo: maximo((x) => x.entro - x.salio),
    },
    ultimoArqueo,
    avisos,
    porPersona,
  };
}
