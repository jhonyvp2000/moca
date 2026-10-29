import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_operador_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/movimientos.dart';
import 'package:moca/dominio/primer_dia.dart';
import 'package:moca/pais/peru/categorias.dart';

void main() {
  late BaseLocal base;
  late RepositorioMovimientosLocal repo;
  late DateTime ahora;

  setUp(() async {
    base = BaseLocal(NativeDatabase.memory());
    // Lunes 12 de octubre de 2026, 9 p. m.
    ahora = DateTime(2026, 10, 12, 21);
    final primerDia = RepositorioPrimerDiaLocal(base, ahora: () => ahora);
    await primerDia.anotarPrimeraVenta({TipoCuenta.efectivo: 35000});
    await primerDia.seguirSinCuenta();
    await primerDia.completarAlta(
      const DatosAlta(
        nombre: 'Bodega Don Lucho',
        tipoNegocio: TipoNegocio.bodega,
        saldos: {TipoCuenta.efectivo: 100000, TipoCuenta.yape: 20000},
        horaCierreMinutos: 21 * 60,
      ),
    );
    repo = RepositorioMovimientosLocal(base, ahora: () => ahora);
  });

  tearDown(() => base.close());

  Future<ResumenInicio> inicio() => repo.observarInicio().first;

  Future<String> categoria(TipoMovimiento tipo, String nombre) async =>
      (await repo.categorias(tipo)).firstWhere((c) => c.nombre == nombre).id;

  test('El Inicio parte del saldo y la venta del primer día', () async {
    final r = await inicio();
    expect(r.nombreNegocio, 'Bodega Don Lucho');
    expect(r.saldosPorCuenta, {
      TipoCuenta.efectivo: 135000,
      TipoCuenta.yape: 20000,
      TipoCuenta.banco: 0,
    });
    expect(r.tienesHoyCentimos, 155000);
    expect(r.semanaEntroCentimos, 35000);
    expect(r.ventaDeHoyCentimos, 35000);
    // No hay semana anterior con qué comparar.
    expect(r.diferenciaConSemanaAnteriorCentimos, isNull);
  });

  test('Las categorías dependen de si entró o salió', () async {
    final entro = await repo.categorias(TipoMovimiento.ingreso);
    expect(entro.map((c) => c.nombre), categoriasComunesIngreso);
    final salio = await repo.categorias(TipoMovimiento.egreso);
    expect(salio.map((c) => c.nombre), contains('Mercadería'));
    expect(await repo.categorias(TipoMovimiento.retiro), isEmpty);
  });

  test('Un gasto baja el saldo de su cuenta y cuenta como «salió»', () async {
    final luz = await categoria(
      TipoMovimiento.egreso,
      'Servicios (luz, agua, internet, teléfono)',
    );
    final guardado = await repo.registrar(
      NuevoMovimiento(
        tipo: TipoMovimiento.egreso,
        montoCentimos: 8000,
        cuenta: TipoCuenta.yape,
        categoriaId: luz,
        nota: '  luz de octubre ',
      ),
    );
    expect(guardado.tienesHoyCentimos, 147000);

    final r = await inicio();
    expect(r.saldosPorCuenta[TipoCuenta.yape], 12000);
    expect(r.semanaSalioCentimos, 8000);
    final movimiento = await (base.select(
      base.movimientos,
    )..where((m) => m.id.equals(guardado.ids.single))).getSingle();
    expect(movimiento.nota, 'luz de octubre');
    expect(movimiento.fuente, Fuente.texto);
  });

  test('El retiro para mí baja la caja pero no es «salió»', () async {
    await repo.registrar(
      const NuevoMovimiento(
        tipo: TipoMovimiento.retiro,
        montoCentimos: 10000,
        cuenta: TipoCuenta.efectivo,
      ),
    );
    final r = await inicio();
    expect(r.saldosPorCuenta[TipoCuenta.efectivo], 125000);
    expect(r.semanaSalioCentimos, 0);
    expect(r.semanaQuedoCentimos, 35000);
  });

  test('Un gasto sin categoría o sin monto no se guarda', () async {
    expect(
      () => repo.registrar(
        const NuevoMovimiento(
          tipo: TipoMovimiento.egreso,
          montoCentimos: 8000,
          cuenta: TipoCuenta.yape,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => repo.registrar(
        const NuevoMovimiento(
          tipo: TipoMovimiento.retiro,
          montoCentimos: 0,
          cuenta: TipoCuenta.yape,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('Avisa cuánto quedaría si una cuenta pasa a negativo', () async {
    final otros = await categoria(TipoMovimiento.egreso, 'Otros');
    final quedaria = await repo.saldoSiSeGuarda(
      NuevoMovimiento(
        tipo: TipoMovimiento.egreso,
        montoCentimos: 25000,
        cuenta: TipoCuenta.yape,
        categoriaId: otros,
      ),
    );
    expect(quedaria, -5000);
  });

  test('Deshacer anula sin borrar y queda en la bitácora', () async {
    final guardado = await repo.registrar(
      const NuevoMovimiento(
        tipo: TipoMovimiento.retiro,
        montoCentimos: 10000,
        cuenta: TipoCuenta.efectivo,
      ),
    );
    await repo.deshacer(guardado);
    // Deshacer dos veces no anota dos veces.
    await repo.deshacer(guardado);

    expect((await inicio()).saldosPorCuenta[TipoCuenta.efectivo], 135000);
    final movimiento = await (base.select(
      base.movimientos,
    )..where((m) => m.id.equals(guardado.ids.single))).getSingle();
    expect(movimiento.estado, EstadoRegistro.anulado);
    final anulaciones = await (base.select(
      base.bitacora,
    )..where((b) => b.accion.equalsValue(AccionBitacora.anular))).get();
    expect(anulaciones, hasLength(1));
  });

  test(
    'La venta de otro día se anota por cuenta y se suma la de hoy',
    () async {
      ahora = DateTime(2026, 10, 13, 21);
      expect((await inicio()).ventaDeHoyCentimos, 0);
      await repo.anotarVentaDelDia({
        TipoCuenta.efectivo: 40000,
        TipoCuenta.yape: 5000,
      });
      await repo.anotarVentaDelDia({TipoCuenta.efectivo: 2000});
      final r = await inicio();
      expect(r.ventaDeHoyCentimos, 47000);
      expect(r.semanaEntroCentimos, 82000);
    },
  );

  test('Compara con la semana pasada hasta el mismo día', () async {
    // Lunes de la semana siguiente.
    ahora = DateTime(2026, 10, 19, 21);
    await repo.anotarVentaDelDia({TipoCuenta.efectivo: 50000});
    final r = await inicio();
    // Esta semana: 500; la pasada hasta el lunes a esta hora: 350.
    expect(r.semanaQuedoCentimos, 50000);
    expect(r.diferenciaConSemanaAnteriorCentimos, 15000);
  });

  test('El Primer día dura una semana, salvo que se salte', () async {
    expect((await inicio()).mostrarPrimerDia, isTrue);
    ahora = DateTime(2026, 10, 19, 21, 1);
    expect((await inicio()).mostrarPrimerDia, isFalse);

    ahora = DateTime(2026, 10, 13);
    expect((await inicio()).mostrarPrimerDia, isTrue);
    await RepositorioOperadorLocal(base).saltarPrimeraSemana();
    expect((await inicio()).mostrarPrimerDia, isFalse);
  });
}
