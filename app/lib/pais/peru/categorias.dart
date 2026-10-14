import '../../dominio/modelos.dart';

// Categorías provisionales de docs/prototipo-v1.md, hasta que la Fase 0
// defina las reales. «Retiro para mí» no es categoría: es un tipo de movimiento.

const categoriaVentaDelDia = 'Venta del día';

const categoriasComunesIngreso = [categoriaVentaDelDia, 'Otro ingreso'];

const categoriasComunesEgreso = [
  'Alquiler',
  'Servicios (luz, agua, internet, teléfono)',
  'Personal',
  'Transporte',
  'Mantenimiento y reparaciones',
  'Impuestos y trámites',
  'Otros',
];

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
