/// El cobro manual por Yape (entregas 24 y 25; decisiones.md, 03-11-2026).
/// El servidor dice el estado del negocio; el teléfono guarda el último y,
/// sin señal, lo pone al día con la fecha.
enum EstadoDelCobro { sinCobro, prueba, pagado, vencido }

class Cobro {
  const Cobro({
    required this.estado,
    this.hasta,
    this.dias,
    this.porVencer = false,
    this.plan,
    this.precioCentimos = 1990,
    this.yape,
    this.nombreYape,
    this.admin = false,
    this.respondio = false,
    this.mercadoPago = false,
  });

  static const sinCobro = Cobro(estado: EstadoDelCobro.sinCobro);

  /// Lo que manda el servidor en «cobro» (`servidor/README.md`).
  factory Cobro.desdeServidor(Map<String, Object?> json) {
    final pago = json['pago'];
    return Cobro(
      estado: switch (json['estado']) {
        'prueba' => EstadoDelCobro.prueba,
        'pagado' => EstadoDelCobro.pagado,
        'vencido' => EstadoDelCobro.vencido,
        _ => EstadoDelCobro.sinCobro,
      },
      hasta: switch (json['hasta']) {
        final String dia => DateTime.tryParse(dia),
        _ => null,
      },
      dias: json['dias'] as int?,
      porVencer: json['porVencer'] == true,
      plan: json['plan'] as String?,
      precioCentimos: json['precio'] as int? ?? 1990,
      yape: pago is Map ? pago['yape'] as String? : null,
      nombreYape: pago is Map ? pago['nombre'] as String? : null,
      admin: json['admin'] == true,
      respondio: json['respondio'] == true,
      mercadoPago: json['mercadopago'] == true,
    );
  }

  final EstadoDelCobro estado;

  /// El último día de la prueba o de lo pagado.
  final DateTime? hasta;

  /// Días que quedan después de hoy (0: hoy es el último).
  final int? dias;
  final bool porVencer;
  final String? plan;

  /// Lo que se cobraría ahora: S/ 14.90 de fundador o S/ 19.90.
  final int precioCentimos;

  /// A dónde yapear; nulo si el servidor todavía no lo tiene.
  final String? yape;
  final String? nombreYape;

  /// Quien registra los pagos (entrega 26).
  final bool admin;

  /// Ya contestó la pregunta del día 10.
  final bool respondio;

  /// Se puede pagar con Mercado Pago (entrega 32).
  final bool mercadoPago;

  /// Al vencer: se anota y se baja el Excel, nada más.
  bool get soloAnotar => estado == EstadoDelCobro.vencido;

  /// Hasta cuántos días pagados se ofrece «Pagar otro mes» (entrega 32.2):
  /// como mucho, unos 3 meses por delante.
  static const diasParaAdelantar = 60;

  /// Pagada y lejos de vencer: «Pagar otro mes» por adelantado.
  bool get puedeAdelantar =>
      estado == EstadoDelCobro.pagado &&
      !porVencer &&
      hasta != null &&
      (dias ?? diasParaAdelantar) < diasParaAdelantar;

  /// Lo que cubriría un pago más si ya está pagada: sigue a lo pagado, como
  /// en el servidor (`periodoDelPago`). Nulo si no está pagada.
  ({DateTime desde, DateTime hasta})? get siguienteMes {
    final ultimo = hasta;
    if (estado != EstadoDelCobro.pagado || ultimo == null) return null;
    final desde = DateTime(ultimo.year, ultimo.month, ultimo.day + 1);
    // Un mes después, con el día ajustado al mes («31 de enero» → «28 de
    // febrero»), menos un día.
    final diasDelMes = DateTime(desde.year, desde.month + 2, 0).day;
    final mes = DateTime(
      desde.year,
      desde.month + 1,
      desde.day > diasDelMes ? diasDelMes : desde.day,
    );
    return (desde: desde, hasta: DateTime(mes.year, mes.month, mes.day - 1));
  }

  /// La pregunta del día 10 de la prueba: quedan 4 días o menos.
  bool get tocaPreguntar =>
      estado == EstadoDelCobro.prueba &&
      hasta != null &&
      (dias ?? 14) <= 4 &&
      !respondio;

  /// El estado con la fecha de hoy: si pasó el último día sin señal para
  /// preguntar, vence igual.
  Cobro alDia(DateTime hoy) {
    final ultimo = hasta;
    if (ultimo == null ||
        (estado != EstadoDelCobro.prueba && estado != EstadoDelCobro.pagado)) {
      return this;
    }
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    final restan = DateTime(
      ultimo.year,
      ultimo.month,
      ultimo.day,
    ).difference(dia).inDays;
    return Cobro(
      estado: restan < 0 ? EstadoDelCobro.vencido : estado,
      hasta: hasta,
      dias: restan < 0 ? null : restan,
      porVencer: restan >= 0 && restan <= 3,
      plan: plan,
      precioCentimos: precioCentimos,
      yape: yape,
      nombreYape: nombreYape,
      admin: admin,
      respondio: respondio,
      mercadoPago: mercadoPago,
    );
  }
}

/// Pagar con Mercado Pago (entrega 32): la orden y la página de pago.
class InicioDePago {
  const InicioDePago({required this.orden, required this.enlace});

  final String orden;
  final String enlace;
}

enum ErrorDePago { sinSenal, noDisponible, soloDuenos, fallo }

typedef ResultadoInicioDePago = ({InicioDePago? inicio, ErrorDePago? error});

/// Cómo va la orden: la app pregunta cada 3 segundos al volver de pagar.
enum EstadoDeOrden { pendiente, pagada, revisar, reembolsada, sinSenal }

/// La orden y, ya pagada, hasta cuándo quedó pagado Moca.
typedef OrdenDePago = ({EstadoDeOrden estado, DateTime? hasta});

enum RespuestaPrecio { si, noSe, no }

/// Lo que Jhony registra (entrega 26).
enum PlanCobro { normal, fundador, anual }

/// Un pago registrado.
class PagoRegistrado {
  const PagoRegistrado({
    this.id = '',
    this.anulado = false,
    required this.plan,
    required this.montoCentimos,
    required this.desde,
    required this.hasta,
    this.nota,
  });

  final String id;

  /// Anulado por error o de prueba (entrega 26.1): queda en la lista.
  final bool anulado;
  final PlanCobro plan;
  final int montoCentimos;
  final DateTime desde;
  final DateTime hasta;
  final String? nota;
}

/// Lo que contestó el negocio a la pregunta del día 10.
class RespuestaRegistrada {
  const RespuestaRegistrada({
    required this.respuesta,
    required this.precioCentimos,
    this.motivo,
  });

  final RespuestaPrecio respuesta;
  final int precioCentimos;
  final String? motivo;
}

/// Cómo usó Moca un negocio en los últimos 7 días (entrega 28): lo que
/// responde las preguntas del piloto.
class UsoDelNegocio {
  const UsoDelNegocio({
    this.diasQueAbrio = 0,
    this.diasQueAnoto = 0,
    this.ventasAnotadas = 0,
    this.segundosParaAnotar,
    this.vozConDuda = 0,
    this.vozCorregida = 0,
    this.fotosIlegibles = 0,
    this.avisosRespondidos = 0,
    this.avisosAbiertos = 0,
    this.arqueosAbiertos = 0,
    this.informesAbiertos = 0,
    this.ultimaApertura,
  });

  final int diasQueAbrio;
  final int diasQueAnoto;
  final int ventasAnotadas;

  /// Lo típico (la mediana); nulo sin ventas.
  final int? segundosParaAnotar;
  final int vozConDuda;
  final int vozCorregida;
  final int fotosIlegibles;
  final int avisosRespondidos;
  final int avisosAbiertos;
  final int arqueosAbiertos;
  final int informesAbiertos;
  final DateTime? ultimaApertura;
}

/// Un negocio como lo ve quien registra los pagos.
class FichaDeCobro {
  const FichaDeCobro({
    required this.empresaId,
    required this.nombre,
    required this.cobro,
    this.celular,
    this.pagos = const [],
    this.respuestas = const [],
    this.uso,
    this.ultimaApertura,
  });

  final String empresaId;
  final String nombre;

  /// Los 9 dígitos del titular.
  final String? celular;
  final Cobro cobro;
  final List<PagoRegistrado> pagos;
  final List<RespuestaRegistrada> respuestas;
  final UsoDelNegocio? uso;

  /// En «Sin abrir Moca»: la última vez que la abrió; nula si nunca.
  final DateTime? ultimaApertura;
}

class ResumenDeCobros {
  const ResumenDeCobros({
    required this.fundadores,
    required this.maximoFundadores,
    required this.negocios,
    this.sinAbrir = const [],
    this.porRevisar = const [],
  });

  final int fundadores;
  final int maximoFundadores;

  /// Lo que vence en 3 días o menos y lo ya vencido.
  final List<FichaDeCobro> negocios;

  /// Los que no abren Moca hace 3 días o más (entrega 28).
  final List<FichaDeCobro> sinAbrir;

  /// Lo cobrado por Mercado Pago que no se aplicó solo (entrega 32).
  final List<PagoPorRevisar> porRevisar;
}

/// Un pago de Mercado Pago que Jhony resuelve a mano: cobró menos, ya no le
/// tocaba el plan, o se devolvió un pago que no era el último.
class PagoPorRevisar {
  const PagoPorRevisar({
    required this.nombre,
    required this.motivo,
    this.celular,
    this.operacion,
    this.montoCentimos = 0,
  });

  final String nombre;
  final String? celular;
  final String motivo;
  final String? operacion;
  final int montoCentimos;
}

enum ResultadoCobro {
  listo,
  sinSenal,
  sinPermiso,
  noEncontrado,

  /// Renovó más de 30 días tarde: paga S/ 19.90.
  perdioFundador,

  /// Ya hay 50 fundadores.
  sinCupoFundador,

  /// Solo se anula el último pago de un negocio.
  noEsElUltimo,
  error,
}

/// La pantalla de cobros de Jhony (entrega 26). Solo funciona con los
/// números que el servidor reconoce.
abstract interface class ServicioPagos {
  Future<ResumenDeCobros?> resumen();

  Future<(FichaDeCobro?, ResultadoCobro)> buscar(String celular);

  /// Anula el último pago del negocio (entrega 26.1).
  Future<(FichaDeCobro?, ResultadoCobro)> anularPago(String pagoId);

  Future<(FichaDeCobro?, ResultadoCobro)> registrarPago(
    String empresaId,
    PlanCobro plan, {
    String? nota,
  });
}
