import '../../dominio/informe.dart';
import '../../dominio/modelos.dart';

// Categorías provisionales de docs/prototipo-v1.md, hasta que la Fase 0
// defina las reales. «Retiro para mí» no es categoría: es un tipo de movimiento.

const categoriaVentaDelDia = 'Venta del día';

const categoriaCobroDeFiado = 'Cobro de fiado';
const categoriaCuotaDePrestamo = 'Cuota de préstamo';

/// Antes iba en «Movilidad del negocio» (entrega 14.14.1).
const categoriaCombustible = 'Combustible';

/// Las del flujo que piden las entidades de crédito (docs/credito/,
/// entrega 14.14): cada fila del flujo sale de una categoría.
const categoriasComunesIngreso = [
  categoriaVentaDelDia,
  categoriaCobroDeFiado,
  'Otro ingreso',
  'Ingreso ocasional',
];

const categoriasComunesEgreso = [
  'Alquiler',
  'Servicios (luz, agua, internet, teléfono)',
  'Sueldos del personal',
  'Movilidad del negocio',
  categoriaCombustible,
  'Flete',
  'Publicidad',
  'Contador o gestoría',
  'Mantenimiento y reparaciones',
  'Impuestos y trámites',
  categoriaCuotaDePrestamo,
  'Otros',
];

/// Nombres que cambiaron (entrega 14.14): «Personal» se confundía con un
/// gasto personal del dueño, que es un retiro.
const categoriasRenombradas = {
  'Personal': 'Sueldos del personal',
  'Transporte': 'Movilidad del negocio',
};

const categoriasEgresoPorNegocio = {
  TipoNegocio.bodega: ['Mercadería', 'Bolsas y envases'],
  TipoNegocio.restaurante: [
    'Insumos de cocina',
    'Bebidas',
    'Gas',
    'Descartables',
  ],
  TipoNegocio.servicios: ['Materiales', 'Herramientas y repuestos'],
  TipoNegocio.otro: ['Mercadería'],
};

/// Las categorías de compras para vender. El informe advierte cuando suben
/// mucho, porque bajan la ganancia del mes aunque la mercadería siga en la
/// tienda.
const categoriasDeMercaderia = {'Mercadería', 'Insumos de cocina'};

/// Categoría → fila del flujo que pide la caja (docs/credito/, entrega
/// 14.15). Una entrada sin categoría o con otra va a «Otros ingresos
/// operativos»; una salida, a «Otros gastos fijos». La cuota de préstamo
/// tiene filas propias, por entidad.
const filaDelFlujo = {
  categoriaVentaDelDia: FilaFlujo.ventasContado,
  categoriaCobroDeFiado: FilaFlujo.ventasCreditoCobradas,
  'Otro ingreso': FilaFlujo.otrosIngresos,
  'Ingreso ocasional': FilaFlujo.ingresosExtraordinarios,
  'Mercadería': FilaFlujo.mercaderia,
  'Insumos de cocina': FilaFlujo.mercaderia,
  'Bebidas': FilaFlujo.mercaderia,
  'Gas': FilaFlujo.mercaderia,
  'Materiales': FilaFlujo.mercaderia,
  'Bolsas y envases': FilaFlujo.envases,
  'Descartables': FilaFlujo.envases,
  'Flete': FilaFlujo.fletes,
  'Alquiler': FilaFlujo.alquiler,
  'Servicios (luz, agua, internet, teléfono)': FilaFlujo.servicios,
  'Sueldos del personal': FilaFlujo.sueldos,
  'Publicidad': FilaFlujo.publicidad,
  'Mantenimiento y reparaciones': FilaFlujo.mantenimiento,
  'Herramientas y repuestos': FilaFlujo.mantenimiento,
  'Contador o gestoría': FilaFlujo.contabilidad,
  'Movilidad del negocio': FilaFlujo.otrosGastosFijos,
  // La plantilla de la caja no tiene fila de combustible.
  categoriaCombustible: FilaFlujo.otrosGastosFijos,
  'Impuestos y trámites': FilaFlujo.otrosGastosFijos,
  'Otros': FilaFlujo.otrosGastosFijos,
};
