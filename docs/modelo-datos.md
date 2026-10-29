# Modelo de datos (borrador)

Este documento desarrolla la lista de entidades de `producto.md`. Las entidades y sus relaciones vienen del análisis; los nombres de campos y las reglas técnicas son una propuesta para revisar en el plan de la V1.

## Reglas generales

- Toda tabla de negocio lleva `empresa_id`, y el aislamiento entre empresas se aplica en la base de datos (RLS), no solo en el código.
- Los montos se guardan en céntimos, como enteros. La app muestra soles enteros; los céntimos solo se ven dentro del comprobante.
- Cada empresa tiene moneda y país; nada asume soles ni Perú fuera del paquete de país.
- Los registros creados sin señal llevan un identificador generado en el teléfono, para que reintentar la subida no los duplique.
- Nada se borra: los registros se anulan y el cambio queda en la bitácora.
- Los informes se precalculan en el backend. Moca lee esas cifras; no suma por su cuenta.

## Entidades

### Usuario
Persona que entra con su celular y un código. Campos: celular, nombre, fecha de alta.

### Empresa
Campos: nombre, tipo de negocio (bodega, restaurante, servicios, otro), modo (Simple o Formal), país, régimen tributario, moneda, hora de cierre, identificación fiscal (opcional en Simple).

### Membresía
Une Usuario y Empresa, de muchos a muchos. Campos: rol (dueño, contador, empleado) y permisos. En la V1 solo existe el rol dueño, pero la tabla nace completa.

### Cuenta
Dónde está la plata. Campos: tipo (efectivo, Yape, BCP —el tipo `banco`— y, si el dueño los usa, Plin, Sip u otra billetera, e Interbank, BBVA, Scotiabank u otro banco o caja; la otra billetera y el otro banco llevan el nombre que él ponga), nombre, saldo inicial y fecha del saldo inicial. Cada movimiento pertenece a una cuenta.

### Contraparte
Cliente o proveedor. Campos: nombre, identificación fiscal (opcional), tipo. Su saldo pendiente se calcula a partir de los movimientos.

### Comprobante
Documento que sustenta uno o más movimientos. Campos: emisor, tipo, serie, número, fecha de emisión, subtotal, impuesto, total, imagen, origen de la lectura (QR, foto, SIRE) y resultado de las validaciones. Llave única por empresa: emisor + tipo + serie + número. Cuando un comprobante llega por SIRE y por foto, la foto enriquece el registro; no crea otro.

### Ítem de comprobante
Campos: descripción, cantidad, precio unitario, importe.

### Movimiento
La unidad de todo informe. Campos:

- tipo: ingreso, egreso o retiro del dueño
- cuenta
- monto
- fecha del movimiento y fecha del comprobante
- estado de pago: pagado, pendiente o parcial; monto pagado; fecha de vencimiento
- categoría
- contraparte (opcional)
- comprobante (opcional)
- nivel de confianza: A, B, C o D
- fuente: voz, texto, foto, QR, SIRE
- autor
- estado: vigente o anulado
- identificador del teléfono y estado de sincronización

La «venta del día» es un movimiento de ingreso por cuenta, sin comprobante, con nivel D (o C si hay vouchers).

### Categoría
Lista por tipo de negocio, con las iniciales definidas en la Fase 0. La empresa puede ajustar la suya.

### Regla de clasificación
Contraparte o texto que fija una categoría, por empresa. Se alimenta de las correcciones del dueño y del contador.

### Arqueo
Campos: fecha, y por cuenta el saldo calculado, el saldo real, la diferencia, el motivo (retiro para mí, gasto olvidado, venta no anotada, error de vuelto, no lo sé) y el movimiento que generó. Retiro, gasto olvidado y venta no anotada generan un movimiento; error de vuelto, «no lo sé» y las diferencias menores a S/ 1 no generan movimiento: ajustan el saldo de la cuenta desde la fecha del arqueo, sin contar como gasto ni ingreso. «No lo sé» queda como diferencia sin explicar.

### Alerta
Campos: tipo, prioridad, estado (pendiente, vista, resuelta, silenciada), texto redactado, datos que la dispararon y fecha. En el prototipo, las reglas se evalúan sobre los datos cada vez y solo se guarda la alerta marcada «Entendido» (vista), con su clave como identificador.

### Periodo
Mes de una empresa, abierto o cerrado. Un periodo cerrado no admite cambios del dueño.

### Bitácora
Quién cambió qué y cuándo, con el valor anterior y el nuevo. Acciones: crear, editar, anular, pagar y arquear. Al corregir un movimiento, el anterior se anula y el nuevo lo apunta con «reemplaza a»; la bitácora guarda una fila «editar» en el anterior, con los valores de antes, los de después y el id del nuevo. Así la historia de un movimiento es la de su cadena de reemplazos.

## Lo que sale del modelo

- **Flujo de caja:** movimientos por fecha de pago y cuenta.
- **Resultados:** movimientos por fecha del comprobante, sin los retiros del dueño. Desde la entrega 14.9 el informe del mes no los usa: muestra el flujo de caja, que cuadra con el saldo; los resultados vuelven cuando Moca sepa cuánta mercadería queda.
- **Lo que te deben y lo que debes:** movimientos pendientes o parciales, por contraparte.
- **Qué tan seguras son las cuentas:** proporción de montos por nivel de confianza.

## Régimen tributario

Cambia el cálculo de la ganancia: en NRUS el IGV pagado es costo; en MYPE o régimen general no lo es. Esta regla vive en el paquete de país.

## Cómo quedó en el servidor (entrega 10)

La primera migración (`servidor/migraciones/001_esquema_inicial.sql`) crea todas las entidades de arriba, con estos ajustes respecto al borrador:

- Los valores fijos usan los mismos nombres que la app (`plin`, `retiroParaMi`, `paraTenerEnCuenta`), para que la sincronización no traduzca nada.
- `items_comprobante` y `arqueo_cuentas` también llevan `empresa_id`, como toda tabla de negocio.
- Se suman, del prototipo: los días cerrados («Hoy no abrí»), la clave de cada aviso (para no repetirlo) y la fuente «arqueo» en los movimientos.
- El movimiento guarda cuándo llegó al servidor; el estado «por subir» vive solo en el teléfono.
- Las referencias entre tablas incluyen la empresa, y un `DELETE` falla en toda tabla de negocio.
- Entrega 13: las alertas suben solo cuando el dueño marca un aviso «Entendido». En el teléfono su id es la clave del aviso; en el servidor el id se deriva de la empresa y la clave (uuid v5), así repetir la subida no duplica.
- Entrega 14.11: el movimiento tiene un tipo más, `aporte` («Puse de mi bolsillo»): sube el saldo pero no es venta ni lleva categoría; y el arqueo, la razón `puseYo` (migración 010).
- Entrega 14.10: dos tipos de cuenta más, `bbvaPlin` y `scotiabankPlin` (migración 009); `plin` es el Plin de Interbank y `yape` se muestra como «BCP Yape».
- Entrega 14.8: única excepción a «un `DELETE` falla»: el dueño puede borrar para siempre su negocio y todo lo suyo (`POST /cuenta/borrar-datos`). Solo vale dentro de esa transacción y para las filas de ese negocio; el usuario (el número) no se borra. Queda anotado en `borrados` (usuario, empresa, fecha).
- Entrega 14.6: `videos_vistos` guarda los videos de ayuda que abrió cada negocio (número del video, desde dónde y cuándo), para saber en el piloto cuáles se ven. Es lo único de la medición que se sube; no se modifica ni se borra.

## Entidades que llegan después

Plan y suscripción (V1.1), pagos fijos y préstamos (V1.1), apartados (V1.1), carga de archivo SIRE y conciliación (V2), referidos y comisiones (después).
