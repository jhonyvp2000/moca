import '../dominio/aviso_cierre.dart';
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
  static const cargandoDemo = 'Preparando la demo…';
  static const estasViendoUnaDemo = 'Estás viendo una demo';
  static const salir = 'Salir';
  static const salirDeLaDemoTitulo = '¿Salir de la demo?';
  static const salirDeLaDemoTexto = 'Se borran los datos de ejemplo.';
  static const empezar = 'Empezar';

  // S07 · Venta de hoy (escrita, hasta que llegue la voz)
  static const ventaDeHoy = 'Venta de hoy';
  static const cuantoVendisteHoy = '¿Cuánto vendiste hoy?';
  static const ventaPorCuentaDetalle =
      'Escribe cuánto entró en cada sitio. Lo que no usaste, déjalo vacío.';
  static const efectivo = 'Efectivo';
  static const yape = 'Yape';
  static const banco = 'BCP';
  static const interbank = 'Interbank';
  static const bbva = 'BBVA';
  static const scotiabank = 'Scotiabank';
  static const otroBanco = 'Otro banco o caja';
  static const agregarBanco = '+ Banco';
  static const plin = 'Plin';
  static const sip = 'Sip';
  static const otraBilletera = 'Otra billetera';
  static const usasOtraBilletera = '¿Usas otra billetera además de Yape?';
  static const puedesAgregarlaDespues =
      'Si no, déjalo así. Puedes agregarla después en Moca.';
  static const otra = 'Otra';
  static const nombreDeLaBilletera = 'Escribe el nombre de la billetera';
  static const misCuentas = 'Mis cuentas';
  static const misCuentasDetalle = 'Saldo por cuenta, billeteras y bancos';
  static const saldoPorPoner = 'Saldo por poner';
  static const agregarBilletera = 'Agregar una billetera';
  static const agregarUnBanco = 'Agregar un banco';
  static const usasOtroBanco = '¿Usas otro banco además del BCP?';
  static const nombreDelBanco = 'Escribe el nombre del banco o la caja';
  static const billeteraEmpiezaEnCero =
      'Empieza en S/\u00A00 desde hoy. Las cuentas no se borran.';
  static const agregar = 'Agregar';
  static String billeteraAgregada(String nombre) => 'Listo, agregaste $nombre.';

  /// El nombre que el dueño le puso a su otra billetera. Lo fija la app al
  /// leer las cuentas.
  static String nombreOtraBilletera = otraBilletera;

  /// El nombre del otro banco o caja del dueño, igual que la otra billetera.
  static String nombreOtroBanco = otroBanco;

  /// Fija los nombres propios al leer las cuentas.
  static void recordarNombres(Iterable<({TipoCuenta tipo, String nombre})> c) {
    for (final cuenta in c) {
      if (cuenta.tipo == TipoCuenta.otra) nombreOtraBilletera = cuenta.nombre;
      if (cuenta.tipo == TipoCuenta.otroBanco) nombreOtroBanco = cuenta.nombre;
    }
  }

  static String nombreCuenta(TipoCuenta cuenta) => switch (cuenta) {
    TipoCuenta.efectivo => efectivo,
    TipoCuenta.yape => yape,
    TipoCuenta.banco => banco,
    TipoCuenta.plin => plin,
    TipoCuenta.sip => sip,
    TipoCuenta.otra => nombreOtraBilletera,
    TipoCuenta.interbank => interbank,
    TipoCuenta.bbva => bbva,
    TipoCuenta.scotiabank => scotiabank,
    TipoCuenta.otroBanco => nombreOtroBanco,
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

  static const enviando = 'Enviando…';
  static const necesitasSenalParaGuardar =
      'Necesitas señal para guardar tu avance. Lo que anotaste sigue en tu '
      'teléfono.';
  static const demasiadosCodigos =
      'Pediste muchos códigos. Intenta otra vez en una hora.';
  static const noPudimosEnviar =
      'No pudimos enviar el código. Intenta otra vez en un momento.';

  // Código (no dibujado; estados de la entrega 11, aprobados el 14-10-2026)
  static const escribeElCodigo = 'Escribe el código';
  static String codigoEnviadoA(String celular) =>
      'Te lo enviamos por SMS al $celular. Vale 10 minutos.';
  static const codigo = 'Código de 6 dígitos';
  static const comprobando = 'Comprobando…';
  static const codigoIncorrecto =
      'Ese código no es. Revisa el mensaje e intenta otra vez.';
  static const codigoVencido = 'El código venció. Te enviamos uno nuevo.';
  static const codigoReenviado = 'Te enviamos un código nuevo.';
  static const reenviarCodigo = '¿No te llegó? Reenviar';
  static String reenviarEn(int segundos) =>
      '¿No te llegó? Reenviar en $segundos s';
  static const noPudimosComprobar =
      'No pudimos comprobar el código. Intenta otra vez en un momento.';
  static const otraCuentaConEsteNumero =
      'Este número ya tiene una cuenta de Moca en otro teléfono. Para no '
      'mezclar lo anotado, lo de este teléfono sigue aquí. Pronto podrás '
      'entrar a esa cuenta.';
  static const guardandoLoAnotado = 'Guardando lo que anotaste…';

  // «Ya tengo cuenta» (estados de la entrega 12, aprobados el 14-10-2026)
  static const entraATuCuenta = 'Entra a tu cuenta';
  static const entraATuCuentaDetalle =
      'Escribe el celular con el que guardaste tu avance. Te llega un código '
      'por SMS.';
  static const necesitasSenalParaEntrar =
      'Necesitas señal para entrar a tu cuenta.';
  static const numeroSinCuenta =
      'Este número no tiene una cuenta de Moca. Empieza anotando tu venta de '
      'hoy.';
  static const anotarMiPrimeraVenta = 'Anotar mi primera venta';
  static const bajandoTusDatos = 'Bajando tus datos…';
  static const seCortoLaSenal =
      'Se cortó la señal. Intenta otra vez: no se perdió nada.';
  static const yaTienesTodo = 'Listo. Ya tienes aquí todo lo que anotaste.';
  static const cuentaAbiertaEnOtro = 'Tu cuenta se abrió en otro teléfono';
  static const cuentaAbiertaEnOtroDetalle =
      'Lo que anotes aquí desde ahora no se guarda en tu cuenta.';
  static const avanceGuardado = 'Listo. Tu avance está guardado.';

  // Tarjeta de la pestaña Moca (entrega 11)
  static const confirmaTuNumero = 'Confirma tu número para guardar tu avance';
  static const confirmaTuNumeroDetalle =
      'En la prueba, el código era de ejemplo. Confírmalo para no perder lo '
      'anotado si cambias de teléfono.';
  static const confirmarMiNumero = 'Confirmar mi número';
  static const guardaTuAvanceDetalle =
      'Así no pierdes lo anotado si cambias de teléfono o se pierde.';
  static const guardarMiAvance = 'Guardar mi avance';
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
  static const fotoNoSeLeyoTodo =
      'Moca no pudo leer todo. Lo que falta lo pones tú; no se guarda nada '
      'hasta que lo confirmes.';
  static const noSeLee = 'No se lee';
  static const paraQueSalgaBien = 'Para que salga bien';
  static const consejoMesa = 'Apoya el papel en una mesa';
  static const consejoCompleto = 'Que se vea completo, sin dobleces';
  static const consejoSombra = 'Sin tu sombra encima';
  static const tomarOtraFoto = 'Tomar otra foto';

  // Foto que no se pudo leer (entrega 14, no dibujado)
  static const fotoSinSenal =
      'No pudimos leer la foto. Revisa tu señal e inténtalo otra vez, o '
      'escríbelo tú.';
  static const fotoNoEsComprobante =
      'Esto no parece un comprobante. Toma otra foto o escríbelo tú.';
  static const fotoSinCuenta =
      'Para leer fotos, guarda tu avance con tu número. Mientras, puedes '
      'escribirlo.';
  static const fotoLimiteDiario =
      'Llegaste al límite de fotos de hoy. Puedes escribirlo; mañana Moca '
      'vuelve a leer fotos.';
  static const escribirloYo = 'Escribirlo yo';
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

  // S12 · Arqueo de la semana
  static const arqueoDeLaSemana = 'Arqueo de la semana';
  static const arqueoDetalle =
      'Moca ya puso lo que debería haber. Corrige solo lo que no coincida '
      'con lo que tienes.';
  static const arqueoPuntoDePartidaDetalle =
      'Escribe cuánto tienes hoy en cada sitio. Lo que cuentes será tu punto '
      'de partida.';
  static const tuPuntoDePartida = 'Tu punto de partida';
  static const escribeCuantoHay = 'Escribe cuánto hay';
  static const cuadra = 'Cuadra';
  static String faltan(String monto) => 'Faltan $monto';
  static String sobran(String monto) => 'Sobran $monto';
  static String preguntaFaltan(String monto, String cuenta) =>
      'Faltan $monto en ${cuenta.toLowerCase()}. ¿Qué pasó con esa plata?';
  static String preguntaSobran(String monto, String cuenta) =>
      'Sobran $monto en ${cuenta.toLowerCase()}. ¿De dónde salió esa plata?';
  static String motivoArqueo(MotivoArqueo motivo) => switch (motivo) {
    MotivoArqueo.retiroParaMi => 'La retiré para mí',
    MotivoArqueo.gastoOlvidado => 'Un gasto que olvidé',
    MotivoArqueo.ventaNoAnotada => 'Una venta que no anoté',
    MotivoArqueo.errorDeVuelto => 'Di mal un vuelto',
    MotivoArqueo.noLoSe => 'No lo sé',
  };
  static String notaMotivo(MotivoArqueo motivo, {required bool faltan}) =>
      switch (motivo) {
        MotivoArqueo.retiroParaMi =>
          'Un retiro para ti no baja la ganancia del negocio; solo la plata '
              'en caja.',
        MotivoArqueo.gastoOlvidado => 'Se anota como un gasto de hoy.',
        MotivoArqueo.ventaNoAnotada => 'Se anota como una venta de hoy.',
        MotivoArqueo.errorDeVuelto =>
          faltan
              ? 'Tu saldo pasa a ser lo que contaste. No cuenta como gasto.'
              : 'Tu saldo pasa a ser lo que contaste. No cuenta como ingreso.',
        MotivoArqueo.noLoSe =>
          'Tu saldo pasa a ser lo que contaste. La diferencia queda sin '
              'explicar.',
      };
  static const guardarArqueo = 'Guardar arqueo';
  static String arqueoGuardado(String monto) =>
      'Arqueo guardado. Ahora tienes $monto';
  static const hacerArqueo = 'Hacer arqueo';
  static const mocaTocaArqueo =
      'Hoy toca el arqueo de la semana. Son dos minutos.';
  static const mocaFaltaArqueo =
      'Falta el arqueo de esta semana. Son dos minutos.';
  static const mocaArqueoHecho = 'Ya hiciste el arqueo de esta semana.';
  static const ajusteDelArqueo = 'Ajuste del arqueo';
  static const ajusteNoCuenta = 'No cuenta como gasto ni ingreso';
  static const ajusteExplicacion =
      'No cuenta como gasto ni ingreso: tu saldo pasó a ser lo que contaste.';
  static const etiquetaMotivo = 'Motivo';
  static const motivoCuadre = 'Diferencia de céntimos';
  static const etiquetaMocaCalculaba = 'Moca calculaba';
  static const etiquetaContaste = 'Contaste';

  // S14 · Informe del mes
  static const compartirPdf = 'Compartir PDF';
  static const mesAnterior = 'Mes anterior';
  static const mesSiguiente = 'Mes siguiente';
  static const hastaHoy = 'Hasta hoy';
  static String desdeElDia(int dia) => 'Desde el día $dia';
  static String desdeElDiaHastaHoy(int dia) => 'Desde el día $dia hasta hoy';
  static const ganaste = 'Ganaste';
  static const perdiste = 'Perdiste';
  static String masQueEn(String monto, String mes) => '$monto más que en $mes';
  static String menosQueEn(String monto, String mes) =>
      '$monto menos que en $mes';
  static String igualQueEn(String mes) => 'Lo mismo que en $mes';
  static const primerMesConMoca =
      'Es tu primer mes con Moca. El próximo mes verás la comparación.';
  static const loQueGanasteYRetiraste = 'Lo que ganaste y lo que retiraste';
  static const ganoElNegocio = 'Ganó el negocio';
  static const perdioElNegocio = 'Perdió el negocio';
  static const retirasteParaTi = 'Retiraste para ti';
  static const quedoEnElNegocio = 'Quedó en el negocio';
  static String sacasteMas(String monto) =>
      'Sacaste $monto más de lo que ganó el negocio.';
  static const enQueSeFue = 'En qué se fue la plata';
  static const loDemas = 'Lo demás';
  static const sinGastos = 'En este mes no hubo gastos.';
  static String subioFrente(String categoria, String monto, String mes) =>
      '$categoria subió $monto frente a $mes.';
  static String bajoFrente(String categoria, String monto, String mes) =>
      '$categoria bajó $monto frente a $mes.';
  static String casiNadaCambio(String mes) => 'Casi nada cambió frente a $mes.';
  static const loQueDebesTitulo = 'Lo que debes';
  static const queTanSeguras = 'Qué tan seguras son estas cuentas';
  static String conComprobante(int n) => '$n% tiene comprobante';
  static String conFoto(int n) => '$n% tiene foto o captura';
  static String sinPapel(int n) => '$n% lo dijiste tú, sin papel';
  static const advertenciaMercaderia =
      'Compraste más mercadería que otros meses, así que la ganancia puede '
      'verse más baja de lo real.';
  static const mesSinRegistros = 'En este mes no hay registros.';
  static const armandoPdf = 'Armando el PDF…';
  static const pdfNoSeArmo = 'No se pudo armar el PDF. Intenta otra vez.';
  static String informeDe(String mes, int anio) => 'Informe de $mes $anio';
  static String hechoEl(String fecha) => 'Hecho el $fecha';
  static const pieDelPdf = 'Hecho con Moca con lo que anotaste en tu teléfono.';

  // S16 · Moca
  static String tuSemanaEn(int segundos) => 'Tu semana, en $segundos segundos';
  static const escuchar = 'Escuchar';
  static const detener = 'Detener';
  static const sinVozEnEspanol =
      'Tu teléfono no tiene voz en español; puedes leerlo aquí.';
  static String semanaPasadaQuedo(String monto) =>
      'La semana pasada te quedaron $monto';
  static String semanaPasadaPerdiste(String monto) =>
      'La semana pasada salieron $monto más de lo que entró';
  static String estaSemanaQueda(String monto) =>
      'En lo que va de la semana te quedan $monto';
  static String estaSemanaPerdiste(String monto) =>
      'En lo que va de la semana salieron $monto más de lo que entró';
  static String masQueLaAnterior(String monto) =>
      ', $monto más que la semana anterior.';
  static String menosQueLaAnterior(String monto) =>
      ', $monto menos que la semana anterior.';
  static const igualQueLaAnterior = ', lo mismo que la semana anterior.';
  static String loQueMasSalio(String categoria, String monto) =>
      ' Lo que más salió fue $categoria: $monto.';
  static const semanaPasadaSinNada = 'La semana pasada no anotaste nada.';
  static const avisos = 'Avisos';
  static const importante = 'Importante';
  static const paraTenerEnCuenta = 'Para tener en cuenta';
  static const sinAvisos =
      'No tienes avisos. Moca te avisa cuando algo necesite tu atención.';
  static const avisoFaltaArqueo = 'Falta el arqueo de esta semana';
  static String avisoDiferencia(String monto, String cuenta) =>
      'Quedaron $monto sin explicar en ${cuenta.toLowerCase()}';
  static String avisoDias(int dias) => 'Llevas $dias días sin anotar';
  static String avisoAtipico(String monto, String categoria) =>
      'Gasto más alto de lo habitual: $monto en $categoria';
  static const verElAjuste = 'Ver el ajuste';
  static const verElGasto = 'Ver el gasto';

  // S05 · Aviso de cierre
  static const canalCierre = 'Aviso de cierre';
  static const canalCierreDetalle =
      'Te recuerda anotar la venta del día a tu hora de cierre.';
  static const canalAvisos = 'Avisos de Moca';
  static const canalAvisosDetalle =
      'Un aviso al día como máximo: el arqueo, los días sin anotar y el '
      'resumen de la semana.';
  static String preguntaVentaCuenta(TipoCuenta cuenta) => switch (cuenta) {
    TipoCuenta.efectivo => '¿Cuánto vendiste hoy en efectivo?',
    _ => '¿Y por ${nombreCuenta(cuenta)}?',
  };
  static String nadaPor(TipoCuenta cuenta) =>
      'Nada por ${nombreCuenta(cuenta)}';
  static const soles = 'Soles';
  static const decirlo = 'Decirlo';
  static const hoyNoAbri = 'Hoy no abrí';
  static const noEntendiElMonto =
      'No entendí el monto. Toca para anotarlo en la app.';
  static String listoHoyVendiste(String monto) => 'Listo. Hoy vendiste $monto.';
  static const resumenListo = 'Tu resumen de la semana está listo.';
  static const permisoAvisos =
      'Moca te recuerda anotar la venta a tu hora de cierre. Para eso '
      'necesita permiso de avisos.';
  static const permitirAvisos = 'Permitir avisos';
  static const ahoraNoCorto = 'Ahora no';
  static const sinPermisoAvisos =
      'Sin permiso, Moca no puede recordarte la venta. Puedes darlo en los '
      'ajustes del teléfono.';

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
  static const pedirArqueo = 'Pedir el arqueo ahora';
  static const pedirArqueoDetalle =
      'Muestra en el Inicio la tarjeta del arqueo sin esperar al domingo.';
  static const arqueoPedido = 'Listo. El Inicio pide el arqueo.';
  static const adelantarReloj = 'Adelantar el reloj un día';
  static const adelantarRelojDetalle =
      'Para probar avisos y cambios de semana o de mes sin esperar. Lo que '
      'anotes queda con esa fecha.';
  static String relojAdelantado(String fecha) =>
      'Listo. Para la app hoy es $fecha.';
  static const volverHoraReal = 'Volver a la hora real';
  static String volverHoraRealDetalle(int dias) => dias == 1
      ? 'La app va 1 día adelantada.'
      : 'La app va $dias días adelantada.';
  static const horaReal = 'Listo. La app usa la hora real.';
  static const probarAvisoCierre = 'Probar el aviso de cierre ahora';
  static const probarAvisoCierreDetalle =
      'Muestra ya la notificación de la hora de cierre, para probar '
      '«Escribirlo», «Decirlo» y «Hoy no abrí» sin esperar.';
  static const avisoDePruebaEnviado =
      'Listo. Baja la barra de notificaciones del teléfono.';
  static const verAvisosProgramados = 'Ver avisos programados';
  static const verAvisosProgramadosDetalle =
      'Qué avisos tiene guardados el teléfono y a qué hora saldrán.';
  static String guardadosAlAbrir(int n) => n == 1
      ? 'Al abrir Moca, el teléfono tenía 1 aviso guardado.'
      : 'Al abrir Moca, el teléfono tenía $n avisos guardados.';
  static const sinAvisosGuardados =
      'Ahora el teléfono no tiene avisos guardados. Si hoy ya anotaste la '
      'venta, el aviso de cierre de hoy no se programa.';
  static String nombreNotificacion(TipoNotificacion tipo) => switch (tipo) {
    TipoNotificacion.cierre => 'Aviso de cierre',
    TipoNotificacion.faltaArqueo => 'Falta el arqueo',
    TipoNotificacion.diasSinAnotar => 'Días sin anotar',
    TipoNotificacion.resumenSemanal => 'Resumen de la semana',
  };
  static const otroAviso = 'Otro aviso';
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
  static const exportarMedicionDetalle =
      'Comparte un archivo con lo que se midió en este teléfono, sin montos '
      'ni nombres.';
  static const medicionDeMoca = 'Medición de Moca';
  static const empezarDemoDetalle =
      'Borra todo y carga diez semanas de una bodega de ejemplo.';
  static const confirmarDemoTitulo = '¿Empezar en «Demo»?';
  static const empezarDemoBoton = 'Borrar y cargar la demo';
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
