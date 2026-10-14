# Servidor de Moca

Servidor de la V1 real (`docs/v1-real.md`): Node con TypeScript y Fastify, y PostgreSQL. Se publica en Render con `render.yaml`, en la raíz del repositorio.

## Lo que garantiza la base de datos

La base hace cumplir estas reglas por sí misma, aunque el código del servidor tenga un error:

- **Aislamiento por empresa (RLS).** Toda consulta ve solo la empresa fijada en la transacción (`conEmpresa`). Sin empresa fijada, las tablas no devuelven nada. La regla vale también para el dueño de las tablas (`FORCE`).
- **Referencias dentro de la empresa.** Un movimiento no puede apuntar a la cuenta, la categoría o el comprobante de otra empresa.
- **Nada se borra.** Un `DELETE` en cualquier tabla de negocio falla; los registros se anulan. La bitácora tampoco se modifica.
- **Sin duplicados.** Los identificadores vienen del teléfono: subir dos veces el mismo registro no lo duplica.

El servidor no arranca si el rol de `DATABASE_URL` es superusuario o tiene `BYPASSRLS`, porque con ese rol el aislamiento no se aplica.

## Comandos

```sh
npm ci              # instalar
npm run revisar     # revisar los tipos
npm run probar      # pruebas (necesitan PostgreSQL; ver abajo)
npm run compilar    # compilar a dist/
npm run migrar      # aplicar migraciones pendientes (también se hace al arrancar)
npm run iniciar     # arrancar (DATABASE_URL y PORT)
```

## Pruebas

Cada archivo de pruebas crea su propia base, la migra y la borra al terminar. Usan un rol normal (`moca_prueba`, sin superusuario), para que el aislamiento se pruebe de verdad. Necesitan una conexión de administrador en `MOCA_BASE_ADMIN`; si no está, usan `postgres://moca_admin:moca@localhost:5432/postgres`. En GitHub corren solas con cada cambio en `servidor/` (`.github/workflows/servidor.yml`).

## Migraciones

Los archivos de `migraciones/` se aplican en orden, una sola vez cada uno y cada uno en su transacción. Una migración publicada no se modifica: los cambios van en un archivo nuevo.

## Rutas

| Ruta | Para qué |
|---|---|
| `GET /salud` | Si el servidor, la base y el aislamiento están bien, y qué versión corre. Render la usa para saber si el servidor está vivo. |
