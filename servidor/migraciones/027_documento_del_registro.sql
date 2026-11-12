-- Entrega 66: tres datos opcionales en cada registro. El tipo de documento
-- (Factura, Boleta, Guía de remisión, Nota de crédito, Nota de débito,
-- Liquidación de compra u Otro) y su número, libre («0045J»), van en el
-- movimiento. La institución (el cliente o el proveedor) ya tenía su lugar:
-- contraparte_id. Los registros de antes quedan sin documento.

SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE movimientos ADD COLUMN documento_tipo text
  CHECK (documento_tipo IS NULL OR char_length(documento_tipo) BETWEEN 1 AND 40);
ALTER TABLE movimientos ADD COLUMN documento_numero text
  CHECK (documento_numero IS NULL OR char_length(documento_numero) BETWEEN 1 AND 40);
