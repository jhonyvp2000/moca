import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../dominio/voz.dart';

/// Reconocimiento de voz de Android, en español de Perú (o el español que
/// tenga el teléfono). Pide el permiso del micrófono la primera vez.
class ReconocedorVozAndroid implements ReconocedorVoz {
  final _voz = SpeechToText();
  StreamController<EventoVoz>? _eventos;
  String? _idioma;

  /// Frases que ayudan al reconocimiento a entender montos y cuentas.
  static const _frasesDeAyuda = [
    'efectivo',
    'yape',
    'plin',
    'banco',
    'vendí',
    'pagué',
    'para mí',
  ];

  @override
  Future<DisponibilidadVoz> preparar() async {
    final listo = await _voz.initialize(
      onError: _alFallar,
      onStatus: _alCambiarEstado,
    );
    if (!listo) {
      return await _voz.hasPermission
          ? DisponibilidadVoz.noDisponible
          : DisponibilidadVoz.sinPermiso;
    }
    _idioma ??= await _elegirIdioma();
    return DisponibilidadVoz.disponible;
  }

  Future<String?> _elegirIdioma() async {
    final idiomas = (await _voz.locales()).map((l) => l.localeId).toList();
    for (final preferido in ['es_PE', 'es-PE', 'es_419', 'es-419', 'es_US']) {
      if (idiomas.contains(preferido)) return preferido;
    }
    return idiomas.firstWhere(
      (id) => id.startsWith('es'),
      orElse: () => 'es_PE',
    );
  }

  @override
  Stream<EventoVoz> escuchar() {
    _eventos?.close();
    final eventos = StreamController<EventoVoz>();
    _eventos = eventos;
    _voz.listen(
      onResult: _alReconocer,
      listenOptions: SpeechListenOptions(
        localeId: _idioma,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 30),
        contextualPhrases: _frasesDeAyuda,
      ),
    );
    return eventos.stream;
  }

  void _alReconocer(SpeechRecognitionResult resultado) {
    final eventos = _eventos;
    if (eventos == null || eventos.isClosed) return;
    if (!resultado.finalResult) {
      eventos.add(VozParcial(resultado.recognizedWords));
      return;
    }
    eventos
      ..add(
        VozFinal([
          for (final a in resultado.alternates)
            AlternativaVoz(
              a.recognizedWords,
              a.hasConfidenceRating ? a.confidence : null,
            ),
        ]),
      )
      ..close();
  }

  void _alFallar(SpeechRecognitionError error) {
    final eventos = _eventos;
    if (eventos == null || eventos.isClosed) return;
    final motivo = switch (error.errorMsg) {
      'error_permission' ||
      'error_insufficient_permissions' => FalloVoz.sinPermiso,
      'error_no_match' || 'error_speech_timeout' => FalloVoz.nadaQueEscuchar,
      _ => FalloVoz.noDisponible,
    };
    eventos
      ..add(VozFallida(motivo))
      ..close();
  }

  void _alCambiarEstado(String estado) {
    // Si terminó sin resultado final, no se escuchó nada.
    if (estado == SpeechToText.doneStatus) {
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        final eventos = _eventos;
        if (eventos != null && !eventos.isClosed) {
          eventos
            ..add(const VozFallida(FalloVoz.nadaQueEscuchar))
            ..close();
        }
      });
    }
  }

  @override
  Future<void> detener() => _voz.stop();
}
