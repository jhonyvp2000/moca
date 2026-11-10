import '../dominio/cuenta_real.dart';
import '../pais/peru/formato.dart';
import '../dominio/cobro.dart';
import '../dominio/aviso_cierre.dart';
import '../dominio/historial.dart';
import '../dominio/modelos.dart';
import '../dominio/tutoria.dart';

/// Todos los textos de la app, en español de Perú y en un solo lugar,
/// para poder ajustarlos después de la prueba con pilotos.
abstract final class Textos {
  static const nombreApp = 'Moca';
  static const eslogan = 'Tú vendes. Moca hace las cuentas.';

  // Barra inferior
  static const pestanaInicio = 'Inicio';
  static const pestanaHistorial = 'Historial';
  static const pestanaInformes = 'Informes';
  static const pestanaMoca = 'Asistente';
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
  static const meInvitaron = 'Me invitaron a un negocio';
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
  // Las billeteras con su banco (entrega 14.10).
  static const yape = 'BCP Yape';
  static const banco = 'BCP';
  static const interbank = 'Interbank';
  static const bbva = 'BBVA';
  static const scotiabank = 'Scotiabank';
  static const otroBanco = 'Otro banco o caja';
  static const agregarBanco = '+ Banco';
  static const plin = 'Interbank Plin';
  static const bbvaPlin = 'BBVA Plin';
  static const scotiabankPlin = 'Scotiabank Plin';
  static const sip = 'Sip';
  static const otraBilletera = 'Otra';
  static const usasOtraBilletera = '¿Usas otra billetera además de BCP Yape?';
  static const puedesAgregarlaDespues =
      'Si no, déjalo así. Puedes agregarla después en Moca.';
  static const otra = 'Otra';
  static const nombreDeLaBilletera = 'Escribe el nombre de la billetera';
  static const misCuentas = 'Mis cuentas';

  // Corregir el saldo con el que empezó (entrega 16.2).
  static const corregirSaldoInicial = 'Corregir el saldo con el que empecé';
  static String conCuantoEmpezaste(String cuenta) =>
      '¿Con cuánto empezaste en $cuenta?';
  static String saldoInicialDesde(String dia) =>
      'El $dia, antes de lo que anotaste';
  static String conEsteCambioTienes(String monto, String cuenta) =>
      'Con este cambio, hoy tienes $monto en $cuenta.';
  static String saldoInicialCorregido(String cuenta) =>
      'Listo. Corregiste el saldo de $cuenta.';
  static const yaHuboArqueoDeLaCuenta =
      'Ya hiciste un arqueo de esta cuenta. Si el saldo no cuadra, haz otro '
      'arqueo.';
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

  /// Las otras cajas de efectivo, con el nombre que les puso el dueño
  /// (entrega 21).
  static const caja2 = 'Caja 2';
  static const caja3 = 'Caja 3';
  static String nombreCaja2 = caja2;
  static String nombreCaja3 = caja3;

  /// Fija los nombres propios al leer las cuentas.
  static void recordarNombres(Iterable<({TipoCuenta tipo, String nombre})> c) {
    for (final cuenta in c) {
      if (cuenta.tipo == TipoCuenta.otra) nombreOtraBilletera = cuenta.nombre;
      if (cuenta.tipo == TipoCuenta.otroBanco) nombreOtroBanco = cuenta.nombre;
      if (cuenta.tipo == TipoCuenta.caja2) nombreCaja2 = cuenta.nombre;
      if (cuenta.tipo == TipoCuenta.caja3) nombreCaja3 = cuenta.nombre;
    }
  }

  static String nombreCuenta(TipoCuenta cuenta) => switch (cuenta) {
    TipoCuenta.efectivo => efectivo,
    TipoCuenta.caja2 => nombreCaja2,
    TipoCuenta.caja3 => nombreCaja3,
    TipoCuenta.yape => yape,
    TipoCuenta.banco => banco,
    TipoCuenta.plin => plin,
    TipoCuenta.sip => sip,
    TipoCuenta.otra => nombreOtraBilletera,
    TipoCuenta.interbank => interbank,
    TipoCuenta.bbva => bbva,
    TipoCuenta.scotiabank => scotiabank,
    TipoCuenta.otroBanco => nombreOtroBanco,
    TipoCuenta.bbvaPlin => bbvaPlin,
    TipoCuenta.scotiabankPlin => scotiabankPlin,
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
  static const esperandoSms =
      'Esperando el SMS… Si llega a este teléfono, el código se escribe solo.';
  static const codigoLeidoDelSms = 'Código leído del SMS.';
  static const reenviarCodigo = '¿No te llegó? Reenviar';
  static String reenviarEn(int segundos) =>
      '¿No te llegó? Reenviar en $segundos s';
  static const noPudimosComprobar =
      'No pudimos comprobar el código. Intenta otra vez en un momento.';
  // Número que ya tiene cuenta (entrega 14.4, no dibujado)
  static const numeroConCuenta = 'Este número ya tiene una cuenta de Moca';
  static const numeroConCuentaDetalle =
      'Puedes entrar a tu cuenta y sumarle lo que anotaste en este teléfono, '
      'o empezar de cero con este número.';
  static const entrarAMiCuenta = 'Entrar a mi cuenta';
  static const empezarDeCero = 'Empezar de cero con este número';
  static const seguirSinCuenta = 'Seguir sin cuenta';
  static const juntandoLoAnotado = 'Juntando lo anotado…';
  static const yaEstanJuntos =
      'Listo: tu cuenta y lo anotado en este teléfono están juntos.';
  static const empezarDeCeroPregunta = '¿Empezar de cero con este número?';
  static const empezarDeCeroDetalle =
      'Tu cuenta anterior queda guardada, pero ya no se verá en la app. Lo '
      'anotado en este teléfono pasa a ser tu cuenta.';
  static const empezarDeCeroSi = 'Empezar de cero';
  static const pasoMuchoTiempo =
      'Pasó mucho tiempo desde el código. Pide uno nuevo para seguir.';
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
  static const noPudimosTraerTuCuenta =
      'No pudimos traer tu cuenta. Intenta otra vez en unos minutos: no se '
      'perdió nada.';
  static const yaTienesTodo = 'Listo. Ya tienes aquí todo lo que anotaste.';
  static const cuentaAbiertaEnOtro = 'Tu cuenta se abrió en otro teléfono';
  static const cuentaAbiertaEnOtroDetalle =
      'Lo que anotes aquí desde ahora no se guarda en tu cuenta.';
  static const avanceGuardado = 'Listo. Tu avance está guardado.';
  static const hoyAnotaste = 'Ventas que anotaste hoy';
  static const loDemasLoVeElDueno =
      'La plata del negocio la ve el dueño. Lo que anotas le llega solo.';
  static String loAnoto(String? nombre, Rol? rol) => nombre != null
      ? 'Lo anotó $nombre'
      : switch (rol) {
          Rol.dueno => 'Lo anotó el dueño',
          Rol.encargado => 'Lo anotó el encargado',
          Rol.ayudante => 'Lo anotó el ayudante',
          _ => 'Lo anotó otra persona',
        };
  static const soloLoDeHoyAyudante =
      'Aquí ves lo de hoy en tu caja y lo que anotaste. Lo de otros días lo '
      've el dueño.';

  // Simular otra persona (entrega 20.1)
  static const verComoRol = 'Ver como…';
  static const verComoRolDetalle =
      'La app se ve como la de un encargado, un ayudante o un contador. No '
      'cambia nada en el servidor.';
  static String viendoComo(String rol) =>
      'Viendo como $rol. Lo que anotes ahora es de verdad y queda a tu nombre.';
  static const volverADueno = 'Volver';
  static const simularVentaDeOtro = 'Simular una venta de Pepe';
  static const simularVentaDeOtroDetalle =
      'Aparece en el Historial «Lo anotó Pepe», como si viniera de otro '
      'teléfono. No se sube.';
  static const ventaDeOtroSimulada =
      'Listo: en el Historial verás «Lo anotó Pepe».';
  static const salirDeLaSimulacion = 'Salir de la simulación';
  static const salirDeLaSimulacionDetalle =
      'Quita la venta de Pepe y vuelve a verse como dueño.';
  static const simulacionTerminada = 'Listo: todo vuelve a ser real.';

  // «Pasé plata» (entrega 21.1)
  static const pasePlata = 'Pasé plata';
  static const pasePlataDetalle =
      'De una caja o cuenta a otra. No es venta ni gasto: tu plata no cambia.';
  static const deDondeSalePase = '¿De dónde sale?';
  static const aDondeVaPase = '¿A dónde va?';
  static String pase(String de, String a) => '$de → $a';
  static const paseNoCuenta = 'Pase entre cuentas';

  // Mis negocios (entrega 22)
  static const misNegocios = 'Mis negocios';
  static const misNegociosDetalle =
      'Si eres contador de varios, o te invitaron a otro';
  static const estasAqui = 'Estás aquí';
  static const verEsteNegocio = 'Ver';
  static String cambiandoA(String negocio) => 'Cambiando a $negocio…';
  static String ahoraVes(String negocio) => 'Listo. Ahora ves $negocio.';
  static const necesitasSenalParaNegocios =
      'Necesitas señal para ver y cambiar de negocio.';
  static const aceptar = 'Aceptar';
  static const teInvitaronA = 'Te invitaron';
  static const sinNegocios =
      'Ya no estás en ningún negocio. Si un dueño te invita, la invitación '
      'aparece aquí.';

  // Cajas (entrega 21)
  static const agregarUnaCaja = '¿Tienes otra caja de efectivo?';
  static const otraCaja = 'Otra caja';
  static const nombreDeLaCaja = 'Nombre de la caja: Caja delivery';
  static const enTuCaja = 'En tu caja hoy';
  static const enTusCajas = 'En tus cajas hoy';
  static const cajasDe = 'Cajas';
  static const cajaPrincipal = 'La caja principal';
  static const elegirCajas = '¿Qué cajas tiene a cargo?';
  static const elegirCajasDetalle =
      'Anota y ve solo lo de esas cajas, además de Yape y banco. Sin '
      'ninguna, la caja principal.';
  static const cajasGuardadas = 'Listo. Sus cajas quedaron guardadas.';

  // Equipo (entregas 17 a 19)
  static const miEquipo = 'Mi equipo';
  static const miEquipoDetalle = 'Quiénes anotan en tu negocio';
  static const entraAlNegocio = 'Entra al negocio';
  static const entraAlNegocioDetalle =
      'Escribe el número con el que te invitó el dueño del negocio.';
  static const sinInvitacion =
      'Este número no tiene una invitación. Pídele al dueño que te invite con '
      'este número desde «Mi equipo».';
  static String teInvitaron(String negocio) => 'Te invitaron a $negocio';
  static String comoRol(String rol) => 'Como $rol';
  static const consentimientoInvitado =
      'Al entrar, aceptas que Moca guarde tu número y lo que anotes en este '
      'negocio para llevar sus cuentas, y que los dueños del negocio lo vean. '
      'Si la app falla, Moca recibe el error, y también cómo la usas (qué '
      'pantallas abres y cuánto tardas en anotar), sin lo que anotaste. '
      'Puedes salir cuando quieras (Ley 29733 de Protección de Datos '
      'Personales).';
  static const aceptarYEntrar = 'Aceptar y entrar';
  static const entrando = 'Entrando…';
  static String yaEstasEn(String negocio) => 'Listo. Ya estás en $negocio.';
  static const invitacionVencida =
      'La invitación venció o el dueño la anuló. Pídele que te invite otra '
      'vez.';
  static const yaTienesNegocio =
      'Ya tienes tu propio negocio en Moca con este número. Por ahora, una '
      'persona está en un solo negocio.';
  static const necesitasSenalParaEquipo =
      'Necesitas señal para ver y cambiar tu equipo.';
  static const tuEquipo = 'En tu negocio';
  static const invitacionesPendientes = 'Invitaciones que esperan';
  static String venceEl(String fecha) => 'Vence el $fecha';
  static const tu = 'Tú';
  static const titular = 'Titular';
  static const sinNombre = 'Sin nombre';
  static const invitarAAlguien = 'Invitar a alguien';
  // Sin tope de personas (entrega 43): el plan incluye algunas y las demás
  // se cobran aparte.
  static String planIncluye(int incluidas) =>
      'Tu plan incluye ${incluidas == 1 ? '1 persona' : '$incluidas personas'} '
      'con el titular. Cada persona más: S/ 2.90 al mes. El contador no '
      'cuenta.';
  static const personaExtraTitulo = 'Esta persona se cobra aparte';
  static String personaExtraDetalle(int incluidas) =>
      'Tu plan incluye ${incluidas == 1 ? '1 persona' : '$incluidas personas'}. '
      'Cada persona más suma S/ 2.90 al mes desde tu próximo pago.';
  static const invitarIgual = 'Invitar igual';
  static const quitar = 'Quitar';
  static String quitarPregunta(String quien) => '¿Quitar a $quien del negocio?';
  static const quitarDetalle =
      'Lo que anotó se queda en el negocio. Su teléfono ya no podrá anotar ni '
      'ver nada aquí.';
  static const anularInvitacion = 'Anular';
  static const nombreDeLaPersona = 'Nombre (opcional)';
  static const nombrePersonaEjemplo = 'Por ejemplo: Rosa';
  static const suNumero = 'Su número de celular';
  static const queHaraEnTuNegocio = '¿Qué hará en tu negocio?';
  static const enviarInvitacion = 'Invitar';
  static const invitando = 'Invitando…';
  static String invitacionEnviada(String quien) =>
      'Listo. Dile a $quien que instale Moca y toque «$meInvitaron» con su '
      'número. La invitación vale 7 días.';
  // «Mis categorías» (entrega 31).
  static const misCategorias = 'Mis categorías';
  static const misCategoriasDetalle = 'Las de Moca y las que agregues';
  static const categoriasDeMoca =
      'Las de Moca no se cambian: de ellas salen el informe y el flujo para '
      'el crédito. Las tuyas se cambian o se dejan de usar.';
  static const deMoca = 'De Moca';
  static const tuya = 'Tuya';
  static const yaNoLaUsas = 'Tuya · ya no la usas';
  static const agregarCategoria = 'Agregar una categoría';
  static const otraCategoria = '+ Otra categoría';
  static const categoriaNueva = 'Categoría nueva';
  static const cambiarCategoria = 'Tu categoría';
  static const nombreCategoria = '¿Cómo se llama?';
  static const nombreCategoriaEjemplo = 'Por ejemplo: Hielo';
  static const esDeLoQue = '¿Es de lo que entra o de lo que sale?';
  static const loQueEntra = 'Lo que entra';
  static const loQueSale = 'Lo que sale';
  static const yaNoLaUso = 'Ya no la uso';
  static const usarlaOtraVez = 'Usarla otra vez';
  static const categoriaRepetida = 'Ya hay una categoría con ese nombre.';
  static const noSePudoCategoria = 'No se pudo guardar. Intenta otra vez.';
  static String sinLugarCategoria(int maximo, bool entra) =>
      'Ya tienes $maximo categorías tuyas de lo que '
      '${entra ? 'entra' : 'sale'}. Deja de usar una para agregar otra.';
  static const categoriaAgregada = 'Listo. Agregaste la categoría.';
  static const categoriaGuardada = 'Listo. Guardado.';
  static const categoriaSinUso =
      'Listo. Ya no se ofrece al anotar; lo anotado la conserva.';
  static const categoriaOtraVez = 'Listo. Se ofrece otra vez al anotar.';

  // La invitación por WhatsApp (entrega 30).
  static const mandarInvitacionWhatsApp = 'Mandarle la invitación por WhatsApp';
  static const mandarPorWhatsApp = 'Mandar por WhatsApp';
  static const listoInvitar = 'Listo';
  static String mensajeDeInvitacion({
    required String? nombre,
    required String negocio,
    required Rol rol,
    required String celular,
    required String vence,
    required String enlace,
  }) =>
      '${nombre == null ? 'Hola,' : 'Hola $nombre,'} te invité a $negocio en '
      'Moca, como ${nombreRol(rol)}.\n'
      '1. Instala Moca desde aquí: $enlace. Si el teléfono pregunta, permite '
      'instalar desde esa fuente.\n'
      '2. Abre Moca, toca «$meInvitaron» y pon tu número, $celular. Te llega '
      'un código por SMS.\n\n'
      'La invitación vale hasta el $vence.';
  static const sinLugar =
      'No hay lugar para otra persona. Quita a alguien o anula una '
      'invitación.';
  static const yaEstaEnElNegocio = 'Esa persona ya está en tu negocio.';
  static const soloLosDuenos = 'Solo un dueño puede cambiar el equipo.';
  static String nombreRol(Rol rol) => switch (rol) {
    Rol.dueno => 'Dueño',
    Rol.encargado => 'Encargado',
    Rol.ayudante => 'Ayudante',
    Rol.contador => 'Contador',
  };
  static String detalleRol(Rol rol) => switch (rol) {
    Rol.dueno => 'Ve y hace todo, como tú.',
    Rol.encargado =>
      'Anota, corrige y hace el arqueo de sus cajas. No ve los informes.',
    Rol.ayudante => 'Anota ventas y gastos. Ve lo que anotó hoy, no lo demás.',
    Rol.contador => 'Solo mira: Historial, informes, PDF y Excel.',
  };

  static const fueraDelNegocio = 'Ya no estás en este negocio';
  static const fueraDelNegocioDetalle =
      'Un dueño te quitó del equipo. Lo que anotaste se queda en el negocio; '
      'lo que anotes aquí desde ahora no se guarda allá.';

  /// «Actualizado hace 5 min» (entrega 18).
  static String actualizadoHace(DateTime cuando, DateTime ahora) {
    final minutos = ahora.difference(cuando).inMinutes;
    if (minutos < 1) return 'Actualizado hace un momento';
    if (minutos < 60) return 'Actualizado hace $minutos min';
    final horas = minutos ~/ 60;
    if (horas < 24) return 'Actualizado hace $horas h';
    final dias = horas ~/ 24;
    return dias == 1 ? 'Actualizado ayer' : 'Actualizado hace $dias días';
  }

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
  // Los tipos de negocio (entrega 48).
  static String nombreTipoNegocio(TipoNegocio tipo) => switch (tipo) {
    TipoNegocio.bodega => 'Bodega o minimarket',
    TipoNegocio.mercado => 'Puesto de mercado (abarrotes, frutas, carnes)',
    TipoNegocio.restaurante => 'Restaurante, menú o pollería',
    TipoNegocio.comida => 'Comida al paso, juguería o cafetería',
    TipoNegocio.panaderia => 'Panadería o pastelería',
    TipoNegocio.ferreteria => 'Ferretería',
    TipoNegocio.farmacia => 'Farmacia o botica',
    TipoNegocio.agroveterinaria => 'Agroveterinaria',
    TipoNegocio.libreria => 'Librería, bazar o útiles',
    TipoNegocio.ropa => 'Ropa, calzado o accesorios',
    TipoNegocio.celulares => 'Celulares y accesorios',
    TipoNegocio.peluqueria => 'Peluquería, barbería o spa',
    TipoNegocio.taller => 'Taller mecánico o de motos',
    TipoNegocio.transporte => 'Transporte (mototaxi, taxi, carga)',
    TipoNegocio.servicios => 'Servicios',
    TipoNegocio.otro => 'Otro',
  };
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

  // Notas del periodo bajo cada título (entrega 36): qué abarca cada cifra.
  static const desdeQueEmpezaste = 'Desde que empezaste con Moca';
  static const saldosDesdeQueEmpezaste = 'Saldos desde que empezaste con Moca';
  static const deLunesAHoy = 'De lunes a hoy';
  static const todoLoQueDebes = 'Todo lo que debes hoy, de cualquier mes';

  /// «Del 1 al 6 de noviembre», «Todo octubre» o «Del 12 al 31 de octubre».
  static String periodoDelMes(
    DateTime mes, {
    required bool enCurso,
    required DateTime hoy,
    int? desdeDia,
  }) {
    final nombre = nombreDelMes(mes);
    final desde = desdeDia ?? 1;
    final hasta = enCurso ? hoy.day : DateTime(mes.year, mes.month + 1, 0).day;
    if (!enCurso && desdeDia == null) return 'Todo $nombre';
    if (desde == hasta) return 'El $desde de $nombre';
    return 'Del $desde al $hasta de $nombre';
  }

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
  static const tusPrimerosPasos = 'Tus primeros pasos';

  // Inicio rediseñado (mejora 01)
  static const tusCuentas = 'Tus cuentas';
  static const verTodas = 'Ver todas';
  static const estaSemana = 'Esta semana';
  static const escucharMiSemana = 'Escuchar mi semana';
  static const queEsEstaCifra = '¿Qué es esta cifra?';
  static String vendisteHoy(String monto) => 'Vendiste hoy $monto';
  static String teDebenCuantos(int personas) => 'Te deben · $personas';
  static String debesCuantos(int personas) => 'Debes · $personas';
  static String pasosHechos(int hechos, int total) => '$hechos de $total';

  /// «Marcos y Rosa», «Marcos, Rosa y 2 más».
  static String nombresPendientes(List<String> nombres) => switch (nombres) {
    [] => '',
    [final uno] => uno,
    [final a, final b] => '$a y $b',
    [final a, final b, ...final resto] => '$a, $b y ${resto.length} más',
  };
  static const pasoDecirPlata = 'Decir cuánta plata tienes';
  static String pasoVentaCincoDias(int llevas) =>
      'Anotar la venta 5 días · llevas $llevas';
  static const pasoPrimerGasto = 'Anotar tu primer gasto con una foto';
  static const pasoPrimerArqueo = 'Hacer tu primer arqueo el domingo';
  static const conEstosPasos =
      'Con estos cuatro pasos Moca ya puede mostrarte cómo se mueve tu plata.';

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
  // Al escribir una compra que se debe (entrega 41).
  static const aQuienLeDebes = '¿A quién le debes?';
  static const aQuienLeDebesEjemplo = 'Puedes dejarlo vacío';
  static const siPagado = 'Sí, pagado';
  static const todaviaLoDebo = 'Todavía lo debo';
  static const cuentaAlPagar =
      'No baja tu plata todavía. Cuando lo pagues, márcalo en el Historial '
      'con «Ya lo pagué» y elige de dónde salió.';
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

  // Fotos de prueba sin cuenta (entrega 14.2, no dibujado)
  static String fotosDePruebaQuedan(int n) =>
      n == 1 ? 'Te queda 1 foto de prueba' : 'Te quedan $n fotos de prueba';
  static const guardaTuAvanceParaFotos = 'Guarda tu avance para leer fotos';
  static String fotoDePrueba(int n, int de) =>
      'Foto de prueba $n de $de. Guarda tu avance con tu número para leer '
      'todas las que quieras.';
  static String fotosDePruebaAgotadas(int n) =>
      'Usaste tus $n fotos de prueba. Guarda tu avance con tu número para '
      'seguir leyendo fotos.';
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
  // La hoja del + (mejora 01)
  static const atajos = 'Atajos';
  static const atajoVentaDelDia = 'Venta del día';
  static const atajoUnGasto = 'Un gasto';
  static String llegaEnLaEntrega(int n) => 'Llega en la entrega $n';

  // «Escribirlo» (no dibujado)
  static const queFue = '¿Qué fue?';
  static const entro = 'Entró';
  static const salio = 'Salió';
  static const retiroParaMi = 'Retiro para mí';
  // Plata que el dueño pone en el negocio (entrega 14.11).
  static const prestamoNoEsVenta =
      'Un préstamo no es venta: es plata que debes. Por ahora anótalo como '
      '«Puse de mi bolsillo», así sube tu plata sin contar como venta. Los '
      'préstamos llegan en una próxima versión.';
  static const puseDeMiBolsillo = 'Puse de mi bolsillo';
  static const retiroDetalle =
      'Baja la plata de la cuenta, pero no cuenta como gasto del negocio.';
  static const aporteDetalle =
      'Plata que pones de tu bolsillo en el negocio: sube tu plata, pero no '
      'cuenta como venta. Si te la prestaron, no es esto.';
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
  static const aporteNoCuenta = 'No cuenta como venta';
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
    TipoMovimiento.aporte => puseDeMiBolsillo,
    TipoMovimiento.transferencia => pasePlata,
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

  // Vender a crédito: «Lo que te deben» (entrega 42).
  static const teDebe = 'Te debe';
  static const yaTePagaron = '¿Ya te pagaron?';
  static const siMePago = 'Sí, ya me pagó';
  static const todaviaMeDebe = 'Todavía me debe';
  static const cuentaAlCobrar =
      'Eliges a dónde entró la plata cuando te pague.';
  static const quienTeDebe = '¿Quién te debe?';
  static const quienTeDebeEjemplo = 'Su nombre';
  static const todaviaTeDebe =
      'Todavía te deben esta venta. No sube tu saldo hasta que te paguen.';
  static const yaMePago = 'Ya me pagó';
  static const cuandoTePago = '¿Cuándo te pagó?';
  static const loQueTeDebenTitulo = 'Lo que te deben';
  static const todoLoQueTeDeben = 'Todo lo que te deben hoy, de cualquier mes';
  static const nadieTeDebe = 'Nadie te debe nada.';
  static const sinCliente = 'Sin nombre';
  static String teDebenTotal(String monto, int ventas) =>
      'Te deben $monto, de $ventas ${ventas == 1 ? 'venta' : 'ventas'}';
  static String grupoTeDeben(String quien, String monto, int ventas) =>
      '$quien · $monto · $ventas ${ventas == 1 ? 'venta' : 'ventas'}';
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
  // Recordarle al cliente por WhatsApp (entrega 45). De usted: es un
  // mensaje del negocio a su cliente.
  static const recordarPorWhatsApp = 'Recordar por WhatsApp';
  static String recordatorioDeuda({
    required String? cliente,
    required String negocio,
    required String falta,
    required List<String> fechas,
    String? total,
  }) {
    final saludo = cliente == null ? 'Hola.' : 'Hola, $cliente.';
    String unir(List<String> partes) => partes.length == 1
        ? partes.single
        : '${partes.sublist(0, partes.length - 1).join(', ')} y '
              '${partes.last}';
    final de = fechas.length == 1
        ? 'de su compra del ${fechas.single}'
        : 'de sus compras ${unir([for (final f in fechas) 'del $f'])}';
    final pendiente = total == null
        ? 'tiene pendiente $falta'
        : 'le queda pendiente $falta de $total';
    return '$saludo Le escribimos de $negocio para recordarle que '
        '$pendiente, $de. Cuando pueda, nos avisa cómo prefiere pagar. '
        'Gracias.';
  }

  // Deshacer un cobro o un pago completo (entrega 44.2).
  static const deshacerElCobro = 'Deshacer el cobro';
  static const deshacerElPago = 'Deshacer el pago';
  static String preguntaDeshacerCobro(String monto, String cuenta) =>
      'La venta vuelve a «Lo que te deben» y salen $monto de '
      '${cuenta.toLowerCase()}.';
  static String preguntaDeshacerPago(String monto, String cuenta) =>
      'La compra vuelve a «Lo que debes» y vuelven $monto a '
      '${cuenta.toLowerCase()}.';
  static String quedariaEn(String cuenta, String saldo) =>
      '$cuenta quedaría en $saldo.';
  static const cobroDeshecho = 'Listo. La venta volvió a «Lo que te deben».';
  static const pagoDeshecho = 'Listo. La compra volvió a «Lo que debes».';
  static const deshicisteCobro =
      'Deshiciste el cobro: volvió a «Lo que te deben»';
  static const deshicistePago = 'Deshiciste el pago: volvió a «Lo que debes»';
  static String tePagaron(String cuenta, String fecha) =>
      'Marcaste que ya cobraste: $cuenta, $fecha';
  static String pagasteParte(String monto, String cuenta, String fecha) =>
      'Pagaste una parte de $monto: $cuenta, $fecha';
  static String tePagaronParte(String monto, String cuenta, String fecha) =>
      'Cobraste una parte de $monto: $cuenta, $fecha';

  // Cobros y pagos en partes (entrega 44).
  static String todoElMonto(String monto) => 'Todo ($monto)';
  static const unaParte = 'Una parte';
  static const montoDeLaParte = 'Monto de la parte';
  static String parteMenorQue(String monto) =>
      'Tiene que ser más que cero y menos de $monto. Si es todo, elige '
      '«Todo».';
  static String cobradoParte(String parte, String quien, String falta) =>
      'Cobrado $parte. $quien todavía te debe $falta.';
  static String pagadoParte(String parte, String falta) =>
      'Pagado $parte. Todavía debes $falta.';
  static const pagoEnParte = 'Pago en parte';
  static String pagoDeTotal(String pagado, String total) =>
      'pagó $pagado de $total';
  static const pagosEnPartes = 'Pagos en partes';
  static String faltaPagar(String monto) =>
      monto.isEmpty ? 'Falta' : 'Falta $monto';
  static String parteDeUnaDeuda(bool cobro, String falta) => cobro
      ? (falta.isEmpty
            ? 'Es una parte de una venta a crédito, que ya está cobrada.'
            : 'Es una parte de una venta a crédito. Todavía te deben $falta.')
      : (falta.isEmpty
            ? 'Es una parte de una compra que debías, que ya está pagada.'
            : 'Es una parte de una compra que debes. Todavía debes $falta.');
  static const verLaDeuda = 'Ver la deuda';
  static const noSePuede = 'No se puede todavía';
  static String traba(TrabaDelRegistro traba) => switch (traba) {
    TrabaDelRegistro.tienePartes =>
      'Tiene pagos en partes. Para corregirla o deshacerla, primero deshaz '
          'sus partes, empezando por la más reciente.',
    TrabaDelRegistro.esParte =>
      'Un pago en parte no se corrige: deshazlo y anótalo otra vez.',
    TrabaDelRegistro.noEsLaUltimaParte =>
      'Solo se deshace la parte más reciente, mientras la deuda siga '
          'abierta.',
  };
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
  static String cobradoAhoraTienes(String monto, String cuenta) =>
      'Cobrado. Ahora tienes $monto en ${cuenta.toLowerCase()}';

  // Cobrar o pagar una deuda por voz (entrega 50)
  static String teDebeEsDeEsa(String quien, String monto) =>
      '$quien te debe $monto. ¿Es de esa deuda?';
  static String leDebesEsDeEsa(String quien, String monto) =>
      'A $quien le debes $monto. ¿Es de esa deuda?';
  static const siDeEsaDeuda = 'Sí, de esa deuda';
  static const noAnotarloAparte = 'No, anotarlo aparte';
  static const anotarloAparte = 'Anotarlo aparte';
  static const deQuienEsElCobro = '¿De quién es lo que cobraste?';
  static const aQuienLePagaste = '¿A quién le pagaste?';
  static String quienYCuanto(String quien, String monto) => '$quien · $monto';
  static String teDebeNoTanto(String quien, String debe, String dicho) =>
      '$quien te debe $debe, no $dicho.';
  static String leDebesNoTanto(String quien, String debe, String dicho) =>
      'A $quien le debes $debe, no $dicho.';
  static String cobrarLos(String monto) => 'Cobrar los $monto';
  static String pagarLos(String monto) => 'Pagar los $monto';
  static String cobroDeLoQueTeDebe(String quien) =>
      'Cobro de lo que te debe $quien';
  static String pagoDeLoQueLeDebes(String quien) =>
      'Pago de lo que le debes a $quien';
  static String leQueda(String monto) => 'Le queda $monto';
  static String teFalta(String monto) => 'Te falta $monto';
  static const yaNoDebeNada = 'Ya no debe nada';
  static const yaNoLeDebesNada = 'Ya no le debes nada';

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
    MotivoArqueo.puseYo => 'La puse yo',
    MotivoArqueo.gastoOlvidado => 'Un gasto que olvidé',
    MotivoArqueo.ventaNoAnotada => 'Una venta que no anoté',
    MotivoArqueo.errorDeVuelto => 'Di mal un vuelto',
    MotivoArqueo.noLoSe => 'No lo sé',
  };
  static String notaMotivo(MotivoArqueo motivo, {required bool faltan}) =>
      switch (motivo) {
        MotivoArqueo.retiroParaMi =>
          'Un retiro para ti baja tu plata, pero no es un gasto del negocio.',
        MotivoArqueo.puseYo =>
          'Se anota como plata que pusiste de tu bolsillo. No es una venta.',
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

  // Resumen del año (entrega 40)
  static const verMes = 'Mes';
  static const verAnio = 'Año';
  static const anioAnterior = 'Año anterior';
  static const anioSiguiente = 'Año siguiente';
  static String enElAnioCrecio(int anio) => 'En $anio tu plata creció';
  static String enElAnioBajo(int anio) => 'En $anio tu plata bajó';
  static String enElAnioIgual(int anio) => 'En $anio tu plata quedó igual';
  static const tocaUnMes = 'Toca un mes para ver su informe.';
  static const antesDeMoca = 'Antes de Moca';
  static const hastaHoyMinuscula = 'hasta hoy';
  static const pusisteDeTuBolsillo = 'Pusiste de tu bolsillo';
  static const salioDelNegocio = 'Salió del negocio';
  static const retirasteParaTi = 'Retiraste para ti';
  static const sobroEnLosArqueos = 'Sobró en los arqueos';
  static const faltoEnLosArqueos = 'Faltó en los arqueos';
  static const sinIngresosDelAnio = 'Este año aún no entra plata.';
  static const sinGastosDelAnio = 'Este año aún no sale plata.';

  /// «De enero a hoy», «Del 12 de octubre a hoy», «Todo 2025» o «Del 12 de
  /// octubre al 31 de diciembre».
  static String periodoDelAnio(DateTime desde, {required bool enCurso}) {
    final todoElAnio = desde.month == 1 && desde.day == 1;
    if (enCurso) {
      return todoElAnio
          ? 'De enero a hoy'
          : 'Del ${desde.day} de ${nombreDelMes(desde)} a hoy';
    }
    return todoElAnio
        ? 'Todo ${desde.year}'
        : 'Del ${desde.day} de ${nombreDelMes(desde)} al 31 de diciembre';
  }

  static String desdeElDia(int dia) => 'Desde el día $dia';
  static String desdeElDiaHastaHoy(int dia) => 'Desde el día $dia hasta hoy';
  // El informe es el flujo de caja del mes, no la ganancia (entrega 14.9).
  static const tuPlataCrecio = 'Este mes tu plata creció';
  static const tuPlataBajo = 'Este mes tu plata bajó';
  static const tuPlataIgual = 'Este mes tu plata quedó igual';
  static String masQueEn(String monto, String mes) => '$monto más que en $mes';
  static String menosQueEn(String monto, String mes) =>
      '$monto menos que en $mes';
  static String igualQueEn(String mes) => 'Lo mismo que en $mes';
  static const primerMesConMoca =
      'Es tu primer mes con Moca. El próximo mes verás la comparación.';
  static const comoSeMovio = 'Cómo se movió tu plata';
  static const empezasteElMesCon = 'Empezaste el mes con';
  static const empezasteCon = 'Empezaste con';
  static const masEntro = '+ Entró';
  static const masPusisteDeTuBolsillo = '+ Pusiste de tu bolsillo';
  static const menosSalioDelNegocio = '− Salió del negocio';
  static const menosRetirasteParaTi = '− Retiraste para ti';
  static const masSobroEnElArqueo = '+ Sobró en el arqueo';
  static const menosFaltoEnElArqueo = '− Faltó en el arqueo';
  static const terminasteElMesCon = 'Terminaste el mes con';
  static const cuentasDePlata =
      'Cuenta la plata el día en que se movió: lo que todavía debes se cuenta '
      'cuando lo pagas.';
  static const enQueSeFue = 'En qué se fue la plata';
  static const conQueEntro = 'Con qué entró la plata';
  static const sinIngresosDelMes = 'En este mes no entró plata.';
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
      'Compraste más mercadería que otros meses: tu plata bajó, pero esa '
      'mercadería sigue en tu tienda.';
  static const mesSinRegistros = 'En este mes no hay registros.';
  static const armandoPdf = 'Armando el PDF…';

  // El PDF en tres versiones (entrega 14.12)
  static const paraQuienEsPdf = '¿Para quién es el informe?';
  static const pdfParaMi = 'Para mí';
  static const pdfParaMiDetalle = 'Una hoja: cómo se movió tu plata.';
  static const pdfParaContador = 'Para mi contador';
  static const pdfParaContadorDetalle =
      'Con lo que debes y los comprobantes del mes.';
  static const pdfParaCredito = 'Para pedir un crédito';
  static const pdfParaCreditoDetalle =
      'Tus últimos meses y el flujo en el formato de la caja.';
  static const mocaPlus = 'Moca Plus';
  static const flujoParaCajaTitulo = 'Para pedir un crédito';
  static String flujoParaCaja(int meses, {String? hastaHoy}) =>
      'Se comparten dos archivos: el resumen en PDF y el flujo de caja en el '
      'formato que usan las cajas y financieras. '
      '${hastaHoy != null ? 'Moca todavía no tiene un mes completo: va lo que llevas de $hastaHoy, hasta hoy. Los meses antes de Moca y los gastos de tu hogar los completas tú con tu asesor.' : 'Moca llenó los 17 datos de tu negocio en $meses de los 6 meses que piden. Los meses antes de Moca y los gastos de tu hogar los completas tú con tu asesor.'}';
  static const compartir = 'Compartir';
  static const etiquetaParaContador = 'Para el contador';
  static const etiquetaParaCredito = 'Para evaluar un crédito';
  static String periodoDelAl(DateTime desde, DateTime hasta) =>
      desde.day == hasta.day && desde.month == hasta.month
      ? 'El ${desde.day} de ${_mes(desde)} de ${desde.year}'
      : 'Del ${desde.day} al ${hasta.day} de ${_mes(hasta)} de ${hasta.year}';
  static String periodoDeMeses(DateTime desde, DateTime hasta) =>
      desde.year == hasta.year
      ? 'De ${_mes(desde)} a ${_mes(hasta)} de ${hasta.year}'
      : 'De ${_mes(desde)} de ${desde.year} a ${_mes(hasta)} de ${hasta.year}';
  static String _mes(DateTime d) => const [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'setiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ][d.month - 1];
  static const aclaracionPdf =
      'Flujo de caja: cómo se movió la plata. No es un estado financiero ni '
      'reemplaza la contabilidad.';
  static String paginaDe(int pagina, int total) => 'Página $pagina de $total';
  static const cuantoHayHoyEnCadaCuenta = 'Cuánto hay hoy en cada cuenta';
  static const cuantoHabiaAlCierre = 'Cuánto había en cada cuenta al cierre';
  // Desde la entrega 35 se llama igual que en el informe.
  static const deDondeVino = conQueEntro;
  static const sinIngresos = 'En este periodo no entró plata.';
  static const noDebesNada = 'No debes nada.';

  // Buscar y filtrar en el Historial (entrega 39).
  static const buscarEnTuHistorial = 'Buscar en tu historial';
  static const filtrar = 'Filtrar';
  static String filtrarCon(int n) => 'Filtrar ($n)';
  static const quitarFiltros = 'Quitar filtros';
  static const verResultados = 'Ver resultados';
  static const quienAnoto = 'Quién lo anotó';
  static const filtroCuenta = 'Cuenta';
  static const filtroCategoria = 'Categoría';
  static const otraPersona = 'Otra persona';
  static const sinResultados = 'No hay registros con esa búsqueda.';
  static String resumenDeBusqueda(int n, String entro, String salio) =>
      '$n ${n == 1 ? 'registro' : 'registros'} · Entró $entro · Salió $salio';

  // «Lo que debes» y los registros de una categoría (entrega 38).
  static const verDetalle = 'Ver detalle';
  static const sinProveedor = 'Sin proveedor';
  static String debesTotal(String monto, int compras) =>
      'Debes $monto, de $compras ${compras == 1 ? 'compra' : 'compras'}';
  static String grupoDeuda(String aQuien, String monto, int compras) =>
      '$aQuien · $monto · $compras ${compras == 1 ? 'compra' : 'compras'}';
  static String totalDeRegistros(String monto, int registros) =>
      '$monto · $registros ${registros == 1 ? 'registro' : 'registros'}';
  static const columnaFecha = 'Fecha';
  static const columnaProveedor = 'Proveedor';
  static const columnaDetalle = 'Detalle';
  static const columnaMonto = 'Monto';
  static const columnaComprobante = 'Comprobante';
  static const columnaRuc = 'RUC';
  static const columnaIgv = 'IGV';
  static const columnaTotal = 'Total';
  static const columnaMes = 'Mes';
  static const columnaEntro = 'Entró';
  static const columnaPusiste = 'Pusiste';
  static const columnaSalio = 'Salió';
  static const columnaRetiraste = 'Retiraste';
  static const columnaCrecio = 'Creció';
  static const columnaAlCierre = 'Al cierre';
  static const comprobantesDelMes = 'Comprobantes del mes';
  static const sinComprobantes = 'En este mes no hay comprobantes.';
  static const loDebesCorto = 'lo debes';
  static String resumenDeMeses(int n) =>
      n == 1 ? 'Resumen del mes' : 'Resumen de los últimos $n meses';
  static const entroPorMes = 'Entró por mes, en promedio';
  static const soloMesesCompletos =
      'Solo con los meses completos (marcados sin *).';
  static const mesIncompleto =
      '* Mes incompleto: el primero con Moca o el que aún no termina.';
  static const mesPorMes = 'Mes por mes';
  static String confianzaEnUnaLinea(int a, int b, int c) =>
      '$a% con comprobante · $b% con foto o captura · $c% sin papel';
  static const notaCredito =
      'Lo anotó el dueño en Moca, con su teléfono. No está verificado por '
      'una entidad.';
  static const pdfNoSeArmo = 'No se pudo armar el PDF. Intenta otra vez.';

  // Excel de las operaciones (entrega 14.13)
  static const compartirExcel = 'Compartir Excel';
  static const armandoExcel = 'Armando el Excel…';
  static const excelNoSeArmo = 'No se pudo armar el Excel. Intenta otra vez.';
  static String operacionesDe(String mes, int anio) =>
      'Operaciones de $mes $anio';
  static const hojaOperaciones = 'Operaciones';
  static const hojaResumen = 'Resumen';
  static const hojaSaldos = 'Saldos por cuenta';
  static const hojaLoQueDebes = 'Lo que debes';
  static const hojaLoQueTeDeben = 'Lo que te deben';
  static const deudasTitulo = 'Lo que debes y lo que te deben';
  static const columnaCliente = 'Cliente';
  static const columnaPagadoEnPartes = 'Pagó en partes';
  static String faltaDe(String falta, String pagado, String total) =>
      '$falta (pagó $pagado de $total)';
  static const columnaTipo = 'Tipo';
  static const columnaCategoria = 'Categoría';
  static const columnaNota = 'Nota';
  static const columnaCuenta = 'Cuenta';
  static const columnaPagado = 'Pagado';
  static const columnaFechaPago = 'Fecha de pago';
  static const columnaConfianza = 'Confianza';
  static const columnaDesde = 'Desde';
  static const columnaSaldo = 'Saldo';
  static const si = 'Sí';
  static String pagadoEnParte(String monto) => 'En parte: $monto';
  static String nivelConfianza(NivelConfianza n) => switch (n) {
    NivelConfianza.a => 'A: verificado con SUNAT',
    NivelConfianza.b => 'B: con comprobante',
    NivelConfianza.c => 'C: con foto o captura',
    NivelConfianza.d => 'D: sin papel',
  };
  static const negocio = 'Negocio';
  static const periodo = 'Periodo';
  static const hechoElCorto = 'Hecho el';
  static const notaCajaExcel =
      'Las cifras son de caja: lo que debes cuenta cuando lo pagas y el '
      'arqueo ajusta el saldo. Por eso la hoja Operaciones puede no sumar lo '
      'mismo.';
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
    TipoNotificacion.cobroPorVencer => 'Fin de la prueba gratis',
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
  // Borrar todo, también en el servidor (entrega 14.8)
  static const borrarEnServidor = 'Borrar todo, también en el servidor';
  static const borrarEnServidorDetalle =
      'Borra para siempre los datos de este número en el servidor y en este '
      'teléfono. Al entrar otra vez, todo empieza en blanco.';
  static const borrarEnServidorTitulo = '¿Borrar todo para siempre?';
  static String borrarEnServidorAviso(String celular) =>
      'Se borran para siempre las ventas, gastos, comprobantes, arqueos y '
      'saldos del número $celular, en el servidor y en este teléfono. No se '
      'puede deshacer.';
  static const continuar = 'Continuar';
  static const escribeBorrar = 'Para confirmar, escribe BORRAR';

  static const seguridad = 'Seguridad';

  // «Ajustes» y «Datos del negocio» (entregas 29 y 29.1).
  static const ajustes = 'Ajustes';
  static const ajustesDetalle = 'Tu negocio, tu equipo y la seguridad';
  static const tuNegocio = 'Tu negocio';
  static const tuEquipoAjustes = 'Tu equipo';
  static const datosDelNegocio = 'Datos del negocio';
  static const datosDelNegocioDetalle = 'El nombre y la hora de cierre';
  static const datosGuardados = 'Listo. Guardado.';

  // El cobro (entrega 25).
  static String pruebaTeQuedan(int dias, String hasta) => switch (dias) {
    0 => 'Hoy es el último día de tu prueba gratis.',
    1 => 'Prueba gratis: te queda 1 día (hasta el $hasta).',
    _ => 'Prueba gratis: te quedan $dias días (hasta el $hasta).',
  };
  static const pruebaSinEmpezar =
      'Tu prueba gratis de 14 días empieza con tu primer registro.';
  static String pagadoHasta(String hasta) =>
      'Moca está pagada hasta el $hasta.';
  static const pruebaTermino = 'Tu prueba gratis terminó';
  static String pagoVencio(String hasta) => 'Tu mes de Moca venció el $hasta';
  static String avisoPorVencer(bool enPrueba, int dias) {
    final que = enPrueba ? 'Tu prueba gratis termina' : 'Tu mes de Moca vence';
    return switch (dias) {
      0 => '$que hoy.',
      1 => '$que mañana.',
      _ => '$que en $dias días.',
    };
  }

  static const comoPagar = 'Cómo pagar';

  // «Mis pagos de Moca» (entrega 33).
  static const misPagos = 'Mis pagos de Moca';
  static const misPagosDetalle = 'Cuándo pagaste y qué cubrió cada pago';
  static const verMisPagos = 'Ver mis pagos';
  static String resumenDeMisPagos(Cobro c) {
    final hasta = c.hasta == null ? '' : formatearDiaYMes(c.hasta!);
    return switch (c.estado) {
      EstadoDelCobro.pagado => [
        'Moca está pagada hasta el $hasta',
        if (c.plan == 'fundador') 'Plan de fundador',
        if (c.plan == 'anual') 'Plan anual',
      ].join(' · '),
      EstadoDelCobro.prueba when c.hasta == null => pruebaSinEmpezar,
      EstadoDelCobro.prueba => pruebaTeQuedan(c.dias ?? 0, hasta),
      EstadoDelCobro.vencido =>
        c.plan == null ? '$pruebaTermino.' : '${pagoVencio(hasta)}.',
      EstadoDelCobro.sinCobro => 'Moca todavía no cobra.',
    };
  }

  static String planDelPago(PlanCobro plan, [int extras = 0]) =>
      switch (plan) {
        PlanCobro.basico => 'Un mes · Básico',
        PlanCobro.normal => 'Un mes · Full',
        PlanCobro.fundador => 'Un mes · Full de fundador',
        PlanCobro.anual => 'Un año · Full',
      } +
      (extras > 0 ? ' · ${masPersonas(extras)}' : '');
  static String masPersonas(int n) => n == 1 ? '+ 1 persona' : '+ $n personas';
  static String cubrio(String desde, String hasta) => 'Del $desde al $hasta';
  static String porMercadoPago(String? operacion) => operacion == null
      ? 'Mercado Pago'
      : 'Mercado Pago · operación $operacion';
  static const porYape = 'Yape';
  static const pagoDevueltoNoCuenta = 'Anulado o devuelto: no cuenta';
  static const pagoEnRevision =
      'Tienes un pago de Mercado Pago en revisión. Te escribiremos por '
      'WhatsApp.';
  static const sinPagosTodavia = 'Todavía no hay pagos.';
  static const misPagosSinSenal =
      'Necesitas señal para ver tus pagos la primera vez.';
  static String actualizadoEl(String dia) => 'Actualizado el $dia';
  static const pagarOtroMes = 'Pagar otro mes';
  static String pagoSumaUnMes(String hasta, String desde, String nuevo) =>
      'Ya está pagada hasta el $hasta. Este pago suma un mes: del $desde al '
      '$nuevo.';
  static const pagaTuMes = 'Paga tu mes de Moca';

  // Pagar con Mercado Pago (entrega 32).
  static String pagaConMercadoPago(String monto) =>
      'Paga $monto con Yape, tarjeta o PagoEfectivo en la página de Mercado '
      'Pago.';
  static const pagarConMercadoPago = 'Pagar con Mercado Pago';
  static const abriendoMercadoPago = 'Abriendo Mercado Pago…';
  static const oYapeaYMandaLaCaptura = 'O yapea y manda la captura:';
  static const esperandoElPago = 'Esperando la confirmación del pago…';
  static const seguirSinEsperar = 'Seguir sin esperar';
  static const mocaPagada = 'Listo. Moca está pagada.';
  static String mocaPagadaHasta(String dia) =>
      'Listo. Moca está pagada hasta el $dia.';
  static const pagoPorRevisar =
      'Recibimos tu pago, pero hay que revisarlo. Te escribiremos por '
      'WhatsApp.';
  static const pagoDevuelto = 'Mercado Pago devolvió el pago. No se cobró.';
  static const siYaPagaste =
      'Si ya pagaste, Moca se activa sola en unos minutos. PagoEfectivo puede '
      'tardar unas horas.';
  static const pagoSinSenal = 'Necesitas señal para pagar.';
  static const pagoNoDisponible =
      'Por ahora no se puede pagar con Mercado Pago. Yapea y manda la captura.';
  static const pagoSoloDuenos = 'Solo un dueño puede pagar Moca.';
  static const pagoFallo =
      'No se pudo abrir el pago. Intenta otra vez en un momento.';
  static const noSeAbrioElPago = 'No se pudo abrir la página de pago.';
  static String yapeaA(String monto, String numero, String nombre) =>
      'Yapea $monto al $numero, a nombre de $nombre.';
  static const precioDeFundador =
      'Es tu precio de fundador: lo conservas mientras renueves a tiempo.';
  static const luegoMandaLaCaptura =
      'Luego manda la captura por WhatsApp. En cuanto la veamos, activamos tu '
      'mes y aquí dirá hasta cuándo.';
  static const copiarElNumero = 'Copiar el número';
  static const numeroCopiado = 'Número copiado.';
  static const mandarLaCaptura = 'Mandar la captura por WhatsApp';
  static String mensajeDePago(String negocio, String celular, String plan) =>
      'Hola, pagué Moca $plan para $negocio. Mi celular es $celular. Te mando '
      'la captura.';

  // Elegir el plan al pagar (entrega 43).
  static const eligeTuPlan = 'Elige tu plan';
  static const planBasico = 'Básico';
  static const planFull = 'Full';
  static const detalleBasico = '1 persona. Sin «Para pedir un crédito».';
  static const detalleFull = '3 personas, con «Para pedir un crédito».';
  static String cuentaDelPlan(
    String plan,
    String base,
    int extras,
    String porExtras,
    String total, {
    bool anual = false,
  }) {
    final periodo = anual ? 'al año' : 'al mes';
    if (extras == 0) return '$plan $base $periodo';
    final personas = extras == 1 ? '1 persona más' : '$extras personas más';
    return '$plan $base + $personas $porExtras = $total $periodo';
  }

  static String conFullPagasMenos(String precio) =>
      'Con el Full pagas menos: $precio al mes, con 3 personas y «Para pedir '
      'un crédito».';
  static String avisoBasicoConExtras(int extras, String monto) =>
      'Tu Básico incluye 1 persona. '
      '${extras == 1 ? 'La otra suma' : 'Las otras $extras suman'} $monto al '
      'mes hasta que las quites en «Mi equipo».';

  // El crédito es del Full (entrega 43).
  static const creditoEsDelFull = 'Está en el plan Full';
  static const creditoEsDelFullDetalle =
      '«Para pedir un crédito» viene con el plan Full: S/ 19.90 al mes, con '
      '3 personas. Puedes cambiarte desde «Cómo pagar».';
  static const pagoSinDatos =
      'Muy pronto podrás pagar desde aquí. Te avisaremos.';
  static const noSeAbrioWhatsApp = 'No se pudo abrir WhatsApp.';
  static const soloAnotarDetalle =
      'Sigues pudiendo anotar y bajar tus operaciones en Excel. Para ver tus '
      'saldos, el arqueo y tus informes, paga tu mes.';
  static const soloAnotarOtros =
      'El negocio necesita renovar Moca. Sigues pudiendo anotar: avísale al '
      'dueño.';
  static const bajarMisOperaciones = 'Bajar mis operaciones del mes (Excel)';
  static String preguntaPrecio(String monto) =>
      '¿Seguirías usando Moca por $monto al mes?';
  static const respuestaSi = 'Sí';
  static const respuestaNoSe = 'No sé';
  static const respuestaNo = 'No';
  static const porQueOpcional = '¿Por qué? (opcional)';
  static const enviarRespuesta = 'Enviar';
  static const graciasPorResponder = 'Gracias. Tu respuesta nos ayuda mucho.';
  static const necesitasSenalParaResponder =
      'Necesitas señal para enviar tu respuesta.';
  // Los errores de la app (entrega 27).
  static const algoSalioMal = 'Algo salió mal en esta pantalla';
  static const algoSalioMalDetalle =
      'Ya nos llegó el aviso. Lo que anotaste está guardado.';
  static const errores = 'Errores';
  static const erroresDetalle =
      'Lo que falló en los teléfonos, de los últimos 90 días.';
  static const sinErrores = 'No hay errores en los últimos 90 días.';
  static const necesitasSenalParaErrores =
      'Necesitas señal para ver los errores.';
  static String erroresVeces(int veces, int negocios) =>
      '${veces == 1 ? '1 vez' : '$veces veces'} · '
      '${negocios == 1 ? '1 negocio' : '$negocios negocios'}';
  static const copiarDetalle = 'Copiar el detalle';
  static const detalleCopiado = 'Detalle copiado.';

  // La versión nueva (entrega 26.3).
  static const hayVersionNueva = 'Hay una versión nueva de Moca';
  static const hayVersionNuevaDetalle =
      'Trae arreglos y mejoras. Se instala encima: no pierdes nada de lo que '
      'anotaste.';
  static const descargar = 'Descargar';
  static const ahoraNoVersion = 'Ahora no';
  static const actualizaMoca = 'Actualiza Moca para seguir';
  static const actualizaParaAnotar =
      'Para seguir anotando, instala la versión nueva. Lo que ya anotaste no '
      'se pierde, y mientras tanto puedes ver tus saldos, tu historial y tus '
      'informes.';
  static const actualizaDesdeManana =
      'Desde mañana tendrás que actualizar para seguir anotando. Toma un '
      'minuto y no pierdes nada de lo anotado.';
  static const actualizaMocaDetalle =
      'Esta versión de Moca ya no funciona con el servidor. Lo que anotaste '
      'está guardado en este teléfono y se sube cuando actualices.';
  static const noSeAbrioLaDescarga = 'No se pudo abrir la descarga.';
  static String versionDeMoca(String entrega, int armado) =>
      entrega.isEmpty ? 'Moca, versión $armado' : 'Moca $entrega ($armado)';
  static const versionDeDesarrollo = 'Moca, versión de desarrollo';
  static String versionCorta(String entrega, int armado) =>
      entrega.isEmpty ? 'armado $armado' : '$entrega ($armado)';

  // «Ayuda» en Ajustes (entrega 46).
  static const ayuda = 'Ayuda';
  static const estadoDeEsteTelefono = 'Estado de este teléfono';
  static const etiquetaCuentaAyuda = 'Cuenta';
  static const etiquetaNegocioAyuda = 'Negocio';
  static const etiquetaServidor = 'Servidor';
  static const etiquetaVersion = 'Versión';
  static String unidoATuCuenta(String celular) => 'Unido a tu cuenta: $celular';
  static const sinCuentaAyuda =
      'Sin cuenta: lo anotado vive solo en este teléfono';
  static const porConfirmarAyuda = 'Falta confirmar tu número';
  static const abiertaEnOtroAyuda = 'Tu cuenta se abrió en otro teléfono';
  static const fueraAyuda = 'Te quitaron de este negocio';
  static String negocioYRol(String negocio, String rol, bool titular) =>
      '${negocio.isEmpty ? 'Tu negocio' : negocio} · $rol'
      '${titular ? ' (titular)' : ''}';
  static String actualizadoAyuda(String cuando) => 'Al día: $cuando';
  static const sinActualizarAyuda = 'Todavía no se conectó';
  static String porSubirAyuda(int n) =>
      '${n == 1 ? '1 registro por subir' : '$n registros por subir'}: abre '
      'Moca con señal';
  static const abiertaEnOtroQueHacer =
      'Usa Moca en el teléfono donde entraste último. Para volver a este, '
      'entra con «Ya tengo cuenta» y tu número.';
  static const fueraQueHacer =
      'Pídele al dueño que te invite otra vez, o entra a otro negocio desde '
      '«Mis negocios».';
  static const pedirAyudaWhatsApp = 'Pedir ayuda por WhatsApp';
  static String mensajeDeAyuda({
    required String version,
    required String cuenta,
    required String negocio,
    required String? codigo,
    required String rol,
    required int porSubir,
  }) =>
      'Hola, necesito ayuda con Moca.\n'
      'Versión: $version · Cuenta: $cuenta · Negocio: $negocio'
      '${codigo == null ? '' : ' (código $codigo)'} · Rol: $rol'
      ' · Por subir: $porSubir';
  static String versionConCommit(String entrega, int armado, String commit) =>
      'Versión: ${entrega.isEmpty ? '—' : entrega} · armado $armado · '
      'commit ${commit.isEmpty ? '—' : commit}';

  // La pantalla de cobros de Jhony (entrega 26).
  static const cobros = 'Cobros';
  static const cobrosDetalle =
      'Buscar un negocio, registrar un pago por Yape y ver lo que vence.';
  static String fundadoresUsados(int usados, int maximo) =>
      'Fundadores: $usados de $maximo.';
  static const celularDelDueno = 'Celular de la persona';

  // La ficha de soporte (entrega 47).
  static const numeroSinCuenta47 =
      'Ese número no tiene cuenta en Moca: nunca guardó su avance.';
  static const sinNegociosActivos =
      'Ese número tiene cuenta, pero no está en ningún negocio.';
  static const enQueNegocios = 'Está en estos negocios:';
  static String negocioYRolSoporte(String nombre, String rol, bool titular) =>
      '$nombre · $rol${titular ? ' (titular)' : ''}';
  static const personasSoporte = 'Personas';
  static String personaSoporte({
    required String rol,
    required bool titular,
    String? nombre,
    String? celular,
    String? version,
    String? subio,
  }) => [
    ?nombre,
    '$rol${titular ? ' (titular)' : ''}',
    ?celular,
    version ?? 'versión sin datos',
    subio == null ? 'no subió todavía' : 'subió $subio',
  ].join(' · ');
  static const invitacionesSoporte = 'Invitaciones';
  static String invitacionSoporte(
    String celular,
    String rol,
    String estado,
    String? nombre,
  ) => [?nombre, celular, rol, estado].join(' · ');
  static String registrosSoporte(int n) =>
      n == 1 ? '1 registro' : '$n registros';
  static const darDiasDePrueba = 'Dar días de prueba';
  static String diasDePrueba(int dias) => '$dias días más';
  static String diasDadosHasta(String hasta) =>
      'Listo. La prueba va hasta el $hasta.';
  static const borrarElNegocio = 'Borrar el negocio';
  static String borrarElNegocioDetalle(String nombre) =>
      'Se borra «$nombre» con todo lo que anotaron, también en el servidor. '
      'Solo a pedido de su titular. Para confirmar, escribe el nombre del '
      'negocio.';
  static const negocioBorrado47 = 'Listo. El negocio se borró.';
  static const yaPagoSoporte =
      'Ese negocio ya pagó alguna vez: no se le dan días de prueba.';
  static const demasiadosDiasSoporte =
      'Ese negocio ya tiene muchos días de regalo.';
  static const nombreNoCoincide = 'El nombre no coincide con el del negocio.';
  static const buscar = 'Buscar';
  static const sinNegocioConEseNumero = 'No hay un negocio con ese número.';
  static const sinPermisoCobros = 'Este número no registra pagos.';
  static const necesitasSenalParaCobros = 'Necesitas señal para los cobros.';
  static const registrarPago = 'Registrar pago';
  static String nombrePlan(PlanCobro plan) => switch (plan) {
    PlanCobro.basico => 'Básico, S/ 14.90',
    PlanCobro.normal => 'Full, S/ 19.90',
    PlanCobro.fundador => 'Full de fundador, S/ 14.90',
    PlanCobro.anual => 'Full al año, S/ 199',
  };
  static String totalConPersonas(int personas, String total) =>
      'Con ${personas == 1 ? '1 persona' : '$personas personas'}: $total';
  static const notaDelPago = 'Nota (número de operación de Yape)';
  static String confirmarPago(String plan, String negocio) =>
      '¿Registrar «$plan» para $negocio?';
  static String pagoRegistrado(String hasta) =>
      'Listo. Pagado hasta el $hasta.';
  static const perdioFundador =
      'Renovó más de 30 días tarde: ya no es fundador. Registra el mes de '
      'S/ 19.90.';
  static const sinCupoFundador = 'Ya están los 50 fundadores.';
  static const pagosRegistrados = 'Pagos';
  static const anularPago = 'Anular';
  static const anularPagoPregunta = '¿Anular este pago?';
  static const anularPagoDetalle =
      'Úsalo para un pago de prueba o registrado por error. El negocio vuelve '
      'a como estaba antes de este pago; el pago queda en la lista, anulado.';
  static const pagoAnulado = 'Listo. El pago quedó anulado.';
  static const anulado = 'anulado';
  static const noEsElUltimoPago = 'Solo se puede anular el último pago.';
  static String pagoDe(String monto, String desde, String hasta) =>
      '$monto · del $desde al $hasta';
  static const respuestaDelDia10 = 'Respuesta del día 10';
  static String respondio(String respuesta, String precio) =>
      '$respuesta, con $precio';
  static const vencenPronto = 'Vencen pronto o ya vencieron';

  // El uso de cada negocio (entrega 28).
  static const usoDeLaSemana = 'Uso de los últimos 7 días';
  static String usoDias(int abrio, int anoto) =>
      'Abrió Moca $abrio de 7 días · anotó $anoto de 7 días';
  static String usoVentas(int ventas, int? segundos) => ventas == 0
      ? 'No anotó la venta del día'
      : '${ventas == 1 ? '1 venta del día' : '$ventas ventas del día'}'
            '${segundos == null ? '' : ' · tarda unos $segundos s en anotarla'}';
  static String usoVoz(int dudas, int corregidas, int fotos) =>
      'Voz: dudó $dudas, corregida $corregidas · fotos ilegibles: $fotos';
  static String usoAvisos(int respondidos, int abiertos) =>
      'Aviso de cierre: respondió $respondidos, lo abrió $abiertos';
  static String usoAbrio(int arqueos, int informes) =>
      'Arqueos abiertos: $arqueos · informes abiertos: $informes';
  static String ultimaVezQueAbrio(String cuando) =>
      'Abrió Moca por última vez: $cuando';
  static const nuncaAbrio = 'Sin datos de uso todavía';
  static const sinAbrirMoca = 'Sin abrir Moca hace 3 días o más';
  static const pagosPorRevisar = 'Pagos de Mercado Pago por revisar';
  static String motivoPorRevisar(String motivo) => switch (motivo) {
    'monto' => 'cobró menos de lo que vale',
    'sin_cupo_fundador' => 'ya no había cupo de fundador',
    'perdio_fundador' => 'ya no le tocaba el precio de fundador',
    'devuelto' => 'devuelto, y no era su último pago',
    _ => motivo,
  };
  static const todosAbren = 'Todos abrieron Moca en los últimos 3 días.';
  static const nadaPorVencer = 'Nada vence en los próximos 3 días.';
  static String estadoCorto(Cobro cobro) {
    final hasta = cobro.hasta == null
        ? ''
        : '${cobro.hasta!.day}/${cobro.hasta!.month}';
    return switch (cobro.estado) {
      EstadoDelCobro.sinCobro => 'Sin cobro',
      EstadoDelCobro.prueba when cobro.hasta == null => 'Prueba sin empezar',
      EstadoDelCobro.prueba => 'Prueba hasta el $hasta',
      EstadoDelCobro.pagado => 'Pagado hasta el $hasta',
      EstadoDelCobro.vencido => 'Venció el $hasta',
    };
  }

  static const notificacionCobro =
      'Tu prueba gratis de Moca termina en 3 días. Toca para ver cómo pagar.';

  // Salir de este negocio (entrega 22.2).
  // Sin acceso al negocio (entrega 37).
  static String sinAccesoTitulo(SinAcceso s) {
    final negocio = s.negocio.isEmpty ? 'El negocio' : s.negocio;
    return switch (s.motivo) {
      MotivoSinAcceso.negocioBorrado => '$negocio ya no está en Moca',
      MotivoSinAcceso.otroTelefono => 'Tu cuenta se abrió en otro teléfono',
      MotivoSinAcceso.salio =>
        s.negocio.isEmpty ? 'Saliste del negocio' : 'Saliste de ${s.negocio}',
      _ =>
        s.negocio.isEmpty
            ? 'Ya no estás en este negocio'
            : 'Ya no estás en ${s.negocio}',
    };
  }

  static String sinAccesoDetalle(MotivoSinAcceso m) => switch (m) {
    MotivoSinAcceso.negocioBorrado =>
      'El dueño borró el negocio y sus datos. Tu cuenta sigue: puedes '
          'empezar tu propio negocio o entrar a otro donde te inviten.',
    MotivoSinAcceso.quitado =>
      'Un dueño te quitó del equipo. Lo que anotaste se quedó en el negocio; '
          'lo que anotaste sin señal después no se pudo guardar.',
    MotivoSinAcceso.salio =>
      'Lo que anotaste se quedó en el negocio. Para volver, un dueño tiene '
          'que invitarte otra vez.',
    MotivoSinAcceso.otroTelefono =>
      'Por seguridad, aquí se borró lo del negocio. Si fuiste tú, vuelve a '
          'entrar con tu número; lo anotado sigue guardado en tu cuenta.',
    MotivoSinAcceso.sinNegocio =>
      'Ya no tienes acceso a este negocio. Tu cuenta sigue: puedes empezar '
          'tu propio negocio o entrar a otro donde te inviten.',
  };
  static const empezarMiNegocio = 'Empezar mi propio negocio';
  static const verMisNegociosEInvitaciones = 'Ver mis negocios e invitaciones';
  static const volverAEntrarConMiNumero = 'Volver a entrar con mi número';
  static const empezarDeCeroAqui = 'Empezar de cero';
  static const salirDeMocaAqui = 'Salir de Moca en este teléfono';

  // Un teléfono sin la cuenta unida (entrega 45.1): siempre hay salida.
  static const entrarConMiCelular = 'Entrar con mi celular';
  static const entrarConMiCelularDetalle =
      'Une este teléfono a tu cuenta, o guarda lo anotado con tu número.';
  static const borrarEsteTelefono = 'Borrar todo en este teléfono';
  static const borrarEsteTelefonoDetalle =
      'Moca vuelve a empezar, como recién instalada.';
  static const borrarEsteTelefonoPregunta = '¿Borrar todo en este teléfono?';
  static const borrarEsteTelefonoTexto =
      'Se borra lo anotado en este teléfono y Moca vuelve a la bienvenida, '
      'donde puedes tocar «Ya tengo cuenta» o empezar de nuevo. No toca lo '
      'guardado en el servidor.';
  static const borrar = 'Borrar';
  static const salirDeMocaAquiDetalle =
      'Tu lugar en el negocio sigue; vuelves a entrar con tu número';
  static const salirDeMocaAquiPregunta = '¿Salir de Moca en este teléfono?';
  static const salirDeMocaAquiTexto =
      'Se borra lo de Moca en este teléfono. Lo que ya subió sigue en el '
      'negocio y vuelves a verlo al entrar con tu número.';
  static const salirDeMocaSinSenal =
      'Hay registros que todavía no suben y no hay señal. Prueba con señal '
      'para no perderlos.';
  static const salirDelNegocio = 'Salir de este negocio';
  static const salirDelNegocioDetalle =
      'Lo que anotaste se queda en el negocio';
  static const salirDelNegocioPregunta = '¿Salir de este negocio?';
  static const salirDelNegocioTexto =
      'Ya no verás ni anotarás en este negocio. Lo que anotaste se queda. '
      'Para volver, un dueño tiene que invitarte otra vez.';
  static const salisteDelNegocio = 'Listo. Saliste del negocio.';
  static const necesitasSenalParaSalir =
      'Necesitas señal para salir del negocio. No cambió nada.';

  // La huella al abrir Moca (entrega 16.3).
  static const pedirHuella = 'Pedir huella al abrir Moca';
  static const pedirHuellaDetalle =
      'Usa el bloqueo de tu teléfono: huella, rostro, patrón o PIN.';
  static const sinBloqueoEnElTelefono =
      'Primero pon un bloqueo en tu teléfono (huella, patrón o PIN).';
  static const huellaActivada = 'Listo. Moca pedirá tu huella al abrir.';
  static const huellaDesactivada = 'Listo. Moca ya no pedirá tu huella.';
  static const confirmaQueEresTu = 'Confirma que eres tú para abrir Moca';
  static const mocaProtegida = 'Moca está protegida';
  static const usarHuella = 'Usar huella';

  // «Borrar mi negocio» (entrega 16.1).
  static const borrarMiNegocio = 'Borrar mi negocio y mis datos';
  static const borrarMiNegocioDetalle =
      'Borra para siempre lo anotado y tu equipo';
  static const queSeBorra =
      'Se borra para siempre, en el servidor y en este teléfono:';
  static const seBorraLoAnotado =
      'Todo lo anotado: ventas, gastos, lo que te deben, lo que debes, '
      'arqueos y saldos.';
  static const seBorranLasFotos =
      'Las fotos de los comprobantes que leyó Moca.';
  static const seBorraElEquipo =
      'Tu equipo: las personas que invitaste ya no podrán entrar.';
  static const seGuardaElNumero =
      'Tu número de celular se guarda, sin datos, para que los días de '
      'prueba no se repitan.';
  static const antesDeBorrar =
      'No se puede deshacer. Si quieres quedarte con lo anotado, descarga '
      'antes el Excel en Informes.';
  static const borrarParaSiempre = 'Borrar para siempre';
  static const borrando = 'Borrando…';
  static const seBorroTodoEnServidor = 'Se borró todo, también en el servidor.';
  static const borrarSinSenal =
      'Necesitas señal para borrar en el servidor. No se borró nada.';
  static const borrarFallo =
      'No se pudo borrar en el servidor. No se borró nada; intenta otra vez.';
  static const confirmarBorrarTitulo = '¿Borrar todo?';
  static const confirmarBorrarTexto =
      'Se borran todos los datos guardados en este teléfono. '
      'No se puede deshacer.';
  static const cancelar = 'Cancelar';
  static const borrarTodoBoton = 'Borrar todo';
  static const seBorroTodo =
      'Se borró todo. La app quedó como recién instalada.';

  // Videos de ayuda (entrega 14.6)
  static String verComo(int segundos) => 'Ver cómo · $segundos s';
  static String primeraVez(int segundos) =>
      '¿Primera vez? Mira cómo se hace en $segundos segundos.';
  static const verVideo = 'Ver video';
  static const aprendeEnTresMinutos = 'Aprende en 3 minutos';
  static const aprendeDetalle =
      'Videos cortos, uno por cada cosa que hace Moca.';
  static String duracionVideo(int segundos) => '$segundos s';
  static const videoVisto = 'Visto';
  static const videoSinEnlace = 'Este video todavía no está listo.';
  static const videoNoSeAbrio =
      'No se pudo abrir el video. Revisa tu señal e intenta otra vez.';
  static String tituloVideo(VideoTutoria video) => switch (video) {
    VideoTutoria.queEsMoca => 'Qué es Moca',
    VideoTutoria.ventaDelDia => 'Anotar la venta del día',
    VideoTutoria.gastoConFoto => 'Anotar un gasto con foto o QR',
    VideoTutoria.avisoDeLaNoche => 'Contestar el aviso de la noche',
    VideoTutoria.arqueo => 'El arqueo del domingo',
    VideoTutoria.informe => 'Entender tu informe del mes',
    VideoTutoria.guardarAvance => 'Guardar tu avance con tu número',
  };
  static const videosSinEnlace = 'Ver los videos sin enlace';
  static const videosSinEnlaceDetalle =
      'Muestra los botones de los videos aunque todavía no estén subidos, '
      'para probarlos.';
  static const videosSinEnlaceActivado =
      'Listo. Se ven los botones de los videos.';
  static const videosSinEnlaceDesactivado =
      'Listo. Solo se ven los videos que ya tienen enlace.';
}
