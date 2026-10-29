# Prueba con varios teléfonos (entrega 23)

Guion para probar con teléfonos de verdad lo que hicieron las entregas 17 a 22, antes de los 10 pilotos. La parte que se hace con un solo teléfono («Ver como…» y «Simular una venta de Pepe» en el ajuste oculto) ya está en la entrega 20.1.

## Qué hace falta

- **Teléfono A:** el de Jhony, con su negocio y la cuenta guardada. Es el dueño titular.
- **Teléfono B:** cualquier Android con **otro número**, que reciba SMS. Puede ser de un familiar o de un empleado. Si alguna vez tuvo Moca, que esté en la Bienvenida o solo con la Demo.
- **Teléfono C (opcional):** un tercer número, solo para probar la parte de la sección 7 que necesita otro teléfono.
- Los dos con el APK de la última entrega y con señal, salvo cuando el guion diga lo contrario.
- Unos 60 a 90 minutos.

**Cuidado:** nunca entres con el número de A en el teléfono B. Moca deja una cuenta en un solo teléfono, y el teléfono A quedaría cerrado.

## Antes de empezar

| # | Qué hacer | Qué debe pasar |
|---|---|---|
| 0.1 | Abre `/salud` del servidor | Responde bien, con la versión del servidor de la última entrega |
| 0.2 | En A y en B, revisa la versión en el ajuste oculto | Las dos terminan en el mismo código del commit |
| 0.3 | En A, anota la hora; es la del inicio de la prueba | Sirve para encontrar después en el Historial lo anotado durante la prueba |

**Cuándo se pasa lo de un teléfono al otro:** a los 5 segundos de abrir la app, al volver a ella y cada 5 minutos. Para no esperar, sal de la app y vuelve a entrar.

## 1. Invitar y aceptar (B entra como encargado)

| # | Teléfono | Qué hacer | Qué debe pasar |
|---|---|---|---|
| 1.1 | A | Pestaña Moca → «Mi equipo» | Sale «Tú» como Dueño · Titular, y cuántos lugares quedan |
| 1.2 | A | «Invitar a alguien»: nombre «Rosa», el número de B, rol Encargado | «Listo. Dile a Rosa que instale Moca…». En «Mi equipo» aparece la invitación con su fecha de vencimiento (7 días) |
| 1.3 | B | En la Bienvenida, «Me invitaron a un negocio», el número de B y el código del SMS | «Te invitaron a [tu negocio] · Como Encargado», con el texto del consentimiento |
| 1.4 | B | «Aceptar y entrar» | Baja lo del negocio y abre el Inicio con «En tu caja hoy» (no «Tienes hoy») |
| 1.5 | A | Vuelve a «Mi equipo» | Rosa aparece como Encargado; la invitación ya no está |
| 1.6 | A | Inicio | Bajo el nombre del negocio dice «Actualizado hace…» |

## 2. Lo que ve el encargado

| # | Teléfono | Qué hacer | Qué debe pasar |
|---|---|---|---|
| 2.1 | B | Mira la barra de abajo | No está la pestaña Informes |
| 2.2 | B | Pestaña Moca | No hay avisos ni resumen de la semana, ni «Mis cuentas». Está «Mi equipo», solo para mirar (sin «Invitar» ni «Quitar») |
| 2.3 | B | Historial | Ve lo de su caja y lo que anotó; lo de otros dice «Lo anotó el dueño» |
| 2.4 | B | Hace el arqueo | Solo cuenta su caja |

## 3. Anotar y corregir entre los dos

| # | Teléfono | Qué hacer | Qué debe pasar |
|---|---|---|---|
| 3.1 | B | Anota por voz «vendí 15 soles en efectivo» | Se guarda en su caja |
| 3.2 | A | Sale y vuelve a la app; abre el Historial | Aparece la venta de S/ 15 con «Lo anotó Rosa». El saldo del efectivo subió S/ 15 |
| 3.3 | A | Corrige esa venta a S/ 18 | Se guarda |
| 3.4 | B | Sale y vuelve; abre el Historial | La venta dice S/ 18 |
| 3.5 | B | Corrige un gasto que anotó A | Se puede: el encargado corrige lo de otros |
| 3.6 | B | Apaga datos y wifi; anota un gasto de S/ 5 | Se guarda en el teléfono |
| 3.7 | B | Prende la señal y vuelve a la app | El gasto sube. En A, tras salir y volver, aparece con «Lo anotó Rosa» |
| 3.8 | A y B | Los dos anotan una venta casi al mismo tiempo | En los dos teléfonos aparecen las dos ventas, sin repetirse ni perderse |

## 4. Varias cajas y «Pasé plata»

| # | Teléfono | Qué hacer | Qué debe pasar |
|---|---|---|---|
| 4.1 | A | «Mis cuentas» → agrega «Caja delivery» con un saldo inicial | Aparece la caja nueva |
| 4.2 | A | «Mi equipo» → en Rosa, toca «Cajas: La caja principal» y elige solo «Caja delivery» | «Listo. Sus cajas quedaron guardadas.» |
| 4.3 | B | Sale y vuelve | El Inicio muestra el saldo de «Caja delivery». Al anotar, su efectivo va a esa caja y la caja principal no se ofrece |
| 4.4 | B | Anota «pasé 10 de la caja a Yape» | Una fila «Pasé plata · Caja delivery → Yape», sin signo |
| 4.5 | A | Sale y vuelve | El pase aparece; «Caja delivery» bajó S/ 10 y Yape subió S/ 10; «Entró» y «Salió» no cambian |
| 4.6 | A | Anota un pase de la caja principal a «Caja delivery» | En B, tras volver, el saldo de su caja sube |

## 5. Quitar y volver a invitar (B pasa a ayudante)

| # | Teléfono | Qué hacer | Qué debe pasar |
|---|---|---|---|
| 5.1 | A | «Mi equipo» → Quitar a Rosa → confirmar | Rosa desaparece; lo que anotó sigue en el Historial |
| 5.2 | B | Sale y vuelve | La pestaña Moca dice «Ya no estás en este negocio»; lo que anote ya no sube |
| 5.3 | A | Invita al número de B como Ayudante | Aparece la invitación |
| 5.4 | B | Ajuste oculto → «Borrar todo y empezar de nuevo» | Vuelve a la Bienvenida |
| 5.5 | B | «Me invitaron a un negocio», número de B y código | «Te invitaron a [tu negocio] · Como Ayudante» |
| 5.6 | B | «Aceptar y entrar» | Baja lo del negocio y abre el Inicio |

Hoy quien fue quitado no ve «Mis negocios», por eso vuelve a entrar desde la Bienvenida (ver `pendientes.md`).

## 6. Lo que ve y hace el ayudante

| # | Teléfono | Qué hacer | Qué debe pasar |
|---|---|---|---|
| 6.1 | B | Inicio | «Ventas que anotaste hoy» y el saldo de su caja; no ve el saldo del negocio |
| 6.2 | B | Historial | Solo lo que anotó hoy |
| 6.3 | B | «Escribirlo» | No ofrece «Retiro para mí» ni «Puse de mi bolsillo» |
| 6.4 | B | Dice por voz «saqué 20 para mí» | Moca pregunta qué tipo es; no lo guarda como retiro |
| 6.5 | B | Anota una venta y la corrige | Se puede: es suya y de hoy |
| 6.6 | B | Busca el arqueo y «Mis cuentas» | No están |
| 6.7 | A | Sale y vuelve | La venta del ayudante aparece con su nombre |

## 7. Límite de 3 personas

| # | Teléfono | Qué hacer | Qué debe pasar |
|---|---|---|---|
| 7.1 | A | Invita a un tercer número (C o cualquier otro) como Ayudante | Se puede: quedan A, B y la invitación |
| 7.2 | A | Intenta invitar a un cuarto número como Encargado | «Ya están las 3 personas. Quita a alguien o anula una invitación.» |
| 7.3 | A | Invita a ese cuarto número como Contador | Se puede: el contador no cuenta |
| 7.4 | A | Anula las dos invitaciones | Desaparecen de «Mi equipo» |

## 8. El contador en varios negocios

B deja de ser ayudante y abre su propio negocio; luego A lo invita como contador del suyo.

| # | Teléfono | Qué hacer | Qué debe pasar |
|---|---|---|---|
| 8.1 | A | Quita a B del equipo | B queda fuera del negocio |
| 8.2 | B | Ajuste oculto → «Borrar todo y empezar de nuevo» | Vuelve a la Bienvenida |
| 8.3 | B | Anota una primera venta y crea el negocio «Prueba B». Cuando pida el celular, usa el número de B | «Este número ya tiene una cuenta de Moca»: elige «Empezar de cero con este número» |
| 8.4 | A | Invita al número de B como Contador | Aparece la invitación |
| 8.5 | B | «Mis negocios» → en «Te invitaron», «Aceptar» | Pasa a ver el negocio de A |
| 8.6 | B | Recorre la app | Inicio con saldos, Historial, Informes con PDF y Excel, avisos. No hay botón para anotar, ni arqueo, ni «Corregir» |
| 8.7 | B | «Mis negocios» | Lista los dos: el de A como Contador con «Estás aquí», y «Prueba B» como Dueño con «Ver» |
| 8.8 | B | «Ver» en «Prueba B» | «Listo. Ahora ves Prueba B.»; está su primera venta |
| 8.9 | B | Sin señal, abre «Mis negocios» | Dice que necesita señal y ofrece «Intentar otra vez» |
| 8.10 | B | Con señal, vuelve al negocio de A | Ve lo último que anotó A |

## 9. Al terminar

| # | Teléfono | Qué hacer | Qué debe pasar |
|---|---|---|---|
| 9.1 | A | Quita a B del equipo | Solo queda A |
| 9.2 | A | Revisa el Historial desde la hora del paso 0.3 | Están las ventas, gastos y pases de la prueba con su autor. Deshaz los que no quieras dejar en el negocio |
| 9.3 | B | Si el teléfono no es tuyo: ajuste oculto → «Borrar todo y empezar de nuevo» y desinstalar | Moca sale del teléfono prestado |

## Cómo anotar lo que salga mal

Para cada paso que no salga como dice la tabla, anota:
- el número del paso y el teléfono;
- qué pasó;
- una captura de pantalla, si se puede.

Pégamelo así en la conversación. Los errores se arreglan antes de los 10 pilotos.
