/// Si el teléfono tiene señal. En el prototipo no hay servidor: solo sirve
/// para marcar «por subir» lo que se guarda sin conexión.
abstract interface class Conexion {
  Future<bool> hayConexion();

  /// Se emite al empezar y cada vez que cambia.
  Stream<bool> observar();
}
