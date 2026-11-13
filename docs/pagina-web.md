# mocanegocios.com: la página de venta de Moca

Análisis del 13-11-2026, pedido de Jhony. Es alcance nuevo: no estaba en `v1-real.md` ni en `prototipo-v1.md` (ver `decisiones.md`). Los mockups están en el canvas «Moca · Página web».

## 1. Qué «compra» la página

Hoy el camino es **instalar → 14 días gratis → pagar dentro de la app**. Nadie paga en la web. El objetivo de la página es que el dueño **empiece la prueba gratis**; la venta de Básico o Full la cierra la app con la experiencia de esos 14 días.

- Acción principal: **«Pruébalo gratis 14 días»**, no «Comprar».
- Los precios se ven como tranquilidad («menos de S/ 0.70 al día»), no como barrera.
- El mayor obstáculo es la instalación por APK. Jhony decidió avanzar con **Play Store** (13-11-2026): el botón de Google Play da confianza al instante.

## 2. A quién le hablamos

El dueño de una bodega, un puesto de mercado o un restaurante chico en el Perú. Usa el celular para todo, vive en WhatsApp y Yape, no tiene formación contable, desconfía de lo «complicado» y lee la página parado, con la tienda abierta.

Su dolor real: «vendo todo el día y a fin de mes no sé dónde se fue la plata», «me olvido de quién me debe», «el banco me pide papeles que no tengo».

## 3. Principios de comportamiento

| Principio | Cómo se aplica |
|---|---|
| Claridad en 5 segundos | Arriba, el eslogan «Tú vendes. Moca hace las cuentas» y el celular con Moca |
| Aversión a la pérdida | «¿Cuánta plata se te va sin que te des cuenta?», «Lo que te deben, Moca no lo olvida» |
| Lo concreto se cree | Capturas reales con montos, no «gestión financiera inteligente» |
| Facilidad percibida | «Lo dices y Moca lo anota», con un video corto de la voz |
| Reciprocidad y riesgo cero | «14 días gratis, sin tarjeta. Si no te sirve, no pagas y lo anotado no se borra» |
| Anclaje de precio | «S/ 19.90 al mes: menos de S/ 0.70 al día»; el anual «ahorras 2 meses» |
| El plan recomendado | Full destacado; el Básico al lado lo hace ver razonable |
| Prueba social real | Solo testimonios de pilotos reales, con autorización escrita. Nunca inventados |
| Cercanía y confianza | «Hecho en Tarapoto», WhatsApp visible, seguridad explicada en simple |
| Un solo objetivo | El mismo botón repetido, sin menús que distraigan |

## 4. Estructura (pensada para celular)

1. Inicio: eslogan, una línea de beneficio, botón «Pruébalo gratis 14 días» (Google Play) y el celular con «Tienes hoy».
2. El problema, con palabras del dueño.
3. Cómo funciona, en 3 pasos: lo dices, foto o QR → Moca hace las cuentas → ves cuánto tienes y quién te debe.
4. Lo que ganas: cuánto tienes por cuenta, lo que te deben con recordatorio por WhatsApp, funciona sin señal, el informe para tu contador, «Pregúntale a Moca».
5. Para pedir un crédito: el flujo de caja que piden la caja o el banco (diferencial del Full).
6. Video corto (guiones en `guiones-videos.md`).
7. Testimonios reales de pilotos.
8. Precios: Básico y Full, mensual y anual, Full recomendado, «14 días gratis, sin tarjeta».
9. Preguntas frecuentes (sin internet, seguridad, contador, cancelar, Yape, «no reemplaza tu contabilidad oficial»).
10. Llamado final y botón flotante de WhatsApp.

## 5. Lo que la página sola no hace

Una página convierte a quien llega, no trae visitas. Canales: WhatsApp y referidos; Facebook y TikTok locales con videos reales; cajas municipales, cooperativas, gremios y mercados (ángulo del crédito); contadores que recomienden Moca. Cada canal con su enlace (UTM) para medir cuál funciona.

## 6. Medición, píxeles y cookies (Ley 29733)

Embudo: visitas → clic en «Pruébalo gratis» → instalación → registro → pago al día 14.

Un **píxel** (de Meta para Facebook e Instagram, o la etiqueta de Google Ads o Analytics) es un código de la empresa publicitaria que se pone en la página: cada vez que alguien la visita o toca el botón, el navegador le avisa a Meta o a Google. Sirve para saber qué anuncio trajo a quién y para mostrarle anuncios después a quien visitó la página. Para eso deja **cookies** (archivos pequeños) en el navegador y le manda a esa empresa datos del visitante: la página que vio, su navegador y, a veces, datos que lo identifican.

Por la Ley 29733 de Protección de Datos Personales eso es tratar datos personales y **pasárselos a un tercero**, muchas veces fuera del Perú. Por eso:

- la **política de privacidad** de la web debe decir qué píxeles y cookies se usan, para qué, a quién se envían los datos (Meta, Google) y cómo oponerse;
- lo prudente es un **aviso de cookies** que pida permiso antes de cargar los píxeles de publicidad (los estrictamente necesarios para que la página funcione no lo necesitan);
- si al inicio no se usan píxeles, no hace falta nada de esto. Se puede empezar midiendo con los enlaces UTM y lo que reporta Play Store, y sumar píxeles cuando haya publicidad pagada.

Todo texto legal lo revisa un abogado antes de publicar, como ya está pendiente.

## 7. Cuidados legales y de confianza

- Solo afirmaciones verdaderas: nada de porcentajes sin datos.
- Política de privacidad y términos en la web, revisados por un abogado.
- Precios exactos y vigentes, idénticos a los de la app.
- Testimonios solo con autorización escrita.

## 8. Play Store

Decidido el 14-10-2026 que la V1 real se distribuye por Play Store en prueba cerrada; Jhony decide avanzar el 13-11-2026. Lo que hace falta:

1. **Cuenta de desarrollador de Google Play** (pago único de USD 25). Jhony tiene una cuenta personal y quiere una de organización para Publisher Online E.I.R.L. (13-11-2026, ver 8.1). La de **organización** pide un número D-U-N-S de la empresa; la **personal** es más rápida, pero Google exige a las cuentas personales nuevas una **prueba cerrada con al menos 12 personas durante 14 días seguidos** antes de publicar para todos. La comprueba Jhony en la consola, porque las reglas cambian.
2. **El paquete:** Play pide un **AAB** (no APK), firmado con una llave de subida, y la firma final la guarda Google («Play App Signing»). El flujo `apk.yml` tiene que sumar el armado del AAB. El identificador `pe.moca.app` queda fijo para siempre al publicar.
3. **La ficha:** nombre, ícono, capturas, descripción corta y larga, categoría (Empresa o Finanzas).
4. **Formularios:** **política de privacidad en una dirección pública** (mocanegocios.com/privacidad), **Seguridad de los datos** (qué datos se recogen y a quién se envían: Twilio, Anthropic, Mercado Pago), clasificación de contenido, público objetivo, y **acceso a la app** con una cuenta de prueba para el revisor (Moca entra por SMS).
5. **Permisos:** micrófono (voz), cámara (fotos y QR), notificaciones. Cada uno justificado.
6. **El cobro, lo más delicado:** Google Play exige usar **su sistema de facturación** para vender funciones digitales dentro de una app de la tienda (como una suscripción a Moca), con una comisión. Cobrar con Mercado Pago o Yape dentro de la versión de Play puede hacer que rechacen o retiren la app. Hay que revisar las reglas vigentes para el Perú (sistema de pagos de Google, comisión de suscripciones, programas de facturación alternativa) **antes de publicar** y decidir: Google Play Billing en la versión de Play, u otra salida que las reglas permitan. Ya estaba anotado en `pendientes.md` (29-10-2026).

### 8.1 Lo investigado sobre el cobro (13-11-2026)

**Corrección (13-11-2026):** la cuenta de Play que tiene Jhony aparece con su nombre, como **cuenta personal**, y la consola pide la **prueba cerrada de 12 personas por 14 días**. Jhony quiere publicar a nombre de su empresa, **Publisher Online E.I.R.L.**: eso pide una cuenta de organización, con el número D-U-N-S de la empresa. Hasta decidirlo, no se sube nada a la cuenta personal.

Lo encontrado, con fuentes secundarias porque la ayuda oficial de Google no se pudo abrir desde la sesión (hay que confirmarlo en la Play Console):

- **Google Play exige su facturación** para vender suscripciones o funciones digitales dentro de una app de la tienda. Para suscripciones cobra alrededor del **15 %** (hoy dividido en 10 % de servicio y 5 % de facturación).
- **El cobro alternativo** (Mercado Pago o Yape dentro de la app, con un descuento de 4 puntos en la comisión) solo existe en algunos mercados: Espacio Económico Europeo, Reino Unido, Estados Unidos, Australia, Japón, Indonesia, Sudáfrica y **Brasil**. **El Perú no aparece** en ninguna lista encontrada.
- **No se puede, dentro de la app de Play, mandar a pagar por fuera** (un enlace o un texto que diga «paga en la web»): eso es «steering» y está prohibido fuera de esos mercados.
- La excepción de «contenido que solo se usa fuera de la app» no sirve: Moca se usa justamente en la app.

Las tres salidas posibles:

| Opción | Cómo cobra | A favor | En contra |
|---|---|---|---|
| A. Google Play Billing | Dentro de la app, con la cuenta de Google | Cumple las reglas, cobro automático, renueva solo | Google se queda ~15 %; el dueño necesita un medio de pago en Google (tarjeta u otro que Google acepte en el Perú, a confirmar) |
| B. Solo consumo | Fuera de la app (web o WhatsApp); la app de Play no dice nada de cómo pagar | Sin comisión de Google, Mercado Pago y Yape | La app no puede explicar cómo pagar: al vencer la prueba, el dueño no sabe qué hacer. Riesgo de rechazo si Google lo interpreta como venta de funciones |
| C. Dos versiones | Play con Google Play Billing; el APK de la web con Mercado Pago y Yape | Cada canal con lo suyo | Dos versiones que mantener |

Recomendación: **A**, con los precios ajustados si hace falta para cubrir la comisión, y confirmar en la Play Console los medios de pago que acepta Google en el Perú.

**Decidido (13-11-2026): opción A.** Jhony eligió Google Play Billing para la versión de Play.

Fuentes: [Understanding Google Play's Payments policy](https://support.google.com/googleplay/android-developer/answer/10281818?hl=en), [Understanding user choice billing](https://support.google.com/googleplay/android-developer/answer/13821247?hl=en), [Enrolling in the external offers programme](https://support.google.com/googleplay/android-developer/answer/14372887?hl=en_mt), [Alternative billing APIs](https://developer.android.com/google/play/billing/alternative), [Adapty: Google Play billing changes](https://adapty.io/blog/google-play-billing-changes-subscriptions-fees/), [HaiPay: Google Play billing, games left out in 5 markets](https://www.haipay.net/news/google-play-user-choice-billing-games-excluded-five-markets).

## 9. Lo que falta decidir

1. El número de WhatsApp de ventas (va solo en la web publicada, no en el repositorio ni en el chat).
2. Qué pilotos dan su testimonio (nombre, foto, frase, autorización).
3. ¿Para todo tipo de negocio, o primero bodegas?
4. ¿Presupuesto para publicidad, o inicio orgánico?
5. Dónde se aloja la web (por ejemplo, un sitio estático en Render o Cloudflare Pages) y quién administra el DNS del dominio.
6. ~~Cómo se cobra en la versión de Play Store~~: Google Play Billing (13-11-2026).
