-- Entrega 14.2: sin cuenta, un teléfono puede leer 3 fotos de prueba con la
-- IA. Se anotan en la misma tabla, con el identificador del teléfono (el
-- del usuario que generó la app, que todavía no existe en el servidor) y la
-- conexión, para los topes por conexión y en total.
ALTER TABLE lecturas ALTER COLUMN usuario_id DROP NOT NULL;
ALTER TABLE lecturas ADD COLUMN prueba_de uuid;
ALTER TABLE lecturas ADD COLUMN ip text;
ALTER TABLE lecturas ADD CONSTRAINT lecturas_de_quien
  CHECK ((usuario_id IS NULL) <> (prueba_de IS NULL));

CREATE INDEX lecturas_de_prueba ON lecturas (prueba_de) WHERE prueba_de IS NOT NULL;
CREATE INDEX lecturas_de_prueba_por_fecha ON lecturas (fecha, ip) WHERE prueba_de IS NOT NULL;
