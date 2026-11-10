# Estilo visual

Reglas extraídas de los 50 mockups. Los HTML de `pantallas/` son la referencia exacta de medidas y colores; no son código de producción (usan estilos en línea y datos fijos).

## Color

Sistema de diseño de la mejora 01 (`docs/mejora-01/moca-08-sistema-de-diseno.png`, decisiones.md, 10-11-2026). Los valores viven en `app/lib/tema/colores.dart`; ninguna pantalla usa colores a mano.

Azul de marca. Ámbar para avisos y para lo pendiente. Rojo coral para las salidas. Sin verde y sin negro.

| Uso | Color |
|---|---|
| Azul 50 · 100 · 400 | `#EEF3FF` · `#E3EDFF` · `#3B6BEB` |
| Marca, botón principal, enlaces, ingreso | `#1D4ED8` |
| Azul 900 (texto sobre tinte, sombras) | `#1E3A8A` |
| Texto principal · secundario | `#13213F` · `#52607A` |
| Fondo de la app · superficie | `#F4F7FC` · `#FFFFFF` |
| Ingreso · su fondo | `#1D4ED8` · `#E3EDFF` |
| Egreso · su fondo | `#C42B3C` · `#FDE8EB` |
| Pendiente (barras y puntos) · texto · fondo | `#D97706` · `#8A4500` · `#FFF1D6` |
| Neutro o cero · su fondo | `#5F6B84` · `#F4F6FA` |
| Icono de Yape · su fondo | `#6D28D9` · `#F1EAFE` |
| Icono de Plin · su fondo | `#0E7490` · `#E0F5FA` |
| Borde de chip y campo · de campo de texto · separador | `#DDE5F0` · `#8696B0` · `#E4EAF3` |
| Sombra (azul al 6 %) | `#1E3A8A` al 6 % |

Todo par de texto y fondo pasa el contraste AA (4.5:1). El ámbar fuerte `#D97706` no lo pasa como texto: va solo en barras y puntos.

**El color nunca va solo.** Ingreso y egreso llevan además su signo (`+ S/ 80`, `– S/ 100`) y su flecha, y cada estado su palabra («Te debe», «Por subir»), para quien no distinga colores. El cero va siempre en gris neutro, nunca en rojo.

- **Rojo coral:** en el monto de una salida y en fondos suaves de chips, iconos y la tarjeta «Debes», siempre con su signo o flecha; nunca en el «Tienes hoy» ni en un resultado que bajó.
- **Subió o bajó (Informes):** flecha y signo siempre; azul si subió, gris neutro si bajó. No se pinta de rojo lo que bajó.
- **Yape morado y Plin celeste:** solo en el icono de esas cuentas, porque se reconocen al instante. El resto de iconos va en azul.

## Tipografía

Plus Jakarta Sans, pesos 400 a 800 (`app/lib/tema/tipografia.dart`).

| Uso | Tamaño / peso |
|---|---|
| Monto principal («Tienes hoy») | 52 / 800, con el «S/» al 45 % y más liviano |
| Monto de tarjeta | 24 / 800 |
| Título de pantalla | 26 / 800 |
| Título de sección | 16 / 800 |
| Texto | 15 / 500, interlineado 1.4 |
| Texto secundario | 14 / 500 |
| Texto de apoyo y etiquetas | 14 / 600 |

Mínimo 14 px en todo texto, sin excepciones (decidido el 12 de octubre de 2026 y confirmado el 10-11-2026: el «13 px» del sistema de diseño queda en 14). Todos los montos van con cifras tabulares. Se prueba con la letra del sistema al 130 % y al 150 %.

## Forma

- Espaciado en múltiplos de 4 y 8. Radios de 12, 16, 20 y 24 px (`app/lib/tema/medidas.dart`).
- Tarjetas: radio 20 px, sin borde gris, con sombra azul suave en dos niveles (`0 1 2` y `0 4 14`).
- Botones: radio 16 px. Principal de 52 px, relleno azul y texto blanco; secundario de 48 px, fondo azul suave y texto azul.
- Campos de texto: 48 px de alto, radio 12 px.
- Objetivo táctil mínimo: 48 px.
- Margen lateral de pantalla: 20 px. Separación entre tarjetas: 12 px.
- Iconos: Material Icons redondeados (vienen con Flutter), uno por tipo de movimiento, por categoría y por cuenta.
- Componentes reutilizables en `app/lib/comun/`: `MontoText`, `TarjetaResumen`, `BadgeEstado`, `ChipSeleccion`, `EstadoVacio`, `SeccionTitulo` y `FilaMovimiento`.

## Marca

- Isotipo: cuadrado azul `#1D4ED8` de esquinas redondeadas con una «M» blanca de trazo.

```html
<svg width="40" height="40" viewBox="0 0 28 28"><rect width="28" height="28" rx="8" fill="#1D4ED8"/><path d="M7 20V9l7 7 7-7v11" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>
```

- Lo que dice Moca va en una tarjeta propia (tinte azul, con el isotipo o el nombre), para que el dueño lo distinga de los datos.

## Estructura de la app

- Barra inferior con cuatro pestañas: Inicio, Historial, Informes, Asistente (antes «Moca»), y el + en el centro, que abre la hoja «Dilo o muéstralo» con voz, foto, QR, escribirlo y los atajos «Venta del día» y «Un gasto» (mejora 01).
- Ajustes se abre con el ⚙ del encabezado del Inicio, en todas sus versiones; la 🔔 lleva a los avisos del Asistente.
- Lienzo de diseño: 390 × 844 px para el teléfono; 1280 px de ancho para el panel web.

## Redacción

- Palabras del dueño: «lo que te deben», «entró», «salió», «te quedó», «plata».
- Montos con el formato `S/ 4,250`. Saldos, totales e informes en soles enteros; cada registro (Historial, su detalle, la voz, el comprobante) con sus céntimos si los tiene: `S/ 3.40`, `S/ 980` (decisiones.md, 16-10-2026).
- Moca habla en tono neutro y profesional, sin jerga contable y sin exclamaciones.
- Los avisos tienen dos prioridades visibles: «Importante» y «Para tener en cuenta».
- Cuando Moca duda, pregunta y ofrece opciones.
