# Servidor de Moca

Servidor de la V1 real (`docs/v1-real.md`): Node con TypeScript y Fastify, y PostgreSQL. Se publica en Render con `render.yaml`, en la raíz del repositorio.

## Lo que garantiza la base de datos

La base hace cumplir estas reglas por sí misma, aunque el código del servidor tenga un error:

- **Aislamiento por empresa (RLS).** Toda consulta ve solo la empresa fijada en la transacción (`conEmpresa`). Sin empresa fijada, las tablas no devuelven nada. La regla vale también para el dueño de las tablas (`FORCE`).
- **Referencias dentro de la empresa.** Un movimiento no puede apuntar a la cuenta, la categoría o el comprobante de otra empresa.
- **Nada se borra.** Un `DELETE` en cualquier tabla de negocio falla; los registros se anulan. La bitácora tampoco se modifica.
- **Sin duplicados.** Los identificadores vienen del teléfono: subir dos veces el mismo registro no lo duplica.
- **Número de cambio (entrega 17).** Cada fila que se crea o cambia de verdad toma el siguiente número de `moca_cambios`; si una subida repite una fila igual, su número no cambia. Así cada teléfono baja solo lo nuevo.

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
| `POST /cuenta/codigo` | Envía el código por SMS al celular (`{celular}`, 9 dígitos). Con `marcaApp` (11 caracteres, entrega 14.7), Twilio la pone al final del SMS (`AppHash`) para que Android se lo dé a Moca y el código se escriba solo; sin ella o con otro formato, el SMS sale sin marca. Máximo 5 pedidos por número y 20 por conexión en una hora. |
| `POST /cuenta/verificar` | Comprueba el código. Con `modo: "guardar"` (`{celular, codigo, usuarioId}`) crea la cuenta o reconoce que el número ya tenía otra (entonces no da llave). Con `modo: "entrar"` («Ya tengo cuenta») no crea nada: si el número no tiene cuenta con datos, responde 404. Con `modo: "invitado"` (`{celular, codigo, usuarioId}`, entrega 17) entra quien tiene una invitación vigente: crea la cuenta si hace falta y devuelve la llave y sus `invitaciones`; sin invitación, 404 `sin_invitacion`. Cada llave nueva revoca la de cualquier otro teléfono. |
| `POST /cuenta/con-pase` | Tras verificar un número que ya tenía cuenta desde un teléfono con datos propios (`cuentaExistente` con `pase`, de un solo uso, 15 minutos): `accion: "entrar"` da la llave de esa cuenta; `accion: "empezar_de_cero"` (con `usuarioId` del teléfono) archiva la cuenta anterior (`celular_archivado`, sin borrar nada), revoca su llave y crea la cuenta con el usuario del teléfono. Pase usado o vencido: 410. |
| `POST /cuenta/borrar-datos` | Con la llave y `{confirmacion: "BORRAR"}` (entrega 14.8; desde la 17, solo el titular; otro miembro recibe 403 `solo_titular`): borra para siempre el negocio del dueño con todo lo suyo, y sus fotos leídas (`lecturas`). El número queda, sin datos; sus llaves se revocan y queda anotado en `borrados`. Sin la confirmación, 400. |
| `POST /datos/subir` | Con la llave (`Authorization: Bearer …`), guarda lo que el teléfono tiene de su empresa (todo, o solo lo que cambió), incluidos los avisos marcados «Entendido» y los videos de ayuda abiertos (`videos_vistos`, entrega 14.6). Repetirlo no duplica nada. Acepta el cuerpo comprimido (`Content-Encoding: gzip`). Desde la entrega 17 revisa el rol fila por fila: lo nuevo lleva como autor a quien sube; corregir lo de otro, solo dueños y encargado; el ayudante solo anota y deshace lo suyo del día; cuentas, categorías y la empresa, solo los dueños; el contador no sube (403 `sin_permiso`). Lo que llega igual a lo que ya está no cuenta como cambio. |
| `GET /datos/bajar` | Con la llave, devuelve lo de la empresa que su rol puede ver (al ayudante, las cuentas sin saldo inicial, las categorías y lo que él anotó; sin cifras), con las mismas tablas y columnas que se suben, y sus cifras, comprimido si el teléfono lo acepta. |
| `GET /cifras` | Con la llave, las cifras de la empresa en este momento: saldos, Inicio, resumen de la semana, avisos (sin los marcados «Entendido») e informe de cada mes. `POST /datos/subir` también las devuelve, con lo recién subido. |
| `GET /datos/cambios?desde=N` | Con la llave (entrega 17), lo nuevo de la empresa desde el cambio `N` que el rol puede ver, con `hasta` (el número desde el que pedir la próxima vez), el `rol` y si es `titular`. `GET /datos/bajar` también devuelve `hasta`. Si ya no está en la empresa, 403 `sin_negocio`. Con `?empresa=` (el contador en varios negocios), esa empresa; vale también en `/datos/bajar`, `/cifras` y `/equipo`. |
| `GET /equipo` | Con la llave, quiénes están en el negocio (`personas`, con su `rol` y `nombre`; el celular solo para los dueños) y, para los dueños, las `invitaciones` vigentes. |
| `POST /equipo/invitar` | Un dueño invita `{celular, rol, nombre}` (rol `dueno`, `encargado`, `ayudante` o `contador`). Hasta 3 personas por negocio con el titular, contando las invitaciones vigentes; el contador no cuenta (409 `sin_lugar`). Invitar otra vez el mismo número reemplaza la invitación. Vence a los 7 días. |
| `POST /equipo/anular` · `POST /equipo/quitar` | Un dueño anula una invitación (`{invitacion}`) o quita a una persona (`{membresia}`). Quitar no borra nada: lo que anotó se queda y su teléfono ya no entra. Al titular nadie lo quita. |
| `GET /cuenta/invitaciones` · `POST /cuenta/aceptar` | Las invitaciones vigentes para el celular de la cuenta, con el nombre del `negocio`; aceptar pide `{invitacion, consentimiento: true}` (Ley 29733). Una persona está en un solo negocio (409 `ya_tiene_negocio`), salvo el contador. |
| `POST /comprobantes/leer` | Con la llave, lee la foto de un comprobante (`{imagen, tipo, categorias}`, imagen en base64): primero Claude Haiku 5.5 y, si lo leído no cuadra, Claude Sonnet 5.5. Responde `leido`, `ilegible` (con lo que sí se leyó) o `no_es_comprobante`. Máximo 30 fotos por usuario al día (429). Sin `ANTHROPIC_API_KEY`, 503. La foto no se guarda; cada lectura queda en `lecturas`. |
| `POST /comprobantes/leer-prueba` | Sin llave: lo mismo, con `telefono` (el identificador del usuario que generó la app). 3 fotos de prueba por teléfono (`pruebasRestantes` en la respuesta; 429 `pruebas_agotadas`), y como máximo 10 al día por conexión y 200 al día en total (429 `pruebas_no_disponibles`). Las lecturas fallidas no gastan pruebas. |

## Cifras (entrega 13)

`src/cifras/calcular.ts` calcula con las mismas reglas que tenía el teléfono, en la hora del Perú (`src/pais/peru.ts`). Se calculan al pedirlas: con los datos de una empresa pequeña tardan milisegundos. La prueba `test/cifras.test.ts` compara el resultado con las cifras que calcula la app con la Demo en cinco momentos (`test/paridad/demo.json`, que arma `app/test/datos/paridad_servidor_test.dart`). Si cambia una regla, se cambia en los dos lados y se rehace ese archivo.

## Twilio

El código lo envía y lo comprueba Twilio Verify: el servidor nunca lo conoce. Se configura en Render con `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` y `TWILIO_VERIFY_SID`. Sin ellos, el servidor no da cuentas (nunca hay un código de prueba). Las llaves de los teléfonos se guardan solo como huella.
