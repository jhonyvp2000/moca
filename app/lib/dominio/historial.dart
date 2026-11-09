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
    this.ajusteArqueo = false,
    this.cuentaDestino,
    this.deOtro = false,
    this.autorNombre,
    this.autorRol,
    this.anotadoEn,
    this.vence,
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

  /// Diferencia del arqueo que ajustó el saldo («Di mal un vuelto» o «No lo
  /// sé»). No es gasto ni ingreso: solo sale en «Todo». [tipo] dice si sobró
  /// (ingreso) o faltó (egreso).
  final bool ajusteArqueo;

  /// En un pase, a dónde fue la plata (entrega 21.1).
  final TipoCuenta? cuentaDestino;

  /// Lo anotó otra persona del negocio (entrega 20): su nombre y su rol, si
  /// se saben.
  final bool deOtro;
  final String? autorNombre;
  final Rol? autorRol;

  /// Cuándo se anotó en el teléfono (el ayudante deshace lo suyo del día).
  final DateTime? anotadoEn;

  /// Cuándo vence una compra que se debe, si se sabe (entrega 38).
  final DateTime? vence;

  /// La misma fila con otro monto: lo que falta pagar de una deuda.
  FilaHistorial conMonto(int centimos) => FilaHistorial(
    id: id,
    tipo: tipo,
    montoCentimos: centimos,
    fecha: fecha,
    cuenta: cuenta,
    loDebes: loDebes,
    porSubir: porSubir,
    categoria: categoria,
    nota: nota,
    proveedor: proveedor,
    ajusteArqueo: ajusteArqueo,
    cuentaDestino: cuentaDestino,
    deOtro: deOtro,
    autorNombre: autorNombre,
    autorRol: autorRol,
    anotadoEn: anotadoEn,
    vence: vence,
  );

  bool cumple(FiltroHistorial filtro) => switch (filtro) {
    FiltroHistorial.todo => true,
    // Un pase no entra ni sale del negocio: solo en «Todo».
    FiltroHistorial.entro => !ajusteArqueo && tipo.entraPlata,
    FiltroHistorial.salio => !ajusteArqueo && !tipo.entraPlata && !tipo.esPase,
    FiltroHistorial.porSubir => porSubir,
  };
}

/// Buscar y filtrar en el Historial (entrega 39). La búsqueda separa por
/// palabras y cada una tiene que estar en el registro («Y»), en cualquier
/// orden y sin importar mayúsculas ni tildes: en la nota, el proveedor, la
/// categoría, quién lo anotó o la cuenta. Una palabra con cifras también
/// encuentra el monto: «80» trae S/ 80 y S/ 80.50; «80.50», solo S/ 80.50.
class FiltrosDelHistorial {
  const FiltrosDelHistorial({
    this.texto = '',
    this.cuentas = const {},
    this.categorias = const {},
    this.personas = const {},
  });

  final String texto;
  final Set<TipoCuenta> cuentas;
  final Set<String> categorias;

  /// Quién lo anotó, por [personaDe].
  final Set<String> personas;

  static const _sinFiltro = FiltrosDelHistorial();

  bool get vacios =>
      texto.trim().isEmpty &&
      cuentas.isEmpty &&
      categorias.isEmpty &&
      personas.isEmpty;

  /// Cuántos de los filtros de la hoja «Filtrar» están puestos.
  int get puestos =>
      (cuentas.isEmpty ? 0 : 1) +
      (categorias.isEmpty ? 0 : 1) +
      (personas.isEmpty ? 0 : 1);

  FiltrosDelHistorial conTexto(String nuevo) => FiltrosDelHistorial(
    texto: nuevo,
    cuentas: cuentas,
    categorias: categorias,
    personas: personas,
  );

  FiltrosDelHistorial sinHoja() => FiltrosDelHistorial(texto: texto);

  /// La clave de quién lo anotó: «yo» o su nombre.
  static String personaDe(FilaHistorial f) =>
      f.deOtro ? (f.autorNombre ?? 'otra') : 'yo';

  bool cumple(FilaHistorial f, {required String Function(TipoCuenta) cuenta}) {
    if (identical(this, _sinFiltro)) return true;
    if (cuentas.isNotEmpty &&
        !cuentas.contains(f.cuenta) &&
        !(f.cuentaDestino != null && cuentas.contains(f.cuentaDestino))) {
      return false;
    }
    if (categorias.isNotEmpty && !categorias.contains(f.categoria)) {
      return false;
    }
    if (personas.isNotEmpty && !personas.contains(personaDe(f))) return false;
    final palabras = _comparable(texto)
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (palabras.isEmpty) return true;
    final enElRegistro = _comparable(
      [
        f.nota,
        f.proveedor,
        f.categoria,
        f.autorNombre,
        cuenta(f.cuenta),
        if (f.cuentaDestino != null) cuenta(f.cuentaDestino!),
      ].whereType<String>().join(' '),
    );
    return palabras.every(
      (p) => enElRegistro.contains(p) || _esElMonto(p, f.montoCentimos),
    );
  }

  /// «80» es S/ 80 con o sin céntimos; «80.5» o «80,50», exacto.
  static bool _esElMonto(String palabra, int centimos) {
    final cifra = palabra.replaceAll('s/', '').replaceAll(',', '.');
    final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(cifra);
    if (m == null) return false;
    final soles = int.parse(m.group(1)!);
    final decimales = m.group(2);
    if (decimales == null) return centimos ~/ 100 == soles;
    return centimos == soles * 100 + int.parse(decimales.padRight(2, '0'));
  }

  static String _comparable(String texto) {
    const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
    final b = StringBuffer();
    for (final letra in texto.toLowerCase().split('')) {
      b.write(tildes[letra] ?? letra);
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
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

/// Lo que dice un ajuste del arqueo.
class AjusteVista {
  const AjusteVista({
    required this.calculadoCentimos,
    required this.contadoCentimos,
    this.motivo,
  });

  final int calculadoCentimos;
  final int contadoCentimos;

  /// Nulo en una diferencia menor a S/ 1, que se ajusta sin preguntar.
  final MotivoArqueo? motivo;
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
    this.ajuste,
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

  /// Si es un ajuste del arqueo: se ve, pero no se corrige ni se deshace.
  final AjusteVista? ajuste;

  /// Del más antiguo al más reciente, incluidos los del registro que este
  /// reemplazó.
  final List<Cambio> cambios;

  /// Cómo queda la cuenta si se deshace. Nulo si no cambia (lo que se debe
  /// no bajó el saldo).
  final int? saldoSiSeDeshaceCentimos;
}

/// Los registros de una o varias categorías en un mes del informe (entrega
/// 38). Con [nombres] nulo son «Lo demás»: todas las de ese tipo menos las
/// de [salvo].
class ConsultaDeCategoria {
  const ConsultaDeCategoria({
    required this.mes,
    required this.tipo,
    required this.titulo,
    this.nombres,
    this.salvo = const {},
  });

  /// El primer día del mes.
  final DateTime mes;
  final TipoMovimiento tipo;
  final String titulo;
  final Set<String>? nombres;
  final Set<String> salvo;
}

abstract interface class RepositorioHistorial {
  Stream<ResumenHistorial> observarHistorial();

  /// «Lo que debes» (entrega 38): las compras que todavía se deben, con lo
  /// que falta pagar de cada una, de la que vence o se anotó antes.
  Stream<List<FilaHistorial>> observarLoQueDebes();

  /// Los registros de una categoría en un mes, con la regla del informe:
  /// lo pagado, el día en que se movió la plata. Suman lo de su barra.
  Stream<List<FilaHistorial>> observarDeCategoria(ConsultaDeCategoria c);

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
