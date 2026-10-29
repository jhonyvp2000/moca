/// Al pedir el código por SMS (S01).
enum ResultadoPedido { enviado, sinSenal, demasiados, invalido, error }

/// Borrar todo, también en el servidor (entrega 14.8).
enum ResultadoBorrado { listo, sinSenal, sinCuenta, error }

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

  /// Para «Me invitaron»: el número no tiene una invitación vigente
  /// (entrega 19).
  sinInvitacion,
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

  /// Un dueño lo quitó del negocio: este teléfono ya no sube ni baja nada
  /// de ese negocio (entrega 18). Lo que anotó se queda allá.
  fueraDelNegocio,
}

class SituacionCuenta {
  const SituacionCuenta({
    required this.estado,
    this.celular,
    this.mostrarTarjeta = false,
    this.actualizadoEn,
    this.variasPersonas = false,
  });

  final EstadoCuenta estado;

  /// Los 9 dígitos, si ya los escribió.
  final String? celular;

  /// La tarjeta de la pestaña Moca: al confirmar el número, o a los tres
  /// días de seguir sin cuenta.
  final bool mostrarTarjeta;

  /// La última vez que bajó lo de los demás (entrega 18).
  final DateTime? actualizadoEn;

  /// Si en el negocio hay más de una persona: entonces el Inicio dice
  /// cuándo se actualizó.
  final bool variasPersonas;
}

/// La cuenta real del dueño (docs/v1-real.md, entrega 11).
abstract interface class ServicioCuenta {
  Future<ResultadoPedido> pedirCodigo(String celular);

  /// Si el código es correcto, guarda la llave del teléfono. No sube nada:
  /// para eso está [subirTodo]. Con [entrar] («Ya tengo cuenta»), no crea
  /// cuentas y después se baja todo con [bajarTodo].
  ///
  /// Con [invitado] («Me invitaron», entrega 19), entra quien tiene una
  /// invitación; después la acepta y baja lo del negocio.
  Future<ResultadoVerificacion> verificar(
    String celular,
    String codigo, {
    bool entrar = false,
    bool invitado = false,
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

  /// Borra para siempre en el servidor el negocio de esta cuenta y las
  /// fotos leídas; el número queda sin datos (entrega 14.8). No toca el
  /// teléfono: eso lo hace quien llama, solo si salió bien.
  Future<ResultadoBorrado> borrarEnElServidor();

  Stream<SituacionCuenta> observar();

  /// Sube lo anotado o cambiado que el servidor todavía no tiene (desde la
  /// entrega 18, solo eso). Devuelve si se subió; si no, se reintenta
  /// después. Repetirlo no duplica nada.
  Future<bool> subirTodo();

  /// Si hay algo anotado o cambiado que el servidor todavía no tiene.
  Future<bool> hayCambiosSinSubir();

  /// Baja lo nuevo que anotaron los demás desde la última vez (entrega 18).
  /// Lo que este teléfono todavía no subió no se pisa. Devuelve si bajó
  /// algo.
  Future<bool> traerCambios();

  /// Pide al servidor las cifras de lo que ya tiene, si las del teléfono no
  /// valen (otro día o algo cambió). Con algo por subir no hace nada: las
  /// cifras llegan con la subida (entrega 13).
  Future<void> actualizarCifras();
}

/// Lee solo el SMS del código, sin permiso para leer los mensajes (SMS
/// Retriever de Android, entrega 14.7). Android entrega a Moca solo el SMS
/// que termina con la marca de la app.
abstract interface class LectorCodigoSms {
  /// La marca de 11 caracteres de la app; nula si el teléfono no puede
  /// leer el SMS (por ejemplo, sin los servicios de Google).
  Future<String?> marca();

  /// Empieza a esperar el SMS, 5 minutos como máximo.
  Future<void> esperar();

  /// Los códigos de 6 dígitos que llegan por SMS.
  Stream<String> get codigos;

  Future<void> dejarDeEsperar();
}

/// Para cuando no se puede leer el SMS: el dueño escribe el código.
class SinLectorSms implements LectorCodigoSms {
  const SinLectorSms();

  @override
  Future<String?> marca() async => null;

  @override
  Future<void> esperar() async {}

  @override
  Stream<String> get codigos => const Stream.empty();

  @override
  Future<void> dejarDeEsperar() async {}
}

/// Donde el teléfono guarda la llave de su cuenta, cifrada.
abstract interface class Llavero {
  Future<String?> leer();
  Future<void> guardar(String llave);
}
