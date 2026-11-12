/// Preferencias sueltas de la app que se guardan en el teléfono.
abstract interface class RepositorioAjustes {
  /// Si ya se explicó para qué se usa el micrófono.
  Future<bool> microfonoExplicado();

  Future<void> marcarMicrofonoExplicado();

  /// Si una sección plegada quedó abierta en este teléfono (entrega 59).
  /// Sin nada guardado, [porDefecto] (entrega 64: las cuentas del Inicio
  /// empiezan abiertas).
  Future<bool> seccionAbierta(String clave, {bool porDefecto = false});

  Future<void> guardarSeccion(String clave, {required bool abierta});
}
