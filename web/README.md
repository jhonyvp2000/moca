# mocanegocios.com

La página de venta de Moca. El análisis y la estructura están en `docs/pagina-web.md`; los mockups, en el canvas «Moca · Página web».

Es HTML y CSS escritos a mano, sin framework ni JavaScript. Se aloja en **Cloudflare Pages** (decisiones.md, 16-11-2026).

## Qué hay aquí

| Archivo | Qué es |
|---|---|
| `sitio/index.html` | La portada |
| `sitio/privacidad.html` | La política de privacidad, en mocanegocios.com/privacidad |
| `sitio/404.html` | La página de «no encontrada» |
| `sitio/estilos.css` | Los estilos, con los colores y medidas de `diseno/estilo.md` |
| `sitio/fuentes/` | Plus Jakarta Sans (licencia OFL), servida desde la misma página: sin Google Fonts, el visitante no le pasa datos a Google |
| `sitio/_headers` | Cabeceras de seguridad que Cloudflare pone a cada página |
| `sitio/img/compartir.png`, `sitio/icono-180.png` | La imagen que se ve al compartir el enlace (WhatsApp, Facebook) y el ícono para la pantalla de inicio del celular |
| `sitio/robots.txt`, `sitio/sitemap.xml` | Para los buscadores |
| `imagenes/` | Los HTML de esas dos imágenes y `hacer.cjs`, que las rehace con Playwright: `node web/imagenes/hacer.cjs` |
| `testimonios.json` | Los testimonios de los pilotos (vacío mientras no haya) |
| `construir.mjs` | Copia `sitio/` a `dist/` y llena lo que cambia: el número de WhatsApp, y Google Play, el video y los testimonios cuando existan |

## Lo que se publica solo cuando existe

En los HTML, un bloque entre `<!--si-X-->` y `<!--fin-X-->` se publica solo si existe X; si hay una parte `<!--sino-X-->`, esa queda cuando X falta. Así la página nunca muestra un espacio vacío ni un marcador.

| X | Se publica cuando… |
|---|---|
| `whatsapp` | hay número en `WHATSAPP_VENTAS` (abajo) |
| `play` | hay enlace de Google Play (abajo) |
| `video` | están `sitio/video/moca.mp4` y `sitio/video/moca.jpg` |
| `testimonios` | `testimonios.json` tiene al menos uno |

## El número de WhatsApp de ventas

El repositorio es público, así que el número no se escribe aquí. Vive en la variable `WHATSAPP_VENTAS` del proyecto en Cloudflare Pages: `51` seguido de los 9 dígitos del celular, sin espacios (por ejemplo `51987654321`).

`{{WHATSAPP}}` es el enlace a WhatsApp con «Hola, quiero probar Moca.». Sin número, los botones llevan al correo de contacto. Un número mal escrito hace fallar la publicación, para que no salga un enlace roto.

## Cuando Moca esté en Google Play

1. Poner el enlace en `enlacePlay`, en `construir.mjs`: `https://play.google.com/store/apps/details?id=pe.moca.app`. No es secreto.
2. Bajar la **insignia oficial** «Disponible en Google Play» en español, de la página de insignias de Google Play, y guardarla **sin cambios** como `sitio/img/google-play.png`. Google no permite dibujar una propia ni modificarla.

Con eso aparecen la insignia junto al botón del inicio, «Se instala en 1 minuto · 14 días gratis · sin tarjeta» y «Se paga dentro de la app, con Google Play». Si falta la insignia o el enlace no es de Google Play, la publicación se detiene.

## Cuando haya video

Guardar el video como `sitio/video/moca.mp4` (H.264, menos de 25 MB, que es el límite de Cloudflare Pages por archivo) y una imagen de su primer cuadro como `sitio/video/moca.jpg`, de 1280 × 720. La sección «Míralo en 1 minuto» aparece, entre el crédito y los precios. El video se sirve desde la misma página, sin YouTube: así la web sigue sin cookies ni terceros. Solo debe mostrar datos de «Ver una demo» (Comercial Terra), nunca los de un negocio real (`docs/guiones-videos.md`).

## Cuando haya testimonios

Solo de pilotos reales y **con su autorización escrita**, que Jhony guarda fuera del repositorio (el repositorio es público). Cada uno va en `testimonios.json`:

```json
[
  {
    "frase": "Lo que dijo, con sus palabras",
    "nombre": "Nombre y apellido, o como autorizó que aparezca",
    "negocio": "Nombre del negocio",
    "ciudad": "Ciudad",
    "foto": "nombre.jpg",
    "autorizacion_escrita": true
  }
]
```

- `foto` es opcional: va en `sitio/img/testimonios/`, cuadrada, de 96 × 96 o más. Sin foto, se ve la inicial del nombre.
- Sin `"autorizacion_escrita": true`, o con un campo vacío, la publicación se detiene.
- Las comillas «» las pone la página: la frase va sin ellas.

## Probarla en la computadora

```bash
cd web && node construir.mjs && cd dist && python3 -m http.server 8765
```

Y abrir `http://localhost:8765`. Con número de prueba: `WHATSAPP_VENTAS=51900000000 node construir.mjs`. Al terminar, el script dice qué se publicó: `whatsapp`, `play`, `video` y `testimonios`, con sí o no.

## Puesta en marcha en Cloudflare (hecha el 17-11-2026)

El proyecto se llama `moca-web` y su dirección de Cloudflare es `moca-web-33a.pages.dev` (`moca-web.pages.dev` ya estaba tomada). `mocanegocios.com` y `www.mocanegocios.com` apuntan a él; `www` lleva a la raíz con la regla «Redirect from WWW to root», que conserva los parámetros (`?utm_source=…`). Estos fueron los pasos, por si hay que rehacerlo:

1. En el panel de Cloudflare: **Workers y Pages** → **Crear** → pestaña **Pages** → **Conectar a Git**. Autorizar GitHub (basta con el repositorio `moca`) y elegir `jhonyvp2000/moca`.
2. Configuración de la compilación:
   - Nombre del proyecto: `moca-web`
   - Rama de producción: `main`
   - Framework: **Ninguno**
   - Comando de compilación: `node construir.mjs`
   - Directorio de salida: `dist`
   - Directorio raíz (en «Avanzado»): `web`
   - Variables de entorno: `NODE_VERSION` = `22`, y `WHATSAPP_VENTAS` con el número (si todavía no está decidido, se deja sin crear y los botones llevan al correo).
3. **Guardar e implementar.** La página queda en `moca-web-33a.pages.dev`.
4. En el proyecto → **Dominios personalizados** → agregar `mocanegocios.com`, y después `www.mocanegocios.com`. Como el dominio ya está en la misma cuenta, Cloudflare crea los registros solo. Los registros del correo (MX) no se tocan: `contacto@mocanegocios.com` sigue llegando.
5. Para que `www` lleve a `mocanegocios.com`: en el dominio → **Reglas** → **Reglas de redirección** → la plantilla «Redirigir de WWW a la raíz», con **Preserve query string** marcado. Si avisa que `www` no pasa por Cloudflare, elegir «Ignore and deploy rule anyway» y revisar en **DNS** que el CNAME de `www` esté en **Proxied**.
6. **Build watch paths** (Settings → Builds) queda en `*`: se publica con cualquier cambio. El campo es una lista: se escribe `*` y se presiona Enter antes de guardar. **Nunca vacío:** con «Include paths» vacío, Cloudflare salta todas las publicaciones (⏩ «Skipped» en Deployments). Eso pasó del 17 al 21-11-2026, y por eso Web 6 no salía. Si una publicación se saltó, se rehace en Deployments → ⋯ → **Retry deployment**.

## Cómo se publica cada cambio

- Lo que se sube a **`main`** se publica en mocanegocios.com en uno o dos minutos.
- Cada **rama de trabajo** tiene su vista previa en `<rama>.moca-web-33a.pages.dev` (la dirección exacta sale en el panel, en «Implementaciones»). Ahí se revisa cada entrega en el teléfono antes de pasarla a `main`. Google no indexa esas vistas previas.

## Cuidados

- **La política de privacidad está en dos lugares** mientras el servidor siga sirviendo la suya (`servidor/src/legal/privacidad.ts`, en `/privacidad` del servidor). Si cambia, se cambian los dos, hasta que el servidor lleve a mocanegocios.com/privacidad. La web tiene además la sección «Esta página web».
- **Sin cookies ni píxeles.** Si un día se suman (Meta, Google Ads, Analytics), antes van el aviso de cookies y el cambio en la política (`docs/pagina-web.md`, sección 6). La cabecera `Content-Security-Policy` de `_headers` bloquea cualquier script: hay que cambiarla a propósito.
- Los correos van entre `<!--email_off-->` y `<!--/email_off-->` para que Cloudflare no los esconda detrás de un script, que la página bloquea.
