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
