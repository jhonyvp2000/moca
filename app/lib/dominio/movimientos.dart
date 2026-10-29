import 'arqueo.dart';
import 'modelos.dart';

/// Lo que el dueño anota en «Escribirlo».
class NuevoMovimiento {
  const NuevoMovimiento({
    required this.tipo,
    required this.montoCentimos,
    required this.cuenta,
    this.cuentaDestino,
    this.categoriaId,
    this.nota,
    this.fuente = Fuente.texto,
  });

  final TipoMovimiento tipo;
  final int montoCentimos;
  final TipoCuenta cuenta;

  /// En un pase, la cuenta a la que va la plata (entrega 21.1).
  final TipoCuenta? cuentaDestino;

  /// Nula en un retiro para el dueño, que no lleva categoría.
  final String? categoriaId;
  final String? nota;

  /// Escrito o dicho por voz.
  final Fuente fuente;
}

/// Lo que ya se sabe de un movimiento para abrir «Escribirlo» con los datos
/// puestos (por ejemplo, al corregir lo que Moca entendió por voz).
class BorradorMovimiento {
  const BorradorMovimiento({
    this.tipo,
    this.montoCentimos,
    this.cuenta,
    this.cuentaDestino,
    this.categoriaId,
  });

  final TipoMovimiento? tipo;
  final int? montoCentimos;
  final TipoCuenta? cuenta;
  final TipoCuenta? cuentaDestino;
  final String? categoriaId;
}

class CategoriaVista {
  const CategoriaVista({required this.id, required this.nombre});

  final String id;
  final String nombre;
}

/// Lo que se acaba de guardar, para poder deshacerlo.
class Guardado {
  const Guardado({required this.ids, required this.tienesHoyCentimos});

  final List<String> ids;

  /// Cuánto tiene el dueño en total después de guardar.
  final int tienesHoyCentimos;
}

/// Lo que muestra el Inicio (S04). Las cifras vienen calculadas.
class ResumenInicio {
  const ResumenInicio({
    required this.nombreNegocio,
    required this.saldosPorCuenta,
    required this.semanaEntroCentimos,
    required this.semanaSalioCentimos,
    required this.semanaConMovimientos,
    required this.diferenciaConSemanaAnteriorCentimos,
    required this.ventaDeHoyCentimos,
    required this.mostrarPrimerDia,
    this.semanaRetirosCentimos = 0,
    this.semanaAportesCentimos = 0,
    this.estadoArqueo = EstadoArqueo.nada,
  });

  final String nombreNegocio;
  final Map<TipoCuenta, int> saldosPorCuenta;
  final int semanaEntroCentimos;
  final int semanaSalioCentimos;
  final bool semanaConMovimientos;

  /// Lo que el dueño retiró para sí esta semana; aparece en el Inicio si
  /// hubo (entrega 14.9).
  final int semanaRetirosCentimos;

  /// Lo que el dueño puso de su bolsillo esta semana (entrega 14.11).
  final int semanaAportesCentimos;

  /// Lo que quedó esta semana menos lo que quedó la semana pasada hasta el
  /// mismo día de la semana. Nulo si la semana pasada no hubo movimientos.
  final int? diferenciaConSemanaAnteriorCentimos;
  final int ventaDeHoyCentimos;

  /// S03 se muestra la primera semana, hasta el primer arqueo.
  final bool mostrarPrimerDia;

  /// Si toca, falta o ya se hizo el arqueo de la semana.
  final EstadoArqueo estadoArqueo;

  int get tienesHoyCentimos =>
      saldosPorCuenta.values.fold(0, (suma, saldo) => suma + saldo);
  int get semanaQuedoCentimos => semanaEntroCentimos - semanaSalioCentimos;
}

abstract interface class RepositorioMovimientos {
  Stream<ResumenInicio> observarInicio();

  Future<List<CategoriaVista>> categorias(TipoMovimiento tipo);

  /// Cuánto quedaría en la cuenta si se guarda este movimiento. Moca
  /// pregunta antes de dejar una cuenta en negativo.
  Future<int> saldoSiSeGuarda(NuevoMovimiento movimiento);

  Future<Guardado> registrar(NuevoMovimiento movimiento);

  /// Venta del día por cuenta, después del primer día. Se suma a lo que ya
  /// se haya anotado hoy.
  Future<Guardado> anotarVentaDelDia(
    Map<TipoCuenta, int> ventaPorCuenta, {
    Fuente fuente = Fuente.texto,
  });

  /// Anula lo guardado: no se borra, y el cambio queda en la bitácora.
  Future<void> deshacer(Guardado guardado);
}
