# Pendientes

Decisiones abiertas al 10 de octubre de 2026. Cuando una se cierre, se anota aquí la respuesta y la fecha, y se actualiza el documento que corresponda.

## Se resuelven en el prototipo V1

- ~~Confirmar los «Ajustes respecto al mockup»~~: se aplican (12-10-2026).
- ~~Si la voz usa el reconocimiento de Android o frases de ejemplo~~: reconocimiento de Android, con frases de ejemplo de respaldo (12-10-2026).
- ~~Cómo funciona «Ver una demo» y qué pasa con quien sigue sin crear cuenta~~: ver «Comportamiento acordado» en `prototipo-v1.md` (12-10-2026).
- ~~Límite de tiempo~~: dos a tres semanas, como dice `prototipo-v1.md` (12-10-2026).
- Estados no dibujados (teclado, vacíos, errores, confirmaciones, franja de la Demo): Claude Code los propone y Jhony los aprueba.
- ~~Día y hora del arqueo~~: domingo a la hora de cierre (12-10-2026).
- Revisar los textos legales y las categorías provisionales de `prototipo-v1.md`.
- Fecha y negocios de la prueba con pilotos.
- ~~«En qué entró la plata» en el informe del mes~~: «Con qué entró la plata», entrega 35 (06-11-2026).
- ~~Construir los planes Básico y Full~~: entrega 43 (09-11-2026).
- ~~«Lo que te deben»~~: entrega 42 (09-11-2026). Mejoras pedidas por Jhony para después: cobros y pagos en partes («me pagó la mitad»); recordarle al cliente por WhatsApp lo que debe; vender a crédito por voz y desde «Anotar la venta de hoy».
- Pasar el pago con Mercado Pago (entrega 32) de la API de Preferences a la API de Orders. Al crear la aplicación «moca» (05-11-2026), el panel avisa que Preferences «será descontinuada pronto»; Mercado Pago dice que sigue con soporte, sin funciones nuevas, y no da fecha. Conviene hacerlo a la vez en Moca y en TVSamGo, que usan la misma API.

## Se resuelven en la Fase 0

Ver `fase-0.md`. En resumen:

- Topes de fotos y de voz del plan Gratis y de Moca Plus (referencia de trabajo, sin validar: 15 fotos y 300 registros de voz en Gratis; 300 fotos y voz sin tope en Plus).
- Precios de Moca Plus y de Moca Formal.
- Porcentaje de comisión del contador y meses incluidos para su invitado.
- Qué modelos de IA se usan para lectura, voz y redacción.
- Si los pagos compartidos desde Yape son viables.
- Si el resumen en audio entra en la V1.
- Categorías iniciales por tipo de negocio.
- Formato del archivo SIRE y de la exportación al software contable.
- Viabilidad de validar comprobantes y RUC contra SUNAT.
- Disponibilidad de la marca «Moca».

## Se resuelven al planificar la V1

- ~~Criterio preciso para dar la V1 por terminada~~: ver «Cuándo está terminada» en `v1-real.md` (03-11-2026).
- Revisar el borrador de `modelo-datos.md`.
- ~~Proveedor para enviar el código de acceso por SMS o WhatsApp~~: Twilio Verify, por SMS y WhatsApp cuando Meta apruebe (14-10-2026).
- ~~Dónde se aloja el backend y el almacén de imágenes~~: plataforma gestionada y simple, con almacén de imágenes aparte; el proveedor se propone en la entrega 10 (14-10-2026, ver `v1-real.md`).
- Cómo funcionan en la V1 real «Ver una demo», «Ya tengo cuenta» y «Ahora no, seguir probando» (en el prototipo ya están resueltos).
- Textos legales: consentimiento de datos (Ley 29733) y aviso de que Moca no reemplaza la contabilidad oficial.
- Estimación de duración de las fases 1 y 2.
- ~~«Salir de este negocio» para las personas invitadas~~: entrega 22.2 (03-11-2026).
- ~~Quien fue quitado de un equipo no ve «Mis negocios»~~: se le muestra, con sus invitaciones (entrega 22.1, 29-10-2026).

## Se resuelven más adelante

- ~~El tiempo fuera de Moca antes de pedir la huella~~: 5 minutos (entrega 16.3.1, 03-11-2026).
- Para la versión final: ocultar la pantalla de Moca en las apps recientes, que también bloquea las capturas de pantalla (por eso no va durante la prueba).
- Textos legales (Ley 29733): el dueño todavía no tiene un texto de consentimiento propio (solo lo tiene el invitado). Debe decir, entre otras cosas, que Moca recibe los errores de la app (entrega 27) y, con la entrega 28, datos de uso, sin lo que anota. Para revisar con el abogado (04-11-2026).
- Al diseñar los días de prueba, revisar también los números archivados (`celular_archivado`): «Empezar de cero» y la entrega 14.4.1 archivan la cuenta vieja y crean otra con el mismo número, y el número no debe volver a tener 7 días de prueba (decisiones.md, 29-10-2026 y 30-10-2026).
- Cobro manual por Yape (entregas 24 a 26): listo. Falta que Jhony ponga en Render `MOCA_ADMIN_CELULARES`, `MOCA_YAPE_NUMERO` y `MOCA_YAPE_NOMBRE`, pruebe la pantalla de cobros y, el día en que reparta el APK a los pilotos, `MOCA_COBRO_DESDE`.
- Sin cuenta guardada no hay cobro: quien nunca guarda su avance usa Moca sin límite, aunque sin respaldo ni varios teléfonos. Revisar con los pilotos si hace falta un tope (03-11-2026).
- Cómo se cobra la suscripción dentro de Play Store: revisar las reglas de pagos de Google Play para Perú (sistema de pagos de Google, comisión, programas de excepción) y la opción de una pasarela que acepte Yape o Plin, antes de diseñar el pago (29-10-2026).

- Criterios precisos para avanzar entre fases.
- Reglas tributarias del borrador de declaración y del riesgo tributario, validadas con contadores.
- Alcance del segundo país.

- Que «Retiro para mí» pueda llevar rubro del hogar (alimentación, educación, salud, transporte, servicios, vivienda, otros) para llenar la hoja de gastos familiares del flujo para crédito (`docs/credito/`). Idea para Moca Plus; no entra en la V1 (29-10-2026).

## Advertencias sobre los diseños

- Ninguna pantalla se ha probado con usuarios reales.
- Las cifras, nombres y fechas de los mockups son ejemplos.
- Las pantallas se dibujaron con el producto completo; varias de la V1 muestran elementos de versiones posteriores.
