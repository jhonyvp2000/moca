import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/pantallas/historial/fila_movimiento.dart';
import 'package:moca/tema/colores.dart';

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

  test('Lo que entró va en azul; lo que salió, en rojo sobrio (14.9.2)', () {
    expect(colorDelMonto(TipoMovimiento.ingreso), Colores.marca);
    expect(colorDelMonto(TipoMovimiento.egreso), Colores.salida);
    expect(colorDelMonto(TipoMovimiento.retiro), Colores.salida);
  });
}
