import 'package:flutter_test/flutter_test.dart';
import 'package:moca/textos/textos.dart';

void main() {
  test('Entrega 75: 4 sugerencias distintas que cambian cada día', () {
    final hoy = Textos.sugerenciasDelDia(DateTime(2026, 11, 13, 9));
    final manana = Textos.sugerenciasDelDia(DateTime(2026, 11, 14, 9));
    expect(hoy, hasLength(4));
    expect(hoy.toSet(), hasLength(4));
    expect(manana, isNot(equals(hoy)));
    // A la misma hora o a otra, el mismo día da las mismas.
    expect(Textos.sugerenciasDelDia(DateTime(2026, 11, 13, 22)), hoy);
    // En tres días se ven las 12.
    final tres = {
      for (var d = 13; d < 16; d++)
        ...Textos.sugerenciasDelDia(DateTime(2026, 11, d)),
    };
    expect(tres, Textos.preguntasSugeridas.toSet());
  });
}
