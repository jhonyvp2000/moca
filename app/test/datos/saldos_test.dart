import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/calculos/saldos.dart';
import 'package:moca/dominio/modelos.dart';

MovimientoParaSaldo _m(
  TipoMovimiento tipo,
  int monto, {
  EstadoRegistro estado = EstadoRegistro.vigente,
  EstadoPago pago = EstadoPago.pagado,
  DateTime? fecha,
}) => MovimientoParaSaldo(
  tipo: tipo,
  montoCentimos: monto,
  estado: estado,
  estadoPago: pago,
  fecha: fecha ?? DateTime(2026, 10, 12, 12),
);

void main() {
  final desde = DateTime(2026, 10, 12);

  test('Saldo inicial más lo que entró menos lo que salió', () {
    expect(
      saldoDeCuenta(
        saldoInicialCentimos: 100000,
        fechaSaldoInicial: desde,
        movimientos: [
          _m(TipoMovimiento.ingreso, 35000),
          _m(TipoMovimiento.egreso, 8000),
        ],
      ),
      127000,
    );
  });

  test('El retiro para mí baja la plata de la cuenta', () {
    expect(
      saldoDeCuenta(
        saldoInicialCentimos: 50000,
        fechaSaldoInicial: desde,
        movimientos: [_m(TipoMovimiento.retiro, 10000)],
      ),
      40000,
    );
  });

  test('No cuentan los anulados ni lo que todavía se debe', () {
    expect(
      saldoDeCuenta(
        saldoInicialCentimos: 50000,
        fechaSaldoInicial: desde,
        movimientos: [
          _m(TipoMovimiento.ingreso, 35000, estado: EstadoRegistro.anulado),
          _m(TipoMovimiento.egreso, 98000, pago: EstadoPago.pendiente),
        ],
      ),
      50000,
    );
  });

  test('Sin saldo inicial se parte de cero', () {
    expect(
      saldoDeCuenta(
        saldoInicialCentimos: null,
        fechaSaldoInicial: null,
        movimientos: [_m(TipoMovimiento.ingreso, 47000)],
      ),
      47000,
    );
  });

  test('No cuenta lo anterior a la fecha del saldo inicial', () {
    expect(
      saldoDeCuenta(
        saldoInicialCentimos: 100000,
        fechaSaldoInicial: desde,
        movimientos: [
          _m(TipoMovimiento.ingreso, 20000, fecha: DateTime(2026, 10, 11)),
        ],
      ),
      100000,
    );
  });
}
