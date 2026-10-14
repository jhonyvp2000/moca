import 'package:share_plus/share_plus.dart';

import '../dominio/servicios.dart';

class CompartidorAndroid implements Compartidor {
  @override
  Future<void> compartirArchivo(
    String ruta, {
    required String asunto,
    String tipo = 'application/pdf',
  }) => SharePlus.instance.share(
    ShareParams(
      files: [XFile(ruta, mimeType: tipo)],
      subject: asunto,
      title: asunto,
    ),
  );
}
