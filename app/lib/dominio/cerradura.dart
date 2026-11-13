/// El bloqueo del teléfono (huella, rostro, patrón o PIN), para que Moca
/// lo pida al abrir (entrega 16.3). Moca no guarda la huella: Android la
/// revisa y solo dice si es la persona del teléfono.
abstract interface class Cerradura {
  /// Falso si el teléfono no tiene ningún bloqueo configurado.
  Future<bool> puedeUsarse();

  /// Verdadero si la persona pasó. Si falla, la cancela o algo sale mal,
  /// falso: Moca sigue cerrada y se puede reintentar.
  Future<bool> verificar(String motivo);
}
