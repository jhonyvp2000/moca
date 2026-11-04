import 'dart:io' show Platform;

/// «Hay una versión nueva de Moca» (entrega 26.3).

/// La versión instalada. GitHub la pone al armar el APK; en un armado local
/// el armado es 0 y nunca se avisa nada.
class VersionInstalada {
  const VersionInstalada({
    required this.entrega,
    required this.armado,
    required this.commit,
    required this.esArm64,
  });

  factory VersionInstalada.delArmado() => VersionInstalada(
    entrega: const String.fromEnvironment('MOCA_ENTREGA'),
    armado: const int.fromEnvironment('MOCA_ARMADO'),
    commit: const String.fromEnvironment('MOCA_COMMIT'),
    // «android_arm64» en los teléfonos de hoy; «android_arm» en los antiguos.
    esArm64: !Platform.version.contains('android_arm"'),
  );

  /// «entrega-26.3» o «piloto-2»; vacío en un armado local.
  final String entrega;

  /// El número de armado de GitHub: crece con cada APK.
  final int armado;
  final String commit;
  final bool esArm64;

  bool get conocida => armado > 0;
}

/// Lo último publicado, según el servidor.
class VersionPublicada {
  const VersionPublicada({
    required this.nombre,
    required this.armado,
    this.arm64,
    this.v7a,
  });

  final String nombre;
  final int armado;
  final String? arm64;
  final String? v7a;
}

class EstadoDeVersion {
  const EstadoDeVersion({this.ultima, this.minima});

  final VersionPublicada? ultima;

  /// Con un armado menor, hay que actualizar sí o sí.
  final int? minima;

  /// Hay una más nueva que la instalada.
  bool hayNueva(VersionInstalada instalada) =>
      instalada.conocida && (ultima?.armado ?? 0) > instalada.armado;

  bool obligatoria(VersionInstalada instalada) =>
      instalada.conocida &&
      minima != null &&
      instalada.armado < minima! &&
      enlace(instalada) != null;

  /// El APK que le toca a este teléfono.
  String? enlace(VersionInstalada instalada) =>
      (instalada.esArm64 ? ultima?.arm64 : ultima?.v7a) ?? ultima?.arm64;
}

abstract interface class ServicioVersion {
  /// Nulo sin señal. Con [todas], también las «entrega-N» (para Jhony).
  Future<EstadoDeVersion?> buscarVersion({required bool todas});
}
