# Moca

Moca («Mi Organización Contable Asistida») es una app Android con panel web que convierte comprobantes y registros del día en flujo de caja e informes que un dueño sin formación contable entiende. Eslogan: «Tú vendes. Moca hace las cuentas.»

El dueño del proyecto es Jhony Vela Paredes (Tarapoto, Perú). Toda la conversación, los textos de la app y la documentación van en español.

## Etapa actual: V1 real, en prueba con pilotos

La V1 ya tiene servidor. La app Flutter (`app/`) guarda en el teléfono, funciona sin señal y sincroniza con el servidor Node (`servidor/`), publicado en Render. Hay cuenta real por SMS, varias personas por negocio, cifras calculadas en el servidor, lectura de fotos con IA y cobro por Mercado Pago, con el Yape manual como segunda opción (S/ 19.90 al mes, 14 días de prueba). El plan y las entregas están en `docs/v1-real.md`; lo que se construyó en el prototipo, y cómo se comporta cada pantalla, sigue en `docs/prototipo-v1.md`. Léelos antes de proponer nada.

En paralelo, Jhony reúne las muestras de la Fase 0 (`docs/fase-0.md`). Las pruebas de la Fase 0 se hacen cuando él lo pida.

## Cómo trabajar aquí

- Antes de programar cualquier cosa, presenta un plan y espera la aprobación de Jhony.
- Trabaja por entregas pequeñas que se puedan instalar y probar en su teléfono. Al terminar cada una, haz commit con un mensaje claro en español y súbelo a GitHub si Jhony lo pide.
- No amplíes el alcance: lo que no está en `docs/v1-real.md` ni en `docs/prototipo-v1.md` no entra, aunque tenga pantalla diseñada.
- El APK se genera solo cuando Jhony lo pide: se lanza el flujo `apk.yml` con `entrega=entrega-N` y queda en Releases.
- Los secretos (Twilio, Anthropic, Mercado Pago, Yape, los números que registran pagos) van solo en el panel de Render, nunca en el repositorio ni en el chat: el repositorio es público.
- Una migración que corre sobre datos empieza con `SET CONSTRAINTS ALL IMMEDIATE;` (ver la 011).
- Si una decisión no está en los documentos, revisa `docs/pendientes.md` y `docs/decisiones.md`; si tampoco está ahí, pregunta en lugar de suponer.
- Cuando se tome una decisión nueva, anótala en `docs/decisiones.md` y actualiza el documento que corresponda en el mismo commit.
- Para comparar una pantalla con su diseño, usa `diseno/capturas/<código>.png` (y la versión `-completa.png` cuando exista).
- Las muestras reales de la Fase 0 (comprobantes, audios, archivos SIRE) tienen datos personales: no se suben al repositorio.

## Dónde vive el proyecto

GitHub (`jhonyvp2000/moca`) es la única copia oficial. Jhony trabaja con Claude Code en la nube desde cualquier computadora, sin copias del proyecto en su disco (decisiones.md, 28-10-2026).

- Claude Code trabaja en la rama de trabajo, hace commit de cada cambio y lo sube a GitHub en cuanto lo termina: lo que no se sube se pierde al cerrar la sesión.
- Si alguna vez se baja el proyecto a una computadora, es para leerlo; cualquier cambio hecho ahí se sube con commit y push, o no cuenta.
- Las muestras reales de la Fase 0 nunca entran al repositorio: Jhony las guarda fuera del proyecto y las pasa solo para las pruebas.

## Trabajo con Claude chat

El análisis, el diseño y los mockups se hacen en Claude chat, que ya no escribe en una carpeta del disco: Jhony le pasa su trabajo a Claude Code (pegado o como archivo adjunto) y Claude Code lo guarda en `docs/` o `diseno/` y lo sube a GitHub.

- Lo que viene de Claude chat va solo a `docs/` y `diseno/`. El código es de Claude Code.
- Antes de guardarlo, léelo completo y avisa si contradice algo ya decidido.
- Si al programar descubres que un diseño o un documento no funciona, dilo y propón el cambio; no lo corrijas en silencio en el código.

## Dónde está cada cosa

| Archivo | Contenido |
|---|---|
| `docs/prototipo-v1.md` | La etapa actual: objetivo, pantallas, qué se simula, entregas |
| `docs/v1-real.md` | Plan de la V1 real: servidor, entregas 10 a 26, cuándo está terminada y lo que falta decidir |
| `app/` | La app Flutter (Android) |
| `servidor/` y `servidor/README.md` | El servidor Node: sus rutas, el cobro y las variables de Render |
| `render.yaml` | La infraestructura en Render |
| `docs/credito/` | El flujo de caja que piden las entidades de crédito |
| `docs/decisiones.md` | Registro de decisiones con fecha |
| `docs/producto.md` | Análisis completo: decisiones, modos, fuentes de datos, agente, arquitectura, modelo comercial, riesgos |
| `docs/alcance-v1.md` | Corte de versiones y detalle de las 15 pantallas de la V1, con los ajustes respecto al mockup |
| `docs/modelo-datos.md` | Borrador del modelo de datos |
| `docs/fase-0.md` | Pruebas con datos reales |
| `docs/soporte.md` | Guía de soporte para Jhony: lo que dice el usuario, qué revisar y qué hacerle hacer, con mensajes listos. Se actualiza cuando cambia la app |
| `docs/prueba-varios-telefonos.md` | Guion de la prueba con dos o tres teléfonos (entrega 23) |
| `docs/guiones-videos.md` | Guiones de los 7 videos cortos de tutoría |
| `docs/pendientes.md` | Decisiones abiertas |
| `docs/pagina-web.md` | La página de venta en mocanegocios.com: análisis, estructura, píxeles y cookies, y lo que falta para Play Store |
| `docs/guia-google-play.md` | Puesta en marcha del cobro con Google Play: la cuenta de servicio, Render, las 12 suscripciones, los avisos por Pub/Sub y la prueba de punta a punta |
| `docs/yape-automatico.md` | Análisis de los yapes automáticos (correo del BCP o notificación de Yape), con lo medido en TVSamGo |
| `diseno/indice.md` | Las 50 pantallas, con su versión y sus archivos |
| `diseno/estilo.md` | Colores, tipografía y reglas de interfaz |
| `diseno/pantallas/` | Un HTML por pantalla (referencia visual, no código de producción) |
| `diseno/capturas/` | Un PNG por pantalla |

## Decisiones que no se discuten de nuevo

- **Plataforma:** Flutter (Android primero) para la app, React para el panel web, un backend Node monolítico, PostgreSQL con aislamiento por empresa (RLS), cola de trabajos con Redis y almacén de imágenes.
- **Una app y un backend, dos modos por empresa:** Simple (informal) y Formal (pyme con contador). Primero Simple.
- **Moca nunca calcula.** Las cifras salen de la capa de datos ya calculadas; Moca (la IA) solo lee, explica y redacta.
- **Moca pregunta cuando duda.** Nunca adivina un monto ni guarda nada sin confirmación del dueño.
- **Las alertas las disparan reglas** sobre los datos; la IA solo las redacta.
- **QR primero**, visión con IA para lo demás; toda lectura por foto se confirma con un toque.
- **Cada movimiento lleva cuenta** (efectivo, Yape, banco), **nivel de confianza** (A a D), fuente y autor.
- **Sin clave SOL.** Las ventas formales entran por archivo exportado de SIRE.
- **Paquete de país:** todo lo específico de Perú (QR, SIRE, IGV, regímenes, calendario) va aislado para poder sumar otros países.
- **Funciona sin señal:** la app guarda en el teléfono y sincroniza después.
- **Fuera de esta etapa:** captura por WhatsApp y emisión de boletas y facturas electrónicas.
- **Varias personas por negocio:** dueño (uno o más; el titular borra), encargado, ayudante y contador (solo mira y puede estar en varios negocios); sin tope de personas: el plan incluye 1 (Básico) o 3 (Full) con el titular y cada persona más cuesta S/ 2.90 al mes; el contador no cuenta (entrega 43). Lo que un rol no puede ver no baja a su teléfono.
- **Cobro por negocio:** 14 días de prueba desde el primer registro; al vencer, «solo anotar», sin perder lo anotado.

## Interfaz

- Azules como color de marca; ámbar solo para avisos; rojo sobrio solo en los montos de salida. Sin verde y sin negro.
- Texto de 14 px como mínimo; objetivos táctiles de 44 px como mínimo.
- Palabras del dueño, no del contador: «lo que te deben», no «cuentas por cobrar».
- Montos con el símbolo pegado a la cifra (`S/ 4,250`, sin que se partan en dos líneas). Saldos, totales e informes en soles enteros; cada registro (Historial, su detalle, la voz, el comprobante) con sus céntimos si los tiene (`S/ 3.40`).
- Tono de Moca: neutro y profesional, sin jerga contable.

El detalle está en `diseno/estilo.md`.
