-- Entrega 21: varias cajas de efectivo con nombre (decisiones.md,
-- 29-10-2026). La caja principal sigue siendo «efectivo»; hasta dos más.
-- Cada encargado o ayudante tiene sus cajas; sin ninguna, la principal.

-- Con datos, las referencias se revisan al momento (ver la 011).
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE cuentas DROP CONSTRAINT cuentas_tipo_check;
ALTER TABLE cuentas ADD CONSTRAINT cuentas_tipo_check CHECK (tipo IN (
  'efectivo', 'caja2', 'caja3', 'yape', 'banco', 'plin', 'sip', 'otra',
  'interbank', 'bbva', 'scotiabank', 'otroBanco',
  'bbvaPlin', 'scotiabankPlin'
));

-- Las cajas a cargo de cada persona (ids de cuentas de efectivo).
ALTER TABLE membresias ADD COLUMN cajas uuid[] NOT NULL DEFAULT '{}';
