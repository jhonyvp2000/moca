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

  /// Al vencer: se anota y se baja el Excel, nada más.
  bool get soloAnotar => estado == EstadoDelCobro.vencido;

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
    );
  }
}

enum RespuestaPrecio { si, noSe, no }
