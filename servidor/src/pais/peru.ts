// Lo propio del Perú que usa el servidor. Las mismas reglas están en la app
// (app/lib/pais/peru/categorias.dart).

/** Lima va cinco horas detrás de UTC todo el año: no cambia la hora. */
export const desfaseHorario = -5 * 60 * 60 * 1000;

export const categoriaVentaDelDia = 'Venta del día';

/**
 * Las categorías de compras para vender. El informe advierte cuando suben
 * mucho, porque bajan la ganancia del mes aunque la mercadería siga en la
 * tienda.
 */
export const categoriasDeMercaderia = new Set(['Mercadería', 'Insumos de cocina']);

/** RUC de 11 dígitos con su dígito verificador (módulo 11), como en la app. */
export function esRucValido(ruc: string): boolean {
  if (!/^(10|15|16|17|20)\d{9}$/.test(ruc)) return false;
  const factores = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
  const suma = factores.reduce((s, f, i) => s + Number(ruc[i]) * f, 0);
  return (11 - (suma % 11)) % 10 === Number(ruc[10]);
}

/** Los tipos de comprobante que se leen por foto, con los nombres de la app. */
export const tiposDeComprobante = ['Factura', 'Boleta', 'Ticket', 'Recibo', 'Nota de venta'] as const;
