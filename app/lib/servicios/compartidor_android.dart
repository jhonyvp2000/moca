import 'package:share_plus/share_plus.dart';

import '../dominio/servicios.dart';

class CompartidorAndroid implements Compartidor {
  @override
  Future<void> compartirArchivo(String ruta, {required String asunto}) =>
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(ruta, mimeType: 'application/pdf')],
          subject: asunto,
          title: asunto,
        ),
      );
}
