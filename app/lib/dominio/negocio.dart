/// «Datos del negocio» (entrega 29.1): lo que el dueño puede cambiar después
/// del alta. El tipo de negocio no: de él dependen las categorías.
class DatosDelNegocio {
  const DatosDelNegocio({
    required this.nombre,
    required this.horaCierreMinutos,
  });

  final String nombre;

  /// Minutos desde la medianoche: 21 * 60 son las 9 de la noche.
  final int horaCierreMinutos;
}

abstract interface class RepositorioNegocio {
  Stream<DatosDelNegocio?> observar();

  /// Lo guarda y lo deja en la bitácora; sube como cualquier cambio.
  Future<void> guardar(DatosDelNegocio datos);
}
