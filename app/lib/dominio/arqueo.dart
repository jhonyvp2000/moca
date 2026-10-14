import 'modelos.dart';

/// Cómo está el arqueo de la semana, para el Inicio (S04).
enum EstadoArqueo {
  /// Nada que pedir.
  nada,

  /// Domingo, o pedido desde el ajuste oculto.
  toca,

  /// Desde el lunes a las 8:00 a. m., si la semana anterior quedó sin arqueo.
  falta,

  /// Ya se hizo esta semana.
  hecho,
}

/// Una diferencia menor a S/ 1 se toma como cuadre (por los céntimos de los
/// comprobantes): el saldo se ajusta sin preguntar.
const toleranciaArqueoCentimos = 100;

/// Lo que Moca calcula para una cuenta antes del arqueo.
class CuentaArqueo {
  const CuentaArqueo({
    required this.cuenta,
    required this.calculadoCentimos,
    required this.puntoDePartida,
  });

  final TipoCuenta cuenta;
  final int calculadoCentimos;

  /// La cuenta todavía no tiene saldo inicial: lo que se cuente será el
  /// punto de partida y no hay diferencia que explicar.
  final bool puntoDePartida;

  /// Lo que se propone en el campo, en soles enteros. Nulo si no hay saldo
  /// inicial o si lo calculado es negativo: el dueño lo escribe.
  int? get propuestoSoles => puntoDePartida || calculadoCentimos < 0
      ? null
      : (calculadoCentimos / 100).round();

  /// Contado menos calculado: negativo si faltan, positivo si sobran. Cero
  /// en un punto de partida.
  int diferencia(int contadoCentimos) =>
      puntoDePartida ? 0 : contadoCentimos - calculadoCentimos;

  bool cuadra(int contadoCentimos) =>
      diferencia(contadoCentimos).abs() < toleranciaArqueoCentimos;
}

/// Las respuestas rápidas según falte o sobre plata.
List<MotivoArqueo> motivosPara(int diferencia) => diferencia < 0
    ? const [
        MotivoArqueo.retiroParaMi,
        MotivoArqueo.gastoOlvidado,
        MotivoArqueo.errorDeVuelto,
        MotivoArqueo.noLoSe,
      ]
    : const [
        MotivoArqueo.ventaNoAnotada,
        MotivoArqueo.errorDeVuelto,
        MotivoArqueo.noLoSe,
      ];

/// Lo que el dueño contó en una cuenta y, si no cuadra, por qué.
class ConteoCuenta {
  const ConteoCuenta({
    required this.cuenta,
    required this.contadoCentimos,
    this.motivo,
    this.categoriaId,
  });

  final TipoCuenta cuenta;
  final int contadoCentimos;
  final MotivoArqueo? motivo;

  /// La categoría del gasto olvidado.
  final String? categoriaId;
}

abstract interface class RepositorioArqueo {
  /// Lo calculado para cada cuenta, en el orden de las cuentas.
  Future<List<CuentaArqueo>> preparar();

  /// Guarda el arqueo: anota los movimientos de las respuestas, ajusta el
  /// saldo de lo demás y lo deja en la bitácora. Devuelve cuánto tiene el
  /// dueño en total después.
  Future<int> guardar(List<ConteoCuenta> conteos);
}
