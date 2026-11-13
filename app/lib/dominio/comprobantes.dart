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
    this.fotoDePrueba,
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

  /// Sin cuenta, el número de la foto de prueba (1 a 3) que se usó para
  /// leerla (entrega 14.2).
  final int? fotoDePrueba;

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
/// Las fotos que un teléfono sin cuenta puede leer con la IA (entrega 14.2).
const fotosDePruebaPorTelefono = 3;

/// Por qué no se pudo leer una foto (entrega 14).
enum ProblemaLectura {
  /// Sin señal, o el servidor no respondió.
  sinSenal,
  noEsComprobante,

  /// Leer fotos usa IA: solo con cuenta.
  sinCuenta,

  /// El tope de fotos leídas por día.
  limiteDiario,

  /// Sin cuenta, ya usó sus fotos de prueba (entrega 14.2).
  pruebasAgotadas,
}

sealed class ResultadoLectura {
  const ResultadoLectura();
}

/// Leída, entera o en parte ([LecturaComprobante.legible]).
final class FotoLeida extends ResultadoLectura {
  const FotoLeida(this.lectura);
  final LecturaComprobante lectura;
}

final class FotoNoLeida extends ResultadoLectura {
  const FotoNoLeida(this.problema);
  final ProblemaLectura problema;
}

/// Busca un código QR dentro de una foto, en el teléfono.
abstract interface class BuscadorQr {
  Future<String?> buscar(String rutaImagen);
}

abstract interface class LectorFoto {
  Future<ResultadoLectura> leer(String rutaImagen);
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
