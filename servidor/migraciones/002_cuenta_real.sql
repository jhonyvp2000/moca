-- Entrega 11: cuenta real con el celular y subida de lo anotado en el teléfono.

-- La llave que recibe el teléfono al verificar su celular. Se guarda solo su
-- huella (sha256): quien lea la base no puede usarla. No vence; se revoca.
-- No son datos de una empresa: sin RLS, solo el servidor las usa.
CREATE TABLE sesiones (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id   uuid NOT NULL REFERENCES usuarios (id),
  huella       bytea NOT NULL UNIQUE,
  creado_en    timestamptz NOT NULL DEFAULT now(),
  usado_en     timestamptz NOT NULL DEFAULT now(),
  revocada_en  timestamptz
);

-- Cada pedido de código, para poner un límite por número y por conexión.
CREATE TABLE pedidos_codigo (
  id       bigserial PRIMARY KEY,
  celular  text NOT NULL,
  ip       text,
  fecha    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX pedidos_por_celular ON pedidos_codigo (celular, fecha);
CREATE INDEX pedidos_por_ip ON pedidos_codigo (ip, fecha);

-- Al verificar el código todavía no se sabe la empresa: el servidor busca al
-- usuario por el celular que acaba de verificar (app.celular)...
CREATE POLICY por_celular_verificado ON usuarios FOR SELECT
  USING (celular = NULLIF(current_setting('app.celular', true), ''));

-- ...y sus empresas, por sus membresías.
CREATE POLICY propias ON membresias FOR SELECT
  USING (usuario_id = moca_usuario_actual());

-- Las referencias se revisan al cerrar la transacción: así lo que sube el
-- teléfono puede llegar en cualquier orden (una corrección antes que el
-- movimiento que reemplaza).
DO $$
DECLARE
  restriccion record;
BEGIN
  FOR restriccion IN
    SELECT c.conname, t.relname
      FROM pg_constraint c
      JOIN pg_class t ON t.oid = c.conrelid
      JOIN pg_namespace n ON n.oid = t.relnamespace
     WHERE c.contype = 'f' AND n.nspname = 'public'
  LOOP
    EXECUTE format(
      'ALTER TABLE %I ALTER CONSTRAINT %I DEFERRABLE INITIALLY DEFERRED',
      restriccion.relname, restriccion.conname);
  END LOOP;
END
$$;
