# Prompt — Rediseño visual y de navegación de la app Moca (Flutter)

Actúa como diseñador senior de UX/UI de apps móviles financieras y como desarrollador Flutter experto en Material 3. Vas a mejorar la parte visual y la navegabilidad del prototipo de Moca, que ya está en este repositorio.

## Contexto del producto
- Moca ("Mi Organización Contable Asistida"), eslogan: "Tú vendes. Moca hace las cuentas."
- Usuarios: dueños de pequeños negocios en Perú (bodegas, restaurantes, servicios), sin formación contable, muchos mayores de 40 años, que usan teléfonos Android de gama media y a veces la app con una mano y con prisa.
- Tono de los textos: neutro, cercano y peruano ("plata", "Entró / Salió", "Te debe / Lo debes"). **No cambies los textos** salvo que te lo pida o que propongas un cambio para acortar o aclarar (lo propones, no lo aplicas sin aprobación).
- Marca: azul con tonos y sombras azules. **Sin verde predominante y sin negro.**
- Es un prototipo con datos simulados: **no toques la lógica, los modelos ni los datos**, solo la capa de presentación (widgets, tema, navegación visual).

## Problema actual (diagnóstico de las capturas)
Todo se ve plano: casi todas las pantallas son tarjetas blancas iguales con el mismo borde gris sobre fondo gris azulado, sin iconos, sin sombras y sin color con significado. La información importante no destaca. En concreto:

1. **Inicio**: el saldo "Tienes hoy S/ 600" está bien de tamaño, pero el desglose por cuenta (Efectivo, BCP Yape, BBVA Plin, BCP, Interbank) es una grilla de texto plano sin iconos ni jerarquía; el párrafo explicativo es largo y pesa igual que los datos. La tarjeta de Moca repite la acción del botón "+" ("Anotar un gasto"). "Tus primeros pasos" queda cortado por la barra inferior. El encabezado (nombre del negocio "Kuis" + "Tu primer día") es débil.
2. **Historial**: los movimientos pendientes ("Lo debes", "Te debe") se marcan solo con texto marrón y no se notan; no hay icono por categoría ni avatar por persona; no hay total del día; el chip "Filtrar" se mezcla con los filtros rápidos y el último chip ("Por subir") queda cortado sin indicar que hay más. Mucho espacio vacío debajo.
3. **Informes**: los botones "Compartir PDF" y "Compartir Excel" ocupan el lugar más visible, compiten con el resultado y "Compartir Excel" se parte en dos líneas. El número clave ("Este mes tu plata creció S/ 100") no tiene color ni indicador de subida/bajada. No hay ningún gráfico. Los S/ 0 de salidas aparecen en rojo aunque sean cero.
4. **Pestaña Moca**: la prueba gratis ("te quedan 8 días") es solo texto, sin barra de progreso ni urgencia visual; "Cómo pagar" es un botón contorneado sin peso. En "Tu semana, en 5 segundos" el dato importante ("te quedan S/ 100") está en letra pequeña debajo del botón Escuchar. El estado vacío de Avisos es un párrafo sin icono. "Ajustes" está como tarjeta dentro de esta pestaña.
5. **Escribirlo (registro manual)**: todos los chips de "¿Qué fue?" (Entró, Salió, Retiro para mí, Puse de mi bolsillo, Pasé plata) se ven iguales, sin color ni icono que diferencie ingreso de egreso. El campo de monto es pequeño, cuando es el dato principal. El botón "Guardar" aparece gris deshabilitado sin decir qué falta. El formulario es largo y se corta. Los chips de categoría con texto largo ("Servicios (luz, agua, internet, teléfono)") rompen el ritmo.
6. **Ajustes**: cada opción es una tarjeta separada con el mismo peso; no hay iconos; el botón atrás en una caja cuadrada se ve pesado.
7. **Navegación**: la pestaña "Moca" es ambigua (¿es el asistente, la cuenta, los ajustes?). El botón central "+" está bien ubicado, pero debe abrir opciones claras de registro.

## Objetivo
Que la app se vea moderna, confiable y clara, que en 2 segundos el dueño entienda **cuánta plata tiene, si va bien o mal y qué tiene pendiente**, y que registrar un movimiento sea lo más rápido posible.

## Lo que debes hacer

### Fase 1 — Sistema de diseño (antes de tocar pantallas)
Crea o reorganiza un tema centralizado (`lib/theme/` o similar) con tokens; ninguna pantalla debe usar colores, tamaños o radios "a mano":
- **Color** (Material 3, `ColorScheme` a partir del azul de marca):
  - Primario azul de marca y su escala (50–900) para fondos, contenedores y sombras azuladas.
  - Colores semánticos: **ingreso** (azul intenso o azul verdoso/teal muy discreto, nunca verde dominante), **egreso** (rojo coral, no rojo puro), **pendiente / por cobrar / por pagar** (ámbar), **neutro / cero** (gris azulado). Cada uno con su versión de fondo suave para chips y badges.
  - Superficies con 2–3 niveles de elevación en lugar de borde gris en todo; sombras suaves con tinte azul.
  - Contraste mínimo WCAG AA (4.5:1 en texto normal).
- **Tipografía**: mantén la familia actual (o propón una alternativa como Plus Jakarta Sans / Inter / Manrope justificando el cambio). Define una escala clara (display para montos, título, subtítulo, cuerpo, etiqueta). **Todos los montos con cifras tabulares** (`FontFeature.tabularFigures()`) y el símbolo "S/" más pequeño y liviano que la cifra.
- **Espaciado** en múltiplos de 4/8, radios consistentes (p. ej. 12 y 20) e **iconografía** (Material Symbols Rounded o Lucide) con un icono por tipo de movimiento, por categoría y por cuenta (efectivo, Yape, Plin, banco).
- **Componentes reutilizables**: `MontoText` (con signo, color semántico y tamaño), `TarjetaResumen`, `FilaMovimiento`, `BadgeEstado` (Pendiente, Te debe, Lo debes, Por subir), `ChipSeleccion` con icono y color por tipo, `EstadoVacio` con icono + texto + acción, `SeccionTitulo`.
- Respeta el escalado de fuente del sistema (probar con 130 %) y áreas táctiles mínimas de 48 dp.

### Fase 2 — Navegación
- Barra inferior con 4 destinos + botón central: Inicio, Historial, [+], Informes, y renombra "Moca" por algo inequívoco (p. ej. "Asistente"); muévelo o justifica dejarlo.
- Ajustes accesible desde un icono de perfil/negocio en el encabezado de Inicio, no como tarjeta.
- El "+" abre una hoja inferior (bottom sheet) con las formas de registrar: Foto de comprobante, Por voz, Escribirlo; cada una con icono grande y una línea de descripción. (Si ya existe ese flujo, solo mejóralo visualmente.)
- Que el contenido nunca quede tapado por la barra inferior (padding inferior correcto).
- Transiciones suaves entre pantallas y animación sutil al cambiar montos (contador animado).

### Fase 3 — Pantallas (una por una, en este orden)
1. **Inicio**: encabezado con nombre del negocio, saludo y fecha; tarjeta principal "Tienes hoy" con fondo azul de marca (degradado suave), monto grande en blanco y debajo las cuentas como lista o carrusel horizontal con icono por cuenta. El texto explicativo pasa a un icono de información (tooltip u hoja inferior). Agrega un bloque "Pendientes" (te deben / debes) con badges ámbar. La tarjeta de Moca muestra el mensaje y una acción distinta al "+". "Tus primeros pasos" como checklist con barra de progreso, y que se oculte al completarse.
2. **Historial**: agrupar por día con total del día (entró / salió); cada fila con icono de categoría o inicial de la persona en círculo, descripción, badge de estado y monto con color semántico y signo. Chips de filtro desplazables con indicación visual de que hay más; "Filtrar" como icono separado. Estado vacío ilustrado.
3. **Informes**: el resultado del periodo arriba, con flecha y color (subió / bajó) y comparación cuando exista. Agrega un gráfico simple (barras entró vs. salió por semana o día) con `fl_chart` o similar. El flujo "Cómo se movió tu plata" como tabla clara con separadores y total destacado; los S/ 0 en gris neutro, no en rojo. "Compartir" pasa a un solo botón/icono en la barra superior que abre opciones PDF / Excel.
4. **Asistente (ex Moca)**: banner de prueba gratis con barra de progreso de días y botón primario lleno "Activar mi plan"; tarjeta "Tu semana" con el dato principal grande y el botón Escuchar como acción secundaria; avisos como lista con icono y prioridad (color); estado vacío amable con icono.
5. **Escribirlo**: el monto como protagonista arriba (campo grande, teclado numérico, "S/" fijo). Chips de "¿Qué fue?" con icono y color según sea ingreso, egreso o movimiento interno. Mostrar solo las preguntas que aplican según la opción elegida (revelado progresivo) y mantener "Guardar" fijo abajo; si está deshabilitado, indicar qué falta ("Falta el monto"). Categorías con icono y texto corto, más un "Ver más".
6. **Ajustes**: secciones agrupadas en una sola tarjeta con divisores, icono a la izquierda de cada opción, botón atrás estándar de Material 3 sin caja.

### Reglas de trabajo
- Antes de programar, entrégame un **plan breve**: tokens propuestos (paleta con códigos hex, escala tipográfica), cambios de navegación y lista de archivos que vas a tocar. **Espera mi aprobación.**
- Después avanza **pantalla por pantalla**; al terminar cada una, dime qué cambiaste y cómo verlo (y, si puedes, genera capturas o golden tests antes/después).
- No agregues dependencias pesadas sin justificarlas; prefiere las de Flutter/Material.
- Mantén modo claro como principal y deja el tema preparado para modo oscuro (no es obligatorio implementarlo ahora).
- Todo el texto de la interfaz y tus explicaciones, en español.
- Al final, haz una revisión de consistencia: que ninguna pantalla use colores, tamaños o estilos fuera del sistema de diseño.
