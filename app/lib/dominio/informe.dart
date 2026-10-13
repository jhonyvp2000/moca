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

/// El informe de un mes (S14). Las cifras vienen calculadas de la capa de
/// datos; la pantalla y el PDF solo las muestran.
class InformeMes {
  const InformeMes({
    required this.mes,
    required this.enCurso,
    required this.sinRegistros,
    required this.entroCentimos,
    required this.salioCentimos,
    required this.retirosCentimos,
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

  /// Ganancia menos la del mes anterior (hasta el mismo día si el mes está
  /// en curso). Nulo sin mes anterior.
  final int? diferenciaConAnteriorCentimos;

  final int entroCentimos;
  final int salioCentimos;
  final int retirosCentimos;

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

  int get gananciaCentimos => entroCentimos - salioCentimos;
  int get quedoCentimos => gananciaCentimos - retirosCentimos;
}

abstract interface class RepositorioInforme {
  /// El informe del mes que empieza en [mes]; nulo es el mes en curso.
  Stream<InformeMes> observarMes(DateTime? mes);
}
