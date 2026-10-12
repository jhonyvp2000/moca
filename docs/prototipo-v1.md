# Prototipo V1

Decidido por Jhony el 12 de octubre de 2026. Es la etapa actual del proyecto.

## Qué es

La app de la V1 construida en Flutter e instalada en un Android real, **sin servidor**: los datos viven en el teléfono, y la foto, la voz y el código de acceso se simulan. Se usa para probar el producto con dueños reales antes de construir el backend.

No es un prototipo desechable: las pantallas y el tema visual se reutilizan en la V1. Lo que se reemplaza después es la capa de datos simulados.

## Qué queremos aprender

El prototipo existe para responder estas preguntas con 5 dueños de los negocios piloto. Si una decisión de construcción no ayuda a responderlas, probablemente sobra.

1. ¿Un dueño anota su venta del día en menos de diez segundos y sin ayuda?
2. ¿Entiende «Tienes hoy» y el saldo por cuenta (efectivo, Yape, banco)?
3. ¿Entiende el arqueo y usa las respuestas rápidas cuando hay diferencia?
4. ¿Entiende el informe del mes, incluido «qué tan seguras son estas cuentas»?
5. ¿Le dan ganas de volver al día siguiente? ¿Responde el aviso de la hora de cierre?

## Límite de tiempo

Dos a tres semanas para tenerlo listo para la prueba con pilotos. Si se acerca el límite, se recorta alcance, no se extiende el plazo. Se acuerda con Jhony.

## Pantallas

Las 15 de la V1 (`alcance-v1.md`), con estas referencias en `diseno/`:

| Código | Pantalla | Archivo |
|---|---|---|
| S00 | Bienvenida | `S00-Bienvenida` |
| S01 | Guarda tu avance | `S01-Cuenta` |
| S02 | Alta inicial | `S02-Alta` |
| S03 | Primer día | `S03-Vacio` |
| S04 | Inicio | `S04-Main` |
| S05 | Aviso de cierre | `S05-Notificacion` |
| S06 | Registrar | `S06-Registrar` |
| S07 | Venta de hoy | `S07-Voz` |
| S08 | Confirmar lectura | `S08-Confirmar` |
| S10 | Historial | `S10-Movimientos` |
| S12 | Arqueo semanal | `S12-Arqueo` |
| S14 | Informe del mes | `S14-Informe` |
| S16 | Moca | `S16-Moca` |
| S17 | Foto ilegible | `S17-Ilegible` |
| S18 | Voz con duda | `S18-VozDuda` |

**Se aplican los «Ajustes respecto al mockup» de `alcance-v1.md`**: no se construyen la franja de prueba y planes, «Lo que viene», el fiado, el cierre de mes, el crédito, el Pulso ni las preguntas libres a Moca, aunque estén dibujados. Si Jhony cambia alguno, se anota en `decisiones.md`.

Los mockups muestran el estado ideal. El prototipo necesita además estados que no están dibujados: teclado abierto, campos vacíos y con error, listas sin datos, confirmaciones y «Deshacer». **Propónlos antes de construirlos**, usando el estilo de `diseno/estilo.md`; no los inventes en silencio.

## Qué se simula y cómo

| Función | En el prototipo | En la V1 real |
|---|---|---|
| Código de acceso | Cualquier código de 6 dígitos entra | SMS o WhatsApp |
| Voz | Se graba (para sentir el gesto), pero el resultado sale de una lista de frases de ejemplo; el operador de la prueba puede elegir cuál | Reconocimiento de voz real (Fase 0) |
| Foto | Se abre la cámara real, pero la lectura es un comprobante de ejemplo; se puede forzar el caso «foto ilegible» | Lectura con IA (Fase 0) |
| QR | Igual que la foto | Lectura del QR |
| Textos de Moca | Plantillas fijas que se llenan con los datos | Redactados por IA a partir de cifras calculadas |
| Resumen en audio | Botón visible; reproduce un audio de ejemplo o se omite | Por decidir en la Fase 0 |
| Aviso de cierre | Notificación local real del teléfono a la hora de cierre, si es sencillo; si no, se simula | Notificación real |
| Pagos compartidos desde Yape | No se incluye | Depende de la Fase 0 |

Usar el reconocimiento de voz que trae Android puede ser una opción barata y más realista. Si te parece viable, propónlo como alternativa; decide Jhony.

## Datos

- Los datos se guardan en el teléfono y sobreviven al cerrar la app, porque la prueba dura varios días.
- Dos formas de arrancar: **«Primer día»** (vacía, para probar el alta) y **«Demo»** (con semanas de datos de ejemplo, para mostrar el Inicio, el arqueo y el informe llenos). Un ajuste oculto permite borrar todo y volver a empezar.
- Los modelos siguen `modelo-datos.md`: montos en céntimos, cuenta en cada movimiento, nivel de confianza, fuente, estado de pago, retiro del dueño.
- Los saldos, la semana y el informe se calculan en la capa de datos, no en las pantallas. Así, al llegar el backend, solo cambia de dónde salen las cifras.

## Estructura sugerida

- La app vive en `app/` dentro del repositorio. Más adelante vendrán `backend/` y `panel/`.
- Las pantallas no conocen la fuente de datos: hablan con interfaces (repositorios o servicios), y en el prototipo esas interfaces tienen una implementación simulada.
- Un solo tema con los colores, la tipografía y las medidas de `diseno/estilo.md`. Nada de colores sueltos en las pantallas.
- Todos los textos en español de Perú y en un solo lugar, para poder ajustarlos después de la prueba.

Esto es una sugerencia: la estructura final la propones tú en el plan y la aprueba Jhony.

## Medición

Opcional, pero útil para la pregunta 1: un registro local de eventos (cuándo se abre «Anotar la venta», cuándo se guarda, cuántas correcciones) que se pueda exportar como archivo al terminar la prueba.

## Qué no entra

Servidor, base de datos central, inicio de sesión real, IA real, sincronización, panel web del contador, iOS, modo Formal, planes y pagos, y todo lo de V1.1 en adelante.

## Entregas sugeridas

Cada entrega se instala y se prueba en el teléfono de Jhony antes de pasar a la siguiente.

1. Proyecto Flutter, tema visual, barra inferior y datos simulados vacíos.
2. Camino del primer día: Bienvenida → Venta de hoy → Guarda tu avance → Alta → Primer día.
3. Inicio con saldos reales del teléfono, Registrar y escribir un movimiento.
4. Voz simulada con duda (S07, S18) y foto simulada con confirmación e ilegible (S08, S17).
5. Historial con filtros y «Deshacer».
6. Arqueo semanal con respuestas rápidas.
7. Informe del mes y pestaña Moca con avisos de plantilla.
8. Aviso de la hora de cierre, modo Demo, APK para instalar en los teléfonos de los pilotos.

## Prueba con pilotos

La organiza Jhony. Cinco dueños, el prototipo instalado en su teléfono, una semana de uso. Al inicio, tareas concretas sin explicación previa («anota que hoy vendiste 350 en efectivo», «haz el arqueo»). Se anota dónde se traban. Las conclusiones se registran en `decisiones.md` antes de empezar la V1.

## Terminado cuando

- Las 15 pantallas funcionan en un Android real, con los ajustes aplicados.
- Los datos persisten entre días y los saldos cuadran con lo registrado.
- Existe un APK que se instala en el teléfono de un piloto.
- Jhony lo aprobó para la prueba.
