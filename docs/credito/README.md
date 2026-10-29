# Requisitos para pedir un crédito

Referencia de Jhony (29-10-2026) sobre lo que piden las cajas municipales, cajas rurales, financieras y bancos para evaluar a un negocio pequeño. Los formatos de las entidades son parecidos: basta uno. El Excel lo llena el analista de crédito.

| Archivo | Contenido |
|---|---|
| `Moca_Guia_Credito_Empresarial.docx` | Guía: las 5 C del crédito, la visita del asesor, documentos, cómo calcular el flujo, errores que llevan al rechazo |
| `Moca_Flujo_Caja_Credito.xlsx` | Plantilla de 4 hojas: INSTRUCCIONES, FLUJO_MENSUAL (6 meses), EXCEDENTE_FAMILIAR, RESUMEN_CREDITO |

## Errores de la plantilla (sin corregir en estos archivos)

- FLUJO_MENSUAL B33:H34: «Total egresos» y «Excedente bruto» son `=0` fijo.
- RESUMEN_CREDITO B4 apunta a `FLUJO_MENSUAL!H99`, que está vacía.
- EXCEDENTE_FAMILIAR B21 apunta a B17 (vacía) y B22:B23 a B20 (un título): dan 0 y `#¡VALOR!`. B3 se copia a mano en vez de traerse de FLUJO_MENSUAL.
- RESUMEN_CREDITO B17 y B21 usan B10, B13 y B14 en vez de B11 (cuota), B15 (tasa) y B16 (plazo).
- La cuota máxima se calcula sobre el excedente sin descontar las cuotas actuales, aunque la guía dice que la suma de todas las cuotas no debe pasar del 40–50 %.
- La guía dice 40 % en un lugar y 50 % en otro, y pide el promedio de 3 meses mientras la plantilla usa 6.
