-- Entrega 21.1: «Pasé plata de una caja a otra». Un solo movimiento que
-- sale de una cuenta (cuenta_id) y entra a otra (cuenta_destino_id) del
-- mismo negocio. No es venta ni gasto; depositar en el banco es esto mismo.

-- Con datos, las referencias se revisan al momento (ver la 011).
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE movimientos DROP CONSTRAINT movimientos_tipo_check;
ALTER TABLE movimientos ADD CONSTRAINT movimientos_tipo_check
  CHECK (tipo IN ('ingreso', 'egreso', 'retiro', 'aporte', 'transferencia'));

-- La cuenta de destino es del mismo negocio, como la de origen.
ALTER TABLE movimientos ADD COLUMN cuenta_destino_id uuid;
ALTER TABLE movimientos ADD CONSTRAINT movimientos_cuenta_destino_fk
  FOREIGN KEY (empresa_id, cuenta_destino_id) REFERENCES cuentas (empresa_id, id)
  DEFERRABLE INITIALLY DEFERRED;

-- Solo el pase lleva destino, y es otra cuenta.
ALTER TABLE movimientos ADD CONSTRAINT movimientos_pase_check CHECK (
  (tipo = 'transferencia') = (cuenta_destino_id IS NOT NULL)
  AND cuenta_destino_id IS DISTINCT FROM cuenta_id
);
