import '../dominio/modelos.dart';

/// Todos los textos de la app, en español de Perú y en un solo lugar,
/// para poder ajustarlos después de la prueba con pilotos.
abstract final class Textos {
  static const nombreApp = 'Moca';
  static const eslogan = 'Tú vendes. Moca hace las cuentas.';

  // Barra inferior
  static const pestanaInicio = 'Inicio';
  static const pestanaHistorial = 'Historial';
  static const pestanaInformes = 'Informes';
  static const pestanaMoca = 'Moca';
  static const registrar = 'Registrar';

  // Pantallas que llegan en entregas siguientes
  static const tituloInicio = 'Inicio';
  static const tituloHistorial = 'Historial';
  static const tituloInforme = 'Informe del mes';
  static const subtituloMoca = 'Tu asistente de cuentas';
  static String llegaEnEntrega(int n) => 'Esta parte llega en la entrega $n.';
  static const entendido = 'Entendido';

  // S00 · Bienvenida
  static const nombreCompleto = 'Mi Organización Contable Asistida';
  static const esloganEnDosLineas = 'Tú vendes.\nMoca hace las cuentas.';
  static const bienvenidaDetalle =
      'Registra con una foto o con tu voz y entérate cada día de cuánta '
      'plata tienes y cuánto te queda.';
  static const anotarPrimeraVenta = 'Anotar mi primera venta';
  static const sinCrearCuenta = 'Sin crear cuenta. Te toma diez segundos.';
  static const verDemo = 'Ver una demo';
  static const yaTengoCuenta = 'Ya tengo cuenta';
  static const demoLlega = 'La demo llega en la entrega 9.';
  static const cuentaEnTelefonoTitulo = 'Tu cuenta está en tu teléfono';
  static const cuentaEnTelefono =
      'En esta prueba tu cuenta vive en el teléfono donde la creaste.';
  static const empezar = 'Empezar';

  // S07 · Venta de hoy (escrita, hasta que llegue la voz)
  static const ventaDeHoy = 'Venta de hoy';
  static const cuantoVendisteHoy = '¿Cuánto vendiste hoy?';
  static const ventaPorCuentaDetalle =
      'Escribe cuánto entró en cada sitio. Lo que no usaste, déjalo vacío.';
  static const efectivo = 'Efectivo';
  static const yape = 'Yape';
  static const banco = 'Banco';
  static const agregarBanco = '+ Banco';
  static String nombreCuenta(TipoCuenta cuenta) => switch (cuenta) {
    TipoCuenta.efectivo => efectivo,
    TipoCuenta.yape => yape,
    TipoCuenta.banco => banco,
  };
  static const totalQueEntroHoy = 'Total que entró hoy';
  static const guardar = 'Guardar';
  static const volver = 'Volver';

  // S01 · Guarda tu avance
  static const primeraVentaAnotada = 'Tu primera venta ya está anotada';
  static String hoyEntraron(String monto) => 'Hoy entraron $monto';
  static const guardaTuAvance = 'Guarda tu avance con tu celular';
  static const sinCorreoNiContrasena =
      'Sin correo ni contraseña. Te llega un código por SMS o WhatsApp.';
  static const tuNumeroDeCelular = 'Tu número de celular';
  static const prefijoPeru = '+51';
  static const celularEjemplo = '9__ ___ ___';
  static const celularInvalido =
      'Revisa el número: son 9 dígitos y empieza con 9.';
  static const enviarmeCodigo = 'Enviarme el código';
  static const ahoraNo = 'Ahora no, seguir probando';

  // Código (no dibujado)
  static const escribeElCodigo = 'Escribe el código';
  static String codigoEnviadoA(String celular) => 'Te lo enviamos al $celular.';
  static const codigoEnPrueba =
      'En esta prueba no llega ningún mensaje: escribe cualquier número '
      'de 6 dígitos.';
  static const codigo = 'Código de 6 dígitos';
  static const confirmar = 'Confirmar';
  static const cambiarNumero = 'Cambiar número';

  // S02 · Alta inicial
  static const unMinutoYListo = 'Un minuto y listo';
  static const cuentaleDeTuNegocio = 'Cuéntale a Moca de tu negocio';
  static const comoSeLlama = '¿Cómo se llama?';
  static const nombreEjemplo = 'Bodega Don Lucho';
  static const queTipoDeNegocio = '¿Qué tipo de negocio es?';
  static const bodega = 'Bodega';
  static const restaurante = 'Restaurante';
  static const servicios = 'Servicios';
  static const otro = 'Otro';
  static const cuantaPlataTienes = '¿Cuánta plata tienes hoy en cada sitio?';
  static const sinContarLaVenta =
      'Sin contar la venta que acabas de anotar. Un aproximado sirve. '
      'Lo ajustas en tu primer arqueo.';
  static const aQueHoraCierras = '¿A qué hora cierras?';
  static const mocaRecuerdaVenta = 'Moca te recuerda anotar la venta del día.';
  static const listoEmpezar = 'Listo, empezar';
  static const noSeCuantoTengo = 'No sé cuánto tengo, lo pongo después';
  static const textoLegalAlta =
      'Tus datos se guardan solo en este teléfono. Al empezar aceptas que '
      'Moca los use para ordenar tus cuentas.';

  // S03 · Primer día
  static const tuPrimerDia = 'Tu primer día';
  static const tienesHoy = 'Tienes hoy';
  static const notaSaldoMasVenta =
      'Es lo que tenías al empezar más tu venta de hoy. Desde aquí Moca '
      'lleva la cuenta.';
  static const notaSoloSaldo =
      'Es lo que anotaste al empezar. Desde aquí Moca lleva la cuenta.';
  static const notaConMovimientos =
      'Es lo que tenías al empezar, más lo que entró y menos lo que salió. '
      'Desde aquí Moca lleva la cuenta.';
  static const notaSaldoPendiente = 'Aún no pones cuánto tenías al empezar.';
  static const mocaEmpiezaPorLaVenta =
      'Empieza por lo más fácil: dime cuánto vendiste hoy. Toma menos de '
      'diez segundos.';
  static const mocaYaAnotaste =
      'Ya anotaste la venta de hoy. Te recuerdo la siguiente a tu hora de '
      'cierre.';
  static const anotarVentaDeHoy = 'Anotar la venta de hoy';
  static const anotarUnGasto = 'Anotar un gasto';
  static const tusPrimerosPasos = 'Tus primeros pasos';
  static const pasoDecirPlata = 'Decir cuánta plata tienes';
  static String pasoVentaCincoDias(int llevas) =>
      'Anotar la venta 5 días · llevas $llevas';
  static const pasoPrimerGasto = 'Anotar tu primer gasto con una foto';
  static const pasoPrimerArqueo = 'Hacer tu primer arqueo el domingo';
  static const conEstosPasos =
      'Con estos cuatro pasos Moca ya puede decirte si ganas o pierdes.';

  // Hoja del saldo (paso 1)
  static const cuantoTeniasAlEmpezar = '¿Cuánta plata tenías al empezar?';
  static const saldoHojaDetalle =
      'Antes de tu primera venta. Un aproximado sirve.';
  static const guardarSaldo = 'Guardar';

  // S04 · Inicio
  static const ocultarMontos = 'Ocultar montos';
  static const mostrarMontos = 'Mostrar montos';
  static const montoOculto = 'S/ •••';
  static const estaSemanaTeQuedo = 'Esta semana te quedó ';
  static String masQueLaSemanaPasada(String monto) =>
      '$monto más que la semana pasada';
  static String menosQueLaSemanaPasada(String monto) =>
      '$monto menos que la semana pasada';
  static const igualQueLaSemanaPasada = 'Lo mismo que la semana pasada';
  static String entroSalio(String entro, String salio) =>
      'Entró $entro · Salió $salio';
  static const semanaSinMovimientos = 'Esta semana todavía no anotas nada.';
  static const mocaFaltaVentaDeHoy = 'Aún no anotas la venta de hoy.';
  static const mocaYaAnotasteHoy = 'Ya anotaste la venta de hoy.';

  // Venta de hoy, después del primer día
  static String hoyYaAnotaste(String monto) =>
      'Hoy ya anotaste $monto. Esto se suma.';

  // S07 y S18 · Voz
  static const registroPorVoz = 'Registro por voz';
  static const microfonoExplicacion =
      'Moca necesita el micrófono para escuchar lo que le dices. No guarda '
      'el audio.';
  static const empezarAEscuchar = 'Empezar a escuchar';
  static const teEscucho = 'Te escucho…';
  static const tocaParaTerminar = 'Toca cuando termines';
  static const tocaParaGrabarOtraVez = 'Toca para grabar otra vez';
  static const preparandoMicrofono = 'Preparando el micrófono…';
  static const ejemploQueDecir = 'Por ejemplo: «Hoy vendí 350 en efectivo»';
  static const prefieroEscribirlo = 'Prefiero escribirlo';
  static const decirloOtraVez = 'Decirlo otra vez';
  static const sinPermisoMicrofono =
      'Sin permiso para el micrófono, Moca no puede escucharte. Puedes '
      'escribirlo, o darle permiso en los ajustes del teléfono.';
  static const vozNoDisponible =
      'Tu teléfono no puede reconocer la voz en este momento. Puedes '
      'escribirlo.';
  static const noTeEntendi =
      'No te entendí. Puedes decir, por ejemplo: «Hoy vendí 350 en efectivo».';
  static const mocaEntendio = 'Moca entendió';
  static const loQueDijiste = 'lo que dijiste';
  static const totalQueSale = 'Total que salió';
  static const corregirUnDato = 'Corregir un dato';
  static const noEscucheElMonto = 'No escuché bien el monto. ¿Cuánto fue?';
  static const otroMonto = 'Otro monto';
  static const confirmarMonto = 'Usar este monto';
  static const entroOSalio = '¿Entró o salió plata?';
  static String dondeEntro(String monto) => '¿Dónde entraron los $monto?';
  static String deDondeSalioMonto(String monto) =>
      '¿De dónde salieron los $monto?';
  static const enQueFue = '¿En qué fue?';
  static const deQueFue = '¿De qué fue?';
  static const mocaNuncaAdivina =
      'Moca pregunta cuando no está segura. Nunca adivina un monto.';

  // Foto y QR
  static const leyendoComprobante = 'Leyendo el comprobante…';
  static const abriendoCamara = 'Abriendo la cámara…';
  static const sinPermisoCamara =
      'Sin permiso para la cámara, Moca no puede leer el comprobante. Puedes '
      'escribirlo, o darle permiso en los ajustes del teléfono.';
  static const apuntaAlQr = 'Apunta al código QR del comprobante';
  static const linterna = 'Linterna';
  static const qrNoEsComprobante =
      'Este código no es de un comprobante electrónico.';
  static const comprobanteYaAnotado = 'Este comprobante ya está anotado.';
  static const intentarOtraVez = 'Intentar otra vez';

  // S08 · Confirmar lectura
  static const revisaLaLectura = 'Revisa la lectura';
  static const foto = 'Foto';
  static const salioCompra = 'Salió plata · compra';
  static const aQuien = 'A quién';
  static const aQuienEjemplo = 'Nombre del proveedor';
  static const queCompraste = 'Qué compraste';
  static String productos(int n) => n == 1 ? '1 producto' : '$n productos';
  static const tipoDeGasto = 'Tipo de gasto';
  static const eligeTipoDeGasto = 'Elige';
  static const yaLoPagaste = '¿Ya lo pagaste?';
  static const siPagado = 'Sí, pagado';
  static const todaviaLoDebo = 'Todavía lo debo';
  static const total = 'Total';
  static const fecha = 'Fecha';
  static const leidoDelQr =
      'Leído del código QR. El QR no dice qué compraste: elige el tipo de '
      'gasto.';
  static const leidoDeLaFoto =
      'Leído de la foto. Revisa que el total sea el '
      'del comprobante.';
  static const completadoAMano =
      'La foto no se leyó completa: lo que falta lo pones tú.';
  static String rucDe(String ruc) => 'RUC $ruc';

  // S17 · Foto ilegible
  static const fotoBorrosa = 'La foto salió borrosa';
  static const fotoBorrosaDetalle =
      'Moca leyó el total, pero no el resto. No se guarda nada hasta que lo '
      'confirmes.';
  static const noSeLee = 'No se lee';
  static const paraQueSalgaBien = 'Para que salga bien';
  static const consejoMesa = 'Apoya el papel en una mesa';
  static const consejoCompleto = 'Que se vea completo, sin dobleces';
  static const consejoSombra = 'Sin tu sombra encima';
  static const tomarOtraFoto = 'Tomar otra foto';
  static const completarAMano = 'Completar a mano';

  // S06 · Registrar
  static const cerrar = 'Cerrar';
  static const diloOMuestralo = 'Dilo o muéstralo';
  static const mocaReconoceSola = 'Moca reconoce sola si entró o salió plata.';
  static const decirloConVoz = 'Decirlo con voz';
  static const ejemplosVoz = '«Hoy vendí 350» · «Pagué 80 de luz»';
  static const tomarFoto = 'Tomar foto';
  static const tomarFotoDetalle = 'Boleta, factura, ticket o nota de venta';
  static const leerQr = 'Leer el código QR';
  static const leerQrDetalle = 'Lectura exacta de comprobantes electrónicos';
  static const escribirlo = 'Escribirlo';
  static const escribirloDetalle = 'Entró o salió, monto y cuenta';
  static String llegaEnLaEntrega(int n) => 'Llega en la entrega $n';

  // «Escribirlo» (no dibujado)
  static const queFue = '¿Qué fue?';
  static const entro = 'Entró';
  static const salio = 'Salió';
  static const retiroParaMi = 'Retiro para mí';
  static const retiroDetalle =
      'Baja la plata de la cuenta, pero no cuenta como gasto del negocio.';
  static const cuanto = '¿Cuánto?';
  static const deDondeSalio = '¿De dónde salió la plata?';
  static const aDondeEntro = '¿A dónde entró la plata?';
  static const enQue = '¿En qué?';
  static const deQue = '¿De qué?';
  static const nota = 'Nota (opcional)';
  static const notaEjemplo = 'Por ejemplo: luz de octubre';
  static const quedariaNegativoTitulo = '¿Lo guardo igual?';
  static String quedariaNegativo(String cuenta, String monto) =>
      'Con esto, en ${cuenta.toLowerCase()} te quedaría $monto.';
  static const revisar = 'Revisar';
  static const guardarIgual = 'Guardar igual';

  // Después de guardar
  static String guardadoAhoraTienes(String monto) =>
      'Guardado. Ahora tienes $monto';
  static const deshacer = 'Deshacer';
  static const seDeshizo = 'Listo, no se guardó.';

  // S10 · Historial
  static const filtroTodo = 'Todo';
  static String filtroPorSubir(int n) => n > 0 ? 'Por subir · $n' : 'Por subir';
  static const marcaPorSubir = 'por subir';
  static const loDebes = 'Lo debes';
  static const retiroNoCuenta = 'No cuenta como gasto del negocio';
  static const historialVacio =
      'Todavía no hay registros. Lo que anotes aparece aquí.';
  static const sinEntradas = 'Todavía no hay registros de plata que entró.';
  static const sinSalidas = 'Todavía no hay registros de plata que salió.';
  static const nadaPorSubir = 'No hay nada por subir.';

  // Detalle del movimiento (no dibujado)
  static const tituloDetalle = 'Registro';
  static const etiquetaQueFue = 'Qué fue';
  static const etiquetaCuenta = 'Cuenta';
  static const etiquetaCategoria = 'Categoría';
  static const etiquetaFecha = 'Fecha';
  static const etiquetaNota = 'Nota';
  static const etiquetaComoSeAnoto = 'Cómo se anotó';
  static const etiquetaPago = 'Pago';
  static const etiquetaProveedor = 'Proveedor';
  static const etiquetaComprobante = 'Comprobante';
  static const etiquetaRuc = 'RUC';
  static String nombreTipo(TipoMovimiento tipo) => switch (tipo) {
    TipoMovimiento.ingreso => entro,
    TipoMovimiento.egreso => salio,
    TipoMovimiento.retiro => retiroParaMi,
  };
  static String comoSeAnoto(Fuente fuente) => switch (fuente) {
    Fuente.voz => 'Lo dijiste por voz',
    Fuente.texto => 'Lo escribiste',
    Fuente.foto => 'Foto del comprobante',
    Fuente.qr => 'QR del comprobante',
    Fuente.sire => 'Archivo de SIRE',
    Fuente.arqueo => 'En el arqueo',
  };
  static const pagado = 'Pagado';
  static String pagadoEl(String fecha) => 'Pagado el $fecha';
  static const todaviaLoDebes =
      'Todavía lo debes. No baja tu saldo hasta que lo pagues.';
  static const guardadoPorSubir =
      'Guardado en tu teléfono. Sube cuando vuelva la señal.';
  static const yaNoCuenta =
      'Este registro ya no cuenta: se deshizo o se corrigió.';
  static const yaLoPague = 'Ya lo pagué';
  static const corregir = 'Corregir';
  static const deshacerRegistro = 'Deshacer este registro';
  static const deshacerTitulo = '¿Deshacer este registro?';
  static String deshacerConSaldo(String cuenta, String monto) =>
      'Tu saldo en ${cuenta.toLowerCase()} vuelve a $monto. Queda anotado '
      'en Cambios.';
  static const deshacerSinSaldo =
      'Tu saldo no cambia, porque todavía lo debías. Queda anotado en '
      'Cambios.';
  static const registroDeshecho = 'Registro deshecho.';
  static const verFoto = 'Ver la foto';

  // Cambios (bitácora)
  static const cambios = 'Cambios';
  static const autorTu = 'Tú';
  static String anotado(Fuente fuente) => switch (fuente) {
    Fuente.voz => 'Lo anotaste por voz',
    Fuente.texto => 'Lo anotaste escrito',
    Fuente.foto => 'Lo anotaste con una foto',
    Fuente.qr => 'Lo anotaste con el QR',
    Fuente.sire => 'Llegó del archivo de SIRE',
    Fuente.arqueo => 'Se anotó en el arqueo',
  };
  static String cambiasteTipo(String antes, String despues) =>
      'Cambiaste qué fue: $antes → $despues';
  static String cambiasteMonto(String antes, String despues) =>
      'Cambiaste el monto: $antes → $despues';
  static String cambiasteCuenta(String antes, String despues) =>
      'Cambiaste la cuenta: $antes → $despues';
  static String cambiasteCategoria(String antes, String despues) =>
      'Cambiaste la categoría: $antes → $despues';
  static String cambiasteNota(String antes, String despues) =>
      'Cambiaste la nota: $antes → $despues';
  static const sinNota = 'sin nota';
  static const sinCategoria = 'sin categoría';
  static const corregisteSinCambios = 'Lo corregiste sin cambiar datos';
  static String pagaste(String cuenta, String fecha) =>
      'Marcaste que ya lo pagaste: $cuenta, $fecha';
  static const deshiciste = 'Lo deshiciste';

  // Corregir
  static const corregirRegistro = 'Corregir registro';
  static const guardarCambios = 'Guardar cambios';
  static const datosDelComprobante =
      'El monto y el tipo son los del comprobante. Si están mal, deshaz este '
      'registro y vuelve a anotarlo.';
  static String cambiosGuardados(String monto) =>
      'Cambios guardados. Ahora tienes $monto';

  // «Ya lo pagué»
  static const conQuePagaste = '¿Con qué pagaste?';
  static const cuandoPagaste = '¿Cuándo?';
  static const hoy = 'Hoy';
  static const ayer = 'Ayer';
  static const otroDia = 'Otro día';
  static String pagadoAhoraTienes(String monto, String cuenta) =>
      'Pagado. Ahora tienes $monto en ${cuenta.toLowerCase()}';

  // Sin señal
  static const sinSenal =
      'Sin señal. Se guarda en tu teléfono y sube cuando vuelva.';

  // Ajuste oculto del operador
  static const tituloOperador = 'Ajustes de la prueba';
  static const subtituloOperador = 'Solo para quien organiza la prueba.';
  static String registrosGuardados(int n) => switch (n) {
    0 => 'No hay datos guardados en este teléfono.',
    1 => 'Hay 1 registro guardado en este teléfono.',
    _ => 'Hay $n registros guardados en este teléfono.',
  };
  static const contandoRegistros = 'Revisando los datos del teléfono…';
  static const borrarTodo = 'Borrar todo y empezar de nuevo';
  static const borrarTodoDetalle =
      'Deja la app como recién instalada en este teléfono.';
  static const empezarPrimerDia = 'Empezar en «Primer día»';
  static const empezarPrimerDiaDetalle =
      'Borra todo y vuelve a la Bienvenida para probar el alta.';
  static const confirmarPrimerDiaTitulo = '¿Empezar en «Primer día»?';
  static const empezarPrimerDiaBoton = 'Borrar y empezar';
  static const saltarPrimeraSemana = 'Saltar la primera semana';
  static const saltarPrimeraSemanaDetalle =
      'Muestra el Inicio completo sin esperar siete días ni el primer arqueo.';
  static const primeraSemanaSaltada = 'Listo. El Inicio ya es el completo.';
  static const empezarDemo = 'Empezar en «Demo»';
  static const forzarFotoIlegible = 'Forzar «foto ilegible»';
  static const forzarFotoIlegibleDetalle =
      'La próxima foto sale borrosa y se ve la pantalla S17.';
  static const fotoIlegibleForzada = 'Listo. La próxima foto saldrá borrosa.';
  static const elegirFrase = 'Elegir frase de ejemplo para la voz';
  static const elegirFraseDetalle =
      'La próxima grabación usa esta frase en lugar del micrófono.';
  static String fraseElegida(String frase) =>
      'La próxima grabación usará: «$frase»';
  static const simularSinSenal = 'Simular sin señal';
  static const simularSinSenalDetalle =
      'Lo que se guarde queda «por subir», como si el teléfono no tuviera '
      'señal.';
  static const simularSinSenalActivo =
      'Activado: todo lo que se guarde queda «por subir». Toca para volver a '
      'la señal del teléfono.';
  static const sinSenalSimulada = 'Listo. La app está sin señal.';
  static const senalDelTelefono = 'Listo. La app usa la señal del teléfono.';
  static const exportarMedicion = 'Exportar la medición';
  static String opcionLlegaEnEntrega(int n) => 'Llega en la entrega $n';
  static const confirmarBorrarTitulo = '¿Borrar todo?';
  static const confirmarBorrarTexto =
      'Se borran todos los datos guardados en este teléfono. '
      'No se puede deshacer.';
  static const cancelar = 'Cancelar';
  static const borrarTodoBoton = 'Borrar todo';
  static const seBorroTodo =
      'Se borró todo. La app quedó como recién instalada.';
}
