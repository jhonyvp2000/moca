import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_categorias_local.dart';
import 'package:moca/datos/repositorios/repositorio_informe_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/categorias.dart';
import 'package:moca/dominio/informe.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/movimientos.dart';
import 'package:moca/dominio/primer_dia.dart';

void main() {
  late BaseLocal base;
  late RepositorioCategoriasLocal repo;
  late RepositorioMovimientosLocal movimientos;
  // Lunes 12 de octubre de 2026.
  var ahora = DateTime(2026, 10, 12, 10);

  setUp(() async {
    ahora = DateTime(2026, 10, 12, 10);
    base = BaseLocal(NativeDatabase.memory());
    final primerDia = RepositorioPrimerDiaLocal(base, ahora: () => ahora);
    await primerDia.anotarPrimeraVenta({TipoCuenta.efectivo: 35000});
    await primerDia.seguirSinCuenta();
    await primerDia.completarAlta(
      const DatosAlta(
        nombre: 'Bodega Don Lucho',
        tipoNegocio: TipoNegocio.bodega,
        saldos: {TipoCuenta.efectivo: 100000},
        horaCierreMinutos: 21 * 60,
      ),
    );
    repo = RepositorioCategoriasLocal(base, ahora: () => ahora);
    movimientos = RepositorioMovimientosLocal(base, ahora: () => ahora);
  });

  tearDown(() => base.close());

  Future<List<String>> ofrecidas(TipoMovimiento tipo) async => [
    for (final c in await movimientos.categorias(tipo)) c.nombre,
  ];

  Future<List<BitacoraData>> bitacora() => (base.select(
    base.bitacora,
  )..where((b) => b.entidad.equals('categoria'))).get();

  test('Las de Moca se ven y no se cambian', () async {
    final todas = await repo.observar().first;
    expect(todas.where((c) => c.propia), isEmpty);
    final mercaderia = todas.firstWhere((c) => c.nombre == 'Mercadería');
    expect(mercaderia.tipo, TipoMovimiento.egreso);
    expect(
      (await repo.renombrar(mercaderia.id, 'Abarrotes')).error,
      ErrorCategoria.sinPermiso,
    );
    expect(
      (await repo.usar(mercaderia.id, activa: false)).error,
      ErrorCategoria.sinPermiso,
    );
  });

  test(
    'Agregar: queda al final, se ofrece al anotar y va a la bitácora',
    () async {
      final r = await repo.agregar('  Hielo  ', TipoMovimiento.egreso);
      expect(r.error, isNull);
      final hielo = (await repo.observar().first).firstWhere(
        (c) => c.id == r.id,
      );
      expect(hielo.nombre, 'Hielo');
      expect(hielo.propia, isTrue);
      expect((await ofrecidas(TipoMovimiento.egreso)).last, 'Hielo');
      expect(await ofrecidas(TipoMovimiento.ingreso), isNot(contains('Hielo')));
      final b = await bitacora();
      expect(b.single.accion, AccionBitacora.crear);
      expect(b.single.valorNuevo, contains('Hielo'));
    },
  );

  test('No repite nombres, aunque cambien mayúsculas y tildes', () async {
    expect(
      (await repo.agregar('mercaderia', TipoMovimiento.egreso)).error,
      ErrorCategoria.repetida,
    );
    // Tampoco con una de lo que entra.
    expect(
      (await repo.agregar('VENTA  DEL DÍA', TipoMovimiento.egreso)).error,
      ErrorCategoria.repetida,
    );
    expect(
      (await repo.agregar('   ', TipoMovimiento.egreso)).error,
      ErrorCategoria.vacia,
    );
    await repo.agregar('Hielo', TipoMovimiento.egreso);
    expect(
      (await repo.agregar('hielo', TipoMovimiento.ingreso)).error,
      ErrorCategoria.repetida,
    );
  });

  test('Hasta 10 de lo que sale y 5 de lo que entra, por negocio', () async {
    for (var i = 1; i <= 10; i++) {
      expect(
        (await repo.agregar('Gasto $i', TipoMovimiento.egreso)).error,
        isNull,
      );
    }
    expect(
      (await repo.agregar('Gasto 11', TipoMovimiento.egreso)).error,
      ErrorCategoria.sinLugar,
    );
    for (var i = 1; i <= 5; i++) {
      expect(
        (await repo.agregar('Ingreso $i', TipoMovimiento.ingreso)).error,
        isNull,
      );
    }
    expect(
      (await repo.agregar('Ingreso 6', TipoMovimiento.ingreso)).error,
      ErrorCategoria.sinLugar,
    );
    // Dejar de usar una libera su lugar; volver a usarla, si hay lugar.
    final gasto1 = (await repo.observar().first).firstWhere(
      (c) => c.nombre == 'Gasto 1',
    );
    await repo.usar(gasto1.id, activa: false);
    expect(
      (await repo.agregar('Gasto 11', TipoMovimiento.egreso)).error,
      isNull,
    );
    expect(
      (await repo.usar(gasto1.id, activa: true)).error,
      ErrorCategoria.sinLugar,
    );
  });

  test('Cambiar el nombre: lo anotado muestra el nombre nuevo', () async {
    final id = (await repo.agregar('Hielo', TipoMovimiento.egreso)).id!;
    await movimientos.registrar(
      NuevoMovimiento(
        tipo: TipoMovimiento.egreso,
        montoCentimos: 800,
        cuenta: TipoCuenta.efectivo,
        categoriaId: id,
      ),
    );
    expect((await repo.renombrar(id, 'Hielo y agua')).error, isNull);
    final movimiento = await (base.select(
      base.movimientos,
    )..where((m) => m.categoriaId.equals(id))).getSingle();
    final categoria = await (base.select(
      base.categorias,
    )..where((c) => c.id.equals(movimiento.categoriaId!))).getSingle();
    expect(categoria.nombre, 'Hielo y agua');
    expect(
      (await repo.renombrar(id, 'Mercadería')).error,
      ErrorCategoria.repetida,
    );
    expect((await bitacora()).last.valorAnterior, contains('"Hielo"'));
  });

  test('«Ya no la uso»: no se ofrece; lo anotado la conserva', () async {
    final id = (await repo.agregar('Hielo', TipoMovimiento.egreso)).id!;
    await movimientos.registrar(
      NuevoMovimiento(
        tipo: TipoMovimiento.egreso,
        montoCentimos: 800,
        cuenta: TipoCuenta.efectivo,
        categoriaId: id,
      ),
    );
    await repo.usar(id, activa: false);
    expect(await ofrecidas(TipoMovimiento.egreso), isNot(contains('Hielo')));
    final hielo = (await repo.observar().first).firstWhere((c) => c.id == id);
    expect(hielo.activa, isFalse);
    expect(
      await (base.select(
        base.movimientos,
      )..where((m) => m.categoriaId.equals(id))).get(),
      hasLength(1),
    );
    await repo.usar(id, activa: true);
    expect(await ofrecidas(TipoMovimiento.egreso), contains('Hielo'));
  });

  test('En el flujo para el crédito, las propias van a «Otros»', () async {
    final hielo = (await repo.agregar('Hielo', TipoMovimiento.egreso)).id!;
    final propina = (await repo.agregar(
      'Propinas',
      TipoMovimiento.ingreso,
    )).id!;
    for (final (tipo, id, centimos) in [
      (TipoMovimiento.egreso, hielo, 800),
      (TipoMovimiento.ingreso, propina, 500),
    ]) {
      await movimientos.registrar(
        NuevoMovimiento(
          tipo: tipo,
          montoCentimos: centimos,
          cuenta: TipoCuenta.efectivo,
          categoriaId: id,
        ),
      );
    }
    final f = await RepositorioInformeLocal(
      base,
      ahora: () => ahora,
    ).flujoParaCredito();
    final octubre = f.meses.last;
    expect(octubre.centimos[FilaFlujo.otrosGastosFijos], 800);
    expect(octubre.centimos[FilaFlujo.otrosIngresos], 500);
    expect(f.categoriasPorFila[FilaFlujo.otrosGastosFijos], contains('Hielo'));
  });
}
