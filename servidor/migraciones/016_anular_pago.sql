-- Entrega 26.1: anular un pago registrado por error o de prueba. No se
-- borra: queda marcado, con su fecha.
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE pagos ADD COLUMN anulado_en timestamptz;
