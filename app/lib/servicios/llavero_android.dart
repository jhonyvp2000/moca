import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../dominio/cuenta_real.dart';

/// La llave de la cuenta, cifrada con el almacén seguro de Android.
class LlaveroAndroid implements Llavero {
  static const _almacen = FlutterSecureStorage();
  static const _clave = 'moca_llave';

  @override
  Future<String?> leer() => _almacen.read(key: _clave);

  @override
  Future<void> guardar(String llave) =>
      _almacen.write(key: _clave, value: llave);
}
