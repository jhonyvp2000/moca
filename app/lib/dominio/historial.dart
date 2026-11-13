import 'modelos.dart';
import 'movimientos.dart';

/// Los filtros rápidos del Historial. «Pendientes»: lo que te deben y lo
/// que debes (mejora 01).
/// «Transacciones» en la hoja de filtros del Historial (entrega 71): se
/// pueden elegir varias; ninguna es todo.
enum Transaccion { entro, salio, teDeben, debes, porSubir }

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
    this.documentoTipo,
    this.documentoNumero,
    this.ajusteArqueo = false,
    this.cuentaDestino,
    this.deOtro = false,
    this.autorNombre,
    this.autorRol,
    this.anotadoEn,
    this.vence,
    this.parteDe,
    this.pagadoEnPartesCentimos = 0,
    this.contraparteId,
    this.celular,
    this.recordadoEn,
    this.fechaPago,
    this.esPago = false,
  });

  /// Cuándo se cobró o se pagó una deuda; nulo si todavía se debe o si no
  /// fue una deuda (entrega 55).
  final DateTime? fechaPago;

  /// La fila del día en que te pagaron un fiado, o en que pagaste lo que
  /// debías (entrega 55). Es el mismo registro: abre el mismo detalle.
  final bool esPago;

  /// Una deuda que se cobró o se pagó otro día: en el día de la venta o de
  /// la compra ya no suma, porque la plata se movió el día del pago.
  bool get pagadoOtroDia =>
      !esPago && !loDebes && fechaPago != null && !_mismoDia(fechaPago!, fecha);

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// El cliente o proveedor, su celular y cuándo se le recordó por WhatsApp
  /// (entrega 53). El celular solo llega a los teléfonos de los dueños.
  final String? contraparteId;
  final String? celular;
  final DateTime? recordadoEn;

  final String id;
  final TipoMovimiento tipo;
  final int montoCentimos;

  /// Cuándo se anotó.
  final DateTime fecha;
  final TipoCuenta cuenta;

  /// Compra que todavía se debe, o venta que todavía te deben (entrega
  /// 42): no ha movido el saldo.
  final bool loDebes;

  /// Una venta a crédito que todavía te deben (entrega 42).
  bool get teDeben => loDebes && tipo == TipoMovimiento.ingreso;

  /// Un pago en parte (entrega 44): el id de la deuda de la que es parte.
  final String? parteDe;

  /// En una deuda: lo que ya se pagó en partes. [montoCentimos] es lo que
  /// falta.
  final int pagadoEnPartesCentimos;

  /// En una deuda con partes: lo que era al principio.
  int get totalConPartesCentimos => montoCentimos + pagadoEnPartesCentimos;
  final bool porSubir;
  final String? categoria;
  final String? nota;

  /// Nombre del proveedor del comprobante, si lo tiene; desde la entrega 66,
  /// también la institución que se anotó (el cliente o el proveedor).
  final String? proveedor;

  /// El documento anotado (entrega 66): «Factura» y «0045J».
  final String? documentoTipo;
  final String? documentoNumero;

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
  FilaHistorial conMonto(int centimos) => _copia(monto: centimos);

  /// La fila del día del pago (entrega 55).
  FilaHistorial comoPago() => _copia(fecha: fechaPago, esPago: true);

  FilaHistorial _copia({int? monto, DateTime? fecha, bool? esPago}) =>
      FilaHistorial(
        id: id,
        tipo: tipo,
        montoCentimos: monto ?? montoCentimos,
        fecha: fecha ?? this.fecha,
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
        parteDe: parteDe,
        pagadoEnPartesCentimos: pagadoEnPartesCentimos,
        contraparteId: contraparteId,
        celular: celular,
        recordadoEn: recordadoEn,
        fechaPago: fechaPago,
        esPago: esPago ?? this.esPago,
      );

  bool cumple(Transaccion transaccion) => switch (transaccion) {
    // Un pase no entra ni sale del negocio: solo sin filtro.
    Transaccion.entro => !ajusteArqueo && tipo.entraPlata,
    Transaccion.salio => !ajusteArqueo && !tipo.entraPlata && !tipo.esPase,
    Transaccion.teDeben => loDebes && teDeben,
    Transaccion.debes => loDebes && !teDeben,
    // El registro sale una vez, aunque tenga la fila del día del pago.
    Transaccion.porSubir => porSubir && !esPago,
  };
}

/// Buscar y filtrar en el Historial (entrega 39). La búsqueda separa por
/// palabras y cada una tiene que estar en el registro («Y»), en cualquier
/// orden y sin importar mayúsculas ni tildes: en la nota, el proveedor, la
/// categoría, quién lo anotó o la cuenta. Una palabra con cifras también
/// encuentra el monto: «80» trae S/ 80 y S/ 80.50; «80.50», solo S/ 80.50.
/// El periodo del Historial (entrega 56): un día, un mes, un año o entre
/// dos fechas. [desde] incluido, [hasta] excluido, los dos a medianoche.
enum TipoPeriodo { dia, mes, anio, rango }

class PeriodoHistorial {
  const PeriodoHistorial._(this.tipo, this.desde, this.hasta);

  factory PeriodoHistorial.dia(DateTime dia) {
    final d = DateTime(dia.year, dia.month, dia.day);
    return PeriodoHistorial._(
      TipoPeriodo.dia,
      d,
      DateTime(d.year, d.month, d.day + 1),
    );
  }

  factory PeriodoHistorial.mes(DateTime mes) => PeriodoHistorial._(
    TipoPeriodo.mes,
    DateTime(mes.year, mes.month),
    DateTime(mes.year, mes.month + 1),
  );

  factory PeriodoHistorial.anio(int anio) =>
      PeriodoHistorial._(TipoPeriodo.anio, DateTime(anio), DateTime(anio + 1));

  /// Del día [primero] al día [ultimo], los dos incluidos.
  factory PeriodoHistorial.rango(DateTime primero, DateTime ultimo) =>
      PeriodoHistorial._(
        TipoPeriodo.rango,
        DateTime(primero.year, primero.month, primero.day),
        DateTime(ultimo.year, ultimo.month, ultimo.day + 1),
      );

  final TipoPeriodo tipo;
  final DateTime desde;
  final DateTime hasta;

  /// El último día incluido.
  DateTime get ultimoDia => DateTime(hasta.year, hasta.month, hasta.day - 1);

  bool contiene(DateTime fecha) =>
      !fecha.isBefore(desde) && fecha.isBefore(hasta);

  /// El mismo tipo de periodo, uno antes (-1) o uno después (1). Un rango
  /// no se mueve.
  PeriodoHistorial mover(int paso) => switch (tipo) {
    TipoPeriodo.dia => PeriodoHistorial.dia(
      DateTime(desde.year, desde.month, desde.day + paso),
    ),
    TipoPeriodo.mes => PeriodoHistorial.mes(
      DateTime(desde.year, desde.month + paso),
    ),
    TipoPeriodo.anio => PeriodoHistorial.anio(desde.year + paso),
    TipoPeriodo.rango => this,
  };

  @override
  bool operator ==(Object other) =>
      other is PeriodoHistorial &&
      other.tipo == tipo &&
      other.desde == desde &&
      other.hasta == hasta;

  @override
  int get hashCode => Object.hash(tipo, desde, hasta);
}

class FiltrosDelHistorial {
  const FiltrosDelHistorial({
    this.texto = '',
    this.cuentas = const {},
    this.categorias = const {},
    this.personas = const {},
    this.periodo,
    this.transacciones = const {},
  });

  /// Entró, salió, te deben, debes o por subir (entrega 71). Una fila pasa
  /// si es de alguna de las elegidas.
  final Set<Transaccion> transacciones;

  final String texto;
  final Set<TipoCuenta> cuentas;
  final Set<String> categorias;

  /// Quién lo anotó, por [personaDe].
  final Set<String> personas;

  /// Nulo: todo (entrega 56).
  final PeriodoHistorial? periodo;

  static const _sinFiltro = FiltrosDelHistorial();

  bool get vacios =>
      texto.trim().isEmpty &&
      cuentas.isEmpty &&
      categorias.isEmpty &&
      personas.isEmpty &&
      periodo == null &&
      transacciones.isEmpty;

  /// Cuántos de los filtros de la hoja «Filtrar» están puestos.
  int get puestos =>
      (periodo == null ? 0 : 1) +
      (cuentas.isEmpty ? 0 : 1) +
      (categorias.isEmpty ? 0 : 1) +
      (personas.isEmpty ? 0 : 1) +
      (transacciones.isEmpty ? 0 : 1);

  FiltrosDelHistorial conTexto(String nuevo) => con(texto: nuevo);

  /// Los mismos filtros con lo que se cambie. [sinPeriodo] vuelve a «Todo».
  FiltrosDelHistorial con({
    String? texto,
    Set<TipoCuenta>? cuentas,
    Set<String>? categorias,
    Set<String>? personas,
    PeriodoHistorial? periodo,
    bool sinPeriodo = false,
    Set<Transaccion>? transacciones,
  }) => FiltrosDelHistorial(
    transacciones: transacciones ?? this.transacciones,
    texto: texto ?? this.texto,
    cuentas: cuentas ?? this.cuentas,
    categorias: categorias ?? this.categorias,
    personas: personas ?? this.personas,
    periodo: sinPeriodo ? null : periodo ?? this.periodo,
  );

  FiltrosDelHistorial sinHoja() => FiltrosDelHistorial(texto: texto);

  /// La clave de quién lo anotó: «yo» o su nombre.
  static String personaDe(FilaHistorial f) =>
      f.deOtro ? (f.autorNombre ?? 'otra') : 'yo';

  bool cumple(FilaHistorial f, {required String Function(TipoCuenta) cuenta}) {
    if (identical(this, _sinFiltro)) return true;
    if (transacciones.isNotEmpty && !transacciones.any(f.cumple)) return false;
    if (periodo case final p? when !p.contiene(f.fecha)) return false;
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
        f.documentoTipo,
        f.documentoNumero,
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

  /// Lo que te deben y lo que debes (mejora 01).
  int get pendientes => filas.where((f) => f.loDebes).length;
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

enum CampoMovimiento {
  tipo,
  monto,
  cuenta,
  categoria,
  nota,
  documento,
  institucion,
}

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
  const CambioPagado(
    super.fecha,
    this.cuenta,
    this.fechaPago, {
    this.parteCentimos,
    this.cobro = false,
  });

  final TipoCuenta cuenta;
  final DateTime fechaPago;

  /// Una venta que te pagaron, no una compra que pagaste (entrega 44.1).
  final bool cobro;

  /// Un pago en parte (entrega 44): cuánto.
  final int? parteCentimos;
}

/// Un pago en parte de una deuda (entrega 44).
class ParteDePago {
  const ParteDePago({
    required this.id,
    required this.fechaPago,
    required this.cuenta,
    required this.montoCentimos,
  });

  final String id;
  final DateTime fechaPago;
  final TipoCuenta cuenta;
  final int montoCentimos;
}

/// La deuda de la que es parte un pago en parte (entrega 44).
class DeudaDeLaParte {
  const DeudaDeLaParte({
    required this.id,
    required this.tipo,
    required this.faltaCentimos,
    required this.abierta,
  });

  final String id;
  final TipoMovimiento tipo;

  /// Lo que todavía se debe; 0 si ya se pagó.
  final int faltaCentimos;
  final bool abierta;
}

/// Por qué no se corrige o no se deshace un registro (entrega 44).
enum TrabaDelRegistro {
  /// Una deuda con pagos en partes: primero se deshacen las partes.
  tienePartes,

  /// Un pago en parte no se corrige: se deshace y se anota otra vez.
  esParte,

  /// Solo se deshace la parte más reciente, con la deuda todavía abierta.
  noEsLaUltimaParte,
}

/// Se deshizo un cobro o un pago completo: volvió a deberse (entrega 44.2).
class CambioPagoDeshecho extends Cambio {
  const CambioPagoDeshecho(super.fecha, {this.cobro = false});

  final bool cobro;
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
    this.partes = const [],
    this.deuda,
    this.trabaAlCorregir,
    this.trabaAlDeshacer,
    this.sePuedeDeshacerElPago = false,
    this.saldoSiSeDeshaceElPagoCentimos,
  });

  /// Fue una deuda y se pagó completa: «Deshacer el cobro» o «Deshacer el
  /// pago» la vuelve a deberse (entrega 44.2).
  final bool sePuedeDeshacerElPago;

  /// Cómo quedaría su cuenta al deshacer el pago.
  final int? saldoSiSeDeshaceElPagoCentimos;

  /// En una deuda: sus pagos en partes, del más viejo al más nuevo
  /// (entrega 44).
  final List<ParteDePago> partes;

  /// En un pago en parte: la deuda de la que es parte.
  final DeudaDeLaParte? deuda;

  /// Nulo si se puede corregir o deshacer.
  final TrabaDelRegistro? trabaAlCorregir;
  final TrabaDelRegistro? trabaAlDeshacer;

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
    this.anual = false,
  });

  /// El primer día del mes; con [anual], desde cuándo cuenta el año.
  final DateTime mes;

  /// Todo el año de [mes] (entrega 40), hasta hoy si es el actual.
  final bool anual;
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

  /// «Lo que te deben» (entrega 42): las ventas que todavía te deben, de la
  /// más vieja a la más nueva.
  Stream<List<FilaHistorial>> observarLoQueTeDeben();

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

  /// Cómo quedaría la cuenta al pagar una compra que se debe, completa o
  /// [parteCentimos] (entrega 44).
  Future<int> saldoSiSePaga(String id, TipoCuenta cuenta, {int? parteCentimos});

  /// «Ya lo pagué» o «Ya me pagó»: completo o, con [parteCentimos], una
  /// parte (entrega 44), que queda como un registro pagado y deja en la
  /// deuda lo que falta. Devuelve el saldo de la cuenta.
  Future<int> pagar(
    String id, {
    required TipoCuenta cuenta,
    required DateTime dia,
    int? parteCentimos,
  });

  /// Anula el registro; no se borra y queda en la bitácora.
  Future<void> deshacer(String id);

  /// «Deshacer el cobro» o «Deshacer el pago» (entrega 44.2): una deuda
  /// pagada completa vuelve a deberse. Devuelve el saldo de su cuenta.
  Future<int> deshacerPago(String id);

  /// El celular de un cliente, o nulo para quitarlo (entrega 53).
  Future<void> guardarCelular(String contraparteId, String? celular);

  /// Que se le recordó hoy por WhatsApp (entrega 53).
  Future<void> marcarRecordado(String contraparteId);
}
