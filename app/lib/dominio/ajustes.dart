/// Preferencias sueltas de la app que se guardan en el teléfono.
abstract interface class RepositorioAjustes {
  /// Si ya se explicó para qué se usa el micrófono.
  Future<bool> microfonoExplicado();

  Future<void> marcarMicrofonoExplicado();
}
