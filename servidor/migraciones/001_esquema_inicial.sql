-- Esquema inicial de Moca (docs/modelo-datos.md).
--
-- Reglas que la base hace cumplir por sí misma, aunque el código falle:
-- - Aislamiento por empresa (RLS): cada consulta ve solo la empresa fijada
--   en la transacción con app.empresa_id. FORCE hace que la regla valga
--   también para el dueño de las tablas.
-- - Las referencias entre tablas llevan empresa_id, así un registro no puede
--   apuntar a la cuenta o la categoría de otra empresa.
-- - Nada se borra: los registros se anulan y el cambio queda en la bitácora.
--   La bitácora tampoco se modifica.
-- - Montos en céntimos, enteros.
-- - Los valores de texto fijos usan los mismos nombres que la app
--   (TipoCuenta.plin → 'plin'), para que la sincronización no traduzca nada.
-- - Los identificadores de los registros se generan en el teléfono (uuid):
--   subir dos veces lo mismo no lo duplica.

-- La empresa y el usuario de la transacción en curso.
CREATE FUNCTION moca_empresa_actual() RETURNS uuid
  LANGUAGE sql STABLE
  AS $$ SELECT NULLIF(current_setting('app.empresa_id', true), '')::uuid $$;

CREATE FUNCTION moca_usuario_actual() RETURNS uuid
  LANGUAGE sql STABLE
  AS $$ SELECT NULLIF(current_setting('app.usuario_id', true), '')::uuid $$;

CREATE FUNCTION moca_no_se_borra() RETURNS trigger
  LANGUAGE plpgsql
  AS $$
BEGIN
  RAISE EXCEPTION 'En Moca nada se borra: % se anula y queda en la bitácora', TG_TABLE_NAME
    USING ERRCODE = 'restrict_violation';
END
$$;

CREATE FUNCTION moca_bitacora_fija() RETURNS trigger
  LANGUAGE plpgsql
  AS $$
BEGIN
  RAISE EXCEPTION 'La bitácora no se modifica'
    USING ERRCODE = 'restrict_violation';
END
$$;

-- --- Personas y empresas ---------------------------------------------------

CREATE TABLE usuarios (
  id         uuid PRIMARY KEY,
  celular    text UNIQUE,
  nombre     text,
  creado_en  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE empresas (
  id                     uuid PRIMARY KEY,
  nombre                 text NOT NULL,
  tipo_negocio           text NOT NULL CHECK (tipo_negocio IN ('bodega', 'restaurante', 'servicios', 'otro')),
  modo                   text NOT NULL DEFAULT 'simple' CHECK (modo IN ('simple', 'formal')),
  pais                   text NOT NULL DEFAULT 'PE',
  moneda                 text NOT NULL DEFAULT 'PEN',
  regimen                text,
  -- Minutos desde la medianoche (21:00 = 1260).
  hora_cierre_minutos    integer NOT NULL CHECK (hora_cierre_minutos BETWEEN 0 AND 1439),
  identificacion_fiscal  text,
  creado_en              timestamptz NOT NULL DEFAULT now()
);

-- Usuario y empresa, de muchos a muchos. En la V1 solo existe el rol dueño.
CREATE TABLE membresias (
  id          uuid PRIMARY KEY,
  empresa_id  uuid NOT NULL REFERENCES empresas (id),
  usuario_id  uuid NOT NULL REFERENCES usuarios (id),
  rol         text NOT NULL CHECK (rol IN ('dueno', 'contador', 'empleado')),
  creado_en   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (empresa_id, usuario_id)
);

-- --- Dónde está la plata y en qué se usa -----------------------------------

CREATE TABLE cuentas (
  id                       uuid PRIMARY KEY,
  empresa_id               uuid NOT NULL REFERENCES empresas (id),
  tipo                     text NOT NULL CHECK (tipo IN ('efectivo', 'yape', 'banco', 'plin', 'sip', 'otra')),
  nombre                   text NOT NULL,
  orden                    integer NOT NULL,
  -- Nulo mientras el dueño no declara su saldo inicial.
  saldo_inicial_centimos   bigint,
  fecha_saldo_inicial      timestamptz,
  UNIQUE (empresa_id, id),
  UNIQUE (empresa_id, tipo)
);

CREATE TABLE categorias (
  id               uuid PRIMARY KEY,
  empresa_id       uuid NOT NULL REFERENCES empresas (id),
  nombre           text NOT NULL,
  tipo_movimiento  text NOT NULL CHECK (tipo_movimiento IN ('ingreso', 'egreso', 'retiro')),
  orden            integer NOT NULL,
  activa           boolean NOT NULL DEFAULT true,
  UNIQUE (empresa_id, id),
  UNIQUE (empresa_id, tipo_movimiento, nombre)
);

CREATE TABLE contrapartes (
  id                     uuid PRIMARY KEY,
  empresa_id             uuid NOT NULL REFERENCES empresas (id),
  nombre                 text NOT NULL,
  identificacion_fiscal  text,
  tipo                   text NOT NULL CHECK (tipo IN ('cliente', 'proveedor')),
  UNIQUE (empresa_id, id)
);

-- --- Comprobantes ----------------------------------------------------------

CREATE TABLE comprobantes (
  id                     uuid PRIMARY KEY,
  empresa_id             uuid NOT NULL REFERENCES empresas (id),
  emisor_identificacion  text,
  emisor_nombre          text,
  tipo                   text,
  serie                  text,
  numero                 text,
  fecha_emision          date,
  subtotal_centimos      bigint,
  impuesto_centimos      bigint,
  total_centimos         bigint NOT NULL CHECK (total_centimos >= 0),
  -- Dónde está la imagen en el almacén (entrega 14).
  imagen_clave           text,
  origen_lectura         text NOT NULL CHECK (origen_lectura IN ('qr', 'foto', 'sire')),
  validaciones           jsonb,
  creado_en              timestamptz NOT NULL DEFAULT now(),
  UNIQUE (empresa_id, id),
  -- Un comprobante no se registra dos veces en la misma empresa.
  UNIQUE (empresa_id, emisor_identificacion, tipo, serie, numero)
);

CREATE TABLE items_comprobante (
  id                        uuid PRIMARY KEY,
  empresa_id                uuid NOT NULL REFERENCES empresas (id),
  comprobante_id            uuid NOT NULL,
  descripcion               text NOT NULL,
  cantidad                  numeric,
  precio_unitario_centimos  bigint,
  importe_centimos          bigint NOT NULL,
  FOREIGN KEY (empresa_id, comprobante_id) REFERENCES comprobantes (empresa_id, id)
);

-- --- Movimientos: la unidad de todo informe ----------------------------------

CREATE TABLE movimientos (
  id                      uuid PRIMARY KEY,
  empresa_id              uuid NOT NULL REFERENCES empresas (id),
  -- El retiro baja la caja pero no es gasto del negocio.
  tipo                    text NOT NULL CHECK (tipo IN ('ingreso', 'egreso', 'retiro')),
  cuenta_id               uuid NOT NULL,
  monto_centimos          bigint NOT NULL CHECK (monto_centimos > 0),
  fecha_movimiento        timestamptz NOT NULL,
  fecha_comprobante       timestamptz,
  estado_pago             text NOT NULL CHECK (estado_pago IN ('pagado', 'pendiente', 'parcial')),
  monto_pagado_centimos   bigint NOT NULL CHECK (monto_pagado_centimos >= 0),
  fecha_vencimiento       timestamptz,
  -- Cuándo salió la plata de la cuenta; nulo mientras se debe.
  fecha_pago              timestamptz,
  categoria_id            uuid,
  contraparte_id          uuid,
  comprobante_id          uuid,
  nivel_confianza         text NOT NULL CHECK (nivel_confianza IN ('a', 'b', 'c', 'd')),
  fuente                  text NOT NULL CHECK (fuente IN ('voz', 'texto', 'foto', 'qr', 'sire', 'arqueo')),
  autor_id                uuid NOT NULL REFERENCES usuarios (id),
  nota                    text,
  estado                  text NOT NULL DEFAULT 'vigente' CHECK (estado IN ('vigente', 'anulado')),
  -- En una corrección, el movimiento anulado que este reemplaza.
  reemplaza_a             uuid,
  creado_en               timestamptz NOT NULL,
  -- Cuándo llegó al servidor.
  recibido_en             timestamptz NOT NULL DEFAULT now(),
  UNIQUE (empresa_id, id),
  FOREIGN KEY (empresa_id, cuenta_id) REFERENCES cuentas (empresa_id, id),
  FOREIGN KEY (empresa_id, categoria_id) REFERENCES categorias (empresa_id, id),
  FOREIGN KEY (empresa_id, contraparte_id) REFERENCES contrapartes (empresa_id, id),
  FOREIGN KEY (empresa_id, comprobante_id) REFERENCES comprobantes (empresa_id, id),
  FOREIGN KEY (empresa_id, reemplaza_a) REFERENCES movimientos (empresa_id, id)
);

CREATE INDEX movimientos_por_fecha ON movimientos (empresa_id, fecha_movimiento);

-- --- Arqueo semanal ----------------------------------------------------------

CREATE TABLE arqueos (
  id          uuid PRIMARY KEY,
  empresa_id  uuid NOT NULL REFERENCES empresas (id),
  fecha       timestamptz NOT NULL,
  autor_id    uuid NOT NULL REFERENCES usuarios (id),
  creado_en   timestamptz NOT NULL,
  UNIQUE (empresa_id, id)
);

-- Por cuenta: lo calculado, lo contado y el motivo de la diferencia. «Di mal
-- un vuelto» y «No lo sé» no generan movimiento: la diferencia ajusta el
-- saldo desde la fecha del arqueo.
CREATE TABLE arqueo_cuentas (
  id                         uuid PRIMARY KEY,
  empresa_id                 uuid NOT NULL REFERENCES empresas (id),
  arqueo_id                  uuid NOT NULL,
  cuenta_id                  uuid NOT NULL,
  saldo_calculado_centimos   bigint NOT NULL,
  saldo_real_centimos        bigint NOT NULL,
  diferencia_centimos        bigint NOT NULL,
  motivo                     text CHECK (motivo IN ('retiroParaMi', 'gastoOlvidado', 'ventaNoAnotada', 'errorDeVuelto', 'noLoSe')),
  movimiento_id              uuid,
  FOREIGN KEY (empresa_id, arqueo_id) REFERENCES arqueos (empresa_id, id),
  FOREIGN KEY (empresa_id, cuenta_id) REFERENCES cuentas (empresa_id, id),
  FOREIGN KEY (empresa_id, movimiento_id) REFERENCES movimientos (empresa_id, id)
);

-- --- Avisos, días cerrados, periodos y reglas ---------------------------------

CREATE TABLE alertas (
  id          uuid PRIMARY KEY,
  empresa_id  uuid NOT NULL REFERENCES empresas (id),
  -- Identifica el aviso para no repetirlo (por ejemplo, el arqueo de una semana).
  clave       text NOT NULL,
  tipo        text NOT NULL,
  prioridad   text NOT NULL CHECK (prioridad IN ('importante', 'paraTenerEnCuenta')),
  estado      text NOT NULL CHECK (estado IN ('pendiente', 'vista', 'resuelta', 'silenciada')),
  texto       text NOT NULL,
  -- Los datos que dispararon el aviso.
  datos       jsonb NOT NULL DEFAULT '{}',
  creado_en   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (empresa_id, clave)
);

-- Los días que el dueño marcó «Hoy no abrí».
CREATE TABLE dias_cerrados (
  id          uuid PRIMARY KEY,
  empresa_id  uuid NOT NULL REFERENCES empresas (id),
  dia         date NOT NULL,
  UNIQUE (empresa_id, dia)
);

-- Un mes cerrado no admite cambios del dueño (llega con el cierre de mes).
CREATE TABLE periodos (
  id          uuid PRIMARY KEY,
  empresa_id  uuid NOT NULL REFERENCES empresas (id),
  mes         date NOT NULL CHECK (extract(day FROM mes) = 1),
  estado      text NOT NULL DEFAULT 'abierto' CHECK (estado IN ('abierto', 'cerrado')),
  UNIQUE (empresa_id, mes)
);

-- Un proveedor o un texto que fija una categoría, por empresa.
CREATE TABLE reglas_clasificacion (
  id              uuid PRIMARY KEY,
  empresa_id      uuid NOT NULL REFERENCES empresas (id),
  contraparte_id  uuid,
  texto           text,
  categoria_id    uuid NOT NULL,
  CHECK (contraparte_id IS NOT NULL OR texto IS NOT NULL),
  FOREIGN KEY (empresa_id, contraparte_id) REFERENCES contrapartes (empresa_id, id),
  FOREIGN KEY (empresa_id, categoria_id) REFERENCES categorias (empresa_id, id)
);

-- Quién cambió qué y cuándo, con el valor anterior y el nuevo.
CREATE TABLE bitacora (
  id              uuid PRIMARY KEY,
  empresa_id      uuid NOT NULL REFERENCES empresas (id),
  autor_id        uuid NOT NULL REFERENCES usuarios (id),
  entidad         text NOT NULL,
  entidad_id      uuid NOT NULL,
  accion          text NOT NULL CHECK (accion IN ('crear', 'editar', 'anular', 'pagar', 'arquear')),
  valor_anterior  jsonb,
  valor_nuevo     jsonb,
  fecha           timestamptz NOT NULL
);

CREATE INDEX bitacora_por_entidad ON bitacora (empresa_id, entidad, entidad_id);

CREATE TRIGGER bitacora_fija
  BEFORE UPDATE ON bitacora
  FOR EACH ROW EXECUTE FUNCTION moca_bitacora_fija();

-- --- Aislamiento y «nada se borra» en todas las tablas ----------------------

-- La empresa se ve a sí misma.
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE empresas FORCE ROW LEVEL SECURITY;
CREATE POLICY por_empresa ON empresas
  USING (id = moca_empresa_actual())
  WITH CHECK (id = moca_empresa_actual());

-- Un usuario se ve a sí mismo y a quienes comparten la empresa en curso.
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios FORCE ROW LEVEL SECURITY;
CREATE POLICY propio_o_de_la_empresa ON usuarios
  USING (id = moca_usuario_actual() OR id IN (SELECT usuario_id FROM membresias))
  WITH CHECK (id = moca_usuario_actual());

DO $$
DECLARE
  tabla text;
BEGIN
  FOREACH tabla IN ARRAY ARRAY[
    'membresias', 'cuentas', 'categorias', 'contrapartes', 'comprobantes',
    'items_comprobante', 'movimientos', 'arqueos', 'arqueo_cuentas', 'alertas',
    'dias_cerrados', 'periodos', 'reglas_clasificacion', 'bitacora'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tabla);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', tabla);
    EXECUTE format(
      'CREATE POLICY por_empresa ON %I USING (empresa_id = moca_empresa_actual()) '
      'WITH CHECK (empresa_id = moca_empresa_actual())', tabla);
  END LOOP;

  FOREACH tabla IN ARRAY ARRAY[
    'usuarios', 'empresas', 'membresias', 'cuentas', 'categorias', 'contrapartes',
    'comprobantes', 'items_comprobante', 'movimientos', 'arqueos', 'arqueo_cuentas',
    'alertas', 'dias_cerrados', 'periodos', 'reglas_clasificacion', 'bitacora'
  ] LOOP
    EXECUTE format(
      'CREATE TRIGGER no_se_borra BEFORE DELETE ON %I '
      'FOR EACH ROW EXECUTE FUNCTION moca_no_se_borra()', tabla);
  END LOOP;
END
$$;
