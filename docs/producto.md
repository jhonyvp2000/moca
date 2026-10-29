# Moca: producto

Copia del análisis consolidado al 10 de octubre de 2026 (Jhony Vela Paredes). Es la fuente de verdad del producto; el alcance de la primera versión está en `alcance-v1.md`.

## Resumen

Moca es una app Android, con panel web para contadores, que convierte comprobantes y registros del día en un flujo de caja y en informes que un dueño sin formación contable entiende. El análisis quedó cerrado tras tres vueltas; lo que falta se resuelve con pruebas sobre datos reales (Fase 0), no con más análisis.

- **Qué hace:** registra ingresos y egresos por foto, QR, voz o texto; los ordena por cuenta y categoría; calcula cuánto entró, cuánto salió y cuánto quedó; y avisa cuando algo requiere atención.
- **Para quién:** dueños de bodegas, restaurantes y negocios de servicios, con una o varias empresas. Dos modos: Simple (informal) y Formal (pyme con contador).
- **Qué la distingue:** el agente que explica y avisa, no la lectura de comprobantes.
- **Estado:** no se ha programado nada. El desarrollo empieza solo con indicación expresa.

**Mockups:** 50 pantallas en `diseno/` (origen: [Moca: mockups](https://claude.ai/artifact/JPrLoRpUxcTKe48PhECeMr)), que ya incorporan las mejoras de las tres revisiones de diseño. Este documento refleja esas funciones.

**Presentación para clientes:** [Moca: presentación](https://claude.ai/artifact/9F6bXmYxut1t3PEpsXEa7C), 23 láminas con las 50 pantallas.

## Decisiones fijadas

| Tema | Decisión |
|---|---|
| Marca | Moca (Mi Organización Contable Asistida), con el eslogan «Tú vendes. Moca hace las cuentas.»; el agente lleva el mismo nombre |
| Clientes | Microempresario informal y pyme formal con contador |
| Producto | Una app y un backend, con dos modos por empresa |
| Orden | Primero modo Simple, después modo Formal |
| Plataforma | Flutter (Android primero), panel web en React, backend Node + PostgreSQL |
| Relación con FacturaPe | Producto y marca separados |
| Ventas formales | Archivo exportado de SIRE, sin clave SOL; además foto y QR |
| Registros sin comprobante | Permitidos, con nivel de confianza y arqueo semanal |
| Inventario | Compras como gasto del mes, más una pregunta opcional de mercadería en el cierre mensual |
| Usuarios | En Simple, solo el dueño; en Formal, dueño, contador y empleados que solo registran |
| Agente | Dentro de la app, totalmente proactivo, tono neutro y profesional |
| Cobro | Por volumen de comprobantes leídos con IA o importados; registros manuales ilimitados |
| Modo Simple | Plan Gratis con topes; plan de pago Moca Plus para el dueño informal |
| Contador | Usuario del panel y canal de venta con comisión |
| Alcance | Perú primero; diseño preparado para LATAM |
| Desarrollo | Jhony con Claude Code; sin plazo ni presupuesto fijos |
| Identidad visual | Azules como color de marca; ámbar reservado para avisos; texto de 14 px como mínimo |
| Prueba | Completa durante 14 días, sin pedir medio de pago |
| Pago | Yape o Plin, sin cobro automático |
| Primer uso | La primera venta se anota antes de crear la cuenta; el ingreso es con celular y código |
| Para otra versión | Captura por WhatsApp y emisión de boletas y facturas electrónicas |

## Clientes y propuesta de valor

El dueño no quiere un estado de resultados; quiere respuestas. Moca existe para contestar seis preguntas en lenguaje simple:

1. ¿Cuánta plata tengo hoy, y dónde está?
2. ¿Gané o perdí este mes, y por qué?
3. ¿Me alcanza la plata para pagar lo que viene?
4. ¿En qué se me va el dinero, y qué subió?
5. ¿Quién me debe y a quién le debo?
6. ¿Cuánto IGV voy a pagar este mes? (solo modo Formal)

**Pilotos disponibles:** bodegas, restaurantes y negocios de servicios dispuestos a probar desde el primer mes, y 3 contadores dispuestos a participar.

**Multiempresa:** un usuario puede tener una o varias empresas, y cada empresa tiene su propio modo, sus cuentas y sus informes.

## Modos Simple y Formal

Los dos modos comparten núcleo, datos e informes; cambia la fuente principal y lo que se muestra. Un negocio que se formaliza pasa de Simple a Formal sin migrar nada.

|  | Modo Simple | Modo Formal |
|---|---|---|
| Cliente | Microempresario informal | Pyme formal con contador |
| Fuente principal | Voz, texto, foto de vouchers y notas | Archivo SIRE, QR y foto |
| Unidad de venta | Venta del día en bloque («hoy vendí 350») | Comprobante por comprobante |
| Informe principal | Cuánto me quedó esta semana | Resultados, IGV, lo que te deben y lo que debes |
| Impuestos | Ocultos o mínimos | IGV estimado y crédito fiscal |
| Usuarios | Solo el dueño | Dueño, contador y empleados que solo registran |
| Precio | Gratis con topes, o Moca Plus | Por tramos de volumen |

## Fuentes de datos y validación

Cada registro entra por una de cuatro fuentes y recibe un nivel de confianza; el arqueo semanal es el control sobre lo que no tiene sustento.

| Fuente | Qué entrega | Costo de IA |
|---|---|---|
| QR del comprobante electrónico | RUC emisor, tipo, serie, número, IGV, total, fecha, documento del cliente | Ninguno |
| Foto leída con IA | Detalle de ítems y comprobantes sin QR: boletas manuales, tickets, recibos, vouchers, notas de venta | Por comprobante |
| Voz o texto | Ventas del día y gastos sin comprobante (alquiler, pagos informales, retiros del dueño) | Casi nulo |
| Archivo exportado de SIRE | Ventas y compras formales del mes; lo carga el contador o el dueño | Ninguno |

**Confirmación.** Toda lectura por foto se confirma con un toque antes de entrar a los informes.

**Niveles de confianza**

- **A:** verificado contra SUNAT (archivo SIRE)
- **B:** comprobante con QR o foto legible
- **C:** foto de sustento informal (voucher Yape, nota de venta, cuaderno)
- **D:** declarado sin sustento

Cada informe muestra qué parte de sus cifras es A/B y qué parte es C/D.

**Arqueo semanal.** El dueño registra cuánto tiene realmente en efectivo, Yape y banco. Moca compara con el saldo calculado y pregunta por la diferencia, que queda como «sin explicar». Por eso cada movimiento lleva su cuenta.

**Saldo inicial.** En el alta, el dueño declara cuánto tiene en cada cuenta. Sin ese punto de partida el primer arqueo no puede cuadrar.

**Retiros del dueño.** Existe el movimiento «Retiro para mí»: baja la plata en caja, pero no cuenta como gasto del negocio. El arqueo ofrece respuestas rápidas para explicar una diferencia: retiro personal, gasto olvidado, error de vuelto o «no lo sé».

**Fiado.** Las ventas al fiado se registran por cliente, también por voz, y se cobran completas o por partes. De ahí sale «lo que te deben» en el modo Simple.

**Pagos por Yape.** El comprobante se recibe compartido desde la app de Yape, sin tomar foto. Hay que confirmar su viabilidad en la Fase 0.

**Reglas automáticas**

- Duplicados entre SIRE y foto por RUC + tipo + serie + número; la foto enriquece el registro de SIRE, no crea otro.
- Subtotal + impuesto = total, e identificación fiscal válida.
- Montos atípicos frente al historial.
- Gastos recurrentes que faltan.

**Caja y resultados son distintos.** Cada movimiento guarda la fecha del comprobante y su estado de pago (pagado, pendiente, parcial). De ahí salen el flujo de caja, los resultados y las cuentas pendientes.

**Inventario.** Las compras cuentan como gasto del mes. En comercios, el cierre mensual pregunta de forma opcional cuánta mercadería queda; quien responde obtiene una ganancia más fiel y quien no, recibe la advertencia de Moca.

## Moca, el agente

Moca nunca calcula: las cifras salen de consultas ya calculadas y la IA solo las lee, las explica y redacta los avisos. Así los números son confiables y el costo se mantiene bajo.

| Tarea | Cómo |
|---|---|
| Lectura | QR primero; visión con un modelo económico, y uno mayor solo si la confianza es baja |
| Clasificación | Categoría por proveedor e ítems; aprende de las correcciones del dueño y del contador |
| Alertas | Las disparan reglas sobre los datos; la IA las redacta |
| Resumen semanal | Qué entró, qué salió, qué quedó y qué cambió, en texto y en audio |
| Chat | Preguntas libres sobre los datos de la empresa (Fase 2) |

**Catálogo inicial de alertas**

- Un pago próximo que la caja no alcanza a cubrir
- Gasto atípico
- Diferencia en el arqueo
- Gasto recurrente que falta
- Días sin registrar, y recordatorio de la venta del día a la hora de cierre
- Cliente que debe hace mucho, por fiado o por factura vencida
- Registro inusual hecho por un empleado
- Resumen semanal

**Control de fatiga.** Cada alerta tiene prioridad; hay un máximo diario y un horario configurable. Si Moca avisa demasiado, el dueño silencia las notificaciones y el producto pierde su diferencia.

**Tono.** Neutro y profesional, sin jerga contable.

**Identidad.** Moca tiene isotipo, un estilo de tarjeta propio y una pestaña fija en la app, para que el dueño distinga lo que dice el agente de los datos.

**Dudas.** Cuando no está segura de una lectura o de lo que escuchó, Moca pregunta. Nunca adivina un monto ni guarda nada sin confirmación.

**Límite.** Moca es una herramienta de gestión; no reemplaza la contabilidad oficial ni da asesoría tributaria.

## Arquitectura

La app del dueño y el panel del contador usan un mismo backend; todo lo específico de Perú vive en un paquete de país que se puede reemplazar.

```
App del dueño (Flutter, Android primero) ─┐
                                          ├─► Backend único (Node, monolito) ─► PostgreSQL (aislamiento por empresa con RLS)
Panel web del contador (React) ───────────┘        │
                                                   ├─► Cola de trabajos (Redis): lectura, validación, clasificación, informes
                                                   ├─► Almacén de imágenes de comprobantes
                                                   ├─► Modelos de IA: visión, voz a texto, redacción de avisos
                                                   └─► Paquete de país (Perú): QR, SIRE, IGV, regímenes, calendario
```

El backend recibe los registros, los valida y precalcula los informes; Moca solo lee esas cifras. La app guarda los registros sin señal y los sincroniza después.

**Flujo de un comprobante:** foto o QR → lectura → validación → clasificación → confirmación del dueño → movimiento → informes.

**Modelo de datos**

- **Usuario y Empresa:** relación de muchos a muchos, con rol (dueño, contador, empleado) y permisos por rol.
- **Empresa:** modo (Simple o Formal), tipo de negocio, país, régimen tributario, moneda, hora de cierre.
- **Cuenta:** efectivo, Yape, banco; con saldo inicial. Cada movimiento pertenece a una.
- **Comprobante e Ítems:** con llave única por emisor + tipo + serie + número.
- **Movimiento:** ingreso, egreso o retiro del dueño; fecha del comprobante, estado de pago, monto pagado, fecha de vencimiento, categoría, contraparte, nivel de confianza, fuente y autor.
- **Contraparte:** cliente o proveedor, con su saldo pendiente (fiado, cuentas por cobrar y por pagar).
- **Arqueo:** saldo real por cuenta, diferencia y motivo.
- **Alerta:** tipo, prioridad y estado.
- **Regla de clasificación:** contraparte o texto que fija una categoría, por empresa.
- **Periodo:** abierto o cerrado; un periodo cerrado no admite cambios del dueño.
- **Bitácora:** quién cambió qué y cuándo.

**Régimen tributario.** Cambia el cálculo de la ganancia: en NRUS el IGV pagado es costo; en MYPE o régimen general no lo es.

## Experiencia de uso

La app se diseña para registrar en segundos y entender de un vistazo; el panel, para que el contador revise muchas empresas rápido.

**App del dueño**

- Inicio abre con «Tienes hoy», por cuenta; luego lo que quedó en la semana comparado con la anterior, y «Lo que viene» con la marca de si alcanza.
- Atajo «Anotar la venta de hoy» y un botón central para registrar con voz, foto, QR o texto. Moca deduce si entró o salió plata.
- Historial con edición y «Deshacer» tras cada guardado; indica qué registros están pendientes de subir cuando no hay señal.
- Pestaña Moca: resumen semanal en texto y audio, avisos por prioridad y preguntas libres.
- Informe del mes: flujo de caja (cuánto creció o bajó la plata y cómo se movió, cuadrado con el saldo), comparado con el mes anterior, la categoría que cambió, qué tan seguras son las cuentas y opción de compartir en PDF. Desde el 29-10-2026 no habla de ganancia: sin saber cuánta mercadería queda, no es una ganancia real (decisiones.md).
- Palabras del dueño, no del contador: «lo que te deben» en lugar de «cuentas por cobrar».
- Montos en soles enteros; céntimos solo dentro del comprobante.
- Estados diseñados para el primer día, la foto ilegible y la voz mal entendida.
- Modo Formal: IGV estimado, proyección de caja a 30 días, punto de equilibrio diario, cobros y pagos con vencimientos y recordatorio por WhatsApp, equipo con permisos y vista consolidada de varias empresas.

**Panel web del contador**

- Cartera ordenada por vencimiento de la declaración, con indicadores que filtran la tabla y el siguiente paso por empresa.
- Conciliación SIRE: lo que está en SIRE y no en Moca, lo que está en Moca y no en SIRE, y los comprobantes con monto distinto.
- Carga de varios archivos SIRE a la vez, con el resultado de cada carga.
- Revisión en lote y reglas de clasificación por empresa.
- «Pedir al cliente»: genera un aviso de Moca al dueño.
- Cierre de periodo y bitácora de cambios.
- Exportación a Excel, CSV y al formato del software contable, por definir con los contadores.
- Código de referido visible para invitar empresas.

## Modelo comercial

> **Cambio del 29-10-2026** (ver `decisiones.md`): ya no hay plan Gratis. La versión base se paga después de 7 días de prueba y Moca Plus es un adicional. La tabla y la lista de abajo se mantienen como historia; donde dicen «Gratis», hoy es la prueba de 7 días.

Hay tres planes. El dueño entra con una prueba completa de 14 días y luego elige; el contador usa el panel sin costo y vende el plan Formal a cambio de comisión.

| Plan | Para quién | Incluye | Precio |
|---|---|---|---|
| Gratis | Negocio que empieza | Pocas fotos al mes, voz holgada, escribir sin límite, saldo, historial y arqueo | S/ 0 |
| Moca Plus | Dueño informal | Más fotos, lo que viene, fiado con recordatorios, resumen en audio, informe en PDF e historial para crédito | Por definir |
| Moca Formal | Pyme con contador | Todo lo de Plus, más IGV, SIRE, cobros y pagos, contador conectado y equipo | Por definir, según comprobantes |

**Unidad de cobro.** Cuentan los comprobantes leídos con IA o importados. El tope de fotos es el apretado; el de voz queda holgado porque la venta diaria por voz sostiene el hábito. Escribir no tiene límite.

**Conversión de prueba a pago**

- Prueba completa de 14 días, sin pedir medio de pago; al terminar, el usuario baja a Gratis si no elige plan.
- La función bloqueada se muestra sobre los datos reales del usuario, no en Ajustes.
- Cada mes, «Lo que Moca hizo por ti»: comprobantes leídos, fiado cobrado, descuadres encontrados.
- Pago por Yape o Plin, sin cobro automático.
- Bajar de plan no borra ni bloquea los datos.
- Aviso de formalización cuando un negocio en modo Simple ya guarda muchas facturas.

**Canales**

1. Contadores con comisión: su invitado entra con meses de Formal incluidos y el panel le muestra qué pruebas están por vencer.
2. Referidos entre dueños: quien invita y quien llega ganan un mes.
3. Mensajes con la marca: recordatorios de cobro e informes salen «enviados con Moca».
4. Directorio de contadores: el dueño sin contador encuentra uno, y al contador le llegan clientes.
5. Calendario tributario con avisos, como gancho para negocios formales.
6. Venta directa en Tarapoto con los negocios piloto.

**Por definir con datos de la Fase 0:** los topes exactos de fotos y de voz, los precios de Plus y de Formal, el porcentaje de comisión y los meses que recibe el invitado de un contador.

## Funciones para decidir y para el contador

La tercera revisión sumó funciones que usan datos que Moca ya captura. Todas tienen pantalla en los mockups; ninguna está validada con usuarios.

| Para el dueño | Qué hace |
|---|---|
| El pulso del negocio | Meta de venta del día, días buenos y malos, productos que toca reponer y alerta cuando compras y ventas no cuadran |
| Cuánto puedo retirar | Monto sugerido que no descapitaliza, con el cálculo a la vista y opción de fijarse un sueldo |
| Apartados | Plata marcada para alquiler, cuotas y servicios, con cuánto apartar cada día |
| Lo que viene | Pagos fijos que se repiten, préstamos con sus cuotas y compras por pagar |
| Precios de proveedores | Alzas y bajas por producto, leídas del detalle de las facturas |
| Personal y adelantos | Sueldos, adelantos y lo que toca pagar a fin de mes |
| Archivo de comprobantes | Búsqueda por texto o voz, con garantías y vencimientos |
| Simulador | Preguntas como «¿puedo pagar una cuota de S/ 500?» con su historial real |
| Cierre de mes guiado | Arqueo, mercadería y pendientes; al terminar arma el paquete para el contador |
| Compra de equipos | Se trata aparte para no hundir la ganancia del mes |
| Historial para crédito | Resumen de ingresos para llevar a una caja o banco; las ofertas de crédito van apagadas por defecto |

| Para el contador | Qué hace |
|---|---|
| Borrador de declaración | Hoja de trabajo mensual con ventas, compras, IGV y pago a cuenta |
| Riesgo tributario | Lo que conviene revisar antes de declarar, por cliente |
| Informe con su marca | Informe de gestión mensual para cada cliente, con su logo y su comentario |
| Moca para el contador | Preguntas sobre su cartera y oportunidades de trabajo detectadas |
| Pendientes por cliente | Qué falta de cada uno, con recordatorios automáticos |
| Cierre anual | Avance del año y paquete para la renta anual |
| Mi estudio | Cobro de sus honorarios y carga de trabajo de sus asistentes |
| Perfil y clientes | Directorio público, comisión del mes y clientes en prueba |

Las cifras que Moca le da al dueño (retiro sugerido, simulador) son estimaciones con lo anotado y se presentan como tales. Las reglas tributarias del borrador y del riesgo deben validarse con los contadores piloto.

## Hoja de ruta

Son cinco fases y cada una avanza solo si cumple su criterio.

| Fase | Contenido | Criterio para avanzar |
|---|---|---|
| 0 · Pruebas | Medir lectura, voz, SIRE, QR y costos con datos reales (`fase-0.md`) | Los resultados permiten fijar topes, precios y alcance |
| 1 · Núcleo y modo Simple | Registro, cuentas, arqueo, informes y Moca para el dueño informal (`alcance-v1.md`) | Los pilotos registran de forma sostenida |
| 2 · Modo Formal | SIRE, IGV, cobros y pagos, equipo y panel del contador | Los contadores piloto cierran un mes con el panel |
| 3 · Comercial | Planes, cobro, referidos, directorio y comisión | Hay clientes que pagan |
| 4 · LATAM | Segundo paquete de país | Por definir |

Las duraciones no están estimadas: las anteriores quedaron desactualizadas al ampliarse el alcance. Los criterios de la tabla son un resumen; hay que precisarlos con Jhony al planificar cada fase.

El arqueo y los niveles de confianza entran al modelo de datos desde la Fase 1. Mientras se construye Simple, los contadores aportan comprobantes y archivos SIRE de muestra y validan el diseño del panel.

Tras la revisión de mockups, la Fase 1 suma el alta con saldo inicial, el fiado, los retiros del dueño, el historial con deshacer y los estados vacíos y de error. La Fase 2 suma la conciliación SIRE, la revisión en lote con reglas, el cierre de periodo, los empleados que registran, la proyección de caja y el punto de equilibrio.

## Riesgos

El riesgo mayor es que el dueño deje de registrar: sin datos, los informes mienten y Moca pierde su valor.

| Riesgo | Mitigación |
|---|---|
| El dueño deja de registrar | Registro en segundos, venta del día en bloque, aviso de días sin registrar |
| Datos declarados sin sustento | Niveles de confianza visibles y arqueo semanal |
| Lectura errónea de una foto | QR primero, reglas de validación y confirmación del dueño |
| Fatiga por exceso de avisos | Prioridad, máximo diario y horario configurable |
| Sin ingresos hasta el modo Formal | Costo de Simple casi nulo: registros manuales y tope de fotos |
| Ganancia distorsionada por compras de mercadería | Advertencia de Moca y pregunta opcional de inventario |
| Competidores con apps de facturación ya instaladas | Diferenciarse por el agente que explica, no por la lectura |
| Responsabilidad tributaria | Presentar Moca como herramienta de gestión, con textos legales claros |
| Datos sensibles | Ley 29733, consentimiento explícito, aislamiento por empresa; no se guarda la clave SOL |
| Nombre «Moca» es una palabra común y puede estar registrada | Revisar Indecopi y Play Store antes de invertir en diseño |
| Un empleado registra mal o de más | Cada registro guarda su autor, los permisos son por rol y Moca avisa al dueño de registros inusuales |
| El alcance creció tras la revisión de mockups | Reestimar las fases y mantener el criterio de avance de cada una antes de sumar funciones |
| 50 pantallas diseñadas sin un solo usuario real | Primera versión acotada y validación con pilotos antes de construir el resto |

## Pendientes para la Fase 0

Estos puntos no se resuelven analizando; se resuelven midiendo con datos reales.

1. Reunir unos 200 comprobantes reales de los pilotos (boletas, facturas, tickets, vouchers, notas de venta).
2. Medir la exactitud de lectura por tipo de comprobante y el costo de IA por comprobante.
3. Probar el registro por voz con frases reales de los dueños.
4. Obtener de los 3 contadores archivos SIRE de muestra y confirmar su formato.
5. Confirmar qué campos trae el QR en los comprobantes de los pilotos.
6. Definir las categorías iniciales para bodega, restaurante y servicios.
7. Revisar la disponibilidad de la marca «Moca» en Indecopi y en Play Store.
8. Investigar competidores en Perú y LATAM.
9. Fijar con esos datos el tope gratuito de fotos, los tramos de precio y la comisión.

10. Probar si Moca puede recibir el comprobante compartido desde la app de Yape.
11. Preguntar a los 3 contadores qué formato de exportación usa su software contable.
12. Definir de dónde sale la fecha de vencimiento de la declaración por empresa.
13. Validar con los pilotos el fiado, el retiro del dueño y las respuestas rápidas del arqueo.
14. Probar el resumen semanal en audio con dueños reales.
15. Reestimar la duración de las fases 1 y 2 con el alcance ampliado.

16. Validar con un contador las reglas de los avisos tributarios y del borrador de declaración.
17. Definir el alcance exacto de la primera versión.
18. Probar con los pilotos si pagarían por Moca Plus y cuánto.
19. Confirmar la viabilidad de validar comprobantes y RUC de proveedores contra SUNAT.
