-- Entrega 43: los planes Básico y Full (decisiones.md, 09-11-2026). El plan
-- «basico» (S/ 14.90, 1 persona, sin «Para pedir un crédito») se suma a los
-- del Full (normal, fundador y anual, con 3 personas). Cada persona más se
-- cobra aparte: se guarda cuántas pagó cada pago y cada orden. Lo que ya
-- existe queda como Full, sin personas extra. Las migraciones con datos
-- empiezan así (ver 011).
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE suscripciones DROP CONSTRAINT suscripciones_plan_check;
ALTER TABLE suscripciones ADD CONSTRAINT suscripciones_plan_check
  CHECK (plan IN ('basico', 'normal', 'fundador', 'anual'));
ALTER TABLE pagos DROP CONSTRAINT pagos_plan_check;
ALTER TABLE pagos ADD CONSTRAINT pagos_plan_check
  CHECK (plan IN ('basico', 'normal', 'fundador', 'anual'));
ALTER TABLE ordenes_pago DROP CONSTRAINT ordenes_pago_plan_check;
ALTER TABLE ordenes_pago ADD CONSTRAINT ordenes_pago_plan_check
  CHECK (plan IN ('basico', 'normal', 'fundador', 'anual'));

ALTER TABLE suscripciones ADD COLUMN personas_extra integer NOT NULL DEFAULT 0
  CHECK (personas_extra >= 0);
ALTER TABLE pagos ADD COLUMN personas_extra integer NOT NULL DEFAULT 0
  CHECK (personas_extra >= 0);
ALTER TABLE ordenes_pago ADD COLUMN personas_extra integer NOT NULL DEFAULT 0
  CHECK (personas_extra >= 0);
