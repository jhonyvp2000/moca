import '../../dominio/medicion.dart';
import '../../dominio/tutoria.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';
import 'medicion_local.dart';

/// Lo visto se guarda en los ajustes del teléfono (también en la Demo); la
/// medición, aparte (entrega 14.6).
class RepositorioTutoriaLocal implements RepositorioTutoria {
  RepositorioTutoriaLocal(BaseLocal base, {DateTime Function()? ahora})
    : _a = AccesoLocal(base, ahora ?? DateTime.now),
      _medicion = MedicionLocal(base, ahora: ahora);

  final AccesoLocal _a;
  final Medicion _medicion;

  static const claveVistos = 'videos_vistos';
  static const claveTarjetasCerradas = 'videos_tarjetas_cerradas';

  Future<Set<VideoTutoria>> _leer(String clave) async => {
    for (final n in (await _a.leerAjuste(clave) ?? '').split(','))
      ?VideoTutoria.porNumero(int.tryParse(n) ?? 0),
  };

  Future<void> _sumar(String clave, VideoTutoria video) async {
    final videos = await _leer(clave);
    if (!videos.add(video)) return;
    final numeros = [for (final v in videos) v.numero]..sort();
    await _a.guardarAjuste(clave, numeros.join(','));
  }

  @override
  Stream<EstadoTutoria> observar() => _a.cambios().asyncMap(
    (_) async => EstadoTutoria(
      vistos: await _leer(claveVistos),
      tarjetasCerradas: await _leer(claveTarjetasCerradas),
    ),
  );

  @override
  Future<void> marcarVisto(VideoTutoria video, DesdeVideo desde) async {
    await _sumar(claveVistos, video);
    await _sumar(claveTarjetasCerradas, video);
    await _medicion.anotar(EventoMedicion.videoAbierto, {
      'video': video.numero,
      'desde': desde.name,
    });
  }

  @override
  Future<void> cerrarTarjeta(VideoTutoria video) =>
      _sumar(claveTarjetasCerradas, video);
}
