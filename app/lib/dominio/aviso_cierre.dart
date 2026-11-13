import 'modelos.dart';

enum TipoNotificacion {
  cierre,
  faltaArqueo,
  diasSinAnotar,
  resumenSemanal,

  /// Tres días antes de que termine la prueba gratis (entrega 25).
  cobroPorVencer,

  /// Los clientes que deben hace una semana o más (entrega 54), sin
  /// nombres ni montos: se ve en la pantalla bloqueada.
  clientesPorCobrar,
}

/// A dónde lleva tocar una notificación.
enum DestinoNotificacion {
  ventaPorVoz,
  ventaEscrita,
  arqueo,
  registrar,
  moca,
  loQueTeDeben,
}

/// Una notificación que el teléfono mostrará a una hora. La app las vuelve
/// a programar cada vez que se abre o cambian los datos.
class NotificacionProgramada {
  const NotificacionProgramada({
    required this.id,
    required this.cuando,
    required this.tipo,
    this.dias,
    this.clientes,
  });

  final int id;
  final DateTime cuando;
  final TipoNotificacion tipo;

  /// En «días sin anotar».
  final int? dias;

  /// En «clientes por cobrar».
  final int? clientes;
}

/// Lo que sigue después de contestar el aviso de cierre.
sealed class SiguientePaso {
  const SiguientePaso();
}

/// Preguntar por la venta de otra cuenta («¿Y por Yape?»).
class PreguntarCuenta extends SiguientePaso {
  const PreguntarCuenta(this.cuenta);

  final TipoCuenta cuenta;
}

/// Ya se anotó todo: cuánto se vendió hoy y si toca el arqueo.
class VentaLista extends SiguientePaso {
  const VentaLista({
    required this.ventaDeHoyCentimos,
    required this.tocaArqueo,
  });

  final int ventaDeHoyCentimos;
  final bool tocaArqueo;
}

/// El monto escrito no se entendió.
class MontoNoEntendido extends SiguientePaso {
  const MontoNoEntendido(this.cuenta);

  final TipoCuenta cuenta;
}

abstract interface class RepositorioAvisoCierre {
  /// Las notificaciones de los próximos siete días. Vacío en la Demo.
  Future<List<NotificacionProgramada>> plan();

  Stream<List<NotificacionProgramada>> observarPlan();

  /// La venta de una cuenta escrita en la notificación. [texto] nulo es
  /// «Nada por Yape».
  Future<SiguientePaso> responderVenta(TipoCuenta cuenta, String? texto);

  /// «Hoy no abrí»: el día cuenta como cerrado.
  Future<void> hoyNoAbri();

  /// Si se preguntó (o se descartó) el permiso de avisos.
  Future<bool> permisoPreguntado();

  Future<void> marcarPermisoPreguntado();
}
