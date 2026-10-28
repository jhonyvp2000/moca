# Moca

Moca («Mi Organización Contable Asistida») es una app Android con panel web que convierte comprobantes y registros del día en flujo de caja e informes que un dueño sin formación contable entiende. Eslogan: «Tú vendes. Moca hace las cuentas.»

El dueño del proyecto es Jhony Vela Paredes (Tarapoto, Perú). Toda la conversación, los textos de la app y la documentación van en español.

## Etapa actual: prototipo V1

Se construye la V1 en Flutter, instalada en Android, **sin servidor y con datos simulados en el teléfono**. Todo el detalle está en `docs/prototipo-v1.md`; léelo antes de proponer nada.

En paralelo, Jhony reúne las muestras de la Fase 0 (`docs/fase-0.md`). Las pruebas de la Fase 0 se hacen cuando él lo pida.

## Cómo trabajar aquí

- Antes de programar cualquier cosa, presenta un plan y espera la aprobación de Jhony.
- Trabaja por entregas pequeñas que se puedan instalar y probar en su teléfono. Al terminar cada una, haz commit con un mensaje claro en español y súbelo a GitHub si Jhony lo pide.
- No amplíes el alcance: lo que no está en `docs/prototipo-v1.md` no entra, aunque tenga pantalla diseñada.
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
| `docs/v1-real.md` | Plan de la V1 real: servidor, entregas 10 a 16 y lo que falta decidir |
| `docs/decisiones.md` | Registro de decisiones con fecha |
| `docs/producto.md` | Análisis completo: decisiones, modos, fuentes de datos, agente, arquitectura, modelo comercial, riesgos |
| `docs/alcance-v1.md` | Corte de versiones y detalle de las 15 pantallas de la V1, con los ajustes respecto al mockup |
| `docs/modelo-datos.md` | Borrador del modelo de datos |
| `docs/fase-0.md` | Pruebas con datos reales |
| `docs/guiones-videos.md` | Guiones de los 7 videos cortos de tutoría |
| `docs/pendientes.md` | Decisiones abiertas |
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

## Interfaz

- Azules como color de marca; ámbar solo para avisos. Sin verde y sin negro.
- Texto de 14 px como mínimo; objetivos táctiles de 44 px como mínimo.
- Palabras del dueño, no del contador: «lo que te deben», no «cuentas por cobrar».
- Montos con el símbolo pegado a la cifra (`S/ 4,250`, sin que se partan en dos líneas). Saldos, totales e informes en soles enteros; cada registro (Historial, su detalle, la voz, el comprobante) con sus céntimos si los tiene (`S/ 3.40`).
- Tono de Moca: neutro y profesional, sin jerga contable.

El detalle está en `diseno/estilo.md`.
