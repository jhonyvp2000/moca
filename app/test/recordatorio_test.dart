import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/historial.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/pantallas/informe/recordatorio_whatsapp.dart';

FilaHistorial venta(int centimos, DateTime fecha, {int partes = 0}) =>
    FilaHistorial(
      id: '$centimos',
      tipo: TipoMovimiento.ingreso,
      montoCentimos: centimos,
      fecha: fecha,
      cuenta: TipoCuenta.efectivo,
      loDebes: true,
      porSubir: false,
      proveedor: 'Doña Rosa',
      pagadoEnPartesCentimos: partes,
    );

void main() {
  test('Entrega 45: el recordatorio, de usted, con lo que falta', () {
    String mensaje(List<FilaHistorial> ventas) => mensajeDeRecordatorio(
      negocio: 'Bodega Don Lucho',
      cliente: 'Doña Rosa',
      ventas: ventas,
    );
    expect(
      mensaje([venta(12000, DateTime(2026, 11, 3))]),
      'Hola, Doña Rosa. Le escribimos de Bodega Don Lucho para recordarle '
      'que tiene pendiente S/ 120, de su compra del 3 de noviembre. '
      'Cuando pueda, nos avisa cómo prefiere pagar. Gracias.',
    );
    // Varias ventas: el total y las fechas, de la más vieja a la más nueva.
    expect(
      mensaje([
        venta(5000, DateTime(2026, 11, 5)),
        venta(12000, DateTime(2026, 11, 3)),
        venta(1050, DateTime(2026, 11, 8)),
      ]),
      contains(
        'tiene pendiente S/ 180.50, de sus compras del 3 de noviembre, '
        'del 5 de noviembre y del 8 de noviembre.',
      ),
    );
    // Con partes ya pagadas: lo que le queda de cuánto.
    expect(
      mensaje([venta(12000, DateTime(2026, 11, 3), partes: 8000)]),
      contains(
        'le queda pendiente S/ 120 de S/ 200, de su compra del 3 '
        'de noviembre.',
      ),
    );
  });
}
