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
  static String registrarLlegaEnEntrega(int n) =>
      'Registrar llega en la entrega $n.';
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
  static const empezarDemo = 'Empezar en «Demo»';
  static const forzarFotoIlegible = 'Forzar «foto ilegible»';
  static const elegirFrase = 'Elegir frase de ejemplo para la voz';
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
