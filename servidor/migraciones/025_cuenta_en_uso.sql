-- Entrega 58: dejar de usar una cuenta. Ninguna cuenta se borra: con saldo
-- S/ 0, el dueño la deja de usar y deja de salir para anotar, en el Inicio,
-- en el cierre y en el arqueo; sus registros se quedan. Todas siguen en uso.

SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE cuentas ADD COLUMN en_uso boolean NOT NULL DEFAULT true;
