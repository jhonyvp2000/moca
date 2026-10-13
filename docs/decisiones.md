# Registro de decisiones

Una línea por decisión, la más reciente arriba. Lo anota quien la tome o la registre: Claude chat (análisis y diseño) o Claude Code (desarrollo). Si una decisión cambia un documento, se actualiza ese documento en el mismo commit.

| Fecha | Decisión | Quién | Documento afectado |
|---|---|---|---|
| 2026-10-13 | Estados de la entrega 5: foto con cámara real y lectura simulada (cuatro comprobantes de ejemplo por turno), «Leyendo el comprobante…», QR real con escáner a pantalla completa, aviso si el QR no es de SUNAT o ya está anotado, S08 con cuenta y «¿Ya lo pagaste?» siempre elegidos por el dueño, S17 forzada desde el ajuste oculto | Jhony | `prototipo-v1.md` |
| 2026-10-13 | Comprobantes: el monto lleva céntimos solo si los tiene (`S/ 980`, `S/ 142.30`); nivel B para QR y foto legible, C para foto ilegible completada a mano; el proveedor se guarda como contraparte y se reutiliza por RUC o nombre; un comprobante deshecho se puede volver a anotar | Claude Code | `modelo-datos.md` |
| 2026-10-13 | Estados de la entrega 4 (voz): la voz se abre desde Bienvenida, Inicio y Registrar con «Prefiero escribirlo» siempre a mano; aviso del micrófono la primera vez; Moca pregunta en orden monto dudoso, entró o salió, cuenta y categoría; «Corregir un dato» abre lo escrito con los datos puestos; frases de ejemplo del operador cuando el teléfono no reconoce voz | Jhony | `prototipo-v1.md` |
| 2026-10-13 | Reglas del intérprete de voz: Moca duda del monto si dos lecturas del reconocimiento dan montos distintos, si la frase quedó cortada o si la confianza es menor a 0.5; «Plin» se anota en la cuenta Yape; la categoría se reconoce por palabras («luz» → Servicios) y, si no, se pregunta | Claude Code | `prototipo-v1.md` |
| 2026-10-12 | Estados de la entrega 3: S04 desde los 7 días o el primer arqueo (y «Saltar la primera semana» en el ajuste oculto), ojo para ocultar montos, tarjeta de Moca de plantilla hasta la entrega 8, S06 con voz, foto y QR apagados, formulario «Escribirlo», pregunta antes de dejar una cuenta en negativo, aviso «Guardado» con «Deshacer» adelantado de la entrega 6 | Jhony | `prototipo-v1.md` |
| 2026-10-12 | «Esta semana te quedó» se compara con la semana pasada hasta el mismo día de la semana, no con la semana pasada completa | Claude Code | `prototipo-v1.md` |
| 2026-10-12 | Estados de la entrega 2: Venta de hoy escrita hasta que llegue la voz, botones fijos sobre el teclado, validación del celular, pantalla del código con aviso de prueba, alta con nombre y tipo obligatorios, saldo pendiente declarable desde el paso 1, la app retoma el paso pendiente, demo y «Ya tengo cuenta» con mensaje | Jhony | `prototipo-v1.md` |
| 2026-10-12 | En el ajuste oculto, «Borrar todo» también vuelve a la Bienvenida, porque sin datos no hay negocio que mostrar | Claude Code | `prototipo-v1.md` |
| 2026-10-12 | Estados de la entrega 1: pestañas con «Esta parte llega en la entrega N», hoja de Registrar provisional y ajuste oculto con «Borrar todo» y confirmación | Jhony | `prototipo-v1.md` |
| 2026-10-12 | Plan del prototipo aprobado: estructura de `app/`, pantallas separadas de los datos por interfaces, paquetes, entregas 0 a 9 y orden de recorte (medición, audio, PDF) | Jhony | `prototipo-v1.md` |
| 2026-10-12 | El APK lo arma GitHub Actions; las entregas se publican en Releases como `entrega-N`; se firma con una llave propia guardada en los secretos de GitHub | Jhony | `app/README.md` |
| 2026-10-12 | Android 7.0 o superior; identificador de la app `pe.moca.app` (provisional hasta publicar en Play Store) | Jhony | `prototipo-v1.md` |
| 2026-10-12 | Ajuste oculto del operador: mantener presionado 3 segundos el isotipo en la pestaña Moca | Jhony | `prototipo-v1.md` |
| 2026-10-12 | Arqueo con «No lo sé»: el saldo pasa a ser el contado, la diferencia no cuenta como gasto ni ingreso, queda en el arqueo y genera el aviso | Jhony | `prototipo-v1.md` |
| 2026-10-12 | La bitácora entra en el prototipo, visible en el detalle de cada movimiento (reemplaza la decisión de dejarla para la V1 real) | Jhony | `prototipo-v1.md` |
| 2026-10-12 | Arqueo semanal el domingo a la hora de cierre (confirmado) | Jhony | `prototipo-v1.md` |
| 2026-10-12 | Prototipo: voz con el reconocimiento de Android (frases de ejemplo de respaldo), lectura real del QR sin IA y resumen en audio con la voz sintética del teléfono | Jhony | `prototipo-v1.md` |
| 2026-10-12 | Prototipo: lo guardado sin conexión queda marcado «por subir» y la marca no cambia | Jhony | `prototipo-v1.md` |
| 2026-10-12 | Primer día: las cuentas existen desde la primera venta; el saldo inicial es el de antes de esa venta; S03 suma la venta y marca el paso hecho | Claude Code, delegado por Jhony | `prototipo-v1.md` |
| 2026-10-12 | Venta del día por cuenta: en una frase o cuenta por cuenta; el aviso de cierre pregunta efectivo y después Yape | Jhony | `prototipo-v1.md` |
| 2026-10-12 | Los «Ajustes respecto al mockup» se aplican, y se oculta cualquier otro elemento de versiones posteriores (S00 «lo que viene», S06 Yape compartido, resumen de S16) | Jhony | `alcance-v1.md` |
| 2026-10-12 | Texto mínimo de 14 px sin excepciones, también en la barra inferior | Claude Code, delegado por Jhony | `diseno/estilo.md` |
| 2026-10-12 | El plazo de 2 a 3 semanas del prototipo vale para esta etapa; «sin plazo fijo» de `producto.md` se refiere al proyecto completo | Claude Code, delegado por Jhony | `prototipo-v1.md` |
| 2026-10-12 | El informe genera un PDF real en el teléfono | Jhony | `prototipo-v1.md` |
| 2026-10-12 | «Escribirlo» es un formulario corto (tipo, monto, cuenta, categoría); «Retiro para mí» se anota desde Registrar | Claude Code y Jhony | `prototipo-v1.md` |
| 2026-10-12 | Las compras «todavía lo debo» no bajan el saldo hasta marcarlas «Ya lo pagué» desde el Historial | Claude Code, delegado por Jhony | `prototipo-v1.md` |
| 2026-10-12 | Semana de lunes a domingo; arqueo el domingo a la hora de cierre | Jhony y Claude Code | `prototipo-v1.md` |
| 2026-10-12 | Umbrales, prioridades, máximo diario y horario de los avisos de la V1 | Claude Code, delegado por Jhony | `prototipo-v1.md` |
| 2026-10-12 | «Ver una demo», «Ya tengo cuenta» y «Ahora no, seguir probando» en el prototipo | Claude Code, delegado por Jhony | `prototipo-v1.md` |
| 2026-10-12 | Estados sin mes o semana anterior y Demo de diez semanas | Claude Code, delegado por Jhony | `prototipo-v1.md` |
| 2026-10-12 | Deshacer y editar anulan sin borrar (la bitácora se dejaba para la V1 real; ver la decisión de arriba) | Jhony | `prototipo-v1.md` |
| 2026-10-12 | Textos legales y categorías provisionales propuestos (por revisar) | Claude Code, delegado por Jhony | `prototipo-v1.md` |
| 2026-10-12 | La etapa actual es un prototipo de la V1 en Flutter con datos simulados en el teléfono, reutilizable para la V1 (opción B) | Jhony | `prototipo-v1.md` |
| 2026-10-12 | El código vive en `F:\JVP\CLAUDECODE\Moca`, con repositorio privado `moca` en GitHub. La carpeta `F:\JVP\CLAUDECHAT\MOCA` queda como respaldo | Jhony | `CLAUDE.md` |
| 2026-10-12 | Las pantallas del teléfono miden 390 × 844; si el contenido es más largo, la parte central se desplaza y las barras quedan fijas | Jhony | `diseno/indice.md` |
| 2026-10-10 | Corte de versiones aprobado: V1 (15 pantallas), V1.1 (9), V2 (9), después (17) | Jhony | `alcance-v1.md` |
| 2026-10-10 | Captura por WhatsApp y emisión de comprobantes quedan para otra versión | Jhony | `producto.md` |
| 2026-10-09 | Prueba completa de 14 días sin medio de pago; pago por Yape o Plin; topes y precios se fijan en la Fase 0 | Jhony | `producto.md` |
| 2026-10-09 | Marca Moca («Mi Organización Contable Asistida»), eslogan «Tú vendes. Moca hace las cuentas.», azules como color de marca, sin verde ni negro | Jhony | `diseno/estilo.md` |

Las decisiones anteriores al 9 de octubre están en la tabla «Decisiones fijadas» de `producto.md`.

## Pendiente de confirmar por Jhony

- El borrador de `modelo-datos.md`.
