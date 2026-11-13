-- Entrega 17: varias personas en un mismo negocio (decisiones.md,
-- 29-10-2026). Roles, invitaciones por número y un número de «cambio» en
-- cada registro para que cada teléfono baje solo lo nuevo.

-- Las referencias se revisan al momento durante esta migración: con datos,
-- una revisión pendiente al cerrar la transacción impide cambiar la tabla
-- («pending trigger events»), y Render no arrancaba (entrega 20).
SET CONSTRAINTS ALL IMMEDIATE;

-- --- Roles -------------------------------------------------------------------

-- Para tocar filas de todas las empresas, la migración se salta un momento el
-- aislamiento (el dueño de la tabla lo puede hacer sin FORCE) y lo vuelve a
-- poner al final.
ALTER TABLE membresias NO FORCE ROW LEVEL SECURITY;

ALTER TABLE membresias DROP CONSTRAINT membresias_rol_check;
UPDATE membresias SET rol = 'ayudante' WHERE rol = 'empleado';
ALTER TABLE membresias ADD CONSTRAINT membresias_rol_check
  CHECK (rol IN ('dueno', 'encargado', 'ayudante', 'contador'));

-- El titular es quien creó el negocio: el único que puede borrarlo todo.
ALTER TABLE membresias ADD COLUMN titular boolean NOT NULL DEFAULT false;
UPDATE membresias SET titular = true WHERE rol = 'dueno';
CREATE UNIQUE INDEX un_titular_por_empresa ON membresias (empresa_id) WHERE titular;

-- Cómo llama el negocio a la persona («Rosa»), para «Lo anotó Rosa».
ALTER TABLE membresias ADD COLUMN nombre text;

-- Cuándo aceptó el uso de sus datos (Ley 29733) quien entró por invitación.
ALTER TABLE membresias ADD COLUMN consentimiento_en timestamptz;

-- Quitar a alguien no borra nada: la membresía queda marcada y su teléfono
-- ya no entra a ese negocio. Lo que anotó se queda.
ALTER TABLE membresias ADD COLUMN quitada_en timestamptz;

-- --- Invitaciones ----------------------------------------------------------

-- Un dueño invita por número de celular. Quien entra a Moca con ese número
-- la ve y la acepta. Vence a los 7 días; el dueño la puede anular.
CREATE TABLE invitaciones (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id    uuid NOT NULL REFERENCES empresas (id) DEFERRABLE INITIALLY DEFERRED,
  celular       text NOT NULL,
  rol           text NOT NULL CHECK (rol IN ('dueno', 'encargado', 'ayudante', 'contador')),
  nombre        text,
  invitada_por  uuid NOT NULL REFERENCES usuarios (id) DEFERRABLE INITIALLY DEFERRED,
  creada_en     timestamptz NOT NULL DEFAULT now(),
  aceptada_en   timestamptz,
  anulada_en    timestamptz
);

CREATE INDEX invitaciones_por_celular ON invitaciones (celular) WHERE aceptada_en IS NULL AND anulada_en IS NULL;

ALTER TABLE invitaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitaciones FORCE ROW LEVEL SECURITY;
CREATE POLICY por_empresa ON invitaciones
  USING (empresa_id = moca_empresa_actual())
  WITH CHECK (empresa_id = moca_empresa_actual());
-- El invitado ve sus invitaciones por el celular de su cuenta (app.celular).
CREATE POLICY para_el_invitado ON invitaciones FOR SELECT
  USING (celular = NULLIF(current_setting('app.celular', true), ''));
CREATE TRIGGER no_se_borra BEFORE DELETE ON invitaciones
  FOR EACH ROW EXECUTE FUNCTION moca_no_se_borra();

-- --- Cambios -----------------------------------------------------------------

-- Cada vez que una fila se crea o cambia de verdad, toma el siguiente número.
-- El teléfono pide «lo nuevo desde el cambio N». Si una subida repite una
-- fila igual, su número no cambia.
CREATE SEQUENCE moca_cambios;

CREATE FUNCTION moca_marcar_cambio() RETURNS trigger
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND (to_jsonb(NEW) - 'cambio') = (to_jsonb(OLD) - 'cambio') THEN
    NEW.cambio := OLD.cambio;
  ELSE
    NEW.cambio := nextval('moca_cambios');
  END IF;
  RETURN NEW;
END
$$;

DO $$
DECLARE
  tabla text;
BEGIN
  FOREACH tabla IN ARRAY ARRAY[
    'empresas', 'membresias', 'cuentas', 'categorias', 'contrapartes', 'comprobantes',
    'items_comprobante', 'movimientos', 'arqueos', 'arqueo_cuentas', 'dias_cerrados',
    'alertas', 'videos_vistos', 'bitacora'
  ] LOOP
    EXECUTE format('ALTER TABLE %I NO FORCE ROW LEVEL SECURITY', tabla);
    EXECUTE format('ALTER TABLE %I ADD COLUMN cambio bigint', tabla);
    -- La bitácora no se modifica: su regla se aparta un momento.
    IF tabla = 'bitacora' THEN
      EXECUTE 'ALTER TABLE bitacora DISABLE TRIGGER bitacora_fija';
    END IF;
    EXECUTE format('UPDATE %I SET cambio = nextval(''moca_cambios'')', tabla);
    IF tabla = 'bitacora' THEN
      EXECUTE 'ALTER TABLE bitacora ENABLE TRIGGER bitacora_fija';
    END IF;
    EXECUTE format('ALTER TABLE %I ALTER COLUMN cambio SET NOT NULL', tabla);
    EXECUTE format(
      'CREATE TRIGGER marcar_cambio BEFORE INSERT OR UPDATE ON %I '
      'FOR EACH ROW EXECUTE FUNCTION moca_marcar_cambio()', tabla);
    EXECUTE format(
      'CREATE INDEX %I ON %I (%I, cambio)',
      tabla || '_por_cambio', tabla, CASE WHEN tabla = 'empresas' THEN 'id' ELSE 'empresa_id' END);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', tabla);
  END LOOP;
END
$$;
