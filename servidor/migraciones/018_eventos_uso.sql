-- Entrega 28: lo que mide la app llega al servidor, para responder las
-- preguntas del piloto (prototipo-v1.md). Sin montos ni nombres: el tipo de
-- evento, la fecha y datos como «tardó 8 segundos». Se guardan 90 días.
SET CONSTRAINTS ALL IMMEDIATE;

CREATE TABLE eventos_uso (
  -- El id lo pone el teléfono: reenviar no duplica.
  id uuid PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES empresas (id),
  usuario_id uuid NOT NULL REFERENCES usuarios (id),
  nombre text NOT NULL,
  fecha timestamptz NOT NULL,
  datos jsonb,
  recibido_en timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX eventos_uso_por_empresa ON eventos_uso (empresa_id, fecha);

ALTER TABLE eventos_uso ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventos_uso FORCE ROW LEVEL SECURITY;
CREATE POLICY por_empresa ON eventos_uso
  USING (empresa_id = moca_empresa_actual())
  WITH CHECK (empresa_id = moca_empresa_actual() AND usuario_id = moca_usuario_actual());
CREATE POLICY admin ON eventos_uso USING (moca_es_admin()) WITH CHECK (moca_es_admin());
CREATE POLICY al_borrar ON eventos_uso FOR DELETE
  USING (empresa_id::text = current_setting('app.borrando_empresa', true));
