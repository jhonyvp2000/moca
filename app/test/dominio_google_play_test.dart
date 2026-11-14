import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/google_play.dart';

void main() {
  test('Cada plan con sus personas extra es un producto de Google, igual que '
      'en el servidor (entrega 80)', () {
    expect(productoDePlay('normal', 0), (
      producto: 'full_0',
      planBase: 'mes',
      oferta: null,
    ));
    expect(productoDePlay('anual', 2), (
      producto: 'full_2',
      planBase: 'anio',
      oferta: null,
    ));
    expect(productoDePlay('fundador', 1), (
      producto: 'full_1',
      planBase: 'mes',
      oferta: 'fundador',
    ));
    expect(productoDePlay('basico_anual', 5), (
      producto: 'basico_5',
      planBase: 'anio',
      oferta: null,
    ));
    expect(productoDePlay('normal', 6), isNull);
    expect(
      administrarEnGooglePlay('full_0'),
      'https://play.google.com/store/account/subscriptions?package=pe.moca.app&sku=full_0',
    );
  });
}
