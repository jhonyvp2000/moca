import { esRucValido } from '../pais/peru.js';
import {
  modeloEconomico,
  modeloMayor,
  precios,
  type Imagen,
  type Lector,
  type Modelo,
  type RespuestaModelo,
} from './lector.js';

// Primero lee el modelo económico; si lo leído no cuadra según reglas fijas,
// lee el mayor. Si tampoco cuadra, la foto es ilegible y el dueño completa lo
// que falte. Nada se guarda sin su confirmación (lo hace la app).

export type Resultado = 'leido' | 'ilegible' | 'no_es_comprobante';

/** Lo que se le devuelve al teléfono, con los nombres de sus columnas. */
export interface LecturaParaLaApp {
  emisor_identificacion: string | null;
  emisor_nombre: string | null;
  tipo: string | null;
  serie: string | null;
  numero: string | null;
  fecha_emision: string | null;
  impuesto_centimos: number | null;
  total_centimos: number | null;
  cantidad_items: number | null;
  categoria: string | null;
}

export interface Paso {
  modelo: Modelo;
  tokensEntrada: number;
  tokensSalida: number;
  /** Lo que el modelo dijo, para comparar después con lo que confirmó el dueño. */
  respuesta: RespuestaModelo | null;
  problemas: string[];
}

export interface Leido {
  resultado: Resultado;
  lectura: LecturaParaLaApp | null;
  pasos: Paso[];
}

/** El IGV y el subtotal pueden no sumar el total por redondeos o recargos. */
const toleranciaSoles = 1;

const centimos = (soles: number | null) =>
  soles == null || !Number.isFinite(soles) ? null : Math.round(soles * 100);

/** Qué no cuadra en lo leído. Vacío: se puede mostrar para confirmar. */
export function problemasDe(r: RespuestaModelo, hoy: string): string[] {
  const problemas: string[] = [];
  if (!r.legible) problemas.push('ilegible');
  if (r.total == null || r.total <= 0) problemas.push('sin_total');
  if (r.ruc != null && !esRucValido(r.ruc)) problemas.push('ruc_invalido');
  if (
    r.subtotal != null &&
    r.igv != null &&
    r.total != null &&
    Math.abs(r.subtotal + r.igv - r.total) > toleranciaSoles
  ) {
    problemas.push('no_suma');
  }
  if (r.fecha != null && !fechaPosible(r.fecha, hoy)) problemas.push('fecha_imposible');
  return problemas;
}

function fechaPosible(fecha: string, hoy: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(fecha) || Number.isNaN(Date.parse(fecha))) return false;
  // Un día de margen por la hora; nada de antes del 2000.
  const manana = new Date(Date.parse(hoy) + 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
  return fecha >= '2000-01-01' && fecha <= manana;
}

/** Lo leído, sin lo que una regla marcó como imposible. */
function paraLaApp(r: RespuestaModelo, categorias: string[], hoy: string): LecturaParaLaApp {
  return {
    emisor_identificacion: r.ruc != null && esRucValido(r.ruc) ? r.ruc : null,
    emisor_nombre: r.emisor?.trim() || null,
    tipo: r.tipo,
    serie: r.serie?.trim().toUpperCase() || null,
    numero: r.numero?.trim().replace(/^0+(?=\d)/, '') || null,
    fecha_emision: r.fecha != null && fechaPosible(r.fecha, hoy) ? r.fecha : null,
    impuesto_centimos: centimos(r.igv),
    total_centimos: r.total != null && r.total > 0 ? centimos(r.total) : null,
    cantidad_items: r.cantidad_items,
    categoria: r.categoria != null && categorias.includes(r.categoria) ? r.categoria : null,
  };
}

/** Costo de los pasos, en millonésimas de dólar. */
export function costoMicrodolares(pasos: Paso[]): number {
  return Math.round(
    pasos.reduce(
      (s, p) =>
        s + p.tokensEntrada * precios[p.modelo].entrada + p.tokensSalida * precios[p.modelo].salida,
      0,
    ),
  );
}

/**
 * Lee la foto. [hoy] es el día en el Perú («2026-10-14»). Si el modelo
 * económico falla (la API no responde), el error sube: el teléfono dice que
 * no pudo leer. Si falla el mayor, queda lo del económico como ilegible.
 */
export async function leerComprobante(
  lector: Lector,
  imagen: Imagen,
  categorias: string[],
  hoy: string,
): Promise<Leido> {
  const pasos: Paso[] = [];
  const intentar = async (modelo: Modelo) => {
    const { respuesta, tokensEntrada, tokensSalida } = await lector.leer(imagen, categorias, modelo);
    const problemas = respuesta ? problemasDe(respuesta, hoy) : ['sin_respuesta'];
    pasos.push({ modelo, tokensEntrada, tokensSalida, respuesta, problemas });
    return { respuesta, problemas };
  };

  const economico = await intentar(modeloEconomico);
  if (economico.respuesta && !economico.respuesta.es_comprobante) {
    return { resultado: 'no_es_comprobante', lectura: null, pasos };
  }
  if (economico.problemas.length === 0) {
    return { resultado: 'leido', lectura: paraLaApp(economico.respuesta!, categorias, hoy), pasos };
  }

  let mayor: Awaited<ReturnType<typeof intentar>> | null = null;
  try {
    mayor = await intentar(modeloMayor);
  } catch {
    // Sin el mayor, queda lo que leyó el económico.
  }
  if (mayor?.respuesta && !mayor.respuesta.es_comprobante) {
    return { resultado: 'no_es_comprobante', lectura: null, pasos };
  }
  if (mayor?.respuesta && mayor.problemas.length === 0) {
    return { resultado: 'leido', lectura: paraLaApp(mayor.respuesta, categorias, hoy), pasos };
  }
  const parcial = mayor?.respuesta ?? economico.respuesta;
  return {
    resultado: 'ilegible',
    lectura: parcial ? paraLaApp(parcial, categorias, hoy) : null,
    pasos,
  };
}
