-- Entrega 14.10: Plin de BBVA y de Scotiabank, aparte del de Interbank
-- (tipo «plin»). Los nombres son los de la app (TipoCuenta).
ALTER TABLE cuentas DROP CONSTRAINT cuentas_tipo_check;
ALTER TABLE cuentas ADD CONSTRAINT cuentas_tipo_check CHECK (tipo IN (
  'efectivo', 'yape', 'banco', 'plin', 'sip', 'otra',
  'interbank', 'bbva', 'scotiabank', 'otroBanco',
  'bbvaPlin', 'scotiabankPlin'
));
