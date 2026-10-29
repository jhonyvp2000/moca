import '../../dominio/modelos.dart';
import 'saldos.dart';

/// La semana va de lunes a domingo (decisiones.md, 12-10-2026).
DateTime inicioDeSemana(DateTime fecha) =>
    inicioDelDia(fecha).subtract(Duration(days: fecha.weekday - 1));

class ResumenPeriodo {
  const ResumenPeriodo({
    required this.entroCentimos,
    required this.salioCentimos,
    required this.cantidad,
    this.retirosCentimos = 0,
    this.aportesCentimos = 0,
  });

  final int entroCentimos;
  final int salioCentimos;

  /// Lo que el dueño retiró para sí: baja la plata, pero no es gasto.
  final int retirosCentimos;

  /// Lo que el dueño puso de su bolsillo: sube la plata, pero no es venta.
  final int aportesCentimos;

  /// Cuántos movimientos cuentan en el periodo.
  final int cantidad;

  int get quedoCentimos => entroCentimos - salioCentimos;
}

/// Lo que entró y salió entre `desde` (incluido) y `hasta` (excluido).
/// Los retiros para el dueño no cuentan como «salió»: bajan la caja, pero no
/// son gasto del negocio. Tampoco cuentan los anulados ni lo que se debe.
ResumenPeriodo resumirPeriodo(
  Iterable<MovimientoParaSaldo> movimientos, {
  required DateTime desde,
  required DateTime hasta,
}) {
  var entro = 0;
  var salio = 0;
  var retiros = 0;
  var aportes = 0;
  var cantidad = 0;
  for (final m in movimientos) {
    if (m.estado != EstadoRegistro.vigente) continue;
    if (m.estadoPago != EstadoPago.pagado) continue;
    if (m.fecha.isBefore(desde) || !m.fecha.isBefore(hasta)) continue;
    switch (m.tipo) {
      case TipoMovimiento.ingreso:
        entro += m.montoCentimos;
        cantidad++;
      case TipoMovimiento.egreso:
        salio += m.montoCentimos;
        cantidad++;
      case TipoMovimiento.retiro:
        retiros += m.montoCentimos;
      case TipoMovimiento.aporte:
        aportes += m.montoCentimos;
    }
  }
  return ResumenPeriodo(
    entroCentimos: entro,
    salioCentimos: salio,
    cantidad: cantidad,
    retirosCentimos: retiros,
    aportesCentimos: aportes,
  );
}
