import 'modelos.dart';

/// Las categorías propias del negocio (entrega 31): el dueño agrega las que
/// no están en la lista de Moca. Las de Moca no se cambian, porque de ellas
/// salen el informe y el flujo para el crédito.
class CategoriaDelNegocio {
  const CategoriaDelNegocio({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.propia,
    required this.activa,
  });

  final String id;
  final String nombre;

  /// Entró (ingreso) o salió (egreso).
  final TipoMovimiento tipo;

  /// La agregó el dueño; las de Moca no se tocan.
  final bool propia;

  /// «Ya no la uso» la deja de ofrecer al anotar; lo anotado la conserva.
  final bool activa;
}

/// Cuántas propias puede tener el negocio, en total (no por persona).
int maximoPropias(TipoMovimiento tipo) =>
    tipo == TipoMovimiento.ingreso ? 5 : 10;

/// Hasta cuántas letras lleva el nombre.
const largoNombreCategoria = 30;

enum ErrorCategoria { vacia, repetida, sinLugar, sinPermiso }

/// El resultado de agregar o cambiar: el id de la categoría, o el error.
typedef ResultadoCategoria = ({String? id, ErrorCategoria? error});

abstract interface class RepositorioCategorias {
  /// Las de entró y salió del negocio, en el orden en que se ofrecen; las
  /// propias que ya no se usan también, para poder volver a usarlas.
  Stream<List<CategoriaDelNegocio>> observar();

  Future<ResultadoCategoria> agregar(String nombre, TipoMovimiento tipo);

  Future<ResultadoCategoria> renombrar(String id, String nombre);

  /// «Ya no la uso» (false) o «Usarla otra vez» (true).
  Future<ResultadoCategoria> usar(String id, {required bool activa});
}

/// Para comparar nombres: sin mayúsculas, sin tildes y sin espacios de más.
/// «mercaderia» choca con «Mercadería».
String nombreComparable(String nombre) {
  const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
  final minusculas = nombre.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final letra in minusculas.split('')) {
    buffer.write(tildes[letra] ?? letra);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
}
