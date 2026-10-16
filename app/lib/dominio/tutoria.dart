/// Los videos cortos de ayuda (docs/guiones-videos.md, entrega 14.6). Se
/// ven en el momento en que hacen falta y en «Aprende en 3 minutos».
enum VideoTutoria {
  queEsMoca(1, 30),
  ventaDelDia(2, 20),
  gastoConFoto(3, 25),
  avisoDeLaNoche(4, 15),
  arqueo(5, 30),
  informe(6, 25),
  guardarAvance(7, 20);

  const VideoTutoria(this.numero, this.segundos);

  /// El número del guion.
  final int numero;
  final int segundos;

  static VideoTutoria? porNumero(int numero) {
    for (final v in values) {
      if (v.numero == numero) return v;
    }
    return null;
  }
}

/// Los enlaces de YouTube («No listado») que pasa Jhony al subir cada video.
/// Un video sin enlace no aparece en la app.
const enlacesDeVideos = <VideoTutoria, String>{};

/// Desde dónde se abrió un video, para la medición.
enum DesdeVideo { pasos, primeraVez, aprende, guardarAvance, permisoAvisos }

class EstadoTutoria {
  const EstadoTutoria({
    this.vistos = const {},
    this.tarjetasCerradas = const {},
    this.enlaces = const {},
    this.sinEnlace = false,
  });

  final Set<VideoTutoria> vistos;

  /// Las tarjetas «¿Primera vez?» que ya se cerraron.
  final Set<VideoTutoria> tarjetasCerradas;

  final Map<VideoTutoria, String> enlaces;

  /// Ajuste del operador: mostrar los videos aunque no tengan enlace, para
  /// probar los botones. Dura mientras la app esté abierta.
  final bool sinEnlace;

  EstadoTutoria con({
    required Map<VideoTutoria, String> enlaces,
    required bool sinEnlace,
  }) => EstadoTutoria(
    vistos: vistos,
    tarjetasCerradas: tarjetasCerradas,
    enlaces: enlaces,
    sinEnlace: sinEnlace,
  );

  bool disponible(VideoTutoria video) =>
      enlaces.containsKey(video) || sinEnlace;

  bool get algunoDisponible => VideoTutoria.values.any(disponible);
}

abstract interface class RepositorioTutoria {
  Stream<EstadoTutoria> observar();

  /// Marca el video como visto, cierra su tarjeta «¿Primera vez?» y lo
  /// anota en la medición.
  Future<void> marcarVisto(VideoTutoria video, DesdeVideo desde);

  Future<void> cerrarTarjeta(VideoTutoria video);
}

/// Abre un enlace fuera de la app (YouTube o el navegador).
abstract interface class AbridorDeEnlaces {
  /// Falso si el teléfono no pudo abrirlo.
  Future<bool> abrir(String enlace);
}
