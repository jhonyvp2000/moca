import 'historial.dart';
import 'modelos.dart';

/// Una de las lecturas posibles que da el reconocimiento de voz. La
/// confianza va de 0 a 1; es nula cuando el teléfono no la informa.
class AlternativaVoz {
  const AlternativaVoz(this.texto, [this.confianza]);

  final String texto;
  final double? confianza;
}

/// Un monto dicho, con la cuenta si se dijo.
class PartidaVoz {
  const PartidaVoz(
    this.centimos, [
    this.cuenta,
    this.bancoSinNombre = false,
    this.plinSinBanco = false,
  ]);

  final int centimos;
  final TipoCuenta? cuenta;

  /// Dijo «banco», «transferencia» o «tarjeta» sin decir cuál: va al BCP,
  /// salvo que el negocio tenga más de un banco (entonces se pregunta).
  final bool bancoSinNombre;

  /// Dijo «Plin» sin decir de qué banco: va al único Plin del negocio; si
  /// tiene más de uno, se pregunta (entrega 14.10).
  final bool plinSinBanco;

  PartidaVoz conCuenta(TipoCuenta cuenta) => PartidaVoz(centimos, cuenta);
}

/// Lo que Moca entendió de una frase. Lo que falta, Moca lo pregunta:
/// nunca adivina un monto.
class LecturaVoz {
  const LecturaVoz({
    required this.textoDicho,
    this.tipo,
    this.partidas = const [],
    this.montosPosibles = const [],
    this.categoria,
    this.prestamo = false,
    this.cuentaDestino,
    this.debe = false,
    this.contraparte,
    this.pagaDeuda = false,
    this.abono,
    this.aparte = false,
  });

  static const vacia = LecturaVoz(textoDicho: '');

  final String textoDicho;

  /// Nulo si no se sabe si entró o salió plata.
  final TipoMovimiento? tipo;
  final List<PartidaVoz> partidas;

  /// Si hay duda sobre el monto, las opciones para preguntar (S18).
  final List<int> montosPosibles;

  /// Nombre de la categoría reconocida, si se reconoció.
  final String? categoria;

  /// Dijo que le prestaron plata: Moca avisa que no es venta (entrega
  /// 14.14).
  final bool prestamo;

  /// En un pase («pasé 500 de la caja a Yape»), a dónde va (entrega 21.1).
  final TipoCuenta? cuentaDestino;

  /// Todavía se debe (entrega 49): una venta a crédito («le fié 50 a doña
  /// Rosa») o una compra que se debe («me fiaron 150»). No mueve la plata,
  /// así que no se pregunta la cuenta.
  final bool debe;

  /// Quién debe o a quién se le debe, si se entendió («Doña Rosa»).
  final String? contraparte;

  /// Dijo que cobra o paga algo que se debía («cobré el fiado», «pagué lo
  /// que debía»), aunque no dijera de quién (entrega 50).
  final bool pagaDeuda;

  /// La deuda que se cobra o se paga con este monto (entrega 50).
  final DeudaDePersona? abono;

  /// El dueño dijo que no es de ninguna deuda: se anota aparte.
  final bool aparte;

  /// Puede ser el cobro o el pago de una deuda (entrega 50): un solo monto
  /// que entró o salió, con un nombre o diciendo que se debía.
  bool get buscaDeuda =>
      !debe &&
      !aparte &&
      abono == null &&
      partidas.length == 1 &&
      (tipo == TipoMovimiento.ingreso || tipo == TipoMovimiento.egreso) &&
      (pagaDeuda || contraparte != null);

  /// Una venta a crédito sin nombre: Moca lo pregunta.
  bool get faltaQuienDebe =>
      debe &&
      tipo == TipoMovimiento.ingreso &&
      (contraparte?.trim().isEmpty ?? true);

  bool get montoDudoso => montosPosibles.isNotEmpty;
  bool get entendida => partidas.isNotEmpty || montoDudoso;
}

sealed class EventoVoz {
  const EventoVoz();
}

/// Lo que va reconociendo mientras el dueño habla.
class VozParcial extends EventoVoz {
  const VozParcial(this.texto);

  final String texto;
}

/// El dueño terminó de hablar.
class VozFinal extends EventoVoz {
  const VozFinal(this.alternativas);

  final List<AlternativaVoz> alternativas;
}

enum FalloVoz { sinPermiso, noDisponible, nadaQueEscuchar }

class VozFallida extends EventoVoz {
  const VozFallida(this.motivo);

  final FalloVoz motivo;
}

/// Una frase que el operador de la prueba usa en lugar de la voz.
class FraseEjemplo {
  const FraseEjemplo(this.alternativas);

  /// La primera es la que «se escuchó»; las demás, otras lecturas posibles.
  final List<AlternativaVoz> alternativas;

  String get texto => alternativas.first.texto;
}

enum DisponibilidadVoz { disponible, sinPermiso, noDisponible }

/// El reconocimiento de voz. En el prototipo es el de Android; para la
/// prueba, el operador puede reemplazar la próxima grabación por una frase de
/// ejemplo.
abstract interface class ReconocedorVoz {
  /// Pide el permiso del micrófono si hace falta.
  Future<DisponibilidadVoz> preparar();

  /// Escucha hasta que el dueño calla unos segundos o se llama a [detener].
  Stream<EventoVoz> escuchar();

  Future<void> detener();
}

/// Lo que Moca pregunta, en orden, hasta tener todo para guardar.
sealed class PreguntaVoz {
  const PreguntaVoz();
}

/// S18: no escuchó bien el monto.
class PreguntaMonto extends PreguntaVoz {
  const PreguntaMonto(this.opciones);

  final List<int> opciones;
}

class PreguntaTipo extends PreguntaVoz {
  const PreguntaTipo();
}

class PreguntaCuenta extends PreguntaVoz {
  const PreguntaCuenta(this.indicePartida);

  final int indicePartida;
}

class PreguntaCategoria extends PreguntaVoz {
  const PreguntaCategoria();
}

/// En un pase: a dónde va la plata (entrega 21.1).
class PreguntaDestino extends PreguntaVoz {
  const PreguntaDestino();
}

/// En una venta a crédito sin nombre: quién debe (entrega 49).
class PreguntaQuienDebe extends PreguntaVoz {
  const PreguntaQuienDebe();
}

/// ¿Es de lo que debe esta persona? Con una sola, se confirma; con varias,
/// se elige (entrega 50).
class PreguntaDeuda extends PreguntaVoz {
  const PreguntaDeuda(this.opciones);

  final List<DeudaDePersona> opciones;
}

/// Dijo más de lo que se debe: no se descuenta solo (entrega 50).
class PreguntaMasDeLoQueSeDebe extends PreguntaVoz {
  const PreguntaMasDeLoQueSeDebe(this.deuda);

  final DeudaDePersona deuda;
}

// --- Cobrar o pagar una deuda por voz (entrega 50) ------------------------------

/// Lo que debe una persona, o lo que se le debe: sus deudas sin pagar, la
/// más antigua primero, con lo que falta de cada una.
class DeudaDePersona {
  const DeudaDePersona(this.nombre, this.deudas);

  final String nombre;
  final List<FilaHistorial> deudas;

  int get totalCentimos => deudas.fold(0, (s, d) => s + d.montoCentimos);
}

/// Junta las deudas por nombre, en el orden en que vienen (la más antigua
/// primero). Las que no tienen nombre no entran: se cobran desde «Lo que
/// te deben» o el Historial.
List<DeudaDePersona> agruparDeudas(List<FilaHistorial> filas) {
  final grupos = <String, (String, List<FilaHistorial>)>{};
  for (final f in filas) {
    final nombre = f.proveedor?.trim();
    if (nombre == null || nombre.isEmpty || f.montoCentimos <= 0) continue;
    final clave = _sinTitulo(nombre).join(' ');
    if (clave.isEmpty) continue;
    grupos.putIfAbsent(clave, () => (nombre, <FilaHistorial>[])).$2.add(f);
  }
  return [
    for (final (nombre, deudas) in grupos.values)
      DeudaDePersona(nombre, deudas),
  ];
}

const _titulos = {'don', 'dona', 'sr', 'sra', 'senor', 'senora', 'tio', 'tia'};

/// Las palabras del nombre, en minúsculas, sin tildes ni «don» o «doña».
List<String> _sinTitulo(String nombre) {
  const tildes = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var t = nombre.toLowerCase();
  tildes.forEach((con, sin) => t = t.replaceAll(con, sin));
  return [
    for (final p in t.replaceAll('.', ' ').split(RegExp(r'\s+')))
      if (p.isNotEmpty && !_titulos.contains(p)) p,
  ];
}

/// El nombre dicho coincide con el de la deuda si todas sus palabras están
/// en el otro: «Rosa» es «Doña Rosa» y «Rosa Pérez».
bool mismoNombre(String dicho, String guardado) {
  final a = _sinTitulo(dicho);
  final b = _sinTitulo(guardado);
  if (a.isEmpty || b.isEmpty) return false;
  return a.every(b.contains) || b.every(a.contains);
}

/// De qué deudas puede ser lo que se dijo. Con nombre, las de esa persona;
/// si nadie se llama así o no dijo nombre, todas, pero solo si dijo que se
/// debía. Vacío: se anota como siempre.
List<DeudaDePersona> deudasPosibles(
  LecturaVoz lectura,
  List<DeudaDePersona> deudas,
) {
  if (!lectura.buscaDeuda) return const [];
  if (lectura.contraparte case final dicho?) {
    final suyas = [
      for (final d in deudas)
        if (mismoNombre(dicho, d.nombre)) d,
    ];
    if (suyas.isNotEmpty) return suyas;
  }
  return lectura.pagaDeuda ? deudas : const [];
}

/// Cómo se reparte el monto: primero la deuda más antigua. Las que alcanza
/// se pagan completas (parte nula) y la última, en parte.
List<(FilaHistorial, int?)> repartirAbono(DeudaDePersona deuda, int centimos) {
  final reparto = <(FilaHistorial, int?)>[];
  var queda = centimos;
  for (final d in deuda.deudas) {
    if (queda <= 0) break;
    if (queda >= d.montoCentimos) {
      reparto.add((d, null));
      queda -= d.montoCentimos;
    } else {
      reparto.add((d, queda));
      queda = 0;
    }
  }
  return reparto;
}

/// Qué falta preguntar. Nulo si ya está todo. [categoriasValidas] y
/// [cuentasValidas] son las del negocio: una categoría o una cuenta
/// reconocida que el negocio no tiene se pregunta («por Plin» sin Plin).
PreguntaVoz? siguientePregunta(
  LecturaVoz lectura, {
  required Set<String> categoriasValidas,
  Set<TipoCuenta> cuentasValidas = const {...TipoCuenta.values},
  Set<TipoCuenta>? destinosValidos,
  List<DeudaDePersona> deudasPosibles = const [],
}) {
  if (lectura.montoDudoso) return PreguntaMonto(lectura.montosPosibles);
  if (lectura.tipo == null) return const PreguntaTipo();
  final variosBancos = cuentasValidas.where((c) => c.esBanco).length > 1;
  final variosPlin = cuentasValidas.where((c) => c.esPlin).length > 1;
  // Lo que se debe no mueve ninguna cuenta: no se pregunta (entrega 49).
  for (final (i, partida)
      in lectura.debe
          ? const <(int, PartidaVoz)>[]
          : lectura.partidas.indexed) {
    if (!cuentasValidas.contains(partida.cuenta) ||
        (partida.bancoSinNombre && variosBancos) ||
        (partida.plinSinBanco && variosPlin)) {
      return PreguntaCuenta(i);
    }
  }
  if (lectura.tipo?.esPase ?? false) {
    final destino = lectura.cuentaDestino;
    final origen = lectura.partidas.firstOrNull?.cuenta;
    if (destino == null ||
        destino == origen ||
        !(destinosValidos ?? cuentasValidas).contains(destino)) {
      return const PreguntaDestino();
    }
    return null;
  }
  // Cobrar o pagar una deuda (entrega 50): no hace falta la categoría.
  if (lectura.abono case final deuda?) {
    final monto = lectura.partidas.single.centimos;
    return monto > deuda.totalCentimos ? PreguntaMasDeLoQueSeDebe(deuda) : null;
  }
  if (deudasPosibles.isNotEmpty) return PreguntaDeuda(deudasPosibles);
  if (!(lectura.tipo?.sinCategoria ?? false) &&
      !categoriasValidas.contains(lectura.categoria)) {
    return const PreguntaCategoria();
  }
  if (lectura.faltaQuienDebe) return const PreguntaQuienDebe();
  return null;
}

extension RespuestasVoz on LecturaVoz {
  LecturaVoz _con({
    TipoMovimiento? tipo,
    List<PartidaVoz>? partidas,
    List<int>? montosPosibles,
    String? categoria,
    TipoCuenta? cuentaDestino,
  }) => LecturaVoz(
    textoDicho: textoDicho,
    tipo: tipo ?? this.tipo,
    partidas: partidas ?? this.partidas,
    montosPosibles: montosPosibles ?? this.montosPosibles,
    categoria: categoria ?? this.categoria,
    prestamo: prestamo,
    cuentaDestino: cuentaDestino ?? this.cuentaDestino,
    debe: debe,
    contraparte: contraparte,
    pagaDeuda: pagaDeuda,
    abono: abono,
    aparte: aparte,
  );

  /// Es de lo que debe esta persona (entrega 50).
  LecturaVoz conAbono(DeudaDePersona deuda) => LecturaVoz(
    textoDicho: textoDicho,
    tipo: tipo,
    partidas: partidas,
    montosPosibles: montosPosibles,
    categoria: categoria,
    prestamo: prestamo,
    cuentaDestino: cuentaDestino,
    contraparte: contraparte,
    pagaDeuda: pagaDeuda,
    abono: deuda,
  );

  /// No es de ninguna deuda: se anota aparte, como siempre (entrega 50).
  LecturaVoz comoAparte() => LecturaVoz(
    textoDicho: textoDicho,
    tipo: tipo,
    partidas: partidas,
    montosPosibles: montosPosibles,
    categoria: categoria,
    prestamo: prestamo,
    cuentaDestino: cuentaDestino,
    contraparte: contraparte,
    pagaDeuda: pagaDeuda,
    aparte: true,
  );

  /// El nombre de quien debe, escrito o corregido (entrega 49).
  LecturaVoz conContraparte(String nombre) => LecturaVoz(
    textoDicho: textoDicho,
    tipo: tipo,
    partidas: partidas,
    montosPosibles: montosPosibles,
    categoria: categoria,
    prestamo: prestamo,
    cuentaDestino: cuentaDestino,
    debe: debe,
    contraparte: nombre.trim().isEmpty ? null : nombre.trim(),
    pagaDeuda: pagaDeuda,
    abono: abono,
    aparte: aparte,
  );

  /// El dueño eligió o escribió el monto: queda una sola partida, con la
  /// cuenta que se haya dicho.
  LecturaVoz conMonto(int centimos) => _con(
    partidas: [
      PartidaVoz(centimos, partidas.isEmpty ? null : partidas.first.cuenta),
    ],
    montosPosibles: const [],
  );

  LecturaVoz conTipo(TipoMovimiento tipo) => _con(tipo: tipo);

  /// Sin el tipo entendido, para preguntarlo: quien no es dueño no anota
  /// retiros ni aportes (entrega 20).
  LecturaVoz sinTipo() => LecturaVoz(
    textoDicho: textoDicho,
    partidas: partidas,
    montosPosibles: montosPosibles,
    categoria: categoria,
    debe: debe,
    contraparte: contraparte,
    pagaDeuda: pagaDeuda,
  );

  LecturaVoz conCuenta(int indicePartida, TipoCuenta cuenta) => _con(
    partidas: [
      for (final (i, p) in partidas.indexed)
        i == indicePartida ? p.conCuenta(cuenta) : p,
    ],
  );

  LecturaVoz conCategoria(String categoria) => _con(categoria: categoria);

  LecturaVoz conDestino(TipoCuenta cuenta) => _con(cuentaDestino: cuenta);

  /// «Por Plin» sin banco va al único Plin que tenga el negocio.
  LecturaVoz conPlinDelNegocio(Set<TipoCuenta> cuentas) {
    final plin = cuentas.where((c) => c.esPlin).toList();
    if (plin.length != 1) return this;
    return _con(
      partidas: [
        for (final p in partidas) p.plinSinBanco ? p.conCuenta(plin.single) : p,
      ],
    );
  }
}
