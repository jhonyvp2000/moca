import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/calculos/saldos.dart';
import 'package:moca/datos/calculos/semana.dart';
import 'package:moca/dominio/modelos.dart';

MovimientoParaSaldo _m(TipoMovimiento tipo, int monto, DateTime fecha) =>
    MovimientoParaSaldo(
      tipo: tipo,
      montoCentimos: monto,
      estado: EstadoRegistro.vigente,
      estadoPago: EstadoPago.pagado,
      fecha: fecha,
    );

void main() {
  test('La semana empieza el lunes', () {
    // 12 de octubre de 2026 es lunes; el 18, domingo.
    expect(inicioDeSemana(DateTime(2026, 10, 12, 21)), DateTime(2026, 10, 12));
    expect(inicioDeSemana(DateTime(2026, 10, 18, 9)), DateTime(2026, 10, 12));
    expect(inicioDeSemana(DateTime(2026, 10, 19)), DateTime(2026, 10, 19));
  });

  test('Lo que entró y salió, sin contar los retiros para el dueño', () {
    final lunes = DateTime(2026, 10, 12);
    final r = resumirPeriodo(
      [
        _m(TipoMovimiento.ingreso, 50000, DateTime(2026, 10, 12, 10)),
        _m(TipoMovimiento.egreso, 8000, DateTime(2026, 10, 13, 10)),
        _m(TipoMovimiento.retiro, 10000, DateTime(2026, 10, 13, 11)),
        // Fuera del periodo.
        _m(TipoMovimiento.ingreso, 99900, DateTime(2026, 10, 11, 23)),
        _m(TipoMovimiento.ingreso, 99900, DateTime(2026, 10, 19)),
      ],
      desde: lunes,
      hasta: DateTime(2026, 10, 19),
    );
    expect(r.entroCentimos, 50000);
    expect(r.salioCentimos, 8000);
    expect(r.quedoCentimos, 42000);
    expect(r.cantidad, 2);
  });
}
