import 'modelos.dart';

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
    this.aportesCentimos = 0,
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

  /// Lo que el dueño puso de su bolsillo (entrega 14.11): no es venta.
  final int aportesCentimos;

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
      entroCentimos +
      aportesCentimos -
      salioCentimos -
      retirosCentimos +
      ajustesCentimos;

  /// La plata al terminar el mes; en el mes en curso, la de hoy.
  int get finCentimos => inicioCentimos + crecioCentimos;
}

/// Para quién es el PDF del informe (entrega 14.12): los mismos datos,
/// distinto detalle.
enum DestinoInforme { dueno, contador, credito }

/// Una compra que todavía se debe.
class DeudaPendiente {
  const DeudaPendiente({
    required this.fecha,
    required this.centimos,
    this.proveedor,
    this.categoria,
  });

  final DateTime fecha;
  final int centimos;
  final String? proveedor;
  final String? categoria;
}

/// Un comprobante del mes, por su fecha de emisión (para el contador).
class ComprobanteDelMes {
  const ComprobanteDelMes({
    required this.fecha,
    required this.totalCentimos,
    required this.pagado,
    this.tipo,
    this.serie,
    this.numero,
    this.ruc,
    this.proveedor,
    this.igvCentimos,
  });

  final DateTime fecha;
  final int totalCentimos;
  final bool pagado;
  final String? tipo;
  final String? serie;
  final String? numero;
  final String? ruc;
  final String? proveedor;
  final int? igvCentimos;
}

/// Lo que el PDF muestra además del informe (entrega 14.12). Se calcula en
/// el teléfono con lo anotado y las mismas reglas del informe.
class DetalleParaPdf {
  const DetalleParaPdf({
    required this.desde,
    required this.hasta,
    required this.saldosAlCierre,
    required this.ingresos,
    required this.deudas,
    required this.comprobantes,
    required this.meses,
    this.operaciones = const [],
  });

  /// El primer y el último día que cubre el informe.
  final DateTime desde;
  final DateTime hasta;

  /// Cuánto había en cada cuenta al terminar el periodo; suman
  /// [InformeMes.finCentimos].
  final Map<TipoCuenta, int> saldosAlCierre;

  /// De dónde vino la plata que entró, por categoría.
  final List<GastoPorCategoria> ingresos;

  /// Todo lo que se debe hoy, de lo más antiguo a lo más nuevo.
  final List<DeudaPendiente> deudas;

  /// Los comprobantes emitidos en el mes.
  final List<ComprobanteDelMes> comprobantes;

  /// Hasta seis meses, del más antiguo al del informe (para un crédito).
  final List<InformeMes> meses;

  /// Lo anotado en el periodo, por fecha (para el Excel, entrega 14.13).
  final List<OperacionDelMes> operaciones;
}

/// Un movimiento vigente anotado en el periodo, con lo que el contador
/// necesita para revisarlo.
class OperacionDelMes {
  const OperacionDelMes({
    required this.fecha,
    required this.tipo,
    required this.cuenta,
    required this.centimos,
    required this.estadoPago,
    required this.fuente,
    required this.confianza,
    this.pagadoCentimos = 0,
    this.fechaPago,
    this.categoria,
    this.nota,
    this.proveedor,
    this.ruc,
    this.comprobante,
    this.igvCentimos,
  });

  final DateTime fecha;
  final TipoMovimiento tipo;
  final TipoCuenta cuenta;
  final int centimos;
  final EstadoPago estadoPago;
  final int pagadoCentimos;
  final DateTime? fechaPago;
  final Fuente fuente;
  final NivelConfianza confianza;
  final String? categoria;
  final String? nota;
  final String? proveedor;
  final String? ruc;

  /// Tipo, serie y número, como «Factura F001-3108».
  final String? comprobante;
  final int? igvCentimos;
}

/// Las filas del flujo que piden las entidades de crédito (docs/credito/,
/// entrega 14.15). Cada una sale de una o más categorías de Moca.
enum FilaFlujo {
  ventasContado,
  ventasCreditoCobradas,
  otrosIngresos,
  ingresosExtraordinarios,
  mercaderia,
  envases,
  fletes,
  alquiler,
  servicios,
  sueldos,
  publicidad,
  mantenimiento,
  contabilidad,
  otrosGastosFijos,
}

enum EstadoMesFlujo {
  /// Moca todavía no anotaba: lo completa el dueño.
  antesDeMoca,

  /// El mes en que empezó Moca, desde ese día.
  incompleto,
  completo,
}

/// Un mes del flujo, en flujo de caja: cada pago cuenta el día que se pagó.
class MesDelFlujo {
  const MesDelFlujo({
    required this.mes,
    required this.estado,
    this.centimos = const {},
    this.cuotas = const [0, 0, 0],
    this.retirosCentimos = 0,
  });

  final DateTime mes;
  final EstadoMesFlujo estado;

  /// Lo de cada fila; la que falta es cero.
  final Map<FilaFlujo, int> centimos;

  /// Lo pagado en cuotas a cada entidad de [FlujoParaCredito.entidades].
  final List<int> cuotas;
  final int retirosCentimos;
}

/// El flujo de los últimos seis meses completos, para la caja (Moca Plus).
class FlujoParaCredito {
  const FlujoParaCredito({
    required this.meses,
    this.entidades = const [],
    this.propietario,
    this.identificacionFiscal,
    this.inicioMoca,
    this.categoriasPorFila = const {},
  });

  /// Seis meses, del más antiguo al más nuevo; el mes en curso no va.
  final List<MesDelFlujo> meses;

  /// Hasta tres entidades a las que se pagan cuotas, de la que más se pagó
  /// a la que menos; la tercera junta a las demás si hay más.
  final List<String> entidades;
  final String? propietario;
  final String? identificacionFiscal;

  /// El día desde el que Moca tiene lo anotado.
  final DateTime? inicioMoca;

  /// Las categorías del negocio que van a cada fila: el «de dónde sale».
  final Map<FilaFlujo, List<String>> categoriasPorFila;

  Iterable<MesDelFlujo> get conMoca =>
      meses.where((m) => m.estado != EstadoMesFlujo.antesDeMoca);

  /// Lo que retiró para él en promedio, solo en meses completos.
  int? get retirosPromedioCentimos {
    final completos = meses.where((m) => m.estado == EstadoMesFlujo.completo);
    if (completos.isEmpty) return null;
    return completos.fold(0, (s, m) => s + m.retirosCentimos) ~/
        completos.length;
  }
}

abstract interface class RepositorioInforme {
  /// El informe del mes que empieza en [mes]; nulo es el mes en curso.
  Stream<InformeMes> observarMes(DateTime? mes);

  /// Lo que el PDF necesita además del informe.
  Future<DetalleParaPdf> detalleParaPdf(InformeMes informe);

  /// El flujo de los últimos seis meses completos para la caja.
  Future<FlujoParaCredito> flujoParaCredito();
}
