import 'modelos.dart';

enum TipoAviso { faltaArqueo, diferenciaArqueo, diasSinRegistrar, gastoAtipico }

/// Un aviso de la pestaña Moca. Lo disparan reglas sobre los datos; el texto
/// lo arma la pantalla con plantillas.
class Aviso {
  const Aviso({
    required this.clave,
    required this.tipo,
    required this.prioridad,
    required this.fecha,
    this.montoCentimos,
    this.cuenta,
    this.categoria,
    this.dias,
    this.destinoId,
  });

  /// Identifica el aviso para no volver a mostrarlo si se marcó «Entendido».
  final String clave;
  final TipoAviso tipo;
  final PrioridadAlerta prioridad;
  final DateTime fecha;
  final int? montoCentimos;
  final TipoCuenta? cuenta;
  final String? categoria;

  /// Días seguidos sin anotar.
  final int? dias;

  /// El movimiento o el ajuste del arqueo al que lleva.
  final String? destinoId;

  /// Los que se resuelven solos (arqueo, días sin anotar) no se descartan.
  bool get descartable =>
      tipo == TipoAviso.diferenciaArqueo || tipo == TipoAviso.gastoAtipico;
}

/// El resumen de la semana para la tarjeta de arriba de la pestaña Moca.
class ResumenSemana {
  const ResumenSemana({
    required this.semanaPasada,
    required this.conMovimientos,
    required this.quedoCentimos,
    this.diferenciaCentimos,
    this.categoriaTop,
    this.categoriaTopCentimos,
  });

  /// Verdadero si resume la semana pasada completa; falso si es lo que va de
  /// la semana.
  final bool semanaPasada;
  final bool conMovimientos;
  final int quedoCentimos;

  /// Frente a la semana anterior a la resumida. Nulo si no hubo.
  final int? diferenciaCentimos;
  final String? categoriaTop;
  final int? categoriaTopCentimos;
}

abstract interface class RepositorioMoca {
  /// Por prioridad y fecha, los más recientes primero.
  Stream<List<Aviso>> observarAvisos();

  Stream<ResumenSemana> observarResumen();

  /// «Entendido»: no se vuelve a mostrar.
  Future<void> descartar(Aviso aviso);
}
