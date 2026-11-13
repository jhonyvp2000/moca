-- Entrega 24: el cobro manual por Yape (decisiones.md, 03-11-2026).
-- Las migraciones con datos empiezan así (ver 011).
SET CONSTRAINTS ALL IMMEDIATE;

-- Quien registra los pagos (Jhony) ve todos los negocios, pero solo cuando
-- el servidor lo reconoció por su número y lo marcó en la transacción.
CREATE FUNCTION moca_es_admin() RETURNS boolean
  LANGUAGE sql STABLE
  AS $$ SELECT coalesce(current_setting('app.admin', true), '') = 'si' $$;

-- Hasta cuándo está pagado cada negocio y con qué plan.
CREATE TABLE suscripciones (
  empresa_id uuid PRIMARY KEY REFERENCES empresas (id),
  plan text NOT NULL CHECK (plan IN ('normal', 'fundador', 'anual')),
  pagado_hasta date NOT NULL,
  -- Pagó alguna vez como fundador: cuenta para los 50.
  fue_fundador boolean NOT NULL DEFAULT false,
  actualizado_en timestamptz NOT NULL DEFAULT now()
);

-- Cada pago que registró Jhony.
CREATE TABLE pagos (
  id uuid PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES empresas (id),
  plan text NOT NULL CHECK (plan IN ('normal', 'fundador', 'anual')),
  monto_centimos integer NOT NULL CHECK (monto_centimos > 0),
  desde date NOT NULL,
  hasta date NOT NULL CHECK (hasta >= desde),
  nota text,
  registrado_por uuid NOT NULL REFERENCES usuarios (id),
  creado_en timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX pagos_por_empresa ON pagos (empresa_id, creado_en);

-- El día en que empezó la prueba de cada número de titular: no se borra
-- con el negocio, para que el mismo número no vuelva a tener 14 días.
CREATE TABLE pruebas_por_celular (
  celular text PRIMARY KEY,
  inicio date NOT NULL
);

DO $$
DECLARE
  tabla text;
BEGIN
  FOREACH tabla IN ARRAY ARRAY['suscripciones', 'pagos'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tabla);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', tabla);
    EXECUTE format(
      'CREATE POLICY por_empresa ON %I FOR SELECT USING (empresa_id = moca_empresa_actual())',
      tabla);
    EXECUTE format(
      'CREATE POLICY admin ON %I USING (moca_es_admin()) WITH CHECK (moca_es_admin())',
      tabla);
  END LOOP;

  -- Para buscar un negocio por el número de su dueño y ver su prueba.
  FOREACH tabla IN ARRAY ARRAY['empresas', 'usuarios', 'membresias', 'movimientos'] LOOP
    EXECUTE format('CREATE POLICY admin_lee ON %I FOR SELECT USING (moca_es_admin())', tabla);
  END LOOP;
END
$$;

ALTER TABLE pruebas_por_celular ENABLE ROW LEVEL SECURITY;
ALTER TABLE pruebas_por_celular FORCE ROW LEVEL SECURITY;
-- El titular del negocio en curso, o quien registra los pagos.
CREATE POLICY del_titular ON pruebas_por_celular
  USING (
    moca_es_admin() OR celular IN (
      SELECT u.celular FROM usuarios u
        JOIN membresias m ON m.usuario_id = u.id
       WHERE m.empresa_id = moca_empresa_actual() AND m.titular
    )
  )
  WITH CHECK (
    celular IN (
      SELECT u.celular FROM usuarios u
        JOIN membresias m ON m.usuario_id = u.id
       WHERE m.empresa_id = moca_empresa_actual() AND m.titular
    )
  );

-- Al borrar el negocio (entrega 14.8) se van también sus pagos; la prueba
-- de su número se queda.
CREATE POLICY al_borrar ON suscripciones FOR DELETE
  USING (empresa_id::text = current_setting('app.borrando_empresa', true));
CREATE POLICY al_borrar ON pagos FOR DELETE
  USING (empresa_id::text = current_setting('app.borrando_empresa', true));

-- Cuántos negocios ya tomaron el precio de fundador (máximo 50). No tiene
-- datos de nadie: solo el número.
CREATE TABLE cupo_fundadores (
  id integer PRIMARY KEY CHECK (id = 1),
  usados integer NOT NULL DEFAULT 0
);
INSERT INTO cupo_fundadores (id, usados) VALUES (1, 0);
