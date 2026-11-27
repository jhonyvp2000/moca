# La ficha de Moca en Google Play y sus formularios

Entrega 85, 16-11-2026. Todo lo que pide la Play Console para publicar Moca, listo para copiar y pegar. Sigue la línea «Para negocios» (`pagina-web.md`, sección 11): no se nombran bodegas, puestos ni el Perú. Lo que dice cada texto tiene que ser verdad en la app: si la app cambia, se cambia aquí.

Dónde va cada cosa en la Play Console: **Crecer → Presencia en la tienda → Ficha principal de la tienda** (textos e imágenes) y **Política y programas → Contenido de la app** (formularios).

## 1. Los textos de la ficha

### Nombre de la app (máximo 30 caracteres)

| Opción | Caracteres | Por qué |
|---|---|---|
| **Moca: cuentas del negocio** (recomendada) | 25 | Dice qué es y a quién sirve; «cuentas» es la palabra que busca el dueño |
| Moca: caja y cuentas | 20 | Más corta; «caja» es muy usada, pero también es el nombre de las cajas municipales |
| Moca · Tú vendes, Moca cuenta | 29 | Eslogan; dice menos qué es |

### Descripción breve (máximo 80 caracteres)

> Anota ventas y gastos en segundos. Moca hace las cuentas de tu negocio por ti.

(78 caracteres)

### Descripción completa (máximo 4000 caracteres)

> **Tú vendes. Moca hace las cuentas.**
>
> Moca es la forma más simple de saber cuánta plata tiene tu negocio, cuánto entró, en qué se fue y quién te debe. Sin formación contable y sin complicaciones: lo dices, le tomas una foto o lo escribes, y Moca ordena tus cuentas por ti.
>
> **Anota como prefieras**
> • Por voz: «Vendí 350 en efectivo» y listo.
> • Con una foto del comprobante: Moca lo lee y tú confirmas con un toque.
> • Escribiéndolo, en pocos segundos.
> • Funciona sin señal: guarda en tu teléfono y sincroniza después.
>
> **Ve cuánto tienes, de verdad**
> • «Tienes hoy»: tu plata en efectivo, billeteras digitales y banco, en una sola mirada.
> • Lo que te deben y lo que debes, sin olvidos, con recordatorio por WhatsApp para tus clientes.
> • El arqueo de caja, para que lo anotado cuadre con lo que tienes.
>
> **Informes que se entienden**
> • Cuánto entró, cuánto salió y cuánto creció tu plata, mes a mes y en el año.
> • Con qué entró la plata y en qué se fue.
> • Compártelo en PDF o Excel con tu contador.
> • Con el plan Full, el flujo de caja que piden el banco o la financiera para darte un crédito.
>
> **Pregúntale a Moca**
> «¿Qué día vendí más?», «¿Quién me debe más?»: Moca responde con las cifras de tu negocio.
>
> **Para todo tu equipo**
> Invita a tus socios, encargados o a tu contador. Cada uno ve solo lo que le toca.
>
> **Planes**
> • 14 días gratis, sin tarjeta, con todo incluido.
> • Básico: S/ 14.90 al mes o S/ 149 al año, para una persona.
> • Full: S/ 19.90 al mes o S/ 199 al año, hasta 3 personas e informes para pedir un crédito.
> • Cada persona más: S/ 2.90 al mes.
> Se paga dentro de la app, con Google Play, y lo cancelas cuando quieras. Si no pagas, Moca sigue guardando lo que anotas.
>
> **Tus datos son tuyos**
> Nunca te pedimos tus claves. Lo anotado viaja cifrado y se guarda separado del de los demás negocios. Puedes borrar todo cuando quieras.
>
> Moca te ayuda a ordenar tus cuentas. No reemplaza la contabilidad oficial ni da asesoría tributaria.

Antes de pegarla: confirma que los precios sigan iguales a los de `servidor/src/cobro/estado.ts` y que las 12 suscripciones estén creadas (`guia-google-play.md`, paso 4).

### Datos de contacto

| Campo | Valor |
|---|---|
| Correo | contacto@mocanegocios.com |
| Sitio web | https://mocanegocios.com |
| Teléfono | Opcional. Si lo pones, es público: el de ventas, no el personal |
| Política de privacidad | https://mocanegocios.com/privacidad |

### Categoría

**Empresa** (recomendada). Moca es una herramienta para llevar un negocio. «Finanzas» es la otra opción: hace que Google mire Moca como app financiera (préstamos, inversión), con más preguntas y revisión más estricta, sin ganar nada a cambio.

Etiquetas sugeridas: «Contabilidad», «Productividad», «Negocios».

## 2. Las imágenes

| Qué | Tamaño | Qué poner |
|---|---|---|
| **Ícono** | 512 × 512, PNG | El isotipo de Moca sobre azul de marca (`diseno/estilo.md`) |
| **Imagen destacada** | 1024 × 500, PNG o JPG | El eslogan «Tú vendes. Moca hace las cuentas.» y el celular con «Tienes hoy». Se puede partir de la imagen para compartir de la web (`web/sitio/img/compartir.png`, 1200 × 630) |
| **Capturas del teléfono** | De 2 a 8; mínimo 1080 px de lado; 9:16 | Las 6 de abajo, en ese orden |

Las capturas se toman en un teléfono con la **Demo** («Ver una demo», negocio «Comercial Terra»), sin datos reales de nadie. Cada una con su título arriba, corto:

1. **Inicio con «Tienes hoy»**: «Cuánto tienes, de un vistazo».
2. **Anotar por voz** (la pantalla de la voz con una frase de ejemplo): «Lo dices y Moca lo anota».
3. **Foto del comprobante leída**: «Una foto y listo».
4. **Informes del mes**: «Informes que se entienden».
5. **Lo que te deben**, con «Recordar por WhatsApp»: «Nadie se olvida de pagarte».
6. **Pregúntale a Moca** con una respuesta: «Pregúntale lo que quieras».

## 3. Contenido de la app (los formularios)

### Política de privacidad
`https://mocanegocios.com/privacidad` (desde el 24-11-2026; es el mismo texto que el del servidor, y la app abre esta)

### Acceso a la app
La cuenta del revisor: `guia-google-play.md`, «La cuenta del revisor» (entrega 82).

### Anuncios
**No**, la app no tiene anuncios.

### Clasificación de contenido
Categoría: **Utilidad, productividad, comunicación u otra**. A todas las preguntas de violencia, sexo, lenguaje, drogas y apuestas: **No**. ¿Los usuarios pueden comunicarse entre sí o compartir contenido? **No**: el equipo de un negocio ve los registros del negocio, pero no hay chat ni contenido público. Resultado esperado: apta para todos (PEGI 3 / IARC 3+).

### Público objetivo
**18 años o más**. Moca es para dueños y trabajadores de negocios (lo dice la política de privacidad). No está dirigida a niños.

### Funciones financieras
Moca **no** da préstamos, no guarda dinero, no hace pagos entre personas ni es un banco o billetera. Ayuda a llevar las cuentas del negocio y arma un informe para presentarlo a quien da el crédito. Respuesta: «Mi app no ofrece ninguna de estas funciones financieras». Si la Play Console pregunta por herramientas de gestión de dinero o presupuesto, describe Moca así: «Registro de ingresos y gastos del propio negocio; no mueve dinero».

### App del gobierno
**No**.

### Salud
**No**.

### Seguridad de los datos

Google pregunta qué datos **recoge** la app (salen del teléfono) y cuáles **comparte** con terceros. Los servicios que trabajan por encargo de Moca (Render, Twilio, Anthropic, Mercado Pago, Google) **no cuentan como compartir**, según la definición de Google. Respuestas generales:

| Pregunta | Respuesta |
|---|---|
| ¿Recoge o comparte datos? | **Sí, recoge** |
| ¿Van cifrados en tránsito? | **Sí** (HTTPS) |
| ¿El usuario puede pedir que se borren? | **Sí**. Dirección para pedirlo: `https://moca-servidor.onrender.com/borrar-cuenta` |
| ¿Se comparten con terceros? | **No** (solo con quienes procesan por encargo de Moca) |

Los tipos de datos (para cada uno: **recogido sí, compartido no**, y el resto como dice la tabla):

| Tipo de dato en Google | Qué es en Moca | ¿Obligatorio? | Para qué |
|---|---|---|---|
| Información personal → **Número de teléfono** | El celular con el que entra | Opcional (Moca funciona sin cuenta) | Funcionalidad de la app, gestión de la cuenta |
| Información personal → **Nombre** | El nombre que pone, y el de su negocio | Opcional | Funcionalidad de la app |
| Información financiera → **Otra información financiera** | Lo que anota: ventas, gastos, cuentas, deudas | Opcional (sale del teléfono solo con cuenta) | Funcionalidad de la app |
| Información financiera → **Historial de compras** | Sus pagos del plan de Moca | Opcional | Funcionalidad de la app, gestión de la cuenta |
| Fotos y videos → **Fotos** | La foto del comprobante que pide leer. **Se procesa y no se guarda** (marca «Los datos se procesan de forma efímera») | Opcional | Funcionalidad de la app |
| Contactos → no | Moca **no** lee la agenda: el celular de un cliente lo escribe el dueño | — | — |
| Audio → no | La voz la reconoce el teléfono; a Moca llega el texto, no el audio | — | — |
| Actividad en la app → **Interacciones con la app** | Qué pantallas se usan, sin lo anotado | Recogido siempre que hay cuenta | Estadísticas |
| Información y rendimiento de la app → **Registros de fallos** y **Diagnóstico** | Los errores de la app | Recogido siempre que hay cuenta | Estadísticas, corregir fallos |
| Identificadores del dispositivo → no | Moca usa su propio identificador de usuario, no el del teléfono | — | — |
| Ubicación → no | Moca no pide la ubicación | — | — |

### Permisos que pide la app

| Permiso | Para qué (si Google pregunta) |
|---|---|
| Micrófono | Anotar por voz. Solo mientras el dueño toca el micrófono |
| Cámara | Leer la foto o el QR de un comprobante |
| Notificaciones | Recordar la venta del día, los cobros y el arqueo |
| Iniciar al encender | Volver a programar esos recordatorios después de reiniciar el teléfono |
| Facturación de Google Play | Pagar el plan dentro de la app |

## 4. Antes de mandar a revisión

- [ ] La cuenta del revisor activa en Render (`guia-google-play.md`).
- [ ] La política (mocanegocios.com/privacidad) y `/borrar-cuenta` abren en el celular.
- [ ] Las 12 suscripciones creadas y con precio.
- [ ] Las capturas tomadas con la Demo, sin datos reales.
- [ ] El abogado revisó la política de privacidad y el consentimiento (`pendientes.md`).
