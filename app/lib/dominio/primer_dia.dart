import 'modelos.dart';

/// En qué paso del camino del primer día está el teléfono. Si la app se
/// cierra a mitad del camino, al volver sigue en el paso pendiente.
enum EtapaInicio {
  /// S00: todavía no hay ninguna venta.
  bienvenida,

  /// S01: ya hay venta; falta decidir lo del celular.
  guardarAvance,

  /// S02: falta el alta del negocio.
  alta,

  /// El camino terminó: la app abre en Inicio.
  listo,
}

class DatosAlta {
  const DatosAlta({
    required this.nombre,
    required this.tipoNegocio,
    required this.saldos,
    required this.horaCierreMinutos,
    this.billeteras = const {},
  });

  final String nombre;
  final TipoNegocio tipoNegocio;

  /// Saldo inicial por cuenta, en céntimos. Nulo: «lo pongo después».
  final Map<TipoCuenta, int>? saldos;
  final int horaCierreMinutos;

  /// Las billeteras y los bancos que usa además de Yape y el BCP, con su
  /// nombre (Plin, Sip u otra; Interbank, BBVA, Scotiabank u otro banco).
  final Map<TipoCuenta, String> billeteras;
}

/// Lo que muestran S01 y S03. Las cifras vienen calculadas de la capa de
/// datos; las pantallas no suman.
class ResumenPrimerDia {
  const ResumenPrimerDia({
    required this.nombreNegocio,
    required this.tienesHoyCentimos,
    required this.saldoPendiente,
    required this.ventaDeHoyCentimos,
    required this.diasConVenta,
    this.conOtrosMovimientos = false,
  });

  final String nombreNegocio;
  final int tienesHoyCentimos;
  final bool saldoPendiente;

  /// Cero si hoy no se anotó venta.
  final int ventaDeHoyCentimos;
  final int diasConVenta;

  /// Si hay algo más que el saldo inicial y las ventas del día (gastos,
  /// retiros, otros ingresos). Cambia cómo se explica «Tienes hoy».
  final bool conOtrosMovimientos;

  bool get ventaDeHoyAnotada => ventaDeHoyCentimos > 0;
}

abstract interface class RepositorioPrimerDia {
  Stream<EtapaInicio> observarEtapa();

  Stream<ResumenPrimerDia> observarResumen();

  /// S07: guarda la venta del día por cuenta (en céntimos) y pasa a S01.
  Future<void> anotarPrimeraVenta(
    Map<TipoCuenta, int> ventaPorCuenta, {
    Fuente fuente = Fuente.texto,
  });

  /// S01: guarda el celular ya verificado y, si viene del primer día, pasa
  /// al alta.
  Future<void> guardarCelular(String celular);

  /// S01: «Ahora no, seguir probando».
  Future<void> seguirSinCuenta();

  /// S02: completa el negocio y termina el camino del primer día.
  Future<void> completarAlta(DatosAlta datos);

  /// S03, paso 1: declarar el saldo que quedó pendiente.
  Future<void> declararSaldo(Map<TipoCuenta, int> saldos);
}
