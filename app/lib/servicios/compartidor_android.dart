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

  @override
  Future<void> compartirArchivos(
    List<(String ruta, String tipo)> archivos, {
    required String asunto,
  }) => SharePlus.instance.share(
    ShareParams(
      files: [for (final (ruta, tipo) in archivos) XFile(ruta, mimeType: tipo)],
      subject: asunto,
      title: asunto,
    ),
  );
}
