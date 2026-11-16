-- Entrega 83: el consentimiento del dueño (Ley 29733). Al guardar su avance
-- marca «Acepto»; quien ya tenía cuenta lo acepta una vez desde el Asistente.
-- Se guarda cuándo y qué versión del texto aceptó. Las migraciones con datos
-- empiezan así (ver 011).
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE usuarios ADD COLUMN consentimiento_en timestamptz;
ALTER TABLE usuarios ADD COLUMN consentimiento_version text;
