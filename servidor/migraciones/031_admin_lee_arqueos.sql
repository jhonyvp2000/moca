-- 26-11-2026: el informe de uso (`npm run uso-pilotos`) contaba 0 arqueos
-- porque el administrador no podía leer esas tablas. Solo lectura, como ya
-- tiene en empresas, usuarios, membresias y movimientos (migración 014).
SET CONSTRAINTS ALL IMMEDIATE;

CREATE POLICY admin_lee ON arqueos FOR SELECT USING (moca_es_admin());
CREATE POLICY admin_lee ON arqueo_cuentas FOR SELECT USING (moca_es_admin());
