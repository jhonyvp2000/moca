import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/acceso_local.dart';
import 'package:moca/datos/repositorios/repositorio_comprobantes_local.dart';
import 'package:moca/datos/repositorios/repositorio_historial_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/comprobantes.dart';
import 'package:moca/dominio/historial.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/movimientos.dart';
import 'package:moca/dominio/primer_dia.dart';

void main() {
  late BaseLocal base;
  late RepositorioHistorialLocal repo;
  late RepositorioMovimientosLocal movimientos;
  late RepositorioComprobantesLocal comprobantes;
  late String servicios;
  late String transporte;
  late String mercaderia;
  var ahora = DateTime(2026, 10, 12, 21);
  var conSenal = true;

  setUp(() async {
    ahora = DateTime(2026, 10, 12, 21);
    conSenal = true;
    base = BaseLocal(NativeDatabase.memory());
    final primerDia = RepositorioPrimerDiaLocal(base, ahora: () => ahora);
    await primerDia.anotarPrimeraVenta({TipoCuenta.efectivo: 35000});
    await primerDia.seguirSinCuenta();
    await primerDia.completarAlta(
      const DatosAlta(
        nombre: 'Bodega Don Lucho',
        tipoNegocio: TipoNegocio.bodega,
        saldos: {
          TipoCuenta.efectivo: 100000,
          TipoCuenta.yape: 20000,
          TipoCuenta.banco: 0,
        },
        horaCierreMinutos: 21 * 60,
      ),
    );
    Future<bool> senal() async => conSenal;
    repo = RepositorioHistorialLocal(
      base,
      ahora: () => ahora,
      hayConexion: senal,
    );
    movimientos = RepositorioMovimientosLocal(
      base,
      ahora: () => ahora,
      hayConexion: senal,
    );
    comprobantes = RepositorioComprobantesLocal(
      base,
      ahora: () => ahora,
      hayConexion: senal,
    );
    final egresos = await movimientos.categorias(TipoMovimiento.egreso);
    servicios = egresos.firstWhere((c) => c.nombre.startsWith('Servicios')).id;
    transporte = egresos
        .firstWhere((c) => c.nombre == 'Movilidad del negocio')
        .id;
    mercaderia = egresos.firstWhere((c) => c.nombre == 'Mercadería').id;
  });

  tearDown(() => base.close());

  Future<String> gasto(int soles, {String? nota}) async =>
      (await movimientos.registrar(
        NuevoMovimiento(
          tipo: TipoMovimiento.egreso,
          montoCentimos: soles * 100,
          cuenta: TipoCuenta.efectivo,
          categoriaId: servicios,
          nota: nota,
        ),
      )).ids.single;

  Future<String> compraQueSeDebe() async => (await comprobantes.guardarCompra(
    CompraConfirmada(
      lectura: const LecturaComprobante(
        origen: OrigenLectura.qr,
        emisorIdentificacion: '20100070970',
        tipo: 'Factura',
        serie: 'F001',
        numero: '12345',
        totalCentimos: 98000,
      ),
      totalCentimos: 98000,
      cuenta: TipoCuenta.efectivo,
      pagado: false,
      categoriaId: mercaderia,
      emisorNombre: 'Distribuidora San Martín',
      fecha: DateTime(2026, 10, 8),
    ),
  )).ids.single;

  Future<ResumenHistorial> historial() => repo.observarHistorial().first;
  Future<DetalleMovimiento> detalle(String id) async =>
      (await repo.observarDetalle(id).first)!;

  test('El Historial va del más reciente al más antiguo', () async {
    ahora = DateTime(2026, 10, 13, 9);
    await gasto(80, nota: 'Recibo de luz');
    final filas = (await historial()).filas;
    expect(filas, hasLength(2));
    expect(filas.first.nota, 'Recibo de luz');
    expect(filas.first.categoria, startsWith('Servicios'));
    expect(filas.last.categoria, 'Venta del día');
    expect(filas.last.tipo, TipoMovimiento.ingreso);
  });

  test('Una compra que se debe sale con el proveedor y «Lo debes»', () async {
    final id = await compraQueSeDebe();
    final fila = (await historial()).filas.firstWhere((f) => f.id == id);
    expect(fila.proveedor, 'Distribuidora San Martín');
    expect(fila.loDebes, isTrue);
    expect(fila.cumple(FiltroHistorial.salio), isTrue);
    expect(fila.cumple(FiltroHistorial.entro), isFalse);
  });

  test('Lo guardado sin señal queda por subir y no cambia', () async {
    conSenal = false;
    final id = await gasto(80);
    conSenal = true;
    final resumen = await historial();
    expect(resumen.porSubir, 1);
    expect(resumen.filas.firstWhere((f) => f.id == id).porSubir, isTrue);
  });

  test('Deshacer anula sin borrar y deja el cambio', () async {
    final id = await gasto(80);
    expect((await detalle(id)).saldoSiSeDeshaceCentimos, 135000);
    await repo.deshacer(id);
    expect((await historial()).filas.map((f) => f.id), isNot(contains(id)));
    final d = await detalle(id);
    expect(d.vigente, isFalse);
    expect(d.cambios.first, isA<CambioCreado>());
    expect(d.cambios.last, isA<CambioDeshecho>());
    final inicio = await movimientos.observarInicio().first;
    expect(inicio.saldosPorCuenta[TipoCuenta.efectivo], 135000);
  });

  test('Corregir reemplaza el registro y guarda qué cambió', () async {
    final id = await gasto(80);
    final correccion = NuevoMovimiento(
      tipo: TipoMovimiento.egreso,
      montoCentimos: 9000,
      cuenta: TipoCuenta.yape,
      categoriaId: transporte,
      nota: 'Mototaxi',
    );
    expect(await repo.saldoSiSeCorrige(id, correccion), 20000 - 9000);
    final guardado = await repo.corregir(id, correccion);
    final nuevoId = guardado.ids.single;
    expect(guardado.tienesHoyCentimos, 135000 + 20000 - 9000);

    final filas = (await historial()).filas;
    expect(
      filas.map((f) => f.id),
      allOf(contains(nuevoId), isNot(contains(id))),
    );
    final d = await detalle(nuevoId);
    expect(d.fila.cuenta, TipoCuenta.yape);
    expect(d.fila.nota, 'Mototaxi');
    expect(d.cambios, hasLength(2));
    final corregido = d.cambios.last as CambioCorregido;
    expect(
      {for (final c in corregido.campos) c.campo: (c.anterior, c.nuevo)},
      {
        CampoMovimiento.monto: (8000, 9000),
        CampoMovimiento.cuenta: (TipoCuenta.efectivo, TipoCuenta.yape),
        CampoMovimiento.categoria: (
          'Servicios (luz, agua, internet, teléfono)',
          'Movilidad del negocio',
        ),
        CampoMovimiento.nota: (null, 'Mototaxi'),
      },
    );
    expect((await detalle(id)).vigente, isFalse);
    expect(() => repo.corregir(id, correccion), throwsStateError);
  });

  test(
    'En una compra con comprobante no cambian el monto ni el tipo',
    () async {
      final id = await compraQueSeDebe();
      final guardado = await repo.corregir(
        id,
        NuevoMovimiento(
          tipo: TipoMovimiento.ingreso,
          montoCentimos: 100,
          cuenta: TipoCuenta.yape,
          categoriaId: servicios,
        ),
      );
      final d = await detalle(guardado.ids.single);
      expect(d.fila.montoCentimos, 98000);
      expect(d.fila.tipo, TipoMovimiento.egreso);
      expect(d.fila.loDebes, isTrue);
      expect(d.comprobante?.serie, 'F001');
    },
  );

  test('«Ya lo pagué» baja el saldo ese día y queda en Cambios', () async {
    final id = await compraQueSeDebe();
    var d = await detalle(id);
    expect(d.saldoSiSeDeshaceCentimos, isNull);
    // El comprobante es del 8, pero Moca lleva las cuentas desde el 12.
    expect(d.primerDiaDePago, DateTime(2026, 10, 12));
    expect(
      () =>
          repo.pagar(id, cuenta: TipoCuenta.yape, dia: DateTime(2026, 10, 11)),
      throwsArgumentError,
    );

    ahora = DateTime(2026, 10, 14, 10);
    expect(await repo.saldoSiSePaga(id, TipoCuenta.yape), 20000 - 98000);
    final saldo = await repo.pagar(
      id,
      cuenta: TipoCuenta.yape,
      dia: DateTime(2026, 10, 13),
    );
    expect(saldo, 20000 - 98000);
    d = await detalle(id);
    expect(d.fila.loDebes, isFalse);
    expect(d.fila.cuenta, TipoCuenta.yape);
    expect(d.fechaPago, DateTime(2026, 10, 13, 12));
    final pagado = d.cambios.last as CambioPagado;
    expect(pagado.cuenta, TipoCuenta.yape);
    expect(pagado.fechaPago, DateTime(2026, 10, 13, 12));
    expect(
      () => repo.pagar(id, cuenta: TipoCuenta.yape, dia: ahora),
      throwsStateError,
    );
  });

  test('La primera venta muestra cómo se anotó', () async {
    final id = (await historial()).filas.single.id;
    final d = await detalle(id);
    expect((d.cambios.single as CambioCreado).fuente, Fuente.texto);
  });

  test('Lo que anotó otra persona dice quién (entrega 20)', () async {
    const rosa = '0f0e0d0c-0000-4000-8000-0000000000ee';
    final empresa = await base.select(base.empresas).getSingle();
    final efectivo = (await (base.select(
      base.cuentas,
    )..where((c) => c.tipo.equalsValue(TipoCuenta.efectivo))).getSingle()).id;
    await base
        .into(base.usuarios)
        .insert(UsuariosCompanion.insert(id: rosa, creadoEn: ahora));
    await base
        .into(base.movimientos)
        .insert(
          MovimientosCompanion.insert(
            id: 'de-rosa',
            empresaId: empresa.id,
            tipo: TipoMovimiento.egreso,
            cuentaId: efectivo,
            montoCentimos: 2000,
            fechaMovimiento: ahora,
            estadoPago: EstadoPago.pagado,
            montoPagadoCentimos: 2000,
            categoriaId: Value(servicios),
            nivelConfianza: NivelConfianza.d,
            fuente: Fuente.voz,
            autorId: rosa,
            estado: EstadoRegistro.vigente,
            estadoSincronizacion: EstadoSincronizacion.subido,
            creadoEn: ahora,
          ),
        );
    final acceso = AccesoLocal(base, () => ahora);
    await acceso.guardarAjuste(
      AccesoLocal.claveEquipo,
      jsonEncode([
        {
          'usuario_id': rosa,
          'nombre': 'Rosa',
          'rol': 'ayudante',
          'titular': false,
        },
      ]),
    );

    final filas = (await repo.observarHistorial().first).filas;
    final deRosa = filas.firstWhere((f) => f.id == 'de-rosa');
    expect(deRosa.deOtro, isTrue);
    expect(deRosa.autorNombre, 'Rosa');
    expect(deRosa.autorRol, Rol.ayudante);
    // Lo propio no dice nada.
    expect(
      filas.where((f) => f.id != 'de-rosa').every((f) => !f.deOtro),
      isTrue,
    );
    expect(await acceso.miRol(), Rol.dueno);
  });
}
