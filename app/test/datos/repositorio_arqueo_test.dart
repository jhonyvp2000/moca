import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_arqueo_local.dart';
import 'package:moca/datos/repositorios/repositorio_historial_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_operador_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/arqueo.dart';
import 'package:moca/dominio/historial.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/primer_dia.dart';

void main() {
  late BaseLocal base;
  late RepositorioArqueoLocal repo;
  late RepositorioMovimientosLocal movimientos;
  late RepositorioHistorialLocal historial;
  // Lunes 12 de octubre de 2026, 9:05 p. m.
  var ahora = DateTime(2026, 10, 12, 21, 5);

  Future<void> empezar({Map<TipoCuenta, int>? saldos}) async {
    final primerDia = RepositorioPrimerDiaLocal(base, ahora: () => ahora);
    await primerDia.anotarPrimeraVenta({TipoCuenta.efectivo: 35000});
    await primerDia.seguirSinCuenta();
    await primerDia.completarAlta(
      DatosAlta(
        nombre: 'Bodega Don Lucho',
        tipoNegocio: TipoNegocio.bodega,
        saldos: saldos,
        horaCierreMinutos: 21 * 60,
      ),
    );
  }

  setUp(() {
    ahora = DateTime(2026, 10, 12, 21, 5);
    base = BaseLocal(NativeDatabase.memory());
    repo = RepositorioArqueoLocal(base, ahora: () => ahora);
    movimientos = RepositorioMovimientosLocal(base, ahora: () => ahora);
    historial = RepositorioHistorialLocal(base, ahora: () => ahora);
  });

  tearDown(() => base.close());

  Future<Map<TipoCuenta, int>> saldos() async =>
      (await movimientos.observarInicio().first).saldosPorCuenta;

  const conSaldos = {
    TipoCuenta.efectivo: 100000,
    TipoCuenta.yape: 62000,
    TipoCuenta.banco: 215000,
  };

  test('Propone lo calculado por cuenta', () async {
    await empezar(saldos: conSaldos);
    final cuentas = await repo.preparar();
    expect(cuentas.map((c) => c.cuenta), TipoCuenta.basicas);
    final efectivo = cuentas.first;
    expect(efectivo.calculadoCentimos, 135000);
    expect(efectivo.propuestoSoles, 1350);
    expect(efectivo.puntoDePartida, isFalse);
    expect(efectivo.diferencia(127000), -8000);
    expect(efectivo.cuadra(134950), isTrue);
    expect(motivosPara(-8000), contains(MotivoArqueo.retiroParaMi));
    expect(motivosPara(5000), contains(MotivoArqueo.ventaNoAnotada));
  });

  test('«La retiré para mí» anota un retiro y cuadra el saldo', () async {
    await empezar(saldos: conSaldos);
    final tienes = await repo.guardar(const [
      ConteoCuenta(
        cuenta: TipoCuenta.efectivo,
        contadoCentimos: 127000,
        motivo: MotivoArqueo.retiroParaMi,
      ),
      ConteoCuenta(cuenta: TipoCuenta.yape, contadoCentimos: 62000),
      ConteoCuenta(cuenta: TipoCuenta.banco, contadoCentimos: 215000),
    ]);
    expect(tienes, 127000 + 62000 + 215000);
    expect((await saldos())[TipoCuenta.efectivo], 127000);
    final filas = (await historial.observarHistorial().first).filas;
    final retiro = filas.firstWhere((f) => f.tipo == TipoMovimiento.retiro);
    expect(retiro.montoCentimos, 8000);
    final detalle = (await historial.observarDetalle(retiro.id).first)!;
    expect(detalle.fuente, Fuente.arqueo);
    // El retiro no es gasto: la semana no lo cuenta como «salió».
    expect((await movimientos.observarInicio().first).semanaSalioCentimos, 0);
  });

  test(
    '«No lo sé» ajusta el saldo sin ser gasto y sale en el Historial',
    () async {
      await empezar(saldos: conSaldos);
      await repo.guardar(const [
        ConteoCuenta(
          cuenta: TipoCuenta.efectivo,
          contadoCentimos: 127000,
          motivo: MotivoArqueo.noLoSe,
        ),
        ConteoCuenta(
          cuenta: TipoCuenta.yape,
          contadoCentimos: 67000,
          motivo: MotivoArqueo.errorDeVuelto,
        ),
        ConteoCuenta(cuenta: TipoCuenta.banco, contadoCentimos: 215000),
      ]);
      final s = await saldos();
      expect(s[TipoCuenta.efectivo], 127000);
      expect(s[TipoCuenta.yape], 67000);
      final inicio = await movimientos.observarInicio().first;
      expect(inicio.semanaSalioCentimos, 0);
      expect(inicio.semanaEntroCentimos, 35000);

      final filas = (await historial.observarHistorial().first).filas;
      final ajustes = filas.where((f) => f.ajusteArqueo).toList();
      expect(ajustes, hasLength(2));
      final falta = ajustes.firstWhere((f) => f.cuenta == TipoCuenta.efectivo);
      expect(falta.tipo, TipoMovimiento.egreso);
      expect(falta.montoCentimos, 8000);
      expect(falta.cumple(FiltroHistorial.salio), isFalse);
      final detalle = (await historial.observarDetalle(falta.id).first)!;
      expect(detalle.ajuste?.motivo, MotivoArqueo.noLoSe);
      expect(detalle.ajuste?.calculadoCentimos, 135000);
      expect(detalle.ajuste?.contadoCentimos, 127000);
    },
  );

  test(
    'Una diferencia menor a S/ 1 se ajusta sin preguntar ni mostrarse',
    () async {
      await empezar(saldos: conSaldos);
      await repo.guardar(const [
        ConteoCuenta(cuenta: TipoCuenta.efectivo, contadoCentimos: 134950),
        ConteoCuenta(cuenta: TipoCuenta.yape, contadoCentimos: 62000),
        ConteoCuenta(cuenta: TipoCuenta.banco, contadoCentimos: 215000),
      ]);
      expect((await saldos())[TipoCuenta.efectivo], 134950);
      final filas = (await historial.observarHistorial().first).filas;
      expect(filas.where((f) => f.ajusteArqueo), isEmpty);
    },
  );

  test('Sin explicar una diferencia no se guarda', () async {
    await empezar(saldos: conSaldos);
    expect(
      () => repo.guardar(const [
        ConteoCuenta(cuenta: TipoCuenta.efectivo, contadoCentimos: 127000),
      ]),
      throwsArgumentError,
    );
    // «Una venta que no anoté» no explica una plata que falta.
    expect(
      () => repo.guardar(const [
        ConteoCuenta(
          cuenta: TipoCuenta.efectivo,
          contadoCentimos: 127000,
          motivo: MotivoArqueo.ventaNoAnotada,
        ),
      ]),
      throwsArgumentError,
    );
  });

  test('«Una venta que no anoté» anota una venta del día', () async {
    await empezar(saldos: conSaldos);
    await repo.guardar(const [
      ConteoCuenta(
        cuenta: TipoCuenta.yape,
        contadoCentimos: 70000,
        motivo: MotivoArqueo.ventaNoAnotada,
      ),
    ]);
    final inicio = await movimientos.observarInicio().first;
    expect(inicio.saldosPorCuenta[TipoCuenta.yape], 70000);
    expect(inicio.ventaDeHoyCentimos, 35000 + 8000);
  });

  test('«La puse yo» anota lo que puso de su bolsillo, no una venta '
      '(entrega 14.11)', () async {
    await empezar(saldos: conSaldos);
    expect(motivosPara(8000), contains(MotivoArqueo.puseYo));
    expect(motivosPara(-8000), isNot(contains(MotivoArqueo.puseYo)));
    await repo.guardar(const [
      ConteoCuenta(
        cuenta: TipoCuenta.yape,
        contadoCentimos: 70000,
        motivo: MotivoArqueo.puseYo,
      ),
    ]);
    final inicio = await movimientos.observarInicio().first;
    expect(inicio.saldosPorCuenta[TipoCuenta.yape], 70000);
    expect(inicio.ventaDeHoyCentimos, 35000);
    expect(inicio.semanaAportesCentimos, 8000);
  });

  test('Sin saldo inicial, lo contado es el punto de partida', () async {
    await empezar();
    final cuentas = await repo.preparar();
    expect(cuentas.every((c) => c.puntoDePartida), isTrue);
    expect(cuentas.first.propuestoSoles, isNull);
    await repo.guardar(const [
      ConteoCuenta(cuenta: TipoCuenta.efectivo, contadoCentimos: 140000),
      ConteoCuenta(cuenta: TipoCuenta.yape, contadoCentimos: 0),
      ConteoCuenta(cuenta: TipoCuenta.banco, contadoCentimos: 50000),
    ]);
    final s = await saldos();
    expect(s[TipoCuenta.efectivo], 140000);
    expect(s[TipoCuenta.banco], 50000);
    final primerDia = await RepositorioPrimerDiaLocal(
      base,
      ahora: () => ahora,
    ).observarResumen().first;
    expect(primerDia.saldoPendiente, isFalse);
    expect((await repo.preparar()).first.puntoDePartida, isFalse);
  });

  test('Estado del arqueo en el Inicio', () async {
    await empezar(saldos: conSaldos);
    Future<EstadoArqueo> estado() async =>
        (await movimientos.observarInicio().first).estadoArqueo;

    expect(await estado(), EstadoArqueo.nada);
    await RepositorioOperadorLocal(base).pedirArqueo();
    expect(await estado(), EstadoArqueo.toca);

    // El domingo toca.
    ahora = DateTime(2026, 10, 18, 10);
    expect(await estado(), EstadoArqueo.toca);
    // El lunes siguiente, antes de las 8:00, todavía no falta.
    ahora = DateTime(2026, 10, 19, 7, 59);
    expect(await estado(), EstadoArqueo.toca);
    ahora = DateTime(2026, 10, 19, 8);
    expect(await estado(), EstadoArqueo.falta);

    await repo.guardar(const [
      ConteoCuenta(cuenta: TipoCuenta.efectivo, contadoCentimos: 135000),
      ConteoCuenta(cuenta: TipoCuenta.yape, contadoCentimos: 62000),
      ConteoCuenta(cuenta: TipoCuenta.banco, contadoCentimos: 215000),
    ]);
    expect(await estado(), EstadoArqueo.hecho);
    // La semana siguiente no falta, porque la anterior tuvo arqueo.
    ahora = DateTime(2026, 10, 26, 9);
    expect(await estado(), EstadoArqueo.nada);
  });
}
