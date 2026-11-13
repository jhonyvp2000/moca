-- Entrega 14.8: el dueño puede borrar para siempre los datos de su negocio
-- (decisiones.md, 28-10-2026). Es la única excepción a «nada se borra»:
-- solo vale dentro de la transacción que marca `app.borrando_empresa`, y
-- solo para las filas de esa empresa. El usuario (el número) no se borra.
CREATE OR REPLACE FUNCTION moca_no_se_borra() RETURNS trigger
  LANGUAGE plpgsql
  AS $$
DECLARE
  borrando text := current_setting('app.borrando_empresa', true);
  empresa text := CASE TG_TABLE_NAME
    WHEN 'empresas' THEN to_jsonb(OLD) ->> 'id'
    ELSE to_jsonb(OLD) ->> 'empresa_id'
  END;
BEGIN
  IF TG_TABLE_NAME <> 'usuarios' AND borrando <> '' AND borrando = empresa THEN
    RETURN OLD;
  END IF;
  RAISE EXCEPTION 'En Moca nada se borra: % se anula y queda en la bitácora', TG_TABLE_NAME
    USING ERRCODE = 'restrict_violation';
END
$$;

-- Cuándo y quién borró sus datos. No es de una empresa: la empresa ya no
-- existe.
CREATE TABLE borrados (
  id          bigserial PRIMARY KEY,
  usuario_id  uuid NOT NULL REFERENCES usuarios (id),
  empresa_id  uuid NOT NULL,
  fecha       timestamptz NOT NULL DEFAULT now()
);
