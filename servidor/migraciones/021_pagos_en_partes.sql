-- Entrega 44: cobros y pagos en partes. Una parte es un movimiento pagado
-- que dice de qué deuda es; la deuda se queda con lo que falta. Las
-- migraciones con datos empiezan así (ver 011).
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE movimientos ADD COLUMN abona_a uuid;
ALTER TABLE movimientos ADD CONSTRAINT movimientos_abona_a_fkey
  FOREIGN KEY (empresa_id, abona_a) REFERENCES movimientos (empresa_id, id)
  DEFERRABLE INITIALLY DEFERRED;
