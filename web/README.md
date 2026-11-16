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
| `construir.mjs` | Copia `sitio/` a `dist/`, pone el número de WhatsApp de ventas y, cuando exista, el enlace de Google Play |

## El número de WhatsApp de ventas

El repositorio es público, así que el número no se escribe aquí. Vive en la variable `WHATSAPP_VENTAS` del proyecto en Cloudflare Pages: `51` seguido de los 9 dígitos del celular, sin espacios (por ejemplo `51987654321`).

En los HTML, los botones de WhatsApp van entre `<!--si-whatsapp-->` y `<!--fin-whatsapp-->`, con `{{WHATSAPP}}` donde va el enlace. Si hay una parte `<!--sino-whatsapp-->`, esa queda cuando falta el número: por ejemplo, el botón principal lleva entonces al correo de contacto. Un número mal escrito hace fallar la publicación, para que no salga un enlace roto.

## El enlace de Google Play

Lo que va entre `<!--si-play-->` y `<!--fin-play-->` (por ahora, «Se paga dentro de la app, con Google Play») no se publica mientras `enlacePlay` esté vacío en `construir.mjs`. Cuando Moca esté en Play, se pone ahí el enlace (no es secreto) y `{{PLAY}}` lo usa (entrega Web 5).

## Probarla en la computadora

```bash
cd web && node construir.mjs && cd dist && python3 -m http.server 8765
```

Y abrir `http://localhost:8765`. Con número de prueba: `WHATSAPP_VENTAS=51900000000 node construir.mjs`.

## Puesta en marcha en Cloudflare (una sola vez, la hace Jhony)

1. En el panel de Cloudflare: **Workers y Pages** → **Crear** → pestaña **Pages** → **Conectar a Git**. Autorizar GitHub (basta con el repositorio `moca`) y elegir `jhonyvp2000/moca`.
2. Configuración de la compilación:
   - Nombre del proyecto: `moca-web`
   - Rama de producción: `main`
   - Framework: **Ninguno**
   - Comando de compilación: `node construir.mjs`
   - Directorio de salida: `dist`
   - Directorio raíz (en «Avanzado»): `web`
   - Variable de entorno: `WHATSAPP_VENTAS` con el número. Si todavía no está decidido, se deja vacía y los botones llevan al correo.
3. **Guardar e implementar.** La página queda en `moca-web.pages.dev`.
4. En el proyecto → **Dominios personalizados** → agregar `mocanegocios.com`, y después `www.mocanegocios.com`. Como el dominio ya está en la misma cuenta, Cloudflare crea los registros solo. Los registros del correo (MX) no se tocan: `contacto@mocanegocios.com` sigue llegando.
5. Para que `www` lleve a `mocanegocios.com`: en el dominio → **Reglas** → **Reglas de redirección** → la plantilla «Redirigir de WWW a la raíz».
6. En el proyecto → **Configuración** → **Compilaciones** → **Rutas de observación** (build watch paths): incluir solo `web/*`, para que los cambios de la app o del servidor no vuelvan a publicar la web.

## Cómo se publica cada cambio

- Lo que se sube a **`main`** se publica en mocanegocios.com en uno o dos minutos.
- Cada **rama de trabajo** tiene su vista previa en `<rama>.moca-web.pages.dev` (la dirección exacta sale en el panel, en «Implementaciones»). Ahí se revisa cada entrega en el teléfono antes de pasarla a `main`. Google no indexa esas vistas previas.

## Cuidados

- **La política de privacidad está en dos lugares** mientras el servidor siga sirviendo la suya (`servidor/src/legal/privacidad.ts`, en `/privacidad` del servidor). Si cambia, se cambian los dos, hasta que el servidor lleve a mocanegocios.com/privacidad. La web tiene además la sección «Esta página web».
- **Sin cookies ni píxeles.** Si un día se suman (Meta, Google Ads, Analytics), antes van el aviso de cookies y el cambio en la política (`docs/pagina-web.md`, sección 6). La cabecera `Content-Security-Policy` de `_headers` bloquea cualquier script: hay que cambiarla a propósito.
- Los correos van entre `<!--email_off-->` y `<!--/email_off-->` para que Cloudflare no los esconda detrás de un script, que la página bloquea.
