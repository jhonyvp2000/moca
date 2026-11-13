-- Entrega 14.6: los videos de ayuda que abrió cada negocio, para saber en
-- el piloto cuáles se ven. Solo el número del video, desde dónde y cuándo.
CREATE TABLE videos_vistos (
  id          uuid PRIMARY KEY,
  empresa_id  uuid NOT NULL REFERENCES empresas (id),
  video       smallint NOT NULL CHECK (video BETWEEN 1 AND 7),
  desde       text NOT NULL CHECK (desde IN (
                'pasos', 'primeraVez', 'aprende', 'guardarAvance', 'permisoAvisos')),
  fecha       timestamptz NOT NULL
);

CREATE INDEX videos_vistos_por_empresa ON videos_vistos (empresa_id, video);

ALTER TABLE videos_vistos ENABLE ROW LEVEL SECURITY;
ALTER TABLE videos_vistos FORCE ROW LEVEL SECURITY;
CREATE POLICY por_empresa ON videos_vistos
  USING (empresa_id = moca_empresa_actual())
  WITH CHECK (empresa_id = moca_empresa_actual());

CREATE TRIGGER no_se_borra BEFORE DELETE ON videos_vistos
  FOR EACH ROW EXECUTE FUNCTION moca_no_se_borra();
