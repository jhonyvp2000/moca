import 'modelos.dart';
import 'movimientos.dart';

enum FiltroHistorial { todo, entro, salio, porSubir }

/// Una fila del Historial (S10). Solo registros vigentes: lo deshecho o
/// reemplazado por una corrección no aparece.
class FilaHistorial {
  const FilaHistorial({
    required this.id,
    required this.tipo,
    required this.montoCentimos,
    required this.fecha,
    required this.cuenta,
    required this.loDebes,
    required this.porSubir,
    this.categoria,
    this.nota,
    this.proveedor,
  });

  final String id;
  final TipoMovimiento tipo;
  final int montoCentimos;

  /// Cuándo se anotó.
  final DateTime fecha;
  final TipoCuenta cuenta;

  /// Compra que todavía se debe: no ha bajado el saldo.
  final bool loDebes;
  final bool porSubir;
  final String? categoria;
  final String? nota;

  /// Nombre del proveedor del comprobante, si lo tiene.
  final String? proveedor;

  bool cumple(FiltroHistorial filtro) => switch (filtro) {
    FiltroHistorial.todo => true,
    FiltroHistorial.entro => tipo == TipoMovimiento.ingreso,
    FiltroHistorial.salio => tipo != TipoMovimiento.ingreso,
    FiltroHistorial.porSubir => porSubir,
  };
}

class ResumenHistorial {
  const ResumenHistorial({required this.filas});

  /// Del más reciente al más antiguo.
  final List<FilaHistorial> filas;

  int get porSubir => filas.where((f) => f.porSubir).length;
}

/// Los datos del comprobante de una compra.
class ComprobanteVista {
  const ComprobanteVista({
    required this.totalCentimos,
    required this.origen,
    this.emisorNombre,
    this.emisorIdentificacion,
    this.tipo,
    this.serie,
    this.numero,
    this.fechaEmision,
    this.rutaImagen,
  });

  final int totalCentimos;
  final OrigenLectura origen;
  final String? emisorNombre;
  final String? emisorIdentificacion;
  final String? tipo;
  final String? serie;
  final String? numero;
  final DateTime? fechaEmision;
  final String? rutaImagen;
}

/// Una línea de «Cambios», sacada de la bitácora.
sealed class Cambio {
  const Cambio(this.fecha);

  final DateTime fecha;
}

class CambioCreado extends Cambio {
  const CambioCreado(super.fecha, this.fuente);

  final Fuente fuente;
}

enum CampoMovimiento { tipo, monto, cuenta, categoria, nota }

/// Un dato que cambió en una corrección. Los valores son del tipo del campo:
/// [TipoMovimiento], céntimos, [TipoCuenta] o el nombre de la categoría y la
/// nota como texto.
class CampoCambiado {
  const CampoCambiado(this.campo, this.anterior, this.nuevo);

  final CampoMovimiento campo;
  final Object? anterior;
  final Object? nuevo;
}

class CambioCorregido extends Cambio {
  const CambioCorregido(super.fecha, this.campos);

  final List<CampoCambiado> campos;
}

class CambioPagado extends Cambio {
  const CambioPagado(super.fecha, this.cuenta, this.fechaPago);

  final TipoCuenta cuenta;
  final DateTime fechaPago;
}

class CambioDeshecho extends Cambio {
  const CambioDeshecho(super.fecha);
}

/// El detalle de un movimiento, con sus cambios. Las cifras vienen
/// calculadas.
class DetalleMovimiento {
  const DetalleMovimiento({
    required this.fila,
    required this.vigente,
    required this.fuente,
    required this.cambios,
    required this.saldoSiSeDeshaceCentimos,
    this.categoriaId,
    this.fechaPago,
    this.primerDiaDePago,
    this.comprobante,
  });

  final FilaHistorial fila;

  /// Falso si se deshizo o se reemplazó por una corrección.
  final bool vigente;
  final Fuente fuente;
  final String? categoriaId;

  /// Cuándo salió la plata, en una compra pagada.
  final DateTime? fechaPago;

  /// En una compra que se debe, el primer día que se puede elegir como fecha
  /// de pago.
  final DateTime? primerDiaDePago;
  final ComprobanteVista? comprobante;

  /// Del más antiguo al más reciente, incluidos los del registro que este
  /// reemplazó.
  final List<Cambio> cambios;

  /// Cómo queda la cuenta si se deshace. Nulo si no cambia (lo que se debe
  /// no bajó el saldo).
  final int? saldoSiSeDeshaceCentimos;
}

abstract interface class RepositorioHistorial {
  Stream<ResumenHistorial> observarHistorial();

  /// Nulo si el movimiento no existe.
  Stream<DetalleMovimiento?> observarDetalle(String id);

  /// Cómo quedaría la cuenta con la corrección. Nulo si no cambia el saldo.
  Future<int?> saldoSiSeCorrige(String id, NuevoMovimiento correccion);

  /// Anula el registro y guarda uno nuevo que lo reemplaza. Devuelve el
  /// nuevo.
  Future<Guardado> corregir(String id, NuevoMovimiento correccion);

  /// Cómo quedaría la cuenta al pagar una compra que se debe.
  Future<int> saldoSiSePaga(String id, TipoCuenta cuenta);

  /// «Ya lo pagué»: se paga completo. Devuelve el saldo de la cuenta.
  Future<int> pagar(
    String id, {
    required TipoCuenta cuenta,
    required DateTime dia,
  });

  /// Anula el registro; no se borra y queda en la bitácora.
  Future<void> deshacer(String id);
}
