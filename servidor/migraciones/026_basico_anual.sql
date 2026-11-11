-- Entrega 60: el Básico por un año (S/ 149), pagado por Mercado Pago como
-- los demás. Desde esta entrega nadie nuevo entra como fundador; quien ya lo
-- era lo conserva (eso lo decide el código, no la base).
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE suscripciones DROP CONSTRAINT suscripciones_plan_check;
ALTER TABLE suscripciones ADD CONSTRAINT suscripciones_plan_check
  CHECK (plan IN ('basico', 'basico_anual', 'normal', 'fundador', 'anual'));
ALTER TABLE pagos DROP CONSTRAINT pagos_plan_check;
ALTER TABLE pagos ADD CONSTRAINT pagos_plan_check
  CHECK (plan IN ('basico', 'basico_anual', 'normal', 'fundador', 'anual'));
ALTER TABLE ordenes_pago DROP CONSTRAINT ordenes_pago_plan_check;
ALTER TABLE ordenes_pago ADD CONSTRAINT ordenes_pago_plan_check
  CHECK (plan IN ('basico', 'basico_anual', 'normal', 'fundador', 'anual'));
