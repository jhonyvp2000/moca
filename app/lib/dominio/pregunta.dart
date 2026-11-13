// «Pregúntale a Moca» (entrega 74): el dueño pregunta por su negocio y la
// IA responde con las cifras que el servidor ya calculó.

/// A qué pantalla lleva una respuesta.
enum EnlaceRespuesta { historial, teDeben, debes, informe, cuentas }

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

  /// Sube lo que falta y pregunta.
  Future<ResultadoPregunta> preguntar(String pregunta);
}
