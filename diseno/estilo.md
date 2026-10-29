# Estilo visual

Reglas extraídas de los 50 mockups. Los HTML de `pantallas/` son la referencia exacta de medidas y colores; no son código de producción (usan estilos en línea y datos fijos).

## Color

Azules como color de marca. Ámbar reservado para avisos. Rojo sobrio solo en los montos de salida. Sin verde y sin negro.

| Uso | Color |
|---|---|
| Texto principal | `#0F1F3D` |
| Texto secundario | `#4B5A75` |
| Marca, botón principal, enlaces | `#1D4ED8` |
| Azul oscuro (enlace activo, texto sobre tinte) | `#1E3A8A` |
| Tinte azul (tarjetas de Moca, selección) | `#E3ECFB` |
| Fondo de pantalla | `#F3F6FB` |
| Superficie de tarjeta | `#FFFFFF` |
| Borde de tarjeta | `#D8E0EC` |
| Borde de botón secundario | `#B5C2D6` |
| Borde de campo de texto | `#8696B0` |
| Separador interno, pista de barra | `#E4EAF3` |
| Aviso: marca y barra | `#9A4A06` |
| Aviso: texto | `#7A3A05` |
| Aviso: texto fuerte | `#5C2C04` |
| Aviso: fondo | `#FBEEDD` |
| Monto de una salida (gasto, retiro, faltante del arqueo) | `#B42318` |

No se usa color para decir si algo es bueno o malo; eso lo dice el texto («Te alcanza», «Faltan S/ 80»). El rojo de las salidas dice hacia dónde fue la plata, no que esté mal: va solo en el monto (en el Historial, su detalle, las filas de salida del informe y su PDF, y el «Salió» y «Retiraste» de la semana en el Inicio), nunca en fondos, tarjetas ni totales como «Tienes hoy» o «tu plata bajó» (decisiones.md, 29-10-2026).

## Tipografía

Plus Jakarta Sans, pesos 400, 500, 600 y 700.

| Uso | Tamaño | Peso |
|---|---|---|
| Cifra principal («Tienes hoy») | grande, ver S04 | 700 |
| Título de pantalla | 17 a 20 px | 700 |
| Título de tarjeta | 16 a 17 px | 700 |
| Texto | 15 px | 400 a 600 |
| Texto secundario y etiquetas | 14 px | 400 a 700 |
| Etiquetas de la barra inferior | 14 px | 500 a 600 |

Mínimo 14 px en todo texto, sin excepciones (decidido el 12 de octubre de 2026; antes las etiquetas de la barra inferior usaban 13 px). Las cifras usan números tabulares.

## Forma

- Tarjetas: radio 16 px, borde de 1 px, relleno 14 a 16 px.
- Botones: radio 12 a 14 px. Principal de 52 px de alto, relleno azul y texto blanco; secundario de 48 px, fondo blanco y borde.
- Campos de texto: 44 px de alto, radio 10 px.
- Objetivo táctil mínimo: 44 px.
- Margen lateral de pantalla: 20 px. Separación entre tarjetas: 12 a 14 px.

## Marca

- Isotipo: cuadrado azul `#1D4ED8` de esquinas redondeadas con una «M» blanca de trazo.

```html
<svg width="40" height="40" viewBox="0 0 28 28"><rect width="28" height="28" rx="8" fill="#1D4ED8"/><path d="M7 20V9l7 7 7-7v11" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>
```

- Lo que dice Moca va en una tarjeta propia (tinte azul, con el isotipo o el nombre), para que el dueño lo distinga de los datos.

## Estructura de la app

- Barra inferior con cuatro pestañas: Inicio, Historial, Informes, Moca. Botón central para registrar.
- Lienzo de diseño: 390 × 844 px para el teléfono; 1280 px de ancho para el panel web.

## Redacción

- Palabras del dueño: «lo que te deben», «entró», «salió», «te quedó», «plata».
- Montos con el formato `S/ 4,250`. Saldos, totales e informes en soles enteros; cada registro (Historial, su detalle, la voz, el comprobante) con sus céntimos si los tiene: `S/ 3.40`, `S/ 980` (decisiones.md, 16-10-2026).
- Moca habla en tono neutro y profesional, sin jerga contable y sin exclamaciones.
- Los avisos tienen dos prioridades visibles: «Importante» y «Para tener en cuenta».
- Cuando Moca duda, pregunta y ofrece opciones.
