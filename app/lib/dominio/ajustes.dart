/// Preferencias sueltas de la app que se guardan en el teléfono.
abstract interface class RepositorioAjustes {
  /// Si ya se explicó para qué se usa el micrófono.
  Future<bool> microfonoExplicado();

  Future<void> marcarMicrofonoExplicado();

  /// Si una sección plegada quedó abierta en este teléfono (entrega 59).
  Future<bool> seccionAbierta(String clave);

  Future<void> guardarSeccion(String clave, {required bool abierta});
}
