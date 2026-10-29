import 'modelos.dart';

/// Una cuenta del negocio como la ve el dueño en «Mis cuentas».
class CuentaVista {
  const CuentaVista({
    this.id = '',
    required this.tipo,
    required this.nombre,
    required this.saldoCentimos,
  });

  /// Para asignar cajas a una persona del equipo (entrega 21).
  final String id;
  final TipoCuenta tipo;
  final String nombre;

  /// Calculado en la capa de datos. Nulo si el saldo inicial está pendiente.
  final int? saldoCentimos;
}

/// Las cuentas del negocio: Efectivo, Yape y Banco siempre; las billeteras
/// solo si el dueño las usa (decisiones.md, 13-10-2026). Nada se borra.
abstract interface class RepositorioCuentas {
  /// En el orden en que se muestran.
  Stream<List<CuentaVista>> observar();

  /// Agrega Plin, Sip u otra billetera, o un banco además del BCP (la otra
  /// billetera y el otro banco con [nombre]). Empieza en S/ 0 desde hoy; si
  /// el saldo inicial del negocio sigue pendiente, queda pendiente.
  Future<void> agregarBilletera(TipoCuenta tipo, {String? nombre});
}
