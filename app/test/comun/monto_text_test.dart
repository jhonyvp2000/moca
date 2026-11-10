import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/comun/badge_estado.dart';
import 'package:moca/comun/monto_text.dart';
import 'package:moca/comun/tono.dart';
import 'package:moca/tema/colores.dart';
import 'package:moca/tema/tema.dart';

// Mejora 01: los componentes del sistema de diseño.

Widget _en(Widget hijo) => MaterialApp(
  theme: temaMoca(),
  home: Scaffold(body: Center(child: hijo)),
);

Color? _colorDe(WidgetTester tester, String texto) =>
    tester.widget<Text>(find.text(texto)).style?.color;

void main() {
  testWidgets('El monto se lee igual que antes y lleva signo con su tono', (
    tester,
  ) async {
    await tester.pumpWidget(
      _en(
        const Column(
          children: [
            MontoText(125000),
            MontoText(8000, tono: Tono.ingreso, conSigno: true),
            MontoText(10000, tono: Tono.egreso, conSigno: true),
            MontoText(340, conCentimos: true),
          ],
        ),
      ),
    );
    expect(find.text('S/ 1,250'), findsOneWidget);
    expect(find.text('+ S/ 80'), findsOneWidget);
    expect(find.text('– S/ 100'), findsOneWidget);
    expect(find.text('S/ 3.40'), findsOneWidget);
    expect(_colorDe(tester, '+ S/ 80'), Colores.ingreso);
    expect(_colorDe(tester, '– S/ 100'), Colores.egreso);
  });

  testWidgets('El cero va en gris neutro y sin signo, nunca en rojo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _en(const MontoText(0, tono: Tono.egreso, conSigno: true)),
    );
    expect(find.text('S/ 0'), findsOneWidget);
    expect(_colorDe(tester, 'S/ 0'), Colores.neutro);
  });

  testWidgets('La etiqueta de estado lleva su palabra y su tono', (
    tester,
  ) async {
    await tester.pumpWidget(_en(const BadgeEstado('Te debe')));
    expect(find.text('Te debe'), findsOneWidget);
    expect(_colorDe(tester, 'Te debe'), Colores.pendienteTexto);
  });
}
