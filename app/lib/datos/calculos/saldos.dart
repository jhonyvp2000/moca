import '../../dominio/modelos.dart';

/// Lo mínimo de un movimiento que hace falta para calcular saldos.
class MovimientoParaSaldo {
  const MovimientoParaSaldo({
    required this.tipo,
    required this.montoCentimos,
    required this.estado,
    required this.estadoPago,
    required this.fecha,
  });

  final TipoMovimiento tipo;
  final int montoCentimos;
  final EstadoRegistro estado;
  final EstadoPago estadoPago;
  final DateTime fecha;
}

/// Saldo de una cuenta: el saldo inicial más lo que entró y menos lo que
/// salió desde la fecha del saldo inicial. No cuentan los movimientos
/// anulados ni las compras que todavía se deben.
int saldoDeCuenta({
  required int? saldoInicialCentimos,
  required DateTime? fechaSaldoInicial,
  required Iterable<MovimientoParaSaldo> movimientos,
}) {
  var saldo = saldoInicialCentimos ?? 0;
  for (final m in movimientos) {
    if (m.estado != EstadoRegistro.vigente) continue;
    if (m.estadoPago != EstadoPago.pagado) continue;
    if (fechaSaldoInicial != null && m.fecha.isBefore(fechaSaldoInicial)) {
      continue;
    }
    saldo += switch (m.tipo) {
      TipoMovimiento.ingreso || TipoMovimiento.aporte => m.montoCentimos,
      TipoMovimiento.egreso || TipoMovimiento.retiro => -m.montoCentimos,
    };
  }
  return saldo;
}

DateTime inicioDelDia(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);
