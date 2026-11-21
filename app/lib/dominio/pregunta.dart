// «Pregúntale a Moca» (entrega 74): el dueño pregunta por su negocio y la
// IA responde con las cifras que el servidor ya calculó.

/// A qué pantalla lleva una respuesta.
enum EnlaceRespuesta { historial, teDeben, debes, informe, cuentas, misPagos }

/// Por qué no hubo respuesta.
enum ErrorDePregunta { sinSenal, topeDelDia, noDisponible, soloDuenos, fallo }

class RespuestaDeMoca {
  const RespuestaDeMoca({required this.texto, this.enlace});

  final String texto;
  final EnlaceRespuesta? enlace;
}

typedef ResultadoPregunta = ({
  RespuestaDeMoca? respuesta,
  ErrorDePregunta? error,

  /// Cuántas preguntas le quedan hoy al negocio, si se sabe.
  int? quedan,
});

abstract interface class ServicioPregunta {
  /// Cuántas preguntas quedan hoy; nulo sin señal.
  Future<int?> preguntasQueQuedan();

  /// Sube lo que falta y pregunta, con las últimas [anteriores] de la
  /// conversación para que Moca entienda «¿y el martes?» (entrega 90).
  Future<ResultadoPregunta> preguntar(
    String pregunta, {
    List<Intercambio> anteriores = const [],
  });
}

/// Una pregunta con lo que respondió Moca y cuándo (entrega 90).
class Intercambio {
  const Intercambio({
    required this.pregunta,
    required this.respuesta,
    required this.cuando,
  });

  final String pregunta;
  final RespuestaDeMoca respuesta;
  final DateTime cuando;

  Map<String, Object?> aJson() => {
    'pregunta': pregunta,
    'respuesta': respuesta.texto,
    'enlace': respuesta.enlace?.name,
    'cuando': cuando.toIso8601String(),
  };

  static Intercambio? desdeJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final pregunta = json['pregunta'];
    final texto = json['respuesta'];
    final cuando = DateTime.tryParse('${json['cuando']}');
    if (pregunta is! String || texto is! String || cuando == null) return null;
    return Intercambio(
      pregunta: pregunta,
      respuesta: RespuestaDeMoca(
        texto: texto,
        enlace: EnlaceRespuesta.values.asNameMap()[json['enlace']],
      ),
      cuando: cuando,
    );
  }
}

/// La conversación con Moca, guardada en el teléfono (entrega 90): las
/// últimas [maximo], de un solo negocio. Al cambiar de negocio empieza vacía.
abstract interface class ConversacionConMoca {
  static const maximo = 20;

  /// Cuántas anteriores se mandan con cada pregunta.
  static const queRecuerda = 4;

  Future<List<Intercambio>> leer();
  Future<void> agregar(Intercambio intercambio);
  Future<void> borrar();
}
