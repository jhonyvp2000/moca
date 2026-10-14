import 'modelos.dart';
import 'movimientos.dart';

/// Lo que se leyó de un comprobante, por foto o por QR. Lo que no se leyó
/// queda nulo y el dueño lo completa.
class LecturaComprobante {
  const LecturaComprobante({
    required this.origen,
    this.legible = true,
    this.emisorIdentificacion,
    this.emisorNombre,
    this.tipo,
    this.serie,
    this.numero,
    this.fechaEmision,
    this.impuestoCentimos,
    this.totalCentimos,
    this.cantidadItems,
    this.categoria,
    this.rutaImagen,
  });

  final OrigenLectura origen;

  /// Falso cuando la foto salió borrosa (S17).
  final bool legible;

  /// RUC del emisor.
  final String? emisorIdentificacion;
  final String? emisorNombre;

  /// «Factura», «Boleta», «Recibo», «Ticket».
  final String? tipo;
  final String? serie;
  final String? numero;
  final DateTime? fechaEmision;
  final int? impuestoCentimos;
  final int? totalCentimos;
  final int? cantidadItems;

  /// Nombre de la categoría que sugiere la lectura, si sugiere una.
  final String? categoria;
  final String? rutaImagen;

  /// Para la llave única: emisor + tipo + serie + número.
  bool get identificable =>
      emisorIdentificacion != null &&
      tipo != null &&
      serie != null &&
      numero != null;
}

/// La compra que el dueño confirmó en S08.
class CompraConfirmada {
  const CompraConfirmada({
    required this.lectura,
    required this.totalCentimos,
    required this.cuenta,
    required this.pagado,
    required this.categoriaId,
    this.emisorNombre,
    this.fecha,
  });

  final LecturaComprobante lectura;
  final int totalCentimos;
  final TipoCuenta cuenta;

  /// Falso: «Todavía lo debo». No baja el saldo hasta pagarse.
  final bool pagado;
  final String categoriaId;
  final String? emisorNombre;

  /// Fecha del comprobante; si no se leyó, hoy.
  final DateTime? fecha;
}

abstract interface class RepositorioComprobantes {
  /// Si ese comprobante ya está anotado (y no se deshizo).
  Future<bool> yaAnotado(LecturaComprobante lectura);

  Future<Guardado> guardarCompra(CompraConfirmada compra);
}

/// Lectura de fotos de comprobantes. En el prototipo es simulada.
abstract interface class LectorFoto {
  Future<LecturaComprobante> leer(String rutaImagen);
}

sealed class ResultadoCamara {
  const ResultadoCamara();
}

class FotoTomada extends ResultadoCamara {
  const FotoTomada(this.ruta);

  final String ruta;
}

class FotoCancelada extends ResultadoCamara {
  const FotoCancelada();
}

class CamaraSinPermiso extends ResultadoCamara {
  const CamaraSinPermiso();
}

abstract interface class Camara {
  /// Abre la cámara y guarda la foto en el teléfono.
  Future<ResultadoCamara> tomarFoto();
}
