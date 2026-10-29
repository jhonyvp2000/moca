/// Una categoría en «En qué se fue la plata». Nulo en [nombre] es «Lo
/// demás».
class GastoPorCategoria {
  const GastoPorCategoria({required this.nombre, required this.centimos});

  final String? nombre;
  final int centimos;
}

/// La categoría que más cambió frente al mes anterior.
class CambioDeCategoria {
  const CambioDeCategoria({required this.nombre, required this.centimos});

  final String nombre;

  /// Positivo si subió; negativo si bajó.
  final int centimos;
}

/// Qué parte del monto del mes tiene sustento, en porcentajes que suman 100.
class ConfianzaDelMes {
  const ConfianzaDelMes({
    required this.conComprobante,
    required this.conFoto,
    required this.sinPapel,
  });

  final int conComprobante;
  final int conFoto;
  final int sinPapel;
}

/// El informe de un mes (S14): el flujo de caja del mes, que cuadra con el
/// saldo (decisiones.md, 29-10-2026). Todo cuenta el día en que la plata se
/// movió. Moca no muestra ganancia: no sabe cuánta mercadería queda. Las
/// cifras vienen calculadas de la capa de datos; la pantalla y el PDF solo
/// las muestran.
class InformeMes {
  const InformeMes({
    required this.mes,
    required this.enCurso,
    required this.sinRegistros,
    required this.inicioCentimos,
    required this.entroCentimos,
    required this.salioCentimos,
    required this.retirosCentimos,
    required this.ajustesCentimos,
    required this.gastos,
    required this.loQueDebesCentimos,
    required this.advertenciaMercaderia,
    this.desdeDia,
    this.mesAnterior,
    this.diferenciaConAnteriorCentimos,
    this.cambio,
    this.confianza,
    this.mesPrevio,
    this.mesSiguiente,
  });

  /// El primer día del mes.
  final DateTime mes;
  final bool enCurso;
  final bool sinRegistros;

  /// Si el primer mes con Moca empezó a mitad: el día en que empezó.
  final int? desdeDia;

  /// Nulo si es el primer mes con Moca.
  final DateTime? mesAnterior;

  /// Cuánto más creció (o menos) la plata que en el mes anterior, hasta el
  /// mismo día si el mes está en curso. Nulo sin mes anterior.
  final int? diferenciaConAnteriorCentimos;

  /// La plata al empezar el mes (o al empezar con Moca, si fue a mitad).
  final int inicioCentimos;

  /// Lo que entró y salió del negocio, y lo que el dueño retiró para sí.
  final int entroCentimos;
  final int salioCentimos;
  final int retirosCentimos;

  /// Las diferencias del arqueo que cambiaron el saldo sin ser venta ni
  /// gasto: positivo si sobró plata.
  final int ajustesCentimos;

  /// De mayor a menor; a lo más cinco filas.
  final List<GastoPorCategoria> gastos;

  /// Nulo si no hay mes anterior. Si no hubo un cambio grande, [cambio] es
  /// nulo y [mesAnterior] no: «Casi nada cambió».
  final CambioDeCategoria? cambio;

  /// Todo lo que se debe hoy, de cualquier mes.
  final int loQueDebesCentimos;

  /// Nulo si el mes no tiene montos.
  final ConfianzaDelMes? confianza;
  final bool advertenciaMercaderia;

  /// Para las flechas: el mes anterior y el siguiente con informe, o nulo.
  final DateTime? mesPrevio;
  final DateTime? mesSiguiente;

  /// Cuánto creció la plata en el mes; negativo si bajó.
  int get crecioCentimos =>
      entroCentimos - salioCentimos - retirosCentimos + ajustesCentimos;

  /// La plata al terminar el mes; en el mes en curso, la de hoy.
  int get finCentimos => inicioCentimos + crecioCentimos;
}

abstract interface class RepositorioInforme {
  /// El informe del mes que empieza en [mes]; nulo es el mes en curso.
  Stream<InformeMes> observarMes(DateTime? mes);
}
