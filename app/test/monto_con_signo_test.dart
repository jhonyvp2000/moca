import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/pantallas/historial/fila_movimiento.dart';

void main() {
  test('Cada registro muestra sus céntimos si los tiene (16-10-2026)', () {
    expect(montoConSigno(TipoMovimiento.egreso, 340), '− S/ 3.40');
    expect(montoConSigno(TipoMovimiento.ingreso, 35000), '+ S/ 350');
    expect(montoConSigno(TipoMovimiento.egreso, 98050), '− S/ 980.50');
  });
}
