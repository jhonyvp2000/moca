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
