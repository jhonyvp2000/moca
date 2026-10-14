import '../../dominio/comprobantes.dart';
import '../../dominio/modelos.dart';

/// En la Demo la foto no se lee con IA: cada foto devuelve uno de estos
/// comprobantes de ejemplo, por turno. El operador puede forzar que la
/// próxima salga ilegible (S17).
class LectorFotoSimulado implements LectorFoto {
  LectorFotoSimulado({
    required this.ahora,
    required this.forzarIlegible,
    this.espera = const Duration(seconds: 2),
  });

  final DateTime Function() ahora;

  /// Devuelve verdadero (una vez) si el operador forzó la foto ilegible.
  final bool Function() forzarIlegible;
  final Duration espera;
  int _turno = 0;

  List<LecturaComprobante> _ejemplos(String ruta) {
    final hoy = ahora();
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    return [
      LecturaComprobante(
        origen: OrigenLectura.foto,
        emisorNombre: 'Distribuidora San Martín',
        tipo: 'Factura',
        fechaEmision: dia.subtract(const Duration(days: 1)),
        totalCentimos: 98000,
        cantidadItems: 12,
        categoria: 'Mercadería',
        rutaImagen: ruta,
      ),
      LecturaComprobante(
        origen: OrigenLectura.foto,
        emisorNombre: 'Electro Oriente',
        tipo: 'Recibo',
        fechaEmision: dia.subtract(const Duration(days: 3)),
        totalCentimos: 14230,
        cantidadItems: 1,
        categoria: 'Servicios (luz, agua, internet, teléfono)',
        rutaImagen: ruta,
      ),
      LecturaComprobante(
        origen: OrigenLectura.foto,
        emisorNombre: 'Ferretería El Constructor',
        tipo: 'Boleta',
        fechaEmision: dia,
        totalCentimos: 8650,
        cantidadItems: 3,
        categoria: 'Mantenimiento y reparaciones',
        rutaImagen: ruta,
      ),
      LecturaComprobante(
        origen: OrigenLectura.foto,
        emisorNombre: 'Grifo Santa Rosa',
        tipo: 'Ticket',
        fechaEmision: dia,
        totalCentimos: 6000,
        cantidadItems: 1,
        categoria: 'Transporte',
        rutaImagen: ruta,
      ),
    ];
  }

  @override
  Future<ResultadoLectura> leer(String rutaImagen) async {
    await Future<void>.delayed(espera);
    if (forzarIlegible()) {
      // Solo se leyó el total.
      return FotoLeida(
        LecturaComprobante(
          origen: OrigenLectura.foto,
          legible: false,
          totalCentimos: 98000,
          rutaImagen: rutaImagen,
        ),
      );
    }
    final ejemplos = _ejemplos(rutaImagen);
    return FotoLeida(ejemplos[_turno++ % ejemplos.length]);
  }
}
