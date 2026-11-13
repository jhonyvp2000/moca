-- Entrega 47: la ficha de soporte en «Cobros». Qué versión de Moca tiene
-- cada persona y cuándo subió por última vez; los días de prueba que regala
-- Jhony; y lo que hace desde soporte, anotado. Las migraciones con datos
-- empiezan así (ver 011).
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE membresias ADD COLUMN version_app text;
ALTER TABLE membresias ADD COLUMN subio_en timestamptz;

-- Días de prueba extra de un negocio (se suman a sus 14).
CREATE TABLE pruebas_extra (
  empresa_id uuid PRIMARY KEY REFERENCES empresas (id),
  dias integer NOT NULL CHECK (dias BETWEEN 1 AND 60),
  actualizado_en timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE pruebas_extra ENABLE ROW LEVEL SECURITY;
ALTER TABLE pruebas_extra FORCE ROW LEVEL SECURITY;
CREATE POLICY por_empresa ON pruebas_extra FOR SELECT
  USING (empresa_id = moca_empresa_actual());
CREATE POLICY admin ON pruebas_extra USING (moca_es_admin()) WITH CHECK (moca_es_admin());
CREATE POLICY al_borrar ON pruebas_extra FOR DELETE
  USING (empresa_id::text = current_setting('app.borrando_empresa', true));

-- Lo que Jhony hace desde soporte. Sin referencia a la empresa: queda aunque
-- el negocio se borre.
CREATE TABLE acciones_soporte (
  id uuid PRIMARY KEY,
  admin_id uuid NOT NULL REFERENCES usuarios (id),
  empresa_id uuid NOT NULL,
  empresa_nombre text NOT NULL,
  accion text NOT NULL CHECK (accion IN ('dias_prueba', 'borrar')),
  detalle text,
  creado_en timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE acciones_soporte ENABLE ROW LEVEL SECURITY;
ALTER TABLE acciones_soporte FORCE ROW LEVEL SECURITY;
CREATE POLICY admin ON acciones_soporte USING (moca_es_admin()) WITH CHECK (moca_es_admin());

-- Quien registra los pagos ve las invitaciones, para la ficha de soporte.
CREATE POLICY admin_lee ON invitaciones FOR SELECT USING (moca_es_admin());
