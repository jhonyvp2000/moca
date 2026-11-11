-- Entrega 53: el celular del cliente para recordarle por WhatsApp, y cuándo
-- se le recordó por última vez. Solo los dueños lo ven y lo cambian: el
-- servidor se lo manda vacío a los demás roles (equipo/miembros.ts) y no
-- toma en cuenta lo que esos teléfonos suban en estas columnas
-- (datos/subir.ts). No toca datos existentes.

SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE contrapartes
  ADD COLUMN celular text,
  ADD COLUMN recordado_en timestamptz;
