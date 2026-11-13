-- Entrega 74: «Pregúntale a Moca», solo para dueños. Se guarda cuántas
-- preguntas hizo cada negocio cada día (el tope es 20) y lo que costó, nunca
-- el texto de la pregunta ni de la respuesta.

SET CONSTRAINTS ALL IMMEDIATE;

CREATE TABLE preguntas (
  id               bigserial PRIMARY KEY,
  empresa_id       uuid NOT NULL REFERENCES empresas (id) ON DELETE CASCADE,
  usuario_id       uuid NOT NULL REFERENCES usuarios (id),
  fecha            timestamptz NOT NULL DEFAULT now(),
  resultado        text NOT NULL CHECK (resultado IN ('respondida', 'error')),
  modelo           text,
  tokens_entrada   integer NOT NULL DEFAULT 0,
  tokens_salida    integer NOT NULL DEFAULT 0,
  milisegundos     integer NOT NULL DEFAULT 0
);

CREATE INDEX preguntas_por_empresa ON preguntas (empresa_id, fecha);
