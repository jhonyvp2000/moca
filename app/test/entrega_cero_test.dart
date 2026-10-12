import 'package:flutter_test/flutter_test.dart';
import 'package:moca/main.dart';

void main() {
  testWidgets('La app abre con la marca y el eslogan', (tester) async {
    await tester.pumpWidget(const MocaApp());

    expect(find.text('Moca'), findsOneWidget);
    expect(find.text('Tú vendes. Moca hace las cuentas.'), findsOneWidget);
    expect(find.byType(Isotipo), findsOneWidget);
  });
}
