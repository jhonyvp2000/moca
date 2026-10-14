import '../../dominio/informe.dart';
import '../../dominio/modelos.dart';
import '../../pais/peru/categorias.dart';
import '../calculos/saldos.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

class RepositorioInformeLocal implements RepositorioInforme {
  RepositorioInformeLocal(BaseLocal base, {DateTime Function()? ahora})
    : _a = AccesoLocal(base, ahora ?? DateTime.now);

  final AccesoLocal _a;
  BaseLocal get _base => _a.base;

  /// Cambio mínimo de una categoría para mencionarlo: S/ 100 y 20 %.
  static const _cambioMinimoCentimos = 10000;
  static const _cambioMinimoProporcion = 0.2;

  /// La mercadería del mes avisa desde 30 % sobre el promedio de hasta tres
  /// meses anteriores.
  static const _umbralMercaderia = 1.3;
  static const _mesesParaPromedio = 3;
  static const _filasDeGastos = 5;

  @override
  Stream<InformeMes> observarMes(DateTime? mes) =>
      _a.cambios().asyncMap((_) => _calcular(mes));

  /// Para el informe, un movimiento cuenta en el mes de su comprobante.
  static DateTime _fecha(Movimiento m) =>
      m.fechaComprobante ?? m.fechaMovimiento;

  Future<InformeMes> _calcular(DateTime? pedido) async {
    final ahora = _a.ahora();
    final actual = DateTime(ahora.year, ahora.month);
    final empresa = await _a.empresa();
    final vigentes = empresa == null
        ? const <Movimiento>[]
        : (await _a.movimientos(empresa.id))
              .where((m) => m.estado == EstadoRegistro.vigente)
              .toList();
    final categorias = empresa == null
        ? const <String, String>{}
        : {
            for (final c in await (_base.select(
              _base.categorias,
            )..where((c) => c.empresaId.equals(empresa.id))).get())
              c.id: c.nombre,
          };

    final inicio = vigentes.isEmpty
        ? ahora
        : vigentes.map(_fecha).reduce((a, b) => a.isBefore(b) ? a : b);
    final primerMes = DateTime(inicio.year, inicio.month);

    var mes = pedido == null ? actual : DateTime(pedido.year, pedido.month);
    if (mes.isAfter(actual)) mes = actual;
    if (mes.isBefore(primerMes)) mes = primerMes;
    final enCurso = mes == actual;
    final finMes = DateTime(mes.year, mes.month + 1);
    final hasta = enCurso
        ? inicioDelDia(ahora).add(const Duration(days: 1))
        : finMes;

    List<Movimiento> periodo(DateTime desde, DateTime hasta) => [
      for (final m in vigentes)
        if (!_fecha(m).isBefore(desde) && _fecha(m).isBefore(hasta)) m,
    ];
    int suma(Iterable<Movimiento> ms, TipoMovimiento tipo) =>
        ms.where((m) => m.tipo == tipo).fold(0, (s, m) => s + m.montoCentimos);
    int ganancia(Iterable<Movimiento> ms) =>
        suma(ms, TipoMovimiento.ingreso) - suma(ms, TipoMovimiento.egreso);
    Map<String, int> porCategoria(Iterable<Movimiento> ms) {
      final total = <String, int>{};
      for (final m in ms.where((m) => m.tipo == TipoMovimiento.egreso)) {
        final nombre = categorias[m.categoriaId] ?? 'Otros';
        total[nombre] = (total[nombre] ?? 0) + m.montoCentimos;
      }
      return total;
    }

    final delMes = periodo(mes, hasta);
    final esPrimero = mes == primerMes;

    // Mes anterior: hasta el mismo día si el mes está en curso.
    DateTime? mesAnterior;
    int? diferencia;
    CambioDeCategoria? cambio;
    if (!esPrimero) {
      mesAnterior = DateTime(mes.year, mes.month - 1);
      var hastaAnterior = mes;
      if (enCurso) {
        final mismoDia = DateTime(
          mesAnterior.year,
          mesAnterior.month,
          ahora.day + 1,
        );
        if (mismoDia.isBefore(mes)) hastaAnterior = mismoDia;
      }
      final anterior = periodo(mesAnterior, hastaAnterior);
      diferencia = ganancia(delMes) - ganancia(anterior);

      final ahoraPorCategoria = porCategoria(delMes);
      final antesPorCategoria = porCategoria(anterior);
      String? mayor;
      var mayorCambio = 0;
      for (final nombre in {
        ...ahoraPorCategoria.keys,
        ...antesPorCategoria.keys,
      }) {
        final c =
            (ahoraPorCategoria[nombre] ?? 0) - (antesPorCategoria[nombre] ?? 0);
        if (c.abs() > mayorCambio.abs()) {
          mayor = nombre;
          mayorCambio = c;
        }
      }
      if (mayor != null) {
        final antes = antesPorCategoria[mayor] ?? 0;
        if (mayorCambio.abs() >= _cambioMinimoCentimos &&
            (antes == 0 ||
                mayorCambio.abs() >= antes * _cambioMinimoProporcion)) {
          cambio = CambioDeCategoria(nombre: mayor, centimos: mayorCambio);
        }
      }
    }

    // En qué se fue la plata: a lo más cinco filas.
    final ordenadas = porCategoria(delMes).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final gastos = ordenadas.length <= _filasDeGastos
        ? [
            for (final e in ordenadas)
              GastoPorCategoria(nombre: e.key, centimos: e.value),
          ]
        : [
            for (final e in ordenadas.take(_filasDeGastos - 1))
              GastoPorCategoria(nombre: e.key, centimos: e.value),
            GastoPorCategoria(
              nombre: null,
              centimos: ordenadas
                  .skip(_filasDeGastos - 1)
                  .fold(0, (s, e) => s + e.value),
            ),
          ];

    // Mercadería frente al promedio de hasta tres meses anteriores.
    int mercaderia(Iterable<Movimiento> ms) => ms
        .where(
          (m) =>
              m.tipo == TipoMovimiento.egreso &&
              categoriasDeMercaderia.contains(categorias[m.categoriaId]),
        )
        .fold(0, (s, m) => s + m.montoCentimos);
    final anteriores = [
      for (var i = 1; i <= _mesesParaPromedio; i++)
        if (!DateTime(mes.year, mes.month - i).isBefore(primerMes))
          mercaderia(
            periodo(
              DateTime(mes.year, mes.month - i),
              DateTime(mes.year, mes.month - i + 1),
            ),
          ),
    ];
    final promedio = anteriores.isEmpty
        ? 0
        : anteriores.reduce((a, b) => a + b) / anteriores.length;
    final advertencia =
        promedio > 0 && mercaderia(delMes) >= promedio * _umbralMercaderia;

    return InformeMes(
      mes: mes,
      enCurso: enCurso,
      sinRegistros: delMes.isEmpty,
      desdeDia: esPrimero && inicio.day > 1 ? inicio.day : null,
      mesAnterior: mesAnterior,
      diferenciaConAnteriorCentimos: diferencia,
      entroCentimos: suma(delMes, TipoMovimiento.ingreso),
      salioCentimos: suma(delMes, TipoMovimiento.egreso),
      retirosCentimos: suma(delMes, TipoMovimiento.retiro),
      gastos: gastos,
      cambio: cambio,
      loQueDebesCentimos: vigentes
          .where(
            (m) =>
                m.tipo == TipoMovimiento.egreso &&
                m.estadoPago != EstadoPago.pagado,
          )
          .fold(0, (s, m) => s + m.montoCentimos - m.montoPagadoCentimos),
      confianza: _confianza(delMes),
      advertenciaMercaderia: advertencia,
      mesPrevio: esPrimero ? null : DateTime(mes.year, mes.month - 1),
      mesSiguiente: enCurso ? null : DateTime(mes.year, mes.month + 1),
    );
  }

  /// Porcentajes del monto por sustento, que suman 100 (resto mayor).
  static ConfianzaDelMes? _confianza(List<Movimiento> ms) {
    final montos = [0, 0, 0];
    for (final m in ms) {
      final i = switch (m.nivelConfianza) {
        NivelConfianza.a || NivelConfianza.b => 0,
        NivelConfianza.c => 1,
        NivelConfianza.d => 2,
      };
      montos[i] += m.montoCentimos;
    }
    final total = montos.fold(0, (s, x) => s + x);
    if (total == 0) return null;
    final exactos = [for (final x in montos) x * 100 / total];
    final enteros = [for (final x in exactos) x.floor()];
    var falta = 100 - enteros.fold(0, (s, x) => s + x);
    final porResto = [0, 1, 2]
      ..sort(
        (a, b) => (exactos[b] - enteros[b]).compareTo(exactos[a] - enteros[a]),
      );
    for (final i in porResto) {
      if (falta == 0) break;
      enteros[i]++;
      falta--;
    }
    return ConfianzaDelMes(
      conComprobante: enteros[0],
      conFoto: enteros[1],
      sinPapel: enteros[2],
    );
  }
}
