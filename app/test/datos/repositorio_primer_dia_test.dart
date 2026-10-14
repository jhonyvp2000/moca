import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/primer_dia.dart';

void main() {
  late BaseLocal base;
  late RepositorioPrimerDiaLocal repo;
  late DateTime ahora;

  setUp(() {
    base = BaseLocal(NativeDatabase.memory());
    ahora = DateTime(2026, 10, 12, 21, 5);
    repo = RepositorioPrimerDiaLocal(base, ahora: () => ahora);
  });

  tearDown(() => base.close());

  Future<EtapaInicio> etapa() => repo.observarEtapa().first;
  Future<ResumenPrimerDia> resumen() => repo.observarResumen().first;

  const venta = {TipoCuenta.efectivo: 35000, TipoCuenta.yape: 12000};

  test('Un teléfono nuevo empieza en la Bienvenida', () async {
    expect(await etapa(), EtapaInicio.bienvenida);
  });

  test(
    'La primera venta crea las tres cuentas sin saldo y pasa a S01',
    () async {
      await repo.anotarPrimeraVenta(venta);

      expect(await etapa(), EtapaInicio.guardarAvance);
      final cuentas = await base.select(base.cuentas).get();
      expect(cuentas.map((c) => c.tipo), TipoCuenta.basicas);
      expect(cuentas.every((c) => c.saldoInicialCentimos == null), isTrue);

      final movimientos = await base.select(base.movimientos).get();
      expect(movimientos, hasLength(2));
      expect(
        movimientos.every((m) => m.nivelConfianza == NivelConfianza.d),
        isTrue,
      );
      expect(
        movimientos.every((m) => m.tipo == TipoMovimiento.ingreso),
        isTrue,
      );

      final r = await resumen();
      expect(r.ventaDeHoyCentimos, 47000);
      expect(r.diasConVenta, 1);
      expect(r.saldoPendiente, isTrue);
    },
  );

  test('La venta queda en la bitácora', () async {
    await repo.anotarPrimeraVenta(venta);
    final entradas = await base.select(base.bitacora).get();
    expect(entradas, hasLength(2));
    expect(entradas.every((e) => e.accion == AccionBitacora.crear), isTrue);
    final nuevo = jsonDecode(entradas.first.valorNuevo!) as Map;
    expect(nuevo['categoria'], 'Venta del día');
  });

  test('Un doble toque en «Guardar» no duplica la venta', () async {
    await Future.wait([
      repo.anotarPrimeraVenta(venta),
      repo.anotarPrimeraVenta(venta),
    ]);
    expect(await base.select(base.movimientos).get(), hasLength(2));
    expect(await base.select(base.empresas).get(), hasLength(1));
  });

  test('Una venta sin montos no se guarda', () async {
    expect(
      () => repo.anotarPrimeraVenta({TipoCuenta.efectivo: 0}),
      throwsArgumentError,
    );
  });

  test('Con celular o sin cuenta, se pasa al alta', () async {
    await repo.anotarPrimeraVenta(venta);
    await repo.guardarCelular('987654321');
    expect(await etapa(), EtapaInicio.alta);
    final usuario = await base.select(base.usuarios).getSingle();
    expect(usuario.celular, '987654321');
  });

  test('El saldo inicial es el de antes de la venta: se suman', () async {
    await repo.anotarPrimeraVenta(venta);
    await repo.seguirSinCuenta();
    await repo.completarAlta(
      const DatosAlta(
        nombre: '  Bodega Don Lucho ',
        tipoNegocio: TipoNegocio.bodega,
        saldos: {TipoCuenta.efectivo: 120000, TipoCuenta.yape: 45000},
        horaCierreMinutos: 20 * 60,
      ),
    );

    expect(await etapa(), EtapaInicio.listo);
    final r = await resumen();
    expect(r.nombreNegocio, 'Bodega Don Lucho');
    // 1,200 + 450 + 0 (banco vacío) + 350 + 120.
    expect(r.tienesHoyCentimos, 212000);
    expect(r.saldoPendiente, isFalse);

    final empresa = await base.select(base.empresas).getSingle();
    expect(empresa.horaCierreMinutos, 20 * 60);
    final categorias = await base.select(base.categorias).get();
    expect(categorias.map((c) => c.nombre), contains('Mercadería'));
    expect(categorias.map((c) => c.nombre), isNot(contains('Gas')));
  });

  test(
    '«Lo pongo después» deja el saldo pendiente; luego se declara',
    () async {
      await repo.anotarPrimeraVenta(venta);
      await repo.seguirSinCuenta();
      await repo.completarAlta(
        const DatosAlta(
          nombre: 'Restaurante Sabor',
          tipoNegocio: TipoNegocio.restaurante,
          saldos: null,
          horaCierreMinutos: 21 * 60,
        ),
      );

      var r = await resumen();
      expect(r.saldoPendiente, isTrue);
      expect(r.tienesHoyCentimos, 47000);

      // Al día siguiente declara su saldo: rige desde el primer día, así que
      // la venta sigue sumando.
      ahora = ahora.add(const Duration(days: 1));
      await repo.declararSaldo({TipoCuenta.efectivo: 50000});
      r = await resumen();
      expect(r.saldoPendiente, isFalse);
      expect(r.tienesHoyCentimos, 97000);
      expect(r.ventaDeHoyAnotada, isFalse);
      expect(r.diasConVenta, 1);
    },
  );
}
