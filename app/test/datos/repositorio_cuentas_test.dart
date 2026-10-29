import 'package:drift/drift.dart' show Value, BooleanExpressionOperators;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_arqueo_local.dart';
import 'package:moca/datos/repositorios/repositorio_aviso_cierre_local.dart';
import 'package:moca/datos/repositorios/repositorio_cuentas_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/arqueo.dart';
import 'package:moca/dominio/aviso_cierre.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/primer_dia.dart';

void main() {
  late BaseLocal base;
  late RepositorioCuentasLocal repo;
  // Lunes 12 de octubre de 2026, 10:00 a. m.
  var ahora = DateTime(2026, 10, 12, 10);

  Future<void> alta({
    Map<TipoCuenta, int>? saldos = const {TipoCuenta.efectivo: 100000},
    Map<TipoCuenta, String> billeteras = const {},
  }) async {
    final primerDia = RepositorioPrimerDiaLocal(base, ahora: () => ahora);
    await primerDia.anotarPrimeraVenta({TipoCuenta.efectivo: 35000});
    await primerDia.seguirSinCuenta();
    await primerDia.completarAlta(
      DatosAlta(
        nombre: 'Bodega Don Lucho',
        tipoNegocio: TipoNegocio.bodega,
        saldos: saldos,
        horaCierreMinutos: 21 * 60,
        billeteras: billeteras,
      ),
    );
  }

  setUp(() {
    ahora = DateTime(2026, 10, 12, 10);
    base = BaseLocal(NativeDatabase.memory());
    repo = RepositorioCuentasLocal(base, ahora: () => ahora);
  });

  tearDown(() => base.close());

  test('El alta crea solo las billeteras elegidas, junto a Yape', () async {
    await alta(
      saldos: {
        TipoCuenta.efectivo: 100000,
        TipoCuenta.plin: 5000,
        TipoCuenta.otra: 2000,
      },
      billeteras: {TipoCuenta.plin: 'Plin', TipoCuenta.otra: '  Bim '},
    );
    final cuentas = await repo.observar().first;
    expect(cuentas.map((c) => c.tipo), [
      TipoCuenta.efectivo,
      TipoCuenta.yape,
      TipoCuenta.plin,
      TipoCuenta.otra,
      TipoCuenta.banco,
    ]);
    expect(cuentas.map((c) => c.nombre), [
      'Efectivo',
      'BCP Yape',
      'Interbank Plin',
      'Bim',
      'BCP',
    ]);
    expect(cuentas[2].saldoCentimos, 5000);
    expect(cuentas[3].saldoCentimos, 2000);
  });

  test('Una billetera agregada después empieza en S/ 0 desde hoy', () async {
    await alta();
    // Ayer no existía: lo de antes no cuenta.
    ahora = DateTime(2026, 10, 14, 9);
    await repo.agregarBilletera(TipoCuenta.sip);
    await repo.agregarBilletera(TipoCuenta.sip);
    var cuentas = await repo.observar().first;
    expect(cuentas.where((c) => c.tipo == TipoCuenta.sip), hasLength(1));
    expect(
      cuentas.firstWhere((c) => c.tipo == TipoCuenta.sip).saldoCentimos,
      0,
    );
    await RepositorioMovimientosLocal(
      base,
      ahora: () => ahora,
    ).anotarVentaDelDia({TipoCuenta.sip: 4000});
    cuentas = await repo.observar().first;
    expect(
      cuentas.firstWhere((c) => c.tipo == TipoCuenta.sip).saldoCentimos,
      4000,
    );
    // Queda en la bitácora.
    final bitacora = await (base.select(
      base.bitacora,
    )..where((b) => b.entidad.equals('cuenta'))).get();
    expect(
      bitacora.where(
        (b) =>
            b.accion == AccionBitacora.crear && b.valorNuevo!.contains('"sip"'),
      ),
      hasLength(1),
    );
  });

  test(
    'Con el saldo pendiente, la billetera también queda pendiente',
    () async {
      await alta(saldos: null);
      await repo.agregarBilletera(TipoCuenta.otra, nombre: 'Bim');
      final otra = (await repo.observar().first).firstWhere(
        (c) => c.tipo == TipoCuenta.otra,
      );
      expect(otra.nombre, 'Bim');
      expect(otra.saldoCentimos, isNull);
      // Al poner el saldo, la billetera entra con el resto.
      await RepositorioPrimerDiaLocal(
        base,
        ahora: () => ahora,
      ).declararSaldo({TipoCuenta.efectivo: 50000, TipoCuenta.otra: 1500});
      final cuentas = await repo.observar().first;
      expect(
        cuentas.firstWhere((c) => c.tipo == TipoCuenta.otra).saldoCentimos,
        1500,
      );
    },
  );

  test('El aviso de cierre pregunta por la billetera con ventas', () async {
    await alta(billeteras: {TipoCuenta.plin: 'Plin', TipoCuenta.sip: 'Sip'});
    await RepositorioMovimientosLocal(
      base,
      ahora: () => ahora,
    ).anotarVentaDelDia({TipoCuenta.plin: 3000, TipoCuenta.banco: 5000});
    ahora = DateTime(2026, 10, 13, 21, 5);
    final aviso = RepositorioAvisoCierreLocal(base, ahora: () => ahora);
    final yape = await aviso.responderVenta(TipoCuenta.efectivo, '300');
    expect((yape as PreguntarCuenta).cuenta, TipoCuenta.yape);
    // Plin tuvo ventas; Sip no, se salta.
    final plin = await aviso.responderVenta(TipoCuenta.yape, null);
    expect((plin as PreguntarCuenta).cuenta, TipoCuenta.plin);
    final banco = await aviso.responderVenta(TipoCuenta.plin, '40');
    expect((banco as PreguntarCuenta).cuenta, TipoCuenta.banco);
    final listo = await aviso.responderVenta(TipoCuenta.banco, null);
    expect((listo as VentaLista).ventaDeHoyCentimos, 34000);
  });

  group('Entrega 14.1: bancos', () {
    test('El alta crea los bancos elegidos después del BCP', () async {
      await alta(
        saldos: {TipoCuenta.efectivo: 100000, TipoCuenta.interbank: 30000},
        billeteras: {
          TipoCuenta.interbank: 'Interbank',
          TipoCuenta.otroBanco: ' Caja Maynas ',
        },
      );
      final cuentas = await repo.observar().first;
      expect(cuentas.map((c) => c.nombre), [
        'Efectivo',
        'BCP Yape',
        'BCP',
        'Interbank',
        'Caja Maynas',
      ]);
      expect(
        cuentas.firstWhere((c) => c.tipo == TipoCuenta.interbank).saldoCentimos,
        30000,
      );
    });

    test('Un banco agregado después empieza en S/ 0 y no se repite', () async {
      await alta();
      await repo.agregarBilletera(TipoCuenta.bbva);
      await repo.agregarBilletera(TipoCuenta.bbva);
      await repo.agregarBilletera(TipoCuenta.otroBanco, nombre: 'Mibanco');
      final cuentas = await repo.observar().first;
      expect(cuentas.where((c) => c.tipo == TipoCuenta.bbva), hasLength(1));
      expect(
        cuentas.firstWhere((c) => c.tipo == TipoCuenta.bbva).saldoCentimos,
        0,
      );
      expect(
        cuentas.firstWhere((c) => c.tipo == TipoCuenta.otroBanco).nombre,
        'Mibanco',
      );
    });

    test('El banco guardado como «Banco» se muestra como BCP', () async {
      await alta();
      await (base.update(base.cuentas)
            ..where((c) => c.tipo.equalsValue(TipoCuenta.banco)))
          .write(const CuentasCompanion(nombre: Value('Banco')));
      final cuentas = await repo.observar().first;
      expect(
        cuentas.firstWhere((c) => c.tipo == TipoCuenta.banco).nombre,
        'BCP',
      );
    });

    test('El aviso de cierre pregunta por cada banco con ventas', () async {
      await alta();
      await repo.agregarBilletera(TipoCuenta.interbank);
      await repo.agregarBilletera(TipoCuenta.scotiabank);
      await RepositorioMovimientosLocal(
        base,
        ahora: () => ahora,
      ).anotarVentaDelDia({TipoCuenta.interbank: 6000});
      ahora = DateTime(2026, 10, 13, 21, 5);
      final aviso = RepositorioAvisoCierreLocal(base, ahora: () => ahora);
      await aviso.responderVenta(TipoCuenta.efectivo, '300');
      // El BCP no tuvo ventas y Scotiabank tampoco: solo Interbank.
      final interbank = await aviso.responderVenta(TipoCuenta.yape, null);
      expect((interbank as PreguntarCuenta).cuenta, TipoCuenta.interbank);
      final listo = await aviso.responderVenta(TipoCuenta.interbank, null);
      expect(listo, isA<VentaLista>());
    });
  });

  group('Entrega 16.2: corregir el saldo con el que empezó', () {
    test('Cambia el punto de partida sin crear ajustes y queda en la '
        'bitácora', () async {
      await alta(saldos: {TipoCuenta.efectivo: 100000, TipoCuenta.yape: 20000});
      var efectivo = (await repo.observar().first).first;
      expect(efectivo.inicialCentimos, 100000);
      expect(efectivo.saldoCentimos, 135000);
      expect(efectivo.seCorrigeElInicial, isTrue);
      expect(efectivo.saldoConInicial(80000), 115000);
      final antes = (await base.select(base.movimientos).get()).length;

      expect(await repo.corregirSaldoInicial(efectivo.id, 80000), isTrue);
      efectivo = (await repo.observar().first).first;
      expect(efectivo.inicialCentimos, 80000);
      expect(efectivo.saldoCentimos, 115000);
      expect(await base.select(base.movimientos).get(), hasLength(antes));

      final cambio =
          (await (base.select(base.bitacora)..where(
                    (b) =>
                        b.entidadId.equals(efectivo.id) &
                        b.accion.equalsValue(AccionBitacora.editar),
                  ))
                  .get())
              .last;
      expect(cambio.valorAnterior, contains('100000'));
      expect(cambio.valorNuevo, contains('80000'));
      expect(cambio.valorNuevo, contains('correccion'));
    });

    test('Después de un arqueo de esa cuenta ya no se corrige; otra sin '
        'arqueo, sí', () async {
      await alta(saldos: {TipoCuenta.efectivo: 100000});
      final cuentas = await repo.observar().first;
      final efectivo = cuentas.firstWhere((c) => c.tipo == TipoCuenta.efectivo);
      final yape = cuentas.firstWhere((c) => c.tipo == TipoCuenta.yape);
      // El arqueo del encargado: solo su caja.
      await RepositorioArqueoLocal(base, ahora: () => ahora).guardar(const [
        ConteoCuenta(cuenta: TipoCuenta.efectivo, contadoCentimos: 135000),
      ]);

      final despues = await repo.observar().first;
      expect(
        despues
            .firstWhere((c) => c.tipo == TipoCuenta.efectivo)
            .seCorrigeElInicial,
        isFalse,
      );
      expect(await repo.corregirSaldoInicial(efectivo.id, 1000), isFalse);
      expect(
        despues
            .firstWhere((c) => c.tipo == TipoCuenta.efectivo)
            .inicialCentimos,
        100000,
      );
      expect(await repo.corregirSaldoInicial(yape.id, 5000), isTrue);
      expect(
        (await repo.observar().first)
            .firstWhere((c) => c.tipo == TipoCuenta.yape)
            .saldoCentimos,
        5000,
      );
    });

    test(
      'Con el saldo pendiente no se corrige: se pone como siempre',
      () async {
        await alta(saldos: null);
        final efectivo = (await repo.observar().first).first;
        expect(efectivo.inicialCentimos, isNull);
        expect(efectivo.seCorrigeElInicial, isFalse);
        expect(await repo.corregirSaldoInicial(efectivo.id, 5000), isFalse);
      },
    );
  });
}
