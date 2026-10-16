import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/pantallas/historial/fila_movimiento.dart';

void main() {
  test('Cada registro muestra sus céntimos si los tiene (16-10-2026)', () {
    // El signo, el símbolo y la cifra van unidos por espacios fijos.
    const fijo = ' ';
    expect(montoConSigno(TipoMovimiento.egreso, 340), '−${fijo}S/${fijo}3.40');
    expect(
      montoConSigno(TipoMovimiento.ingreso, 35000),
      '+${fijo}S/${fijo}350',
    );
    expect(
      montoConSigno(TipoMovimiento.egreso, 98050),
      '−${fijo}S/${fijo}980.50',
    );
  });
}
