-- Entrega 32: pagar Moca con Mercado Pago (Checkout Pro). Como en TVSamGo,
-- una orden por cada intento de pago: su id es la referencia que viaja a
-- Mercado Pago y vuelve en el aviso. Las migraciones con datos empiezan así
-- (ver 011).
SET CONSTRAINTS ALL IMMEDIATE;

CREATE TABLE ordenes_pago (
  id uuid PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES empresas (id),
  -- El dueño que tocó «Pagar con Mercado Pago».
  usuario_id uuid NOT NULL REFERENCES usuarios (id),
  plan text NOT NULL CHECK (plan IN ('normal', 'fundador', 'anual')),
  monto_centimos integer NOT NULL CHECK (monto_centimos > 0),
  -- pendiente → pagada | rechazada | reembolsada | revisar (lo ve Jhony).
  estado text NOT NULL DEFAULT 'pendiente'
    CHECK (estado IN ('pendiente', 'pagada', 'rechazada', 'reembolsada', 'revisar')),
  motivo text,
  mp_preferencia_id text,
  mp_pago_id text UNIQUE,
  creado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ordenes_pago_por_empresa ON ordenes_pago (empresa_id, creado_en DESC);

ALTER TABLE ordenes_pago ENABLE ROW LEVEL SECURITY;
ALTER TABLE ordenes_pago FORCE ROW LEVEL SECURITY;
-- El negocio ve las suyas; el servidor las escribe como quien registra pagos.
CREATE POLICY por_empresa ON ordenes_pago FOR SELECT
  USING (empresa_id = moca_empresa_actual());
CREATE POLICY admin ON ordenes_pago USING (moca_es_admin()) WITH CHECK (moca_es_admin());
CREATE POLICY al_borrar ON ordenes_pago FOR DELETE
  USING (empresa_id::text = current_setting('app.borrando_empresa', true));

-- De dónde vino cada pago, y el de Mercado Pago una sola vez.
ALTER TABLE pagos ADD COLUMN origen text NOT NULL DEFAULT 'yape'
  CHECK (origen IN ('yape', 'mercadopago'));
ALTER TABLE pagos ADD COLUMN mp_pago_id text UNIQUE;
