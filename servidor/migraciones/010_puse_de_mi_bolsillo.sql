-- Entrega 14.11: «Puse de mi bolsillo», la plata que el dueño pone en el
-- negocio (tipo «aporte»), y la razón del arqueo «La puse yo» (puseYo).
-- Los nombres son los de la app.
ALTER TABLE movimientos DROP CONSTRAINT movimientos_tipo_check;
ALTER TABLE movimientos ADD CONSTRAINT movimientos_tipo_check
  CHECK (tipo IN ('ingreso', 'egreso', 'retiro', 'aporte'));

ALTER TABLE arqueo_cuentas DROP CONSTRAINT arqueo_cuentas_motivo_check;
ALTER TABLE arqueo_cuentas ADD CONSTRAINT arqueo_cuentas_motivo_check
  CHECK (motivo IN ('retiroParaMi', 'puseYo', 'gastoOlvidado', 'ventaNoAnotada', 'errorDeVuelto', 'noLoSe'));
