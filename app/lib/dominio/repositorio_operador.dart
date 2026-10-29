import 'modelos.dart';

/// Lo que necesita el ajuste oculto del operador de la prueba.
abstract interface class RepositorioOperador {
  /// Cuántos registros hay guardados en el teléfono, sumando todas las tablas.
  Future<int> contarRegistros();

  /// Borra todos los datos del teléfono y deja la app como recién instalada.
  Future<void> borrarTodo();

  /// Muestra el Inicio completo (S04) sin esperar la primera semana.
  Future<void> saltarPrimeraSemana();

  /// Muestra en el Inicio la tarjeta del arqueo sin esperar al domingo.
  Future<void> pedirArqueo();

  /// Borra todo y carga diez semanas de una bodega de ejemplo.
  Future<void> cargarDemo();

  /// Si la app está mostrando la Demo.
  Stream<bool> observarDemo();

  /// Simular otra persona con un solo teléfono (entrega 20.1): el teléfono
  /// se ve como el rol elegido; nulo vuelve a lo real. No toca el servidor.
  Future<void> verComo(Rol? rol);

  /// El rol con que se está viendo la app; nulo si no se simula.
  Stream<Rol?> observarVerComo();

  /// Agrega en este teléfono una venta de «Pepe», como si viniera de otro
  /// teléfono del negocio. No se sube.
  Future<void> simularVentaDeOtro();

  /// Vuelve a lo real: quita la venta simulada y el «Ver como».
  Future<void> salirDeLaSimulacion();
}
