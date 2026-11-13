-- Entrega 14.4: un teléfono con datos propios verifica un número que ya
-- tiene cuenta. Al verificar recibe un pase de un solo uso para elegir sin
-- pedir otro SMS: entrar a la cuenta (y sumar lo anotado) o empezar de cero.

-- El pase: se guarda solo su huella, como las llaves. No es de una empresa.
CREATE TABLE pases (
  id          bigserial PRIMARY KEY,
  huella      bytea NOT NULL UNIQUE,
  celular     text NOT NULL,
  usuario_id  uuid NOT NULL REFERENCES usuarios (id),
  creado_en   timestamptz NOT NULL DEFAULT now(),
  usado_en    timestamptz
);

-- «Empezar de cero»: la cuenta anterior no se borra, se archiva. El número
-- queda libre para el teléfono nuevo y se recuerda aquí.
ALTER TABLE usuarios ADD COLUMN celular_archivado text;
ALTER TABLE usuarios ADD COLUMN archivado_en timestamptz;
