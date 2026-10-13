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
}
