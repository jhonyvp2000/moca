-- Entrega 27: los errores de la app llegan al servidor (decisiones.md,
-- 04-11-2026). Solo lo técnico: qué falló, dónde y en qué versión; nada de
-- lo anotado. Se guardan 90 días.
SET CONSTRAINTS ALL IMMEDIATE;

CREATE TABLE errores_app (
  -- El id lo pone el teléfono: reenviar el mismo error no lo duplica.
  id uuid PRIMARY KEY,
  usuario_id uuid NOT NULL REFERENCES usuarios (id),
  -- Sin referencia: el error queda aunque se borre el negocio.
  empresa_id uuid,
  -- Mismo error en el mismo lugar, misma firma.
  firma text NOT NULL,
  mensaje text NOT NULL,
  pila text,
  pantalla text,
  entrega text,
  armado integer,
  veces integer NOT NULL DEFAULT 1 CHECK (veces > 0),
  primera timestamptz NOT NULL,
  ultima timestamptz NOT NULL,
  recibido_en timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX errores_app_por_firma ON errores_app (firma, ultima);

ALTER TABLE errores_app ENABLE ROW LEVEL SECURITY;
ALTER TABLE errores_app FORCE ROW LEVEL SECURITY;
-- Cada quien escribe los suyos; solo quien registra los pagos los lee.
CREATE POLICY propios ON errores_app
  USING (usuario_id = moca_usuario_actual())
  WITH CHECK (usuario_id = moca_usuario_actual());
CREATE POLICY admin ON errores_app USING (moca_es_admin()) WITH CHECK (moca_es_admin());
