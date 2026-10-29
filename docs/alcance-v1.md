# Alcance por versiones

El corte fue aprobado por Jhony el 10 de octubre de 2026. Reparte las 50 pantallas diseñadas en cuatro versiones. Las versiones V1 y V1.1 corresponden a la Fase 1 de la hoja de ruta; la V2, a la Fase 2.

| Versión | Qué busca | Pantallas |
|---|---|---|
| V1 | Que un dueño registre y entienda su mes | 15 |
| V1.1 | Crear hábito y empezar a cobrar | 9 |
| V2 | Modo Formal y panel base del contador | 9 |
| Después | Ampliar valor | 17 |

La lista completa, con archivos, está en `diseno/indice.md`.

## V1

**Objetivo:** un dueño informal anota su venta y sus gastos en segundos, sabe cuánta plata tiene y dónde, hace su arqueo semanal y ve si ganó o perdió en el mes.

**Para quién:** los negocios piloto (bodegas, restaurantes, servicios) en modo Simple. Un solo usuario por empresa: el dueño.

**Sin cobro.** La V1 no tiene planes, topes ni pago. Sirve para los pilotos.

### Pantallas

| Código | Pantalla | Qué debe hacer |
|---|---|---|
| S00 | Bienvenida | Presenta la marca y lleva a anotar la primera venta sin crear cuenta. Enlaces a demo y a «Ya tengo cuenta». |
| S01 | Guarda tu avance | Tras la primera venta, pide el número de celular y envía un código. Sin correo ni contraseña. Permite seguir sin cuenta. |
| S02 | Alta inicial | Nombre y tipo de negocio, saldo inicial por cuenta (efectivo, Yape, banco) y hora de cierre. El saldo se puede dejar para después. |
| S03 | Primer día | Inicio sin datos: muestra el saldo declarado, invita a anotar la venta y lista los cuatro primeros pasos. |
| S04 | Inicio | «Tienes hoy» por cuenta, lo que quedó en la semana frente a la anterior, atajo «Anotar la venta de hoy» y un aviso de Moca. |
| S05 | Aviso de cierre | Notificación a la hora de cierre que se contesta sin abrir la app: decirlo, escribirlo o «Hoy no abrí». |
| S06 | Registrar | Cuatro entradas: voz, foto, QR y texto. Moca deduce si entró o salió plata. |
| S07 | Venta de hoy | Muestra lo que Moca entendió de la voz, por cuenta, y pide guardar o corregir. Funciona sin señal. |
| S08 | Confirmar lectura | Resultado de la foto o del QR: monto, proveedor, tipo de gasto, cuenta de la que salió y si ya está pagado. Guarda solo tras confirmar. |
| S10 | Historial | Movimientos por día con filtros (todo, entró, salió, por subir), edición y «Deshacer» tras guardar. |
| S12 | Arqueo semanal | Propone el saldo esperado por cuenta; el dueño corrige. Ante una diferencia, ofrece respuestas rápidas: retiro para mí, gasto olvidado, error de vuelto, no lo sé. |
| S14 | Informe del mes | Flujo de caja del mes (desde la entrega 14.9): cuánto creció o bajó la plata frente al mes anterior; cómo se movió (empezaste con, entró, pusiste de tu bolsillo, salió del negocio, retiraste para ti, ajustes del arqueo, terminaste con), que cuadra con el saldo; en qué se fue la plata, qué tan seguras son las cuentas (niveles de confianza) y compartir en PDF. No muestra ganancia: Moca no sabe cuánta mercadería queda. |
| S16 | Moca | Resumen semanal en texto y audio, y avisos por prioridad. |
| S17 | Foto ilegible | Muestra lo que sí se leyó, da consejos para repetir la foto y permite completar a mano o por voz. No guarda nada sin confirmación. |
| S18 | Voz con duda | Cuando no se entendió el monto, Moca pregunta y ofrece opciones. Nunca adivina. |

### Funciones que la V1 necesita aunque no tengan pantalla propia

- Movimiento «Retiro para mí»: baja la caja, no cuenta como gasto.
- Estado de pago en las compras (pagado o «todavía lo debo»), porque S08 lo pregunta.
- Niveles de confianza A a D en cada movimiento.
- Guardado sin señal y sincronización posterior, con la marca «por subir».
- Catálogo de alertas de la V1: falta el arqueo, diferencia en el arqueo, días sin registrar, gasto atípico y resumen semanal. Con prioridad, máximo diario y horario.
- Categorías iniciales para bodega, restaurante y servicios (se definen en la Fase 0).
- Bitácora de cambios.

### Ajustes respecto al mockup

Los mockups se dibujaron con el producto completo, así que varias pantallas de la V1 muestran elementos de versiones posteriores. Jhony confirmó el 12 de octubre de 2026 que estos ajustes se aplican, y que se oculta cualquier otro elemento de versiones posteriores.

| Pantalla | Elemento del mockup | En la V1 |
|---|---|---|
| S00 | «…y si te alcanza para lo que viene» | Se cambia por «…cuánta plata tienes y cuánto te queda» |
| S06 | «¿Te pagaron por Yape? En Yape toca Compartir…» | Se omite, igual que los pagos compartidos |
| S01 | «Empiezas con 14 días de Moca Plus, gratis» | Se omite: no hay planes |
| S04 | Franja «Prueba completa · te quedan 9 días · Ver planes» | Se omite |
| S04 | Bloque «Lo que viene» con «Te alcanza» | Se omite; llega con S13 en la V1.1 |
| S05 | Acceso directo en la pantalla del teléfono | Se deja para después; en la V1 solo la notificación |
| S05, S06, S07 | Pagos compartidos desde Yape | Depende de la prueba de viabilidad de la Fase 0 |
| S06, S10, S16 | Ejemplos de fiado («Le fié 20 a doña Rosa») | Se omiten; el fiado llega en la V1.1 |
| S14 | «Lo que te deben» y «Ver quiénes» | Se omite hasta la V1.1 |
| S14 | «Lo que debes» y «Ver a quiénes» | Se muestra solo el total de compras marcadas «todavía lo debo», sin el enlace |
| S14 | Botón «Cerrar el mes» | Se omite; llega con S15 en la V1.1 |
| S14 | Botón «Usarlo para pedir crédito» | Se omite; queda para después |
| S14 | Pregunta de mercadería que queda | Se mantiene solo la advertencia; la pregunta llega con el cierre de mes |
| S16 | Enlace «Pulso» | Se omite; queda para después |
| S16 | «Pregúntale» (preguntas libres) | Se omite; el chat es de la Fase 2 |
| S16 | Resumen que menciona «Te alcanza» y el fiado | El resumen y los avisos no hablan de pagos futuros ni de fiado |

### Fuera de la V1

Planes y pago, fiado, pagos fijos y préstamos, cierre de mes guiado, retiro sugerido, apartados, modo Formal, panel del contador, varios usuarios por empresa, varias empresas por usuario en la interfaz, iOS.

El modelo de datos sí debe nacer preparado para varias empresas, roles y modo Formal (ver `modelo-datos.md`), aunque la interfaz de la V1 no lo muestre.

### Criterio para dar la V1 por terminada

Por precisar con Jhony. Como punto de partida: los negocios piloto registran su venta la mayoría de los días durante varias semanas seguidas, hacen el arqueo semanal y entienden su informe del mes sin ayuda.

## V1.1

| Código | Pantalla |
|---|---|
| S11 | Lo que te deben (fiado) |
| S13 | Lo que viene (pagos fijos, préstamos, compras por pagar) |
| S15 | Cierre de mes |
| D2 | Cuánto puedo retirar |
| D3 | Apartados |
| P1 | Función bloqueada |
| P2 | Planes |
| P3 | Pago con Yape |
| P4 | Lo que Moca hizo por ti |

Los topes y precios de los planes salen de la Fase 0.

## V2

| Código | Pantalla |
|---|---|
| F1 | Inicio (modo Formal) |
| F2 | Confirmar factura |
| F3 | Cobros y pagos |
| F6 | Calendario tributario |
| F7 | Equipo |
| C1 | Cartera |
| C2 | Conciliación SIRE |
| C3 | Por revisar |
| C4 | Borrador de declaración |

## Después

S09 Compra de un equipo, D1 Pulso, D4 Precios de proveedores, D5 Personal y adelantos, D6 Archivo de comprobantes, D7 Simulador, P5 Historial y ofertas de crédito, P6 Invita a otro negocio, P7 Encuentra un contador, F4 Recordatorio de cobro, F5 Avisos de Moca (Formal), F8 Mis empresas, C5 Informe con tu marca, C6 Pendientes y cierre anual, C7 Moca para el contador, C8 Mi estudio, C9 Mi perfil y mis clientes.

## Para otra versión, sin diseño

Captura por WhatsApp y emisión de boletas y facturas electrónicas.
