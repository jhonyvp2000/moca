/// Al pedir el código por SMS (S01).
enum ResultadoPedido { enviado, sinSenal, demasiados, invalido, error }

/// Al escribir el código.
enum ResultadoVerificacion {
  verificado,
  incorrecto,
  vencido,
  sinSenal,

  /// El número ya tiene cuenta desde otro teléfono y este teléfono tiene sus
  /// propios datos: no se mezclan.
  otraCuenta,

  /// Para entrar («Ya tengo cuenta»): el número no tiene una cuenta con
  /// datos.
  sinCuenta,
  error,
}

/// Al bajar los datos de la cuenta a este teléfono (entrega 12).
enum ResultadoBajada { listo, sinSenal, error }

enum EstadoCuenta {
  /// Siguió con «Ahora no»: lo anotado vive solo en el teléfono.
  sinCuenta,

  /// Pasó por «Guarda tu avance» en el prototipo, donde el código era de
  /// prueba: falta confirmar el número de verdad.
  porConfirmar,

  /// El número está verificado y lo anotado se sube al servidor.
  guardada,

  /// La cuenta se abrió en otro teléfono: este ya no sube nada (un teléfono
  /// por cuenta, entrega 12).
  cerradaEnOtro,
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
  /// para eso está [subirTodo]. Con [entrar] («Ya tengo cuenta»), no crea
  /// cuentas y después se baja todo con [bajarTodo].
  Future<ResultadoVerificacion> verificar(
    String celular,
    String codigo, {
    bool entrar = false,
  });

  /// Reemplaza lo del teléfono por lo de la cuenta (el teléfono está en la
  /// Bienvenida: no tiene datos propios).
  Future<ResultadoBajada> bajarTodo();

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
