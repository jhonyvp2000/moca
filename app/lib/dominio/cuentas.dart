import 'modelos.dart';

/// Una cuenta del negocio como la ve el dueño en «Mis cuentas».
class CuentaVista {
  const CuentaVista({
    this.id = '',
    required this.tipo,
    required this.nombre,
    required this.saldoCentimos,
    this.inicialCentimos,
    this.desde,
    this.arqueada = false,
  });

  /// Para asignar cajas a una persona del equipo (entrega 21).
  final String id;
  final TipoCuenta tipo;
  final String nombre;

  /// Calculado en la capa de datos. Nulo si el saldo inicial está pendiente.
  final int? saldoCentimos;

  /// El saldo con el que empezó y desde qué día (entrega 16.2); nulos si
  /// está pendiente.
  final int? inicialCentimos;
  final DateTime? desde;

  /// Si ya entró en un arqueo: desde entonces el arqueo es el que corrige.
  final bool arqueada;

  /// «Corregir el saldo con el que empecé»: solo antes de su primer arqueo
  /// (decisiones.md, 29-10-2026).
  bool get seCorrigeElInicial => inicialCentimos != null && !arqueada;

  /// Cuánto tendría hoy si hubiera empezado con [nuevo]: lo anotado no
  /// cambia, solo el punto de partida.
  int saldoConInicial(int nuevo) =>
      (saldoCentimos ?? 0) - (inicialCentimos ?? 0) + nuevo;
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

  /// Cambia el saldo con el que empezó la cuenta, sin crear ningún ajuste
  /// (entrega 16.2). Falso si la cuenta ya entró en un arqueo o su saldo
  /// sigue pendiente: no cambia nada.
  Future<bool> corregirSaldoInicial(String cuentaId, int centimos);
}
