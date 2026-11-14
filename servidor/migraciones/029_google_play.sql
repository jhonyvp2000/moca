-- Entrega 78: pagar Moca con Google Play en la versión de Play Store
-- (decisiones.md, 13-11-2026). Cada compra de Google se guarda por su token;
-- cada cobro de Google (la compra y cada renovación) es un pago, una sola
-- vez, por su número de orden. Las migraciones con datos empiezan así (ver 011).
SET CONSTRAINTS ALL IMMEDIATE;

CREATE TABLE compras_google (
  -- El token de compra que Google le da al teléfono.
  token text PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES empresas (id),
  -- El dueño que compró.
  usuario_id uuid NOT NULL REFERENCES usuarios (id),
  -- «full_2»: el plan y sus personas extra; «mes» o «anio»; «fundador».
  producto text NOT NULL,
  plan_base text,
  oferta text,
  -- Como lo dice Google: SUBSCRIPTION_STATE_ACTIVE, …_CANCELED, …_EXPIRED…
  estado text NOT NULL,
  vence timestamptz,
  ultima_orden text,
  -- Por qué no se aplicó (lo ve Jhony); nulo si se aplicó.
  motivo text,
  -- Una compra de las cuentas de prueba de Google: no cobra.
  prueba boolean NOT NULL DEFAULT false,
  creado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX compras_google_por_empresa ON compras_google (empresa_id, creado_en DESC);

ALTER TABLE compras_google ENABLE ROW LEVEL SECURITY;
ALTER TABLE compras_google FORCE ROW LEVEL SECURITY;
CREATE POLICY por_empresa ON compras_google FOR SELECT
  USING (empresa_id = moca_empresa_actual());
CREATE POLICY admin ON compras_google USING (moca_es_admin()) WITH CHECK (moca_es_admin());
CREATE POLICY al_borrar ON compras_google FOR DELETE
  USING (empresa_id::text = current_setting('app.borrando_empresa', true));

ALTER TABLE pagos DROP CONSTRAINT pagos_origen_check;
ALTER TABLE pagos ADD CONSTRAINT pagos_origen_check
  CHECK (origen IN ('yape', 'mercadopago', 'google'));
ALTER TABLE pagos ADD COLUMN google_orden text UNIQUE;
