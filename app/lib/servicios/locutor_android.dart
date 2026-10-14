import 'package:flutter_tts/flutter_tts.dart';

import '../dominio/servicios.dart';

/// La voz sintética del teléfono, en español (de Perú si existe).
class LocutorAndroid implements Locutor {
  final _tts = FlutterTts();
  bool? _listo;

  static const _idiomas = ['es-PE', 'es-US', 'es-419', 'es-MX', 'es-ES'];

  Future<bool> _preparar() async {
    if (_listo != null) return _listo!;
    try {
      for (final idioma in _idiomas) {
        if (await _tts.isLanguageAvailable(idioma) == true) {
          await _tts.setLanguage(idioma);
          await _tts.setSpeechRate(0.5);
          await _tts.awaitSpeakCompletion(true);
          return _listo = true;
        }
      }
    } on Exception {
      // Sin motor de voz: se lee en pantalla.
    }
    return _listo = false;
  }

  @override
  Future<bool> disponible() => _preparar();

  @override
  Future<void> decir(String texto) async {
    if (!await _preparar()) return;
    await _tts.speak(texto);
  }

  @override
  Future<void> detener() async {
    try {
      await _tts.stop();
    } on Exception {
      return;
    }
  }
}
