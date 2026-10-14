import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../dominio/comprobantes.dart';

/// La cámara del teléfono. La foto se copia a la carpeta de la app, junto a
/// los demás comprobantes.
class CamaraAndroid implements Camara {
  final _selector = ImagePicker();

  @override
  Future<ResultadoCamara> tomarFoto() async {
    try {
      final foto = await _selector.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 75,
      );
      if (foto == null) return const FotoCancelada();
      final carpeta = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/comprobantes',
      );
      await carpeta.create(recursive: true);
      final destino = '${carpeta.path}/${const Uuid().v4()}.jpg';
      await File(foto.path).copy(destino);
      return FotoTomada(destino);
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') return const CamaraSinPermiso();
      rethrow;
    }
  }
}
