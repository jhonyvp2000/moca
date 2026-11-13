-- Entrega 14.1: además del BCP (tipo «banco»), el dueño puede usar
-- Interbank, BBVA, Scotiabank y otro banco o caja (con el nombre que
-- escriba). Los nombres son los de la app (TipoCuenta).
ALTER TABLE cuentas DROP CONSTRAINT cuentas_tipo_check;
ALTER TABLE cuentas ADD CONSTRAINT cuentas_tipo_check CHECK (tipo IN (
  'efectivo', 'yape', 'banco', 'plin', 'sip', 'otra',
  'interbank', 'bbva', 'scotiabank', 'otroBanco'
));
