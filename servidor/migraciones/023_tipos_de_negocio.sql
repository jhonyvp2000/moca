-- Entrega 48: más tipos de negocio (decisiones.md, 10-11-2026). Los cuatro
-- de antes siguen igual. Las migraciones con datos empiezan así (ver 011).
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE empresas DROP CONSTRAINT empresas_tipo_negocio_check;
ALTER TABLE empresas ADD CONSTRAINT empresas_tipo_negocio_check CHECK (tipo_negocio IN (
  'bodega', 'restaurante', 'servicios', 'otro', 'mercado', 'comida', 'panaderia', 'ferreteria',
  'farmacia', 'agroveterinaria', 'libreria', 'ropa', 'celulares', 'peluqueria', 'taller',
  'transporte'
));
