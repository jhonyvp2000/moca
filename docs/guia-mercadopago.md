# Guía: activar el pago con Mercado Pago

Para que los dueños paguen Moca con Mercado Pago (entrega 32). Tiempo: unos 15 minutos. Está basada en la guía de TVSamGo (`docs/guia-cambiar-cuenta-mercadopago.md` de ese repositorio), con lo que allá ya se aprendió.

La plata entra a tu misma cuenta de Mercado Pago. Moca tiene su propia **aplicación** dentro de esa cuenta, con su propio token, su propia clave y su propio webhook. Así, cambiar una credencial de TVSamGo no deja a Moca sin cobrar, y los avisos de una app no le llegan a la otra.

## Las dos credenciales

| Credencial | Cómo se ve | Para qué sirve |
|---|---|---|
| **Access Token** de producción | `APP_USR-...` (unos 70 caracteres) | El servidor crea el pago y lo consulta |
| **Clave secreta** del webhook | 64 caracteres hexadecimales | Comprueba que el aviso de pago venga de Mercado Pago de verdad |

No son la *Public Key* (también empieza con `APP_USR-`, pero no se usa) ni el *Client ID / Client Secret*.

**Regla de oro:** las dos salen de **la misma aplicación**. Si no, la firma del aviso nunca valida y los pagos no se activan solos.

Nunca las pegues en el chat ni en el repositorio: el repositorio es público. Van solo en el panel de Render.

## Paso 1. Crear la aplicación «moca»

1. Entra a `mercadopago.com.pe` con tu cuenta, la misma que cobra TVSamGo.
2. Ve a `https://www.mercadopago.com.pe/developers/panel/app`.
3. **Crear aplicación**: nombre `moca`, producto **CheckoutPro** (pagos online).

## Paso 2. Copiar el Access Token

1. En la aplicación `moca`, menú lateral → **Credenciales de producción**.
2. Si aparece **Activar credenciales**, tócalo.
3. Copia el **Access Token** con el **ícono 📋**. Nunca lo selecciones a mano: el campo se ve cortado y se copia incompleto.

## Paso 3. Configurar el webhook y copiar la clave secreta

1. Menú lateral → **Webhooks** → **Configurar notificaciones**.
2. Pestaña **Modo productivo** (no «Modo de prueba»).
3. **URL de producción:** `https://moca-servidor.onrender.com/mercadopago/webhook`
4. **Eventos:** marca solo **Pagos**.
5. **Guardar**. Abajo aparece la **Clave secreta**: cópiala con su ícono 📋.

## Paso 4. Ponerlas en Render

1. En Render, abre el servicio `moca-servidor` → **Environment**.
2. Pega el Access Token en `MP_ACCESS_TOKEN` y la clave en `MP_WEBHOOK_SECRET`.
3. Guarda. Render reinicia el servidor solo.
4. Abre `https://moca-servidor.onrender.com/salud`: tiene que decir la versión **0.32.0** o una más nueva.

Desde ese momento, «Cómo pagar» muestra **Pagar con Mercado Pago** a los dueños, con el cobro ya empezado (`MOCA_COBRO_DESDE`).

## Paso 5. Probar con un pago real chico

El modo de prueba de Mercado Pago para Perú no funciona (TVSamGo lo comprobó en julio de 2026: rechaza sus propias tarjetas de prueba). La prueba honesta es un pago real:

1. Desde un teléfono que **no** esté conectado a tu cuenta de Mercado Pago (no puedes pagarte a ti mismo), entra a Moca como dueño de un negocio de prueba.
2. Pestaña Moca → **Cómo pagar** → **Pagar con Mercado Pago** → paga con Yape.
3. En la página de regreso, toca **«Volver a Moca»** (entrega 32.1): debe volver la misma Moca, con la espera del pago, y en segundos decir «Listo. Moca está pagada hasta el…». En «Recientes» tiene que haber una sola Moca.
4. En el ajuste oculto → **Cobros**, busca ese negocio: el pago aparece con la nota «Mercado Pago · operación …».
5. Si fue solo prueba, devuélvelo desde tu panel de Mercado Pago. Moca lo anula sola.

## Trampas conocidas (todas le pasaron a TVSamGo)

- **Token copiado a mano se corta:** usa siempre el ícono 📋.
- **La clave del modo de prueba no es la del modo productivo:** cada pestaña tiene la suya.
- **Mercado Pago responde «OK» aunque descarte el aviso:** si los pagos no se activan solos, casi siempre el token y la clave son de aplicaciones distintas. Aun así, el servidor repasa los pagos cada 5 minutos y los aplica.
- **Si una credencial se expone** (captura, chat, registro): regenérala en el panel (⟳ junto a la clave, «Renovar» en el token) y vuelve a ponerla en Render.

## Si un pago queda «por revisar»

En **Cobros** aparece «Pagos de Mercado Pago por revisar» cuando Mercado Pago cobró pero Moca no pudo aplicarlo sola:

| Motivo | Qué pasó | Qué hacer |
|---|---|---|
| cobró menos de lo que vale | El monto no cubre el mes | Devolver el pago o registrar el mes a mano |
| ya no había cupo de fundador | Se llenaron los 50 mientras pagaba | Devolver la diferencia o registrarlo a mano |
| ya no le tocaba el precio de fundador | Renovó más de 30 días tarde | Igual que el anterior |
| devuelto, y no era su último pago | Se devolvió un pago con otro después | Anular a mano los pagos que correspondan |
