import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/voz.dart';
import 'package:moca/servicios/voz_android.dart';

void main() {
  const poco = Duration(milliseconds: 20);

  Future<String?> textoFinal(Stream<EventoVoz> eventos) async {
    final ultimo = await eventos.last;
    return switch (ultimo) {
      VozFinal(:final alternativas) => alternativas.first.texto,
      _ => null,
    };
  }

  test('El final normal se entrega tal cual', () async {
    final s = SesionDeEscucha(espera: poco);
    final fin = textoFinal(s.eventos);
    s.alParcial('hoy vendí');
    s.alFinal([const AlternativaVoz('hoy vendí 50 por Plin', 0.9)], '');
    expect(await fin, 'hoy vendí 50 por Plin');
  });

  test('Si Android avisa «terminé» sin final, usa lo último que oyó', () async {
    final s = SesionDeEscucha(espera: poco);
    final fin = textoFinal(s.eventos);
    s.alParcial('hoy vendí 50 por Plin');
    s.alTerminar();
    expect(await fin, 'hoy vendí 50 por Plin');
  });

  test('Un error después de oír la frase no la pierde', () async {
    final s = SesionDeEscucha(espera: poco);
    final fin = textoFinal(s.eventos);
    s.alParcial('hoy vendí 50 por Plin');
    s.alFallar(FalloVoz.noDisponible);
    expect(await fin, 'hoy vendí 50 por Plin');
  });

  test('Si el final llega tarde, se usa el final', () async {
    final s = SesionDeEscucha(espera: const Duration(milliseconds: 200));
    final fin = textoFinal(s.eventos);
    s.alParcial('hoy vendí 15');
    s.alTerminar();
    s.alFinal([const AlternativaVoz('hoy vendí 50 por Plin')], '');
    expect(await fin, 'hoy vendí 50 por Plin');
  });

  test('Un final sin alternativas usa las palabras reconocidas', () async {
    final s = SesionDeEscucha(espera: poco);
    final fin = textoFinal(s.eventos);
    s.alFinal(const [], 'vendí 80 en efectivo');
    expect(await fin, 'vendí 80 en efectivo');
  });

  test('Sin haber oído nada, sigue diciendo que no escuchó', () async {
    final s = SesionDeEscucha(espera: poco);
    final ultimo = s.eventos.last;
    s.alTerminar();
    expect(
      await ultimo,
      isA<VozFallida>().having(
        (f) => f.motivo,
        'motivo',
        FalloVoz.nadaQueEscuchar,
      ),
    );
  });

  test('Sin permiso, avisa el permiso aunque haya oído algo', () async {
    final s = SesionDeEscucha(espera: poco);
    final ultimo = s.eventos.last;
    s.alParcial('hoy');
    s.alFallar(FalloVoz.sinPermiso);
    expect(
      await ultimo,
      isA<VozFallida>().having((f) => f.motivo, 'motivo', FalloVoz.sinPermiso),
    );
  });
}
