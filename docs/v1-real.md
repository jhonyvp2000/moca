# V1 real: plan

Plan aprobado por Jhony el 14 de octubre de 2026 (ver `decisiones.md`). Sigue al prototipo (`prototipo-v1.md`), cuya app es la base: las pantallas no se rehacen; cambia de dónde salen los datos.

## Objetivo

La misma V1 de `alcance-v1.md` (modo Simple, un solo usuario por empresa, sin cobro), ahora con servidor: cuenta real, datos en la nube, sincronización, cifras calculadas en el servidor, lectura de fotos y redacción de Moca con IA, y publicación en la Play Store.

## Cómo se trabaja

- El servidor se construye **en paralelo** a la prueba con pilotos y a la Fase 0. Lo que no depende de la Fase 0 va primero; la IA espera sus resultados.
- Entregas pequeñas, como en el prototipo. Antes de cada una, Claude Code propone lo que no está decidido y espera la aprobación.
- Los registros que los pilotos hicieron en el prototipo **se conservan**: al crear su cuenta real, la app sube lo que tiene en el teléfono. El prototipo ya usa identificadores generados en el teléfono, que evitan duplicados.
- El servidor tiene la cifra oficial. La app guarda lo último que recibió y suma lo pendiente de subir, para seguir funcionando sin señal (por aprobar en la entrega 13).

## Infraestructura

- **Alojamiento:** Render, en la región Virginia: el servidor Node y PostgreSQL (`render.yaml`). Servidor de pruebas: `https://moca-servidor.onrender.com` (creado por Jhony el 14-10-2026, desde la rama de trabajo). Se empieza con los planes gratuitos; la base gratuita de Render vence a las pocas semanas, así que antes de los pilotos se pasa al plan pagado más pequeño. Redis y el almacén de imágenes (propuesta: Cloudflare R2) se suman en la entrega 14.
- **Distribución:** Play Store, en prueba cerrada. Necesita una cuenta de Google Play Console a nombre de Jhony y confirmar que la marca está libre (prueba 14 de la Fase 0).

## Entregas

| # | Entrega | Depende de |
|---|---|---|
| 10 | Servidor base: proyecto Node, base PostgreSQL con el modelo de `modelo-datos.md` y aislamiento por empresa (RLS), pruebas y un servidor de pruebas publicado | — |
| 11 | Cuenta real: código por SMS en «Guarda tu avance» (Twilio Verify; WhatsApp cuando Meta apruebe), tarjeta en Moca para guardar el avance o confirmar el número, y subida automática de lo anotado | Proveedor del código |
| 12 | «Ya tengo cuenta» de verdad (entrar desde otro teléfono y bajar todo), un teléfono por cuenta y subidas comprimidas | 11 |
| 13 | Cifras en el servidor: saldos, semana, informe y avisos por reglas, precalculados; la app los lee | 12 |
| 14 | Lectura de fotos con IA: imagen al almacén, cola de trabajos, lectura con un modelo económico y uno mayor si la confianza es baja | Prueba 1 de la Fase 0 |
| 15 | Moca redacta con IA los avisos y el resumen semanal; audio si lo aprueba la Fase 0 | Prueba 7 de la Fase 0 |
| 16 | Cierre: textos legales, Demo y «Ahora no» reales, respaldos, aviso de errores y publicación en la Play Store | Textos legales revisados, marca |

## Pendiente de decidir

- Twilio para los pilotos: perfil de cumplimiento («Primary Compliance Profile») y salir del modo prueba, para enviar a cualquier número sin verificarlo antes.
- Textos legales (Ley 29733), revisados por un abogado, incluida la posible inscripción del banco de datos personales.
- Criterio para dar la V1 por terminada.
- Revisión del borrador de `modelo-datos.md` (entrega 10).
