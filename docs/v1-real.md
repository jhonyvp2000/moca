# V1 real: plan

Plan aprobado por Jhony el 14 de octubre de 2026 (ver `decisiones.md`). Sigue al prototipo (`prototipo-v1.md`), cuya app es la base: las pantallas no se rehacen; cambia de dónde salen los datos.

## Objetivo

La misma V1 de `alcance-v1.md` (modo Simple, varias personas por negocio desde las entregas 17 a 23, sin cobro: el cobro tampoco entra en la versión siguiente, ver `decisiones.md` del 29-10-2026), ahora con servidor: cuenta real, datos en la nube, sincronización, cifras calculadas en el servidor, lectura de fotos y redacción de Moca con IA, y publicación en la Play Store.

## Cómo se trabaja

- El servidor se construye **en paralelo** a la prueba con pilotos y a la Fase 0. Lo que no depende de la Fase 0 va primero; la IA espera sus resultados.
- Entregas pequeñas, como en el prototipo. Antes de cada una, Claude Code propone lo que no está decidido y espera la aprobación.
- Los registros que los pilotos hicieron en el prototipo **se conservan**: al crear su cuenta real, la app sube lo que tiene en el teléfono. El prototipo ya usa identificadores generados en el teléfono, que evitan duplicados.
- El servidor tiene la cifra oficial. Con todo subido, la app muestra las cifras que le mandó el servidor; con algo por subir (sin señal) o desde otro día, calcula lo mismo en el teléfono con las mismas reglas, sin avisar nada. Una prueba compara los dos cálculos con la Demo (entrega 13).

## Infraestructura

- **Alojamiento:** Render, en la región Virginia: el servidor Node y PostgreSQL (`render.yaml`). Servidor de pruebas: `https://moca-servidor.onrender.com` (creado por Jhony el 14-10-2026, desde la rama de trabajo). El servidor está en el plan Starter (USD 7 al mes) desde el 14-10-2026: el gratuito se dormía y tardaba hasta un minuto en responder. La base pasó al plan pagado el mismo día, antes del piloto. Redis y el almacén de imágenes (propuesta: Cloudflare R2) se suman en la entrega 14.
- **Distribución:** Play Store, en prueba cerrada. Necesita una cuenta de Google Play Console a nombre de Jhony y confirmar que la marca está libre (prueba 14 de la Fase 0).

## Entregas

| # | Entrega | Depende de |
|---|---|---|
| 10 | Servidor base: proyecto Node, base PostgreSQL con el modelo de `modelo-datos.md` y aislamiento por empresa (RLS), pruebas y un servidor de pruebas publicado | — |
| 11 | Cuenta real: código por SMS en «Guarda tu avance» (Twilio Verify; WhatsApp cuando Meta apruebe), tarjeta en Moca para guardar el avance o confirmar el número, y subida automática de lo anotado | Proveedor del código |
| 12 | «Ya tengo cuenta» de verdad (entrar desde otro teléfono y bajar todo), un teléfono por cuenta y subidas comprimidas | 11 |
| 13 | Cifras en el servidor: saldos, semana, informe y avisos por reglas, precalculados; la app los lee | 12 |
| 14 | Lectura de fotos con IA, adelantada para el piloto: primero el QR dentro de la foto (en el teléfono, gratis); si no hay, Claude Haiku 5.5; si lo leído no cuadra según reglas fijas (RUC, suma del IGV, total, fecha), Claude Sonnet 5.5. La foto no se guarda en el servidor; cada lectura se anota (modelo, costo, tiempo) para medir la prueba 1 con las fotos del piloto. Tope de 30 fotos por cuenta al día; sin cuenta, 3 fotos de prueba por teléfono (entrega 14.2). La entrega 14.6 suma los videos de ayuda (`guiones-videos.md`) y la 14.7, la lectura automática del código del SMS. La cola de trabajos y el almacén de imágenes quedan para cuando el volumen lo pida | — |
| 15 | Moca redacta con IA los avisos y el resumen semanal; audio si lo aprueba la Fase 0 | Prueba 7 de la Fase 0 |
| 16 | Cierre: textos legales, Demo y «Ahora no» reales, respaldos, aviso de errores y publicación en la Play Store | Textos legales revisados, marca |
| 17 | Equipo A · Servidor: invitaciones por número, roles y permisos en el servidor, sincronización registro por registro (cada teléfono sube solo lo que cambió y baja lo nuevo de los demás) | 12, 13 |
| 18 | Equipo B · La app sincroniza en los dos sentidos: baja lo de los demás al abrir, al volver y cada pocos minutos con señal; «Actualizado hace…» | 17 |
| 19 | Equipo C · «Mi equipo» en la «M»: invitar por número (hasta 3 personas por negocio), aceptar con el consentimiento de la Ley 29733, quitar | 17, 18 |
| 20 | Equipo D · Roles en la app (qué ve y hace cada uno) y «Lo anotó…» en el Historial | 19 |
| 21 | Equipo E · Varias cajas de efectivo con responsables, arqueo por caja y «Pasé plata de una caja a otra» | 20 |
| 22 | Equipo F · El contador en varios negocios: elige cuál mirar, solo lectura | 20 |
| 23 | Equipo G · Prueba con dos o tres teléfonos de verdad y simulación de otra persona desde el ajuste oculto, antes de los 10 pilotos | 20 (y 21, 22) |

## Pendiente de decidir

- ~~Twilio para los pilotos~~: la cuenta «Moca» es pagada desde el 14-10-2026 (USD 20 de saldo) y su perfil de cumplimiento («Primary Customer Profile») quedó aprobado el 14-10-2026; sin él, Twilio rechazaba los números no verificados (error 21608).
- Borrar de verdad una cuenta a pedido del dueño (Ley 29733); desde la entrega 14.4, «Empezar de cero» solo la archiva. Desde la entrega 14.8 se pueden borrar para siempre los datos del negocio y las fotos leídas, pero solo desde los Ajustes de la prueba; falta llevarlo a un lugar visible para los dueños y decidir si también se borra el número.
- Textos legales (Ley 29733), revisados por un abogado, incluida la posible inscripción del banco de datos personales. Deben decir que las fotos de los comprobantes se envían a un proveedor de IA (Anthropic) para leerlas.
- Antes del lanzamiento abierto, pasar Moca a su propio workspace de Anthropic, con su límite de gasto. Para el piloto usa una llave propia (`moca-render`) dentro del workspace «Default», compartido con TVSamGo (14-10-2026).
- Criterio para dar la V1 por terminada.
- Revisión del borrador de `modelo-datos.md` (entrega 10).
