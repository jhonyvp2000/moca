import 'dart:io' show Platform;

/// «Hay una versión nueva de Moca» (entrega 26.3).

/// Por dónde llegó Moca al teléfono (entrega 77): el APK de Releases o la
/// Play Store. En la de Play no se nombran Mercado Pago ni el Yape para
/// pagar el plan, ni se descarga un APK: Play cobra y actualiza.
enum Canal { apk, play }

/// La versión instalada. GitHub la pone al armar el APK; en un armado local
/// el armado es 0 y nunca se avisa nada.
class VersionInstalada {
  const VersionInstalada({
    required this.entrega,
    required this.armado,
    required this.commit,
    required this.esArm64,
    this.canal = Canal.apk,
  });

  factory VersionInstalada.delArmado() => VersionInstalada(
    entrega: const String.fromEnvironment('MOCA_ENTREGA'),
    armado: const int.fromEnvironment('MOCA_ARMADO'),
    commit: const String.fromEnvironment('MOCA_COMMIT'),
    // «android_arm64» en los teléfonos de hoy; «android_arm» en los antiguos.
    esArm64: !Platform.version.contains('android_arm"'),
    canal: const String.fromEnvironment('MOCA_CANAL') == 'play'
        ? Canal.play
        : Canal.apk,
  );

  /// «entrega-26.3» o «piloto-2»; vacío en un armado local.
  final String entrega;

  /// El número de armado de GitHub: crece con cada APK.
  final int armado;
  final String commit;
  final bool esArm64;
  final Canal canal;

  bool get conocida => armado > 0;

  /// La de Play Store: la actualiza Play, no un APK de Releases.
  bool get dePlay => canal == Canal.play;
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

/// Una versión obligatoria (entrega 34): el primer día avisa; desde el
/// siguiente, deja de anotar hasta actualizar. Ver, el Historial, los
/// informes y el Excel siguen.
enum BloqueoPorVersion { ninguno, desdeManana, bloqueado }

class EstadoDeVersion {
  const EstadoDeVersion({
    this.ultima,
    this.minima,
    this.obligatoriaDesde,
    this.soporte,
  });

  /// El WhatsApp de soporte (entrega 46), los 9 dígitos; viene del servidor.
  final String? soporte;

  final VersionPublicada? ultima;

  /// Con un armado menor, hay que actualizar sí o sí.
  final int? minima;

  /// El día («2026-11-06») en que este teléfono supo de esa mínima: ese día
  /// es de gracia.
  final String? obligatoriaDesde;

  /// Si se puede anotar. El teléfono de Jhony nunca se bloquea; sin señal,
  /// tampoco, porque no podría bajar la versión nueva.
  BloqueoPorVersion bloqueo(
    VersionInstalada instalada, {
    required String hoy,
    required bool admin,
    required bool conSenal,
  }) {
    if (admin || !obligatoria(instalada)) return BloqueoPorVersion.ninguno;
    final desde = obligatoriaDesde;
    if (desde == null || desde.compareTo(hoy) >= 0) {
      return BloqueoPorVersion.desdeManana;
    }
    return conSenal ? BloqueoPorVersion.bloqueado : BloqueoPorVersion.ninguno;
  }

  /// Hay una más nueva que la instalada.
  /// La de Play Store nunca: la versión de Releases puede no estar aún en
  /// Play, y Play actualiza solo (entrega 77).
  bool hayNueva(VersionInstalada instalada) =>
      instalada.conocida &&
      !instalada.dePlay &&
      (ultima?.armado ?? 0) > instalada.armado;

  bool obligatoria(VersionInstalada instalada) =>
      instalada.conocida &&
      !instalada.dePlay &&
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
