-- Entrega 14: cada foto que lee la IA. Sirve para el tope diario por
-- usuario y para medir la prueba 1 de la Fase 0 (qué modelo leyó, cuánto
-- costó y, comparando con el comprobante que guardó el dueño, cuánto
-- acertó). La foto no se guarda. Es del usuario, no de una empresa: sin
-- RLS, como las sesiones; solo el servidor la usa.
CREATE TABLE lecturas (
  id                 bigserial PRIMARY KEY,
  usuario_id         uuid NOT NULL REFERENCES usuarios (id),
  fecha              timestamptz NOT NULL DEFAULT now(),
  resultado          text NOT NULL CHECK (resultado IN ('leido', 'ilegible', 'no_es_comprobante', 'error')),
  -- El último modelo que leyó, y si hizo falta el mayor.
  modelo             text,
  escalo             boolean NOT NULL DEFAULT false,
  -- Lo que dijo cada modelo y qué no cuadró.
  pasos              jsonb NOT NULL DEFAULT '[]',
  costo_microdolares integer NOT NULL DEFAULT 0,
  milisegundos       integer NOT NULL
);

CREATE INDEX lecturas_por_usuario ON lecturas (usuario_id, fecha);
