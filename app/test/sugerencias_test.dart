import 'package:flutter_test/flutter_test.dart';
import 'package:moca/comun/sugerencias.dart';

void main() {
  test('Entrega 69: primero los que empiezan, sin tildes ni mayúsculas', () {
    const nombres = [
      'Comercial El Sol',
      'Comercial Tarapoto',
      'Ferretería El Constructor',
      'Hotel Río Mayo',
    ];
    expect(sugerenciasDeNombres(nombres, 'Co'), [
      'Comercial El Sol',
      'Comercial Tarapoto',
      'Ferretería El Constructor',
    ]);
    expect(sugerenciasDeNombres(nombres, 'com'), [
      'Comercial El Sol',
      'Comercial Tarapoto',
    ]);
    expect(sugerenciasDeNombres(nombres, 'ferreteria'), [
      'Ferretería El Constructor',
    ]);
    expect(sugerenciasDeNombres(nombres, 'rio'), ['Hotel Río Mayo']);
    expect(sugerenciasDeNombres(nombres, '  '), isEmpty);
    // Lo ya escrito tal cual no se vuelve a sugerir.
    expect(sugerenciasDeNombres(nombres, 'Hotel Río Mayo'), isEmpty);
  });
}
