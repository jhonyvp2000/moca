import 'package:url_launcher/url_launcher.dart';

import '../dominio/tutoria.dart';

/// Abre el video en la app de YouTube o, si no la tiene, en el navegador.
class AbridorAndroid implements AbridorDeEnlaces {
  @override
  Future<bool> abrir(String enlace) async {
    try {
      return await launchUrl(
        Uri.parse(enlace),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      return false;
    }
  }
}
