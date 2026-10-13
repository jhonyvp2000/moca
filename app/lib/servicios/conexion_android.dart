import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../dominio/conexion.dart';

/// Si el teléfono tiene wifi o datos. No comprueba que haya internet: en el
/// prototipo solo sirve para la marca «por subir».
class ConexionAndroid implements Conexion {
  final _conectividad = Connectivity();

  static bool _conectado(List<ConnectivityResult> r) =>
      r.any((x) => x != ConnectivityResult.none);

  @override
  Future<bool> hayConexion() async {
    try {
      return _conectado(await _conectividad.checkConnectivity());
    } on Exception {
      // Si no se puede saber, no se marca nada como por subir.
      return true;
    }
  }

  @override
  Stream<bool> observar() async* {
    yield await hayConexion();
    try {
      yield* _conectividad.onConnectivityChanged.map(_conectado);
    } on Exception {
      return;
    }
  }
}

/// «Simular sin señal», del ajuste oculto del operador.
class ConexionSimuladaSinSenal implements Conexion {
  const ConexionSimuladaSinSenal();

  @override
  Future<bool> hayConexion() async => false;

  @override
  Stream<bool> observar() => Stream.value(false);
}
