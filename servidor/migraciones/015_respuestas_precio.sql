-- Entrega 25: la pregunta del día 10 de la prueba (decisiones.md,
-- 03-11-2026): «¿Seguirías usando Moca por S/ 19.90 al mes?».
SET CONSTRAINTS ALL IMMEDIATE;

CREATE TABLE respuestas_precio (
  id uuid PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES empresas (id),
  usuario_id uuid NOT NULL REFERENCES usuarios (id),
  respuesta text NOT NULL CHECK (respuesta IN ('si', 'no_se', 'no')),
  motivo text,
  -- El precio que se le preguntó, en céntimos.
  precio_centimos integer NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX respuestas_precio_por_empresa ON respuestas_precio (empresa_id, creado_en);

ALTER TABLE respuestas_precio ENABLE ROW LEVEL SECURITY;
ALTER TABLE respuestas_precio FORCE ROW LEVEL SECURITY;
CREATE POLICY por_empresa ON respuestas_precio
  USING (empresa_id = moca_empresa_actual())
  WITH CHECK (empresa_id = moca_empresa_actual() AND usuario_id = moca_usuario_actual());
CREATE POLICY admin ON respuestas_precio FOR SELECT USING (moca_es_admin());
CREATE POLICY al_borrar ON respuestas_precio FOR DELETE
  USING (empresa_id::text = current_setting('app.borrando_empresa', true));
