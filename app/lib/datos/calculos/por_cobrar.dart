import '../../dominio/modelos.dart';
import '../local/base_local.dart';
import 'saldos.dart';

/// Un cliente al que toca recordarle lo que debe (entrega 54).
class ClientePorCobrar {
  const ClientePorCobrar({
    required this.contraparteId,
    required this.nombre,
    required this.faltaCentimos,
    required this.desde,
  });

  final String contraparteId;
  final String nombre;

  /// Lo que falta cobrarle, de todas sus ventas fiadas.
  final int faltaCentimos;

  /// La fecha de la venta fiada más antigua que todavía debe.
  final DateTime desde;
}

/// Cuántos días tiene que llevar la deuda, y desde el último recordatorio,
/// para que Moca avise.
const diasParaRecordarCliente = 7;

/// Los clientes con ventas fiadas cuya deuda más antigua tiene 7 días o más
/// el [dia] dado y a los que no se les recordó en los últimos 7 días. La
/// misma regla que el servidor (`calcular.ts`).
List<ClientePorCobrar> clientesPorCobrar(
  Iterable<Movimiento> movimientos,
  Iterable<Contraparte> contrapartes,
  DateTime dia,
) {
  final hoy = inicioDelDia(dia);
  final falta = <String, int>{};
  final desde = <String, DateTime>{};
  for (final m in movimientos) {
    final id = m.contraparteId;
    if (id == null ||
        m.estado != EstadoRegistro.vigente ||
        m.tipo != TipoMovimiento.ingreso ||
        m.estadoPago == EstadoPago.pagado) {
      continue;
    }
    final resto = m.montoCentimos - m.montoPagadoCentimos;
    if (resto <= 0) continue;
    falta[id] = (falta[id] ?? 0) + resto;
    final fecha = m.fechaMovimiento;
    if (desde[id] == null || fecha.isBefore(desde[id]!)) desde[id] = fecha;
  }
  final porId = {for (final c in contrapartes) c.id: c};
  final lista = <ClientePorCobrar>[];
  for (final MapEntry(key: id, value: centimos) in falta.entries) {
    final cliente = porId[id];
    if (cliente == null) continue;
    final recordado = cliente.recordadoEn;
    var base = inicioDelDia(desde[id]!);
    if (recordado != null && inicioDelDia(recordado).isAfter(base)) {
      base = inicioDelDia(recordado);
    }
    final aviso = DateTime(
      base.year,
      base.month,
      base.day + diasParaRecordarCliente,
    );
    if (hoy.isBefore(aviso)) continue;
    lista.add(
      ClientePorCobrar(
        contraparteId: id,
        nombre: cliente.nombre,
        faltaCentimos: centimos,
        desde: desde[id]!,
      ),
    );
  }
  return lista;
}
