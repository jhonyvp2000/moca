/// Al pedir el código por SMS (S01).
enum ResultadoPedido { enviado, sinSenal, demasiados, invalido, error }

/// Al escribir el código.
enum ResultadoVerificacion {
  verificado,
  incorrecto,
  vencido,
  sinSenal,

  /// El número ya tiene cuenta desde otro teléfono: no se mezclan los datos
  /// (la recuperación llega en la entrega 12).
  otraCuenta,
  error,
}

enum EstadoCuenta {
  /// Siguió con «Ahora no»: lo anotado vive solo en el teléfono.
  sinCuenta,

  /// Pasó por «Guarda tu avance» en el prototipo, donde el código era de
  /// prueba: falta confirmar el número de verdad.
  porConfirmar,

  /// El número está verificado y lo anotado se sube al servidor.
  guardada,
}

class SituacionCuenta {
  const SituacionCuenta({
    required this.estado,
    this.celular,
    this.mostrarTarjeta = false,
  });

  final EstadoCuenta estado;

  /// Los 9 dígitos, si ya los escribió.
  final String? celular;

  /// La tarjeta de la pestaña Moca: al confirmar el número, o a los tres
  /// días de seguir sin cuenta.
  final bool mostrarTarjeta;
}

/// La cuenta real del dueño (docs/v1-real.md, entrega 11).
abstract interface class ServicioCuenta {
  Future<ResultadoPedido> pedirCodigo(String celular);

  /// Si el código es correcto, guarda la llave del teléfono. No sube nada:
  /// para eso está [subirTodo].
  Future<ResultadoVerificacion> verificar(String celular, String codigo);

  Stream<SituacionCuenta> observar();

  /// Sube todo lo anotado. Devuelve si se subió; si no, se reintenta
  /// después. Repetirlo no duplica nada.
  Future<bool> subirTodo();

  /// Si hay algo anotado o cambiado que el servidor todavía no tiene.
  Future<bool> hayCambiosSinSubir();
}

/// Donde el teléfono guarda la llave de su cuenta, cifrada.
abstract interface class Llavero {
  Future<String?> leer();
  Future<void> guardar(String llave);
}
