# Yapes automáticos: análisis (11-11-2026)

Pedido de Jhony: aprovechar el aviso que llega por cada yapeo para que Moca lo reciba sola y lo concilie con lo que anota el dueño. Esto es un **análisis**, no una decisión: lo abierto está en `pendientes.md`. No está en `v1-real.md` ni en `prototipo-v1.md`, así que es alcance nuevo.

## Lo que ya se midió (en TVSamGo, septiembre de 2026)

TVSamGo concilia los yapeos de la empresa con el correo del BCP y con la notificación de Yape (su app «Puente Yape»). Lo medido allí vale para Moca:

| | Correo del BCP («Constancia de recepción de Yapeo») | Notificación de Yape en el teléfono |
|---|---|---|
| ¿Llega por todos los yapeos? | **No.** El BCP no manda correo cuando el yapeo es de un Yape BCP a otro Yape BCP (probado varias veces con S/ 1, el 14 y el 15-09-2026). Solo llega si la plata viene de otro banco o billetera | **Sí**, por todos |
| Nombre de quien paga | Completo | Recortado («Monica Pom*») |
| Monto | Sí | Sí, a veces sin ceros y pegado al punto («S/ 40.5.») |
| Hora | Al minuto | Al instante |
| N.º de operación | No | No (solo está dentro de la app de Yape) |
| Código de seguridad (3 cifras) | No | Sí («El cód. de seguridad es: 463») |
| Cuándo llega | Minutos después | Segundos |

Otras lecciones de TVSamGo:

- El texto de la notificación **ya cambió una vez** respecto de la captura de referencia: el lector tiene que aceptar los dos formatos conocidos y avisar cuando no entiende uno.
- Una vía que deja de funcionar **no avisa sola**: el reenvío por correo estuvo 30 horas muerto sin que nadie lo notara. Hace falta un vigilante.
- El permiso de leer notificaciones deja leer **todas**. La app propia descarta lo que no es de Yape sin leerlo; por eso no se usa MacroDroid ni Tasker.
- En Android 13 o más reciente, una app instalada desde un APK (no desde Play Store) muestra ese permiso en gris («Configuración restringida»). Se destraba a mano: Información de la app → ⋮ → Permitir configuración restringida.

## Las tres vías

### A. Correo reenviado a un webhook

Una dirección propia por negocio; el dueño crea en Gmail un filtro que reenvía la constancia; un servicio de correo entrante (SendGrid, Mailgun o Cloudflare) la entrega al servidor.

- Solo cubre los yapeos que vienen de otro banco o billetera.
- Gmail no deja crear filtros de reenvío desde la app del celular, solo desde la computadora, y pide confirmar la dirección con un código. Muy difícil para un dueño sin formación.
- Cualquiera podría mandar un correo falso a esa dirección: hay que verificar la firma del BCP (DKIM) del correo reenviado.
- Si el filtro se rompe, nadie se entera.

### B. Leer el Gmail del dueño con su permiso (OAuth)

Simple para el dueño, pero el permiso para leer correos es «restringido» para Google: exige una auditoría de seguridad anual pagada para una app pública. Y tampoco ve los yapeos de un Yape BCP a otro. **Descartada.**

### C. La notificación de Yape en el mismo teléfono (recomendada)

Moca ya es una app Android en el teléfono del dueño, que suele ser el mismo donde tiene Yape. Con el permiso «acceso a notificaciones», Moca lee «Fulano te envió un pago por S/ 50» en el momento.

- Ve todos los yapeos, incluidos los de un Yape BCP a otro.
- Funciona sin señal: queda en el teléfono y sube con la sincronización de siempre. No necesita webhook, correo ni servidor nuevo.
- Moca descarta sin leer cualquier notificación que no sea del paquete de Yape. Debe explicarse en el consentimiento del dueño (Ley 29733).
- Con el APK, el permiso hay que destrabarlo a mano (ver arriba); con Play Store, ese paso desaparece.
- Algunas marcas (Xiaomi, por ejemplo) cortan las apps en segundo plano: hace falta un aviso «Moca no recibe tus yapeos desde hace N días».
- Si Yape cambia el texto, hay que ajustar el lector.

## Qué haría Moca con cada yapeo

Moca nunca guarda nada sin confirmación del dueño: un yapeo detectado no es un movimiento, queda **por confirmar**, y se usa en tres lugares:

1. **Al cierre del día.** «¿Cuánto vendiste hoy por Yape?» viene prellenado con la suma de los yapeos de hoy: «Te llegaron 14 yapeos por S/ 312. ¿Lo anoto?». El dueño anota la venta del día como **un total por cuenta**, no yapeo por yapeo; por eso se concilia **la suma del día** con lo que anotó, no cada yapeo con un registro.
2. **Con los fiados.** «Rosa Mendoza te yapeó S/ 50. ¿Es del fiado de doña Rosa?»: el nombre se compara con los clientes de «Lo que te deben» y se cobra con «Sí, de esa deuda», como en la entrega 50.
3. **En el arqueo de Yape.** «Según tus yapeos, deberías tener S/ X», para explicar una diferencia antes del «No lo sé».

Lo confirmado lleva la fuente «Notificación de Yape» y un nivel de confianza mayor que lo escrito a mano.

## Lo que hay que decidir

Anotado en `pendientes.md`:

1. Si entra en la V1 o queda para después.
2. La vía: se recomienda C; el correo (A), como mucho, como complemento para quien tenga Yape en otro teléfono.
3. Una prueba antes de programar, con el Yape de Jhony: el texto de hoy de la notificación (de BCP a BCP y desde otro banco) y si el permiso se destraba en su teléfono con el APK.
4. Si se empieza solo con Yape o también con Plin y las billeteras de otros bancos (cada una con su texto).
5. El consentimiento del dueño (todavía pendiente) tendría que mencionar este permiso.
