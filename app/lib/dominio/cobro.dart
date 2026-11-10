/// El cobro manual por Yape (entregas 24 y 25; decisiones.md, 03-11-2026).
/// El servidor dice el estado del negocio; el teléfono guarda el último y,
/// sin señal, lo pone al día con la fecha.
enum EstadoDelCobro { sinCobro, prueba, pagado, vencido }

/// Básico o Full (entrega 43; decisiones.md, 09-11-2026).
enum NivelDePlan { basico, full }

/// Lo que pagaría con un plan: el monto y cuántas personas extra lleva.
class OpcionDePlan {
  const OpcionDePlan({
    required this.plan,
    required this.precioCentimos,
    this.extras = 0,
  });

  static OpcionDePlan? desdeServidor(Object? json) => json is Map
      ? OpcionDePlan(
          plan: PlanCobro.values.asNameMap()[json['plan']] ?? PlanCobro.normal,
          precioCentimos: json['precio'] as int? ?? 0,
          extras: json['extras'] as int? ?? 0,
        )
      : null;

  Map<String, Object?> aJson() => {
    'plan': plan.name,
    'precio': precioCentimos,
    'extras': extras,
  };

  final PlanCobro plan;
  final int precioCentimos;

  /// Personas por encima de las que incluye el plan.
  final int extras;

  NivelDePlan get nivel =>
      plan == PlanCobro.basico ? NivelDePlan.basico : NivelDePlan.full;

  /// El precio del plan solo, sin las personas extra.
  int get precioBaseCentimos => precioDelPlan(plan);
}

/// Lo que cuesta cada plan al mes, o al año el anual, como en el servidor.
int precioDelPlan(PlanCobro plan) => switch (plan) {
  PlanCobro.basico => 1490,
  PlanCobro.normal => 1990,
  PlanCobro.fundador => 1490,
  PlanCobro.anual => 19900,
};

/// Cada persona más: S/ 2.90 al mes, S/ 34.80 al año.
int precioPersonaExtra(PlanCobro plan) => plan == PlanCobro.anual ? 3480 : 290;

/// Personas que incluye el plan, con el titular; el contador no cuenta.
int personasIncluidas(PlanCobro plan) => plan == PlanCobro.basico ? 1 : 3;

int extrasPara(PlanCobro plan, int personas) {
  final extras = personas - personasIncluidas(plan);
  return extras < 0 ? 0 : extras;
}

int precioConExtras(PlanCobro plan, int personas) =>
    precioDelPlan(plan) + extrasPara(plan, personas) * precioPersonaExtra(plan);

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
    this.nivel = NivelDePlan.full,
    this.personas = 1,
    this.incluidas = 3,
    this.credito = true,
    this.opcionFull,
    this.opcionBasico,
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
      // Los planes (entrega 43). Sin ellos (servidor anterior), Full.
      nivel: json['nivel'] == 'basico' ? NivelDePlan.basico : NivelDePlan.full,
      personas: json['personas'] as int? ?? 1,
      incluidas: json['incluidas'] as int? ?? 3,
      credito: json['credito'] != false,
      opcionFull: switch (json['opciones']) {
        final Map<Object?, Object?> o => OpcionDePlan.desdeServidor(o['full']),
        _ => null,
      },
      opcionBasico: switch (json['opciones']) {
        final Map<Object?, Object?> o => OpcionDePlan.desdeServidor(
          o['basico'],
        ),
        _ => null,
      },
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

  /// El plan que tiene: Full en la prueba y sin pagos (entrega 43).
  final NivelDePlan nivel;

  /// Personas del negocio sin el contador, y las que incluye su plan.
  final int personas;
  final int incluidas;

  /// Puede armar «Para pedir un crédito»: solo el Full.
  final bool credito;

  /// Lo que pagaría con cada plan; al fundador no se le ofrece el Básico.
  final OpcionDePlan? opcionFull;
  final OpcionDePlan? opcionBasico;

  /// El Full, aunque el servidor todavía no mande las opciones.
  OpcionDePlan get full =>
      opcionFull ??
      OpcionDePlan(
        plan: precioCentimos < 1990 ? PlanCobro.fundador : PlanCobro.normal,
        precioCentimos: precioCentimos,
      );

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
      nivel: nivel,
      personas: personas,
      incluidas: incluidas,
      credito: credito,
      opcionFull: opcionFull,
      opcionBasico: opcionBasico,
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

/// Lo que Jhony registra (entrega 26). «basico» es el Básico (entrega 43);
/// los demás son el Full.
enum PlanCobro { basico, normal, fundador, anual }

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
    this.personasExtra = 0,
  });

  final String id;

  /// Las personas extra que se cobraron (entrega 43).
  final int personasExtra;

  /// Anulado por error o de prueba (entrega 26.1): queda en la lista.
  final bool anulado;
  final PlanCobro plan;
  final int montoCentimos;
  final DateTime desde;
  final DateTime hasta;
  final String? nota;
}

/// «Mis pagos de Moca» (entrega 33): lo que el dueño pagó, para verlo él.
enum MedioDePago { mercadoPago, yape }

class PagoDeMoca {
  const PagoDeMoca({
    required this.plan,
    required this.montoCentimos,
    required this.desde,
    required this.hasta,
    required this.pagadoEn,
    required this.medio,
    this.operacion,
    this.anulado = false,
    this.personasExtra = 0,
  });

  final PlanCobro plan;

  /// Las personas extra que se cobraron (entrega 43).
  final int personasExtra;
  final int montoCentimos;
  final DateTime desde;
  final DateTime hasta;
  final DateTime pagadoEn;
  final MedioDePago medio;

  /// El número de operación de Mercado Pago; del Yape no va la nota.
  final String? operacion;

  /// Anulado o devuelto: no cuenta.
  final bool anulado;
}

class MisPagos {
  const MisPagos({
    required this.pagos,
    required this.actualizado,
    this.enRevision = 0,
  });

  /// Lo que manda el servidor en `/cobro/mis-pagos`.
  factory MisPagos.desdeServidor(
    Map<String, Object?> json,
    DateTime actualizado,
  ) {
    DateTime dia(Object? v) =>
        (v is String ? DateTime.tryParse(v) : null) ?? DateTime(2000);
    return MisPagos(
      actualizado: actualizado,
      enRevision: (json['en_revision'] as List? ?? const []).length,
      pagos: [
        for (final p in (json['pagos'] as List? ?? const []))
          if (p case final Map<String, Object?> p)
            PagoDeMoca(
              plan: PlanCobro.values.asNameMap()[p['plan']] ?? PlanCobro.normal,
              montoCentimos: p['monto_centimos'] as int? ?? 0,
              personasExtra: p['personas_extra'] as int? ?? 0,
              desde: dia(p['desde']),
              hasta: dia(p['hasta']),
              pagadoEn: dia(p['pagado_en']).toLocal(),
              medio: p['medio'] == 'mercadopago'
                  ? MedioDePago.mercadoPago
                  : MedioDePago.yape,
              operacion: p['operacion'] as String?,
              anulado: p['anulado'] == true,
            ),
      ],
    );
  }

  /// Del más nuevo al más viejo.
  final List<PagoDeMoca> pagos;

  /// Cobros de Mercado Pago que Jhony todavía tiene que revisar.
  final int enRevision;

  /// Cuándo bajó del servidor: sin señal se muestra lo último.
  final DateTime actualizado;
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

/// Una persona del negocio en la ficha de soporte (entrega 47).
class PersonaDeSoporte {
  const PersonaDeSoporte({
    required this.rol,
    this.titular = false,
    this.nombre,
    this.celular,
    this.version,
    this.subioEn,
  });

  final String rol;
  final bool titular;
  final String? nombre;
  final String? celular;

  /// «entrega-47 (180)»; nulo si todavía no subió con una versión que lo
  /// diga.
  final String? version;
  final DateTime? subioEn;
}

/// Una invitación en la ficha de soporte: vigente, vencida, aceptada o
/// anulada.
class InvitacionDeSoporte {
  const InvitacionDeSoporte({
    required this.celular,
    required this.rol,
    required this.estado,
    this.nombre,
  });

  final String celular;
  final String rol;
  final String estado;
  final String? nombre;
}

/// Un negocio en el que está un número (entrega 47).
class NegocioDeSoporte {
  const NegocioDeSoporte({
    required this.empresaId,
    required this.nombre,
    required this.rol,
    this.titular = false,
  });

  final String empresaId;
  final String nombre;
  final String rol;
  final bool titular;
}

/// Lo que se sabe de un número: si tiene cuenta y en qué negocios está.
class BusquedaDeSoporte {
  const BusquedaDeSoporte({
    required this.tieneCuenta,
    this.negocios = const [],
  });

  final bool tieneCuenta;
  final List<NegocioDeSoporte> negocios;
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
    this.personas = const [],
    this.invitaciones = const [],
    this.registros,
  });

  /// La ficha de soporte (entrega 47): quiénes están, con su versión y su
  /// última subida, las invitaciones y cuántos registros hay.
  final List<PersonaDeSoporte> personas;
  final List<InvitacionDeSoporte> invitaciones;
  final int? registros;

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

  /// Días de prueba: el negocio ya pagó alguna vez, o ya tiene muchos.
  yaPago,
  demasiadosDias,

  /// Para borrar hay que escribir el nombre del negocio.
  sinConfirmacion,
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

  /// Soporte (entrega 47): un número cualquiera, con sus negocios.
  Future<(BusquedaDeSoporte?, ResultadoCobro)> buscarNumero(String celular);

  /// La ficha de un negocio por su id.
  Future<(FichaDeCobro?, ResultadoCobro)> fichaDeNegocio(String empresaId);

  /// 7 o 14 días más de prueba, a un negocio que nunca pagó.
  Future<(FichaDeCobro?, ResultadoCobro)> darDiasDePrueba(
    String empresaId,
    int dias,
  );

  /// Borra el negocio a pedido de su titular, con su nombre escrito.
  Future<ResultadoCobro> borrarNegocio(String empresaId, String confirmacion);
}
