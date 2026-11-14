import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/version.dart';

void main() {
  const instalada = VersionInstalada(
    entrega: 'piloto-1',
    armado: 100,
    commit: 'abc',
    esArm64: true,
  );
  EstadoDeVersion estado({int? minima, String? desde}) => EstadoDeVersion(
    minima: minima,
    obligatoriaDesde: desde,
    ultima: const VersionPublicada(
      nombre: 'piloto-2',
      armado: 110,
      arm64: 'https://x/arm64.apk',
    ),
  );
  BloqueoPorVersion bloqueo(
    EstadoDeVersion e, {
    String hoy = '2026-11-07',
    bool admin = false,
    bool conSenal = true,
  }) => e.bloqueo(instalada, hoy: hoy, admin: admin, conSenal: conSenal);

  test('Una versión obligatoria: un día de gracia y luego no se anota '
      '(entrega 34)', () {
    // Sin mínima, o ya al día: nada.
    expect(bloqueo(estado()), BloqueoPorVersion.ninguno);
    expect(bloqueo(estado(minima: 100)), BloqueoPorVersion.ninguno);
    // El día en que se supo, gracia.
    expect(
      bloqueo(estado(minima: 105, desde: '2026-11-07')),
      BloqueoPorVersion.desdeManana,
    );
    expect(bloqueo(estado(minima: 105)), BloqueoPorVersion.desdeManana);
    // Desde el día siguiente, bloquea.
    expect(
      bloqueo(estado(minima: 105, desde: '2026-11-06')),
      BloqueoPorVersion.bloqueado,
    );
    // Sin señal, no: no podría bajar la versión nueva.
    expect(
      bloqueo(estado(minima: 105, desde: '2026-11-06'), conSenal: false),
      BloqueoPorVersion.ninguno,
    );
    // El teléfono de Jhony, nunca.
    expect(
      bloqueo(estado(minima: 105, desde: '2026-11-06'), admin: true),
      BloqueoPorVersion.ninguno,
    );
  });

  test('La versión de Play Store no avisa ni se bloquea por un APK nuevo '
      '(entrega 77)', () {
    const dePlay = VersionInstalada(
      entrega: 'piloto-1',
      armado: 100,
      commit: 'abc',
      esArm64: true,
      canal: Canal.play,
    );
    final e = estado(minima: 105, desde: '2026-11-06');
    expect(e.hayNueva(instalada), isTrue);
    expect(e.hayNueva(dePlay), isFalse);
    expect(e.obligatoria(dePlay), isFalse);
    expect(
      e.bloqueo(dePlay, hoy: '2026-11-07', admin: false, conSenal: true),
      BloqueoPorVersion.ninguno,
    );
  });
}
