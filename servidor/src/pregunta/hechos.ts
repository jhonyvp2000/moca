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
  teDeben: { total: string; cuantos: number; clientes: Deuda[] };
  debes: { total: string; cuantos: number; proveedores: Deuda[] };
}

interface Deuda {
  nombre: string;
  monto: string;
  desde: string;
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
function deudas(datos: Fila, tipo: 'ingreso' | 'egreso'): { total: number; lista: Deuda[] } {
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
      };
    });
  return { total, lista };
}

export function hechosDelNegocio(datos: Fila, cifras: Cifras, ahora: Date): Hechos {
  const hoy = enPeru(ahora);
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
    teDeben: { total: soles(teDeben.total), cuantos: teDeben.lista.length, clientes: teDeben.lista },
    debes: { total: soles(debes.total), cuantos: debes.lista.length, proveedores: debes.lista },
  };
}
