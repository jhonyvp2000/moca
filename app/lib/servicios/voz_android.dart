import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../dominio/voz.dart';

/// Reconocimiento de voz de Android, en español de Perú (o el español que
/// tenga el teléfono). Pide el permiso del micrófono la primera vez.
class ReconocedorVozAndroid implements ReconocedorVoz {
  final _voz = SpeechToText();
  SesionDeEscucha? _sesion;
  String? _idioma;

  /// Frases que ayudan al reconocimiento a entender montos y cuentas.
  static const _frasesDeAyuda = [
    'efectivo',
    'yape',
    'plin',
    'sip',
    'interbank',
    'bbva',
    'scotiabank',
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
    _sesion?.cancelar();
    final sesion = SesionDeEscucha();
    _sesion = sesion;
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
    return sesion.eventos;
  }

  void _alReconocer(SpeechRecognitionResult resultado) {
    final sesion = _sesion;
    if (sesion == null) return;
    if (!resultado.finalResult) {
      sesion.alParcial(resultado.recognizedWords);
      return;
    }
    sesion.alFinal([
      for (final a in resultado.alternates)
        AlternativaVoz(
          a.recognizedWords,
          a.hasConfidenceRating ? a.confidence : null,
        ),
    ], resultado.recognizedWords);
  }

  void _alFallar(SpeechRecognitionError error) {
    _sesion?.alFallar(switch (error.errorMsg) {
      'error_permission' ||
      'error_insufficient_permissions' => FalloVoz.sinPermiso,
      'error_no_match' || 'error_speech_timeout' => FalloVoz.nadaQueEscuchar,
      _ => FalloVoz.noDisponible,
    });
  }

  void _alCambiarEstado(String estado) {
    if (estado == SpeechToText.doneStatus) _sesion?.alTerminar();
  }

  @override
  Future<void> detener() => _voz.stop();
}

/// Una grabación: junta lo que Android va avisando y entrega un solo final.
///
/// Muchos teléfonos avisan «terminé» o un error (`error_no_match`,
/// `error_client`) antes del resultado final, o en lugar de él, aunque ya
/// mostraron la frase entera como resultado parcial. En esos casos se espera
/// un momento al final y, si no llega, se usa lo último que se oyó: el dueño
/// igual lo revisa antes de guardar.
class SesionDeEscucha {
  SesionDeEscucha({this.espera = const Duration(milliseconds: 1200)});

  final Duration espera;
  final _eventos = StreamController<EventoVoz>();
  String _ultimoParcial = '';
  Timer? _reloj;

  Stream<EventoVoz> get eventos => _eventos.stream;

  void alParcial(String texto) {
    if (_eventos.isClosed) return;
    if (texto.trim().isNotEmpty) _ultimoParcial = texto;
    _eventos.add(VozParcial(texto));
  }

  void alFinal(List<AlternativaVoz> alternativas, String palabras) {
    final validas = [
      for (final a in alternativas)
        if (a.texto.trim().isNotEmpty) a,
    ];
    if (validas.isEmpty && palabras.trim().isNotEmpty) {
      validas.add(AlternativaVoz(palabras));
    }
    if (validas.isEmpty) {
      // Un final vacío después de oír algo: vale lo último que se oyó.
      _cerrar(_conLoOido(FalloVoz.nadaQueEscuchar));
      return;
    }
    _cerrar(VozFinal(validas));
  }

  void alFallar(FalloVoz motivo) {
    if (motivo == FalloVoz.sinPermiso || _ultimoParcial.isEmpty) {
      _cerrar(VozFallida(motivo));
      return;
    }
    _esperarFinal(motivo);
  }

  /// Android dejó de escuchar; el final puede llegar un poco después.
  void alTerminar() => _esperarFinal(FalloVoz.nadaQueEscuchar);

  void cancelar() {
    _reloj?.cancel();
    if (!_eventos.isClosed) _eventos.close();
  }

  void _esperarFinal(FalloVoz motivo) {
    _reloj ??= Timer(espera, () => _cerrar(_conLoOido(motivo)));
  }

  EventoVoz _conLoOido(FalloVoz motivo) => _ultimoParcial.isEmpty
      ? VozFallida(motivo)
      : VozFinal([AlternativaVoz(_ultimoParcial)]);

  void _cerrar(EventoVoz evento) {
    _reloj?.cancel();
    if (_eventos.isClosed) return;
    _eventos
      ..add(evento)
      ..close();
  }
}
