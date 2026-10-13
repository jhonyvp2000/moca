/// La voz sintética del teléfono, para escuchar el resumen de la semana.
abstract interface class Locutor {
  /// Falso si el teléfono no tiene voz en español.
  Future<bool> disponible();

  /// Lee el texto; el futuro termina cuando acaba de hablar o se detiene.
  Future<void> decir(String texto);

  Future<void> detener();
}

/// Comparte un archivo con el menú de Android (WhatsApp, correo…).
abstract interface class Compartidor {
  Future<void> compartirArchivo(String ruta, {required String asunto});
}
