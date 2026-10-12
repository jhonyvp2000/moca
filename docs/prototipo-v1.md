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
| Voz | Reconocimiento de voz de Android, en español. Moca interpreta el texto con reglas en el teléfono (monto, entró o salió, cuenta). Si el reconocimiento no está disponible (por ejemplo, sin señal), el operador de la prueba elige una frase de ejemplo | Reconocimiento de voz definido en la Fase 0 |
| Foto | Se abre la cámara real, pero la lectura es un comprobante de ejemplo; se puede forzar el caso «foto ilegible» | Lectura con IA (Fase 0) |
| QR | Lectura real del QR del comprobante electrónico de SUNAT, en el teléfono y sin IA. Si el código no es de un comprobante, Moca lo dice y ofrece tomar foto o escribirlo | Lectura del QR |
| Textos de Moca | Plantillas fijas que se llenan con los datos | Redactados por IA a partir de cifras calculadas |
| Resumen en audio | La voz sintética del teléfono lee el resumen semanal | Por decidir en la Fase 0 |
| Aviso de cierre | Notificación local real del teléfono a la hora de cierre | Notificación real |
| Informe en PDF | PDF real generado en el teléfono y compartido con el menú de Android | Igual |
| Sincronización | No existe. Lo que se guarda sin conexión queda marcado «por subir» y la marca no cambia | Sube al servidor cuando vuelve la señal |
| Pagos compartidos desde Yape | No se incluye | Depende de la Fase 0 |

## Datos

- Los datos se guardan en el teléfono y sobreviven al cerrar la app, porque la prueba dura varios días.
- Dos formas de arrancar: **«Primer día»** (vacía, para probar el alta) y **«Demo»** (con semanas de datos de ejemplo, para mostrar el Inicio, el arqueo y el informe llenos). Un ajuste oculto permite borrar todo y volver a empezar.
- Los modelos siguen `modelo-datos.md`: montos en céntimos, cuenta en cada movimiento, nivel de confianza, fuente, estado de pago, retiro del dueño.
- Los saldos, la semana y el informe se calculan en la capa de datos, no en las pantallas. Así, al llegar el backend, solo cambia de dónde salen las cifras.
- El modo Demo trae diez semanas de datos de una bodega (más de dos meses), para que el informe pueda compararse con el mes anterior y el Historial muestre un par de registros «por subir». La Demo se abre desde «Ver una demo» de la Bienvenida, muestra una franja «Estás viendo una demo · Salir», y al salir se borra y se vuelve a la Bienvenida.

## Comportamiento acordado

Decidido el 12 de octubre de 2026 (ver `decisiones.md`). Lo que dice un mockup y contradice esta sección, cede ante esta sección.

### Primer día (S00 → S07 → S01 → S02 → S03)

- Las tres cuentas (efectivo, Yape, banco) existen desde la primera venta, con saldo inicial pendiente. La primera venta va a la cuenta que dijo el dueño; si no la dijo, Moca pregunta con las tres opciones.
- El saldo inicial que se declara en S02 es el de **antes** de esa venta, con fecha de hoy. Bajo la pregunta se agrega: «Sin contar la venta que acabas de anotar».
- S03 muestra «Tienes hoy» = saldo declarado + venta anotada, con la nota «Es lo que tenías al empezar más tu venta de hoy». En los primeros pasos, «Decir cuánta plata tienes» queda hecho si se declaró y «Anotar la venta 5 días» dice «llevas 1». Si la venta de hoy ya está anotada, la tarjeta de Moca dice «Ya anotaste la venta de hoy. Te recuerdo la siguiente a tu hora de cierre» y el botón pasa a ser «Anotar un gasto».
- El Inicio es S03 durante la primera semana, hasta el primer arqueo; después es S04.
- Si se deja el saldo para después, se toma como cero y el paso 1 queda pendiente.

### Enlaces sin servidor (S00, S01)

- «Ver una demo» abre el modo Demo.
- «Ya tengo cuenta» pide número y código. Como no hay servidor, responde: «En esta prueba tu cuenta vive en el teléfono donde la creaste» y ofrece empezar.
- «Ahora no, seguir probando» sigue al alta sin número. Los datos quedan en el teléfono. A los tres días aparece en la pestaña Moca una tarjeta «Guarda tu avance» que lleva a S01.

### Registrar

- **Texto:** es un formulario corto: entró, salió o «Retiro para mí»; monto (teclado numérico); cuenta; categoría; nota opcional. Es el camino más rápido y el que no falla sin señal.
- **Voz:** Moca deduce entró o salió del verbo («vendí», «pagué», «saqué para mí»). Si no está segura del monto, abre S18; si falta la cuenta o el tipo, pregunta con opciones. Nunca adivina.
- **Retiro para mí:** se anota desde Registrar, por voz («saqué 100 para mí») o en el formulario de texto.
- **Venta del día por cuenta:** se dice en una frase («350 en efectivo y 120 por Yape») o se anota cuenta por cuenta.

### Compras que todavía se deben

- No bajan el saldo de ninguna cuenta hasta que se pagan, pero sí cuentan en la ganancia del mes de su comprobante.
- En el Historial llevan la marca «Lo debes». Al abrirlas, «Ya lo pagué» pide la cuenta y la fecha (hoy por defecto) y baja el saldo ese día. En el prototipo solo se paga completo.
- S14 muestra el total en «Lo que debes», sin el enlace «Ver a quiénes».

### Aviso de cierre (S05)

- Hora de cierre por defecto: 9:00 p. m.
- La notificación pregunta «¿Cuánto vendiste hoy en efectivo?». «Escribirlo» se contesta desde la misma notificación; luego llega «¿Y por Yape?». Banco solo se pregunta si hubo ventas al banco en los últimos 30 días.
- «Decirlo» abre la app en S07.
- «Hoy no abrí» marca el día como cerrado y no cuenta como día sin registrar.

### Semana y arqueo

- La semana va de lunes a domingo.
- Arqueo: **domingo a la hora de cierre** (aprobado por Jhony). Ese día, el aviso de cierre ofrece el arqueo después de la venta. Se puede hacer cualquier día y cubre la semana en curso.
- Si el lunes a las 8:00 a. m. no hay arqueo de la semana anterior, aparece «Falta el arqueo de esta semana».
- Con una respuesta rápida que genera movimiento («La retiré para mí», «Un gasto que olvidé»), se anota ese movimiento. Con «Di mal un vuelto» o «No lo sé», el saldo pasa a ser el contado y la diferencia no cuenta como gasto ni como ingreso del mes; queda registrada en el arqueo y, con «No lo sé», genera el aviso.

### Avisos

| Aviso | Cuándo | Prioridad |
|---|---|---|
| Falta el arqueo | Lunes 8:00 a. m. sin arqueo de la semana anterior; sigue visible hasta hacerlo | Importante |
| Diferencia en el arqueo | Queda una diferencia de S/ 10 o más marcada «No lo sé» | Importante |
| Días sin registrar | Dos días seguidos sin registros ni «Hoy no abrí» | Importante |
| Gasto atípico | Un gasto de S/ 100 o más que duplica el promedio de su categoría en las últimas 8 semanas (con al menos 3 gastos previos en ella) | Para tener en cuenta |
| Resumen semanal | Lunes 8:00 a. m. | Para tener en cuenta |

- Notificaciones del teléfono: el aviso de cierre, más un aviso al día como máximo (el de mayor prioridad), entre las 8:00 a. m. y la hora de cierre. Dentro de la app, la pestaña Moca muestra todos, ordenados por prioridad y fecha.
- El resumen semanal y los avisos no mencionan «Lo que viene», «te alcanza» ni fiado.

### Informe del mes (S14)

- Muestra el mes en curso hasta hoy y permite ver los meses anteriores.
- Si no hay mes anterior: «Es tu primer mes con Moca. El próximo mes verás la comparación». Si el primer mes empezó a mitad, se indica «desde el día X».
- Lo mismo para la semana en S04: sin semana anterior, se omite la comparación.
- «Compartir PDF» genera el PDF en el teléfono.

### Historial y cambios

- «Deshacer» y las ediciones anulan el registro anterior; nada se borra.
- La bitácora entra en el prototipo: cada alta, edición, anulación, pago de una compra y arqueo guarda quién, cuándo, el valor anterior y el nuevo, en la capa de datos.
- Se ve en el detalle de cada movimiento, como una lista «Cambios» (estado no dibujado: se propone antes de construirlo).
- La bitácora no sale en la exportación de la medición, porque tiene montos.

### Textos legales (propuesta para revisar)

- Al pie del alta (S02): «Tus datos se guardan solo en este teléfono. Al empezar aceptas que Moca los use para ordenar tus cuentas».
- En el informe y en el PDF: «Moca te ayuda a ordenar tus cuentas. No reemplaza la contabilidad oficial ni da asesoría tributaria».
- El registro de eventos de la medición no guarda montos, nombres ni números de celular.

### Categorías provisionales

Hasta que la Fase 0 defina las reales. «Retiro para mí» no es categoría: es un tipo de movimiento.

| Tipo | Entró | Salió |
|---|---|---|
| Todos | Venta del día, Otro ingreso | Alquiler; Servicios (luz, agua, internet, teléfono); Personal; Transporte; Mantenimiento y reparaciones; Impuestos y trámites; Otros |
| Bodega | — | Mercadería; Bolsas y envases |
| Restaurante | — | Insumos de cocina; Bebidas; Gas; Descartables |
| Servicios | — | Materiales; Herramientas y repuestos |
| Otro | — | Mercadería |

## Estructura (aprobada el 12-10-2026)

- La app vive en `app/` dentro del repositorio. Más adelante vendrán `backend/` y `panel/`.
- Las pantallas no conocen la fuente de datos: hablan con interfaces (repositorios o servicios), y en el prototipo esas interfaces tienen una implementación simulada. Un solo archivo (`lib/inyeccion.dart`) elige la implementación, y una prueba automática impide que una pantalla importe datos directamente.
- Carpetas de `app/lib/`: `tema/`, `textos/`, `comun/`, `dominio/` (modelos e interfaces), `datos/` (base local, repositorios, cálculos y simulados), `servicios/`, `moca/` (reglas de avisos y plantillas), `pais/peru/`, `pantallas/` y `operador/`.
- Un solo tema con los colores, la tipografía y las medidas de `diseno/estilo.md`. Nada de colores sueltos en las pantallas. La fuente va incluida en la app.
- Todos los textos en español de Perú y en un solo archivo (`lib/textos/textos.dart`), para poder ajustarlos después de la prueba.
- Paquetes: drift (SQLite), flutter_riverpod, go_router, speech_to_text, image_picker, mobile_scanner, flutter_tts, flutter_local_notifications con timezone, pdf, share_plus, permission_handler, connectivity_plus, intl y uuid.
- Android 7.0 o superior. Identificador `pe.moca.app`.
- El APK lo arma GitHub Actions, firmado con la llave de Moca (ver `app/README.md`).
- **Ajuste oculto del operador:** mantener presionado 3 segundos el isotipo en la pestaña Moca. Permite borrar todo, arrancar en Primer día o Demo, forzar foto ilegible, elegir frase de ejemplo y exportar la medición.

## Medición

Opcional, pero útil para la pregunta 1: un registro local de eventos (cuándo se abre «Anotar la venta», cuándo se guarda, cuántas correcciones) que se pueda exportar como archivo al terminar la prueba.

## Qué no entra

Servidor, base de datos central, inicio de sesión real, IA real, sincronización, panel web del contador, iOS, modo Formal, planes y pagos, y todo lo de V1.1 en adelante.

## Entregas (aprobadas el 12-10-2026)

Cada entrega se instala y se prueba en el teléfono de Jhony antes de pasar a la siguiente. Antes de cada una, Claude Code describe los estados no dibujados que necesita y espera la aprobación.

0. Armado del APK: proyecto vacío, ícono y compilación automática en GitHub.
1. Base: tema, fuente, barra inferior con botón central, base local vacía y ajuste oculto.
2. Camino del primer día: Bienvenida → Venta de hoy (a mano por ahora) → Guarda tu avance → Alta → Primer día.
3. Inicio con saldos reales del teléfono, Registrar, «Escribirlo» y retiro para mí.
4. Voz con el reconocimiento de Android y duda (S07, S18).
5. Foto simulada con confirmación e ilegible y QR real (S08, S17); compras «todavía lo debo».
6. Historial con filtros, edición, «Deshacer», «Ya lo pagué», «por subir» y bitácora.
7. Arqueo semanal con respuestas rápidas.
8. Informe del mes con PDF y pestaña Moca con avisos, resumen y audio.
9. Aviso de la hora de cierre, modo Demo, medición y APK para los pilotos.

Si se acerca el límite de tiempo, se recorta en este orden: medición, audio y PDF. Las entregas 2, 3, 6 y 7 no se recortan.

## Prueba con pilotos

La organiza Jhony. Cinco dueños, el prototipo instalado en su teléfono, una semana de uso. Al inicio, tareas concretas sin explicación previa («anota que hoy vendiste 350 en efectivo», «haz el arqueo»). Se anota dónde se traban. Las conclusiones se registran en `decisiones.md` antes de empezar la V1.

## Terminado cuando

- Las 15 pantallas funcionan en un Android real, con los ajustes aplicados.
- Los datos persisten entre días y los saldos cuadran con lo registrado.
- Existe un APK que se instala en el teléfono de un piloto.
- Jhony lo aprobó para la prueba.
