import 'package:flutter_test/flutter_test.dart';
import 'package:moca/textos/textos.dart';

void main() {
  test('La nota del periodo del informe (entrega 36)', () {
    final hoy = DateTime(2026, 11, 6);
    expect(
      Textos.periodoDelMes(DateTime(2026, 11), enCurso: true, hoy: hoy),
      'Del 1 al 6 de noviembre',
    );
    expect(
      Textos.periodoDelMes(DateTime(2026, 10), enCurso: false, hoy: hoy),
      'Todo octubre',
    );
    // El primer mes con Moca, empezado a mitad.
    expect(
      Textos.periodoDelMes(
        DateTime(2026, 10),
        enCurso: false,
        hoy: hoy,
        desdeDia: 12,
      ),
      'Del 12 al 31 de octubre',
    );
    expect(
      Textos.periodoDelMes(
        DateTime(2026, 11),
        enCurso: true,
        hoy: hoy,
        desdeDia: 6,
      ),
      'El 6 de noviembre',
    );
  });
}
