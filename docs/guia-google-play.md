# Guía: poner en marcha el cobro con Google Play

Entrega 81, 14-11-2026. Paso a paso para Jhony, en orden. El código ya está hecho (entregas 77 a 80); lo que falta se hace en las consolas de Google y en Render. Ningún secreto va en el repositorio ni en el chat: la llave de Google y la clave de los avisos van **solo en el panel de Render**.

Antes de empezar hace falta la **cuenta de organización de Play** de Publisher Online E.I.R.L. (con el D-U-N-S, ver `pagina-web.md` 8.2).

## 1. La app en la Play Console

1. En **play.google.com/console** (la cuenta de organización) → **Crear app**: nombre **Moca**, idioma **Español (Latinoamérica) – es-419**, **App**, **Gratuita**.
2. **Configurar la app** (el Panel la lista): política de privacidad `https://moca-servidor.onrender.com/privacidad`, acceso a la app (una cuenta de prueba para el revisor: Moca entra por SMS, ver `pendientes.md`), anuncios (no tiene), clasificación de contenido, público objetivo (mayores de 18), Seguridad de los datos, categoría **Empresa** o **Finanzas**, correo `contacto@mocanegocios.com`.
3. **La firma.** Al crear la primera versión, Google pregunta por la firma de la app (Play App Signing). Para que los pilotos actualicen desde Play **sin desinstalar**, hay que subirle la **llave de Moca** (la que firma el APK). Eso se hace con la herramienta PEPK de Google y la llave, que vive en los secretos de GitHub: **avísale a Claude Code en ese paso** y arma un flujo de GitHub que lo haga sin que la llave salga de ahí.
4. **Prueba interna → Crear versión** y sube el **AAB** de la última `piloto-N` de Releases (`moca-piloto-N-…-play.aab`). La versión de Play se arma junto con el APK desde la entrega 77.

## 2. Google Cloud: la cuenta de servicio

Es la llave con la que el servidor le pregunta a Google por cada compra.

1. Entra a **console.cloud.google.com** con la misma cuenta de Google. Crea un proyecto: **moca-play**.
2. **APIs y servicios → Biblioteca**: busca **Google Play Android Developer API** y **Habilitar**. Busca también **Cloud Pub/Sub API** y **Habilitar**.
3. **IAM y administración → Cuentas de servicio → Crear cuenta de servicio**: nombre **moca-servidor**. No hace falta darle roles en Cloud.
4. Entra a la cuenta creada → **Claves → Agregar clave → Crear clave nueva → JSON**. Se descarga un archivo `.json`. **Es un secreto**: no lo mandes por WhatsApp ni lo pegues en el chat.
5. En la **Play Console → Usuarios y permisos → Invitar usuarios**: el correo de la cuenta de servicio (termina en `iam.gserviceaccount.com`). Permisos de la cuenta: **Ver información de la app**, **Ver información financiera**, **Administrar pedidos y suscripciones**, y **Administrar presencia en la tienda** (para crear las suscripciones). Aplica a la app Moca. Google puede tardar hasta un día en reconocer el permiso.

## 3. Render: las dos variables

En **dashboard.render.com → moca-servidor → Environment**:

| Variable | Valor |
|---|---|
| `GOOGLE_PLAY_CUENTA_SERVICIO` | Abre el `.json` con el Bloc de notas, copia **todo** y pégalo |
| `GOOGLE_PLAY_AVISOS_CLAVE` | Una clave larga al azar, solo letras y números (por ejemplo, 40 caracteres de un generador de contraseñas). Guárdala: va en el paso 5 |

**Save Changes** y luego **Manual Deploy → Deploy latest commit**. En los Logs ya no debe salir «Sin GOOGLE_PLAY_CUENTA_SERVICIO».

## 4. Las 12 suscripciones, de una vez

Con el AAB ya subido (paso 1.4), en Render → moca-servidor → **Shell**:

```
npm run suscripciones-play
```

Crea `full_0` a `full_5` y `basico_0` a `basico_5`, con los planes base **mes** y **anio** (y **fundador** en el Full), en soles y solo para el Perú, con los mismos precios del servidor. Debe terminar con «Listo: las 12 suscripciones de Moca están en Google Play.». Si se corre otra vez, las pone al día sin duplicar.

Después, en la Play Console → **Monetizar → Suscripciones**, revisa una: **confirma si Google muestra el precio con IGV incluido** y anota lo que te queda por cada una (Google se queda ~15 %). Si hay que cambiar precios, se cambian en el servidor (`servidor/src/cobro/estado.ts`) y se vuelve a correr el comando: nunca a mano en la consola.

## 5. Los avisos en tiempo real (Pub/Sub)

1. En Google Cloud → **Pub/Sub → Temas → Crear tema**: `moca-avisos-play`.
2. En el tema → **Permisos → Agregar principal**: `google-play-developer-notifications@system.gserviceaccount.com` con el rol **Publicador de Pub/Sub**.
3. En el tema → **Crear suscripción**: nombre `moca-avisos-render`, tipo **Push**, extremo:
   `https://moca-servidor.onrender.com/google/avisos?clave=<la clave del paso 3>`
4. En la Play Console → **Monetizar → Configuración de monetización → Notificaciones para desarrolladores en tiempo real**: el tema completo, `projects/moca-play/topics/moca-avisos-play`. **Enviar notificación de prueba**: en Render, los Logs no deben mostrar errores.

## 6. El perfil de pagos

Play Console → **Configuración → Perfil de pagos**: los datos de Publisher Online E.I.R.L. (RUC, dirección fiscal) y la cuenta bancaria donde Google deposita. Pregúntale a tu contador cómo se declaran esos depósitos (ver `decisiones.md`, 14-11-2026).

## 7. La prueba de punta a punta

Play Console → **Configuración → Pruebas de licencia**: agrega tu Gmail y el de 1 o 2 pilotos. Esas cuentas compran **sin que se les cobre**, y Google acelera las renovaciones: **la mensual se renueva cada 5 minutos** (hasta 6 veces) y la anual cada 30.

Instala Moca desde el enlace de la prueba interna con una de esas cuentas, entra con un negocio de prueba y revisa:

| # | Qué hacer | Qué debe pasar |
|---|---|---|
| 1 | Moca → «Activar mi plan» → Básico → «Suscribirme por S/ 14.90 al mes» | La hoja de Google dice «Compra de prueba». Al pagar: «Listo. Moca está pagada hasta …» |
| 2 | «Ver mis pagos» | Un pago por **Google Play**; el botón «Administrar en Google Play» |
| 3 | Esperar 5 minutos con Moca cerrada y abrirla | Un pago nuevo (la renovación llegó por el aviso de Google) |
| 4 | Volver a «Activar mi plan» | Dice que el plan se renueva solo con Google Play; no ofrece comprar otro |
| 5 | En Google Play → Pagos y suscripciones → cancelar Moca | Sigue pagado hasta la fecha; al vencer, «solo anotar» |
| 6 | Play Console → **Pedidos** → reembolsar el último pedido | El último pago queda anulado en «Mis pagos» |
| 7 | Comprar con la tarjeta de prueba «Rechaza siempre» | No queda pagado; si era una renovación, la tarjeta del cobro avisa que Google no pudo cobrar |
| 8 | En tu teléfono, «Cobros» | Nada en «por revisar», salvo el reembolso de un pago que no era el último |

Si algo no da lo que dice la tabla, manda a Claude Code el número del paso y una captura.
