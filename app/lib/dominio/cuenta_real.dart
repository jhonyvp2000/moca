/// Al pedir el código por SMS (S01).
enum ResultadoPedido { enviado, sinSenal, demasiados, invalido, error }

/// Al escribir el código.
enum ResultadoVerificacion {
  verificado,
  incorrecto,
  vencido,
  sinSenal,

  /// El número ya tiene cuenta y este teléfono tiene sus propios datos: el
  /// dueño elige entrar y sumarlos, empezar de cero o seguir sin cuenta
  /// (entrega 14.4).
  otraCuenta,

  /// Para entrar («Ya tengo cuenta»): el número no tiene una cuenta con
  /// datos.
  sinCuenta,
  error,
}

/// Al bajar los datos de la cuenta a este teléfono (entrega 12). Vencido:
/// pasó mucho tiempo desde el código y hay que pedir otro (entrega 14.4).
enum ResultadoBajada { listo, sinSenal, vencido, error }

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

  /// Tras [ResultadoVerificacion.otraCuenta]: entra a la cuenta del número,
  /// baja lo que tiene y le suma lo anotado en este teléfono (entrega 14.4).
  Future<ResultadoBajada> entrarYSumar();

  /// Tras [ResultadoVerificacion.otraCuenta]: la cuenta anterior se archiva
  /// en el servidor (no se borra) y el número pasa a este teléfono con lo
  /// que tiene. Al verificarse, sigue como cualquier cuenta nueva.
  Future<ResultadoVerificacion> empezarDeCero();

  Stream<SituacionCuenta> observar();

  /// Sube todo lo anotado. Devuelve si se subió; si no, se reintenta
  /// después. Repetirlo no duplica nada.
  Future<bool> subirTodo();

  /// Si hay algo anotado o cambiado que el servidor todavía no tiene.
  Future<bool> hayCambiosSinSubir();

  /// Pide al servidor las cifras de lo que ya tiene, si las del teléfono no
  /// valen (otro día o algo cambió). Con algo por subir no hace nada: las
  /// cifras llegan con la subida (entrega 13).
  Future<void> actualizarCifras();
}

/// Donde el teléfono guarda la llave de su cuenta, cifrada.
abstract interface class Llavero {
  Future<String?> leer();
  Future<void> guardar(String llave);
}
