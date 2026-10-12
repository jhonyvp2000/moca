# Fase 0: pruebas con datos reales

La Fase 0 mide lo que el análisis no puede resolver. No construye el producto: produce números y respuestas que fijan topes, precios y alcance. El código de esta fase son scripts de prueba desechables.

Las muestras tienen datos personales y de negocios reales. Se guardan fuera del repositorio (por ejemplo en `fase0/muestras/`, ignorada por git).

Los umbrales de «suficientemente bueno» no están fijados; se acuerdan con Jhony al ver los primeros resultados.

## Pruebas técnicas

| # | Prueba | Qué se necesita | Qué se mide | Qué decide |
|---|---|---|---|---|
| 1 | Lectura de comprobantes por foto | Unos 200 comprobantes reales de los pilotos: boletas, facturas, tickets, vouchers, notas de venta | Exactitud por campo (total, fecha, emisor, ítems) y por tipo de comprobante; costo de IA por comprobante con un modelo económico y con uno mayor | Qué modelo usar, cuándo escalar al mayor, tope de fotos y precio |
| 2 | Contenido del QR | Comprobantes electrónicos de los pilotos | Qué campos trae el QR en la práctica y en qué proporción de comprobantes aparece | Cuánto trabajo le quita el QR a la lectura por foto |
| 3 | Registro por voz | Frases reales grabadas por dueños («hoy vendí 350», «pagué 80 de luz») | Exactitud del monto, del tipo de movimiento y de la cuenta; costo por registro | Si la voz puede ser la entrada principal del modo Simple y qué tope lleva |
| 4 | Archivos SIRE | Archivos de muestra de los 3 contadores | Formato real, campos, variantes entre ventas y compras | Diseño de la importación y de la conciliación (V2) |
| 5 | Comprobante compartido desde Yape | Un teléfono con Yape | Si la app puede recibir lo que Yape comparte y qué datos trae | Si los pagos por Yape se registran sin foto en la V1 |
| 6 | Validación contra SUNAT | — | Si es viable consultar el estado de un comprobante y de un RUC, con qué límites y costo | Los avisos sobre proveedores y el nivel de confianza A fuera de SIRE |
| 7 | Resumen semanal en audio | Un resumen real generado con datos de un piloto | Si los dueños lo escuchan y lo entienden; costo por resumen | Si el audio entra en la V1 o se queda en texto |

## Definiciones con pilotos y contadores

| # | Tema | Con quién |
|---|---|---|
| 8 | Categorías iniciales para bodega, restaurante y servicios | Pilotos |
| 9 | Fiado, retiro del dueño y respuestas rápidas del arqueo: si las palabras y el flujo se entienden | Pilotos |
| 10 | Si pagarían por Moca Plus y cuánto | Pilotos |
| 11 | Formato de exportación de su software contable | Contadores |
| 12 | De dónde sale la fecha de vencimiento de la declaración por empresa | Contadores |
| 13 | Reglas de los avisos tributarios y del borrador de declaración | Un contador |

## Investigación

| # | Tema |
|---|---|
| 14 | Disponibilidad de la marca «Moca» en Indecopi y en Play Store |
| 15 | Competidores en Perú y LATAM |

## Resultados que cierran la fase

Con los datos anteriores se fijan:

- el tope gratuito de fotos y el de voz;
- los precios de Moca Plus y de Moca Formal, y los tramos por volumen;
- el porcentaje de comisión del contador y los meses que recibe su invitado;
- la confirmación o el ajuste del alcance de la V1;
- una nueva estimación de las fases 1 y 2.

## Orden sugerido

Primero las pruebas 1, 2 y 3, porque de ellas depende que el producto sea viable y cuánto cuesta operarlo. Las pruebas 5 y 7 afectan el alcance de la V1. La 4 y la 6 pueden avanzar en paralelo porque son de la V2.
