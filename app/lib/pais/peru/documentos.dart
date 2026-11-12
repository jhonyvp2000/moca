/// Los tipos de documento que se pueden asociar a un registro (entrega 66).
/// Es de Perú: va aislado en el paquete de país. La lista se puede ampliar.
const tiposDeDocumento = [
  'Factura',
  'Boleta',
  'Guía de remisión',
  'Nota de crédito',
  'Nota de débito',
  'Liquidación de compra',
  'Otro',
];

/// «Factura 0045J», «Boleta», «0045J» o nada.
String? textoDelDocumento(String? tipo, String? numero) {
  final partes = [
    if (tipo != null && tipo.trim().isNotEmpty) tipo.trim(),
    if (numero != null && numero.trim().isNotEmpty) numero.trim(),
  ];
  return partes.isEmpty ? null : partes.join(' ');
}
