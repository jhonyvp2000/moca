import 'package:local_auth/local_auth.dart';

import '../dominio/cerradura.dart';

/// La huella o el bloqueo del teléfono, con el paquete oficial de Flutter.
class CerraduraAndroid implements Cerradura {
  final _autenticacion = LocalAuthentication();

  @override
  Future<bool> puedeUsarse() async {
    try {
      return await _autenticacion.isDeviceSupported();
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> verificar(String motivo) async {
    try {
      // Sin «solo huella»: si no hay huella o falla, sirve el PIN o el
      // patrón del teléfono. Nunca deja a la persona fuera de sus datos.
      return await _autenticacion.authenticate(localizedReason: motivo);
    } on Exception {
      return false;
    }
  }
}
