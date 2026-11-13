import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:moca/textos/textos.dart';
import 'package:moca/dominio/informe.dart';
import 'package:moca/pantallas/informe/excel_informe.dart';
import 'package:moca/pantallas/informe/pdf_informe.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/acceso_local.dart';
import 'package:moca/datos/repositorios/repositorio_comprobantes_local.dart';
import 'package:moca/datos/repositorios/repositorio_historial_local.dart';
import 'package:moca/datos/repositorios/repositorio_informe_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/comprobantes.dart';
import 'package:moca/dominio/historial.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/movimientos.dart';
import 'package:moca/dominio/primer_dia.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
    expect(fila.cumple(Transaccion.salio), isTrue);
    expect(fila.cumple(Transaccion.entro), isFalse);
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

  test(
    '«Lo que debes»: lo que falta pagar, y al pagar sale (entrega 38)',
    () async {
      final id = await compraQueSeDebe();
      var deudas = await repo.observarLoQueDebes().first;
      expect(deudas.single.id, id);
      expect(deudas.single.proveedor, 'Distribuidora San Martín');
      expect(deudas.single.montoCentimos, 98000);
      // Lo pagado no es deuda, ni lo deshecho.
      await gasto(80);
      expect(await repo.observarLoQueDebes().first, hasLength(1));
      ahora = DateTime(2026, 10, 14, 10);
      await repo.pagar(
        id,
        cuenta: TipoCuenta.yape,
        dia: DateTime(2026, 10, 13),
      );
      deudas = await repo.observarLoQueDebes().first;
      expect(deudas, isEmpty);
    },
  );

  test(
    'Los registros de una categoría suman lo de su barra (entrega 38)',
    () async {
      ahora = DateTime(2026, 10, 13, 9);
      await gasto(80, nota: 'Recibo de luz');
      await gasto(20);
      await movimientos.registrar(
        NuevoMovimiento(
          tipo: TipoMovimiento.egreso,
          montoCentimos: 1500,
          cuenta: TipoCuenta.efectivo,
          categoriaId: transporte,
        ),
      );
      // Lo que se debe no está en la barra hasta pagarlo.
      await compraQueSeDebe();
      final mes = DateTime(2026, 10);
      final servicio = (await movimientos.categorias(TipoMovimiento.egreso))
          .firstWhere((c) => c.id == servicios)
          .nombre;
      final deServicios = await repo
          .observarDeCategoria(
            ConsultaDeCategoria(
              mes: mes,
              tipo: TipoMovimiento.egreso,
              titulo: servicio,
              nombres: {servicio},
            ),
          )
          .first;
      expect(
        deServicios.map((f) => f.montoCentimos).fold(0, (a, b) => a + b),
        10000,
      );
      expect(deServicios, hasLength(2));
      // «Lo demás»: todas menos las que ya tienen fila.
      final loDemas = await repo
          .observarDeCategoria(
            ConsultaDeCategoria(
              mes: mes,
              tipo: TipoMovimiento.egreso,
              titulo: 'Lo demás',
              salvo: {servicio},
            ),
          )
          .first;
      expect(loDemas.single.montoCentimos, 1500);
      expect(loDemas.single.categoria, 'Movilidad del negocio');
      // Otro mes, nada.
      final noviembre = await repo
          .observarDeCategoria(
            ConsultaDeCategoria(
              mes: DateTime(2026, 11),
              tipo: TipoMovimiento.egreso,
              titulo: servicio,
              nombres: {servicio},
            ),
          )
          .first;
      expect(noviembre, isEmpty);
    },
  );

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

  group('Entrega 41: escribir una compra que se debe', () {
    Future<int> tienesHoy() async => (await movimientos.saldoSiSeGuarda(
      NuevoMovimiento(
        tipo: TipoMovimiento.aporte,
        montoCentimos: 0,
        cuenta: TipoCuenta.efectivo,
      ),
    ));

    Future<String> deuda(int soles, {String? proveedor}) async =>
        (await movimientos.registrar(
          NuevoMovimiento(
            tipo: TipoMovimiento.egreso,
            montoCentimos: soles * 100,
            cuenta: TipoCuenta.efectivo,
            categoriaId: mercaderia,
            pagado: false,
            contraparte: proveedor,
          ),
        )).ids.single;

    test('no baja la plata, sale en «Lo que debes» y se paga', () async {
      final antes = await tienesHoy();
      final id = await deuda(120, proveedor: 'Distribuidora Rosita');
      expect(await tienesHoy(), antes);
      var debes = await repo.observarLoQueDebes().first;
      expect(debes.single.id, id);
      expect(debes.single.proveedor, 'Distribuidora Rosita');
      expect(debes.single.montoCentimos, 12000);
      expect(debes.single.loDebes, isTrue);
      // El mismo proveedor, aunque se escriba distinto.
      await deuda(30, proveedor: ' distribuidora rosita ');
      expect(await base.select(base.contrapartes).get(), hasLength(1));
      // Sin nombre, también se debe.
      await deuda(10);
      debes = await repo.observarLoQueDebes().first;
      expect(debes, hasLength(3));
      expect(debes.where((f) => f.proveedor == null), hasLength(1));
      // Al pagarla baja la cuenta elegida.
      final yape = await repo.pagar(id, cuenta: TipoCuenta.yape, dia: ahora);
      expect(yape, 20000 - 12000);
      expect(await repo.observarLoQueDebes().first, hasLength(2));
    });

    test('un gasto normal sigue pagado y sin proveedor', () async {
      final antes = await tienesHoy();
      final id = (await movimientos.registrar(
        NuevoMovimiento(
          tipo: TipoMovimiento.egreso,
          montoCentimos: 5000,
          cuenta: TipoCuenta.efectivo,
          categoriaId: servicios,
          contraparte: 'Nadie',
        ),
      )).ids.single;
      expect(await tienesHoy(), antes - 5000);
      expect(await repo.observarLoQueDebes().first, isEmpty);
      final m = await (base.select(
        base.movimientos,
      )..where((x) => x.id.equals(id))).getSingle();
      expect(m.contraparteId, isNull);
      // «Todavía lo debo» solo vale para «Salió».
      await movimientos.registrar(
        NuevoMovimiento(
          tipo: TipoMovimiento.retiro,
          montoCentimos: 1000,
          cuenta: TipoCuenta.efectivo,
          pagado: false,
        ),
      );
      expect(await tienesHoy(), antes - 6000);
    });

    test('al corregir, pasa a deberse o a estar pagada', () async {
      final antes = await tienesHoy();
      final id = await gasto(40);
      expect(await tienesHoy(), antes - 4000);
      final debida = (await repo.corregir(
        id,
        NuevoMovimiento(
          tipo: TipoMovimiento.egreso,
          montoCentimos: 4000,
          cuenta: TipoCuenta.efectivo,
          categoriaId: servicios,
          pagado: false,
          contraparte: 'Luz del Oriente',
        ),
      )).ids.single;
      expect(await tienesHoy(), antes);
      final debes = await repo.observarLoQueDebes().first;
      expect(debes.single.id, debida);
      expect(debes.single.proveedor, 'Luz del Oriente');
      await repo.corregir(
        debida,
        NuevoMovimiento(
          tipo: TipoMovimiento.egreso,
          montoCentimos: 4500,
          cuenta: TipoCuenta.efectivo,
          categoriaId: servicios,
        ),
      );
      expect(await tienesHoy(), antes - 4500);
      expect(await repo.observarLoQueDebes().first, isEmpty);
    });
  });

  group('Entrega 42: vender a crédito', () {
    Future<String> venta(int soles, {String? cliente}) async {
      final ingresos = await movimientos.categorias(TipoMovimiento.ingreso);
      return (await movimientos.registrar(
        NuevoMovimiento(
          tipo: TipoMovimiento.ingreso,
          montoCentimos: soles * 100,
          cuenta: TipoCuenta.efectivo,
          categoriaId: ingresos.first.id,
          pagado: false,
          contraparte: cliente,
        ),
      )).ids.single;
    }

    Future<int> efectivo() => movimientos.saldoSiSeGuarda(
      const NuevoMovimiento(
        tipo: TipoMovimiento.aporte,
        montoCentimos: 0,
        cuenta: TipoCuenta.efectivo,
      ),
    );

    test('no sube la plata, sale en «Lo que te deben» y se cobra', () async {
      final antes = await efectivo();
      final id = await venta(200, cliente: 'Doña Rosa');
      expect(await efectivo(), antes);
      final deben = await repo.observarLoQueTeDeben().first;
      expect(deben.single.id, id);
      expect(deben.single.proveedor, 'Doña Rosa');
      expect(deben.single.teDeben, isTrue);
      // No se mezcla con lo que tú debes.
      expect(await repo.observarLoQueDebes().first, isEmpty);
      // El mismo cliente, aunque se escriba distinto; es cliente, no
      // proveedor.
      await venta(50, cliente: 'doña rosa');
      final contrapartes = await base.select(base.contrapartes).get();
      expect(contrapartes.single.tipo, TipoContraparte.cliente);
      // Al cobrarla, sube la cuenta elegida.
      final yape = await repo.pagar(id, cuenta: TipoCuenta.yape, dia: ahora);
      expect(yape, 20000 + 20000);
      expect(await repo.observarLoQueTeDeben().first, hasLength(1));
    });

    test(
      'el celular del cliente y cuándo se le recordó (entrega 53)',
      () async {
        final ingresos = await movimientos.categorias(TipoMovimiento.ingreso);
        await movimientos.registrar(
          NuevoMovimiento(
            tipo: TipoMovimiento.ingreso,
            montoCentimos: 4000,
            cuenta: TipoCuenta.efectivo,
            categoriaId: ingresos.first.id,
            pagado: false,
            contraparte: 'Doña Rosa',
            celularContraparte: '987000053',
          ),
        );
        var fila = (await repo.observarLoQueTeDeben().first).single;
        expect(fila.celular, '987000053');
        expect(fila.recordadoEn, isNull);
        // Otra venta sin celular no lo borra; una con otro número lo cambia.
        await venta(10, cliente: 'doña rosa');
        expect(
          (await base.select(base.contrapartes).getSingle()).celular,
          '987000053',
        );
        await repo.guardarCelular(fila.contraparteId!, '987000054');
        await repo.marcarRecordado(fila.contraparteId!);
        fila = (await repo.observarLoQueTeDeben().first).first;
        expect(fila.celular, '987000054');
        expect(fila.recordadoEn, ahora);
        await repo.guardarCelular(fila.contraparteId!, null);
        expect((await repo.observarLoQueTeDeben().first).first.celular, isNull);
      },
    );

    test('no se guarda sin nombre', () async {
      expect(() => venta(30), throwsArgumentError);
      expect(() => venta(30, cliente: '  '), throwsArgumentError);
    });

    test('al corregir, pasa a deberse o a estar cobrada', () async {
      final ingresos = await movimientos.categorias(TipoMovimiento.ingreso);
      final antes = await efectivo();
      final id = await venta(80, cliente: 'Don Pepe');
      final cobrada = (await repo.corregir(
        id,
        NuevoMovimiento(
          tipo: TipoMovimiento.ingreso,
          montoCentimos: 8000,
          cuenta: TipoCuenta.efectivo,
          categoriaId: ingresos.first.id,
        ),
      )).ids.single;
      expect(await efectivo(), antes + 8000);
      expect(await repo.observarLoQueTeDeben().first, isEmpty);
      await repo.corregir(
        cobrada,
        NuevoMovimiento(
          tipo: TipoMovimiento.ingreso,
          montoCentimos: 8000,
          cuenta: TipoCuenta.efectivo,
          categoriaId: ingresos.first.id,
          pagado: false,
          contraparte: 'Don Pepe',
        ),
      );
      expect(await efectivo(), antes);
      expect(
        (await repo.observarLoQueTeDeben().first).single.proveedor,
        'Don Pepe',
      );
    });
  });

  group('Entrega 44: cobros y pagos en partes', () {
    Future<String> venta(int soles) async {
      final ingresos = await movimientos.categorias(TipoMovimiento.ingreso);
      return (await movimientos.registrar(
        NuevoMovimiento(
          tipo: TipoMovimiento.ingreso,
          montoCentimos: soles * 100,
          cuenta: TipoCuenta.efectivo,
          categoriaId: ingresos.first.id,
          pagado: false,
          contraparte: 'Doña Rosa',
        ),
      )).ids.single;
    }

    Future<int> saldo(TipoCuenta cuenta) => movimientos.saldoSiSeGuarda(
      NuevoMovimiento(
        tipo: TipoMovimiento.aporte,
        montoCentimos: 0,
        cuenta: cuenta,
      ),
    );

    test(
      'una parte sube la cuenta, la deuda baja y el resto la cierra',
      () async {
        final informe = RepositorioInformeLocal(base, ahora: () => ahora);
        final entro = (await informe.observarMes(null).first).entroCentimos;
        final yapeAntes = await saldo(TipoCuenta.yape);
        final efectivoAntes = await saldo(TipoCuenta.efectivo);
        final id = await venta(200);
        expect(
          await repo.saldoSiSePaga(id, TipoCuenta.yape, parteCentimos: 8000),
          yapeAntes + 8000,
        );
        final yape = await repo.pagar(
          id,
          cuenta: TipoCuenta.yape,
          dia: ahora,
          parteCentimos: 8000,
        );
        expect(yape, yapeAntes + 8000);
        var deben = (await repo.observarLoQueTeDeben().first).single;
        expect(deben.montoCentimos, 12000);
        expect(deben.pagadoEnPartesCentimos, 8000);
        expect(deben.totalConPartesCentimos, 20000);
        // Otra parte, en efectivo; y el resto completo.
        await repo.pagar(
          id,
          cuenta: TipoCuenta.efectivo,
          dia: ahora,
          parteCentimos: 5000,
        );
        deben = (await repo.observarLoQueTeDeben().first).single;
        expect(deben.montoCentimos, 7000);
        final detalle = (await repo.observarDetalle(id).first)!;
        expect([for (final p in detalle.partes) p.montoCentimos], [8000, 5000]);
        expect(detalle.trabaAlCorregir, TrabaDelRegistro.tienePartes);
        expect(detalle.trabaAlDeshacer, TrabaDelRegistro.tienePartes);
        await repo.pagar(id, cuenta: TipoCuenta.efectivo, dia: ahora);
        expect(await repo.observarLoQueTeDeben().first, isEmpty);
        // Todo suma exactamente la venta, también en el informe del mes.
        expect(
          (await informe.observarMes(null).first).entroCentimos,
          entro + 20000,
        );
        expect(await saldo(TipoCuenta.yape), yapeAntes + 8000);
        expect(await saldo(TipoCuenta.efectivo), efectivoAntes + 5000 + 7000);
        final historial = (await repo.observarHistorial().first).filas;
        expect(
          historial
              .where((f) => f.id == id || f.parteDe == id)
              .fold(0, (s, f) => s + f.montoCentimos),
          20000,
        );
        // La deuda ya pagada: sus partes no se deshacen.
        final parte = historial.firstWhere((f) => f.parteDe == id);
        final dp = (await repo.observarDetalle(parte.id).first)!;
        expect(dp.trabaAlDeshacer, TrabaDelRegistro.noEsLaUltimaParte);
        expect(dp.trabaAlCorregir, TrabaDelRegistro.esParte);
        expect(dp.deuda!.abierta, isFalse);
        expect(() => repo.deshacer(parte.id), throwsStateError);
      },
    );

    test('deshacer la última parte la devuelve a la deuda', () async {
      final efectivo = await saldo(TipoCuenta.efectivo);
      final id = await venta(100);
      await repo.pagar(
        id,
        cuenta: TipoCuenta.efectivo,
        dia: ahora,
        parteCentimos: 3000,
      );
      await repo.pagar(
        id,
        cuenta: TipoCuenta.efectivo,
        dia: ahora,
        parteCentimos: 2000,
      );
      final partes = (await repo.observarDetalle(id).first)!.partes;
      // Solo la más reciente.
      expect(() => repo.deshacer(partes.first.id), throwsStateError);
      expect(() => repo.deshacer(id), throwsStateError);
      await repo.deshacer(partes.last.id);
      expect(
        (await repo.observarLoQueTeDeben().first).single.montoCentimos,
        7000,
      );
      expect(await saldo(TipoCuenta.efectivo), efectivo + 3000);
      final detalle = (await repo.observarDetalle(partes.first.id).first)!;
      expect(detalle.trabaAlDeshacer, isNull);
      expect(detalle.deuda!.faltaCentimos, 7000);
    });

    test(
      'no se paga cero ni lo que falta como parte; compras también',
      () async {
        final id = await venta(50);
        for (final parte in [0, -100, 5000, 6000]) {
          expect(
            () => repo.pagar(
              id,
              cuenta: TipoCuenta.efectivo,
              dia: ahora,
              parteCentimos: parte,
            ),
            throwsArgumentError,
            reason: '$parte',
          );
        }
        // Una compra que se debe, en partes.
        final efectivo = await saldo(TipoCuenta.efectivo);
        final compra = (await movimientos.registrar(
          NuevoMovimiento(
            tipo: TipoMovimiento.egreso,
            montoCentimos: 9000,
            cuenta: TipoCuenta.efectivo,
            categoriaId: mercaderia,
            pagado: false,
            contraparte: 'Distribuidora',
          ),
        )).ids.single;
        await repo.pagar(
          compra,
          cuenta: TipoCuenta.efectivo,
          dia: ahora,
          parteCentimos: 4000,
        );
        expect(await saldo(TipoCuenta.efectivo), efectivo - 4000);
        expect(
          (await repo.observarLoQueDebes().first).single.montoCentimos,
          5000,
        );
      },
    );
  });

  test('Entrega 44.1: lo que te deben en el PDF y el Excel; los cambios '
      'de un cobro', () async {
    final ingresos = await movimientos.categorias(TipoMovimiento.ingreso);
    final venta = (await movimientos.registrar(
      NuevoMovimiento(
        tipo: TipoMovimiento.ingreso,
        montoCentimos: 20000,
        cuenta: TipoCuenta.efectivo,
        categoriaId: ingresos.first.id,
        pagado: false,
        contraparte: 'Doña Rosa',
      ),
    )).ids.single;
    await repo.pagar(
      venta,
      cuenta: TipoCuenta.yape,
      dia: ahora,
      parteCentimos: 2000,
    );
    final informe = RepositorioInformeLocal(base, ahora: () => ahora);
    final mes = await informe.observarMes(null).first;
    final d = await informe.detalleParaPdf(mes);
    expect(d.deudas, isEmpty);
    expect(d.teDeben.single.proveedor, 'Doña Rosa');
    expect(d.teDeben.single.centimos, 18000);
    expect(d.teDeben.single.pagadoEnPartesCentimos, 2000);
    // Lo mismo que la tarjeta de la app.
    expect(
      d.loQueTeDebenCentimos,
      (await repo.observarLoQueTeDeben().first).fold(
        0,
        (s, f) => s + f.montoCentimos,
      ),
    );
    for (final destino in DestinoInforme.values) {
      expect(
        await armarPdfDelInforme(
          mes,
          d,
          destino: destino,
          nombreNegocio: 'Bodega Don Lucho',
          hoy: ahora,
        ),
        isNotEmpty,
        reason: destino.name,
      );
    }
    final zip = ZipDecoder().decodeBytes(
      armarExcelDelInforme(mes, d, nombreNegocio: 'Bodega', hoy: ahora),
    );
    expect(
      utf8.decode(zip.findFile('xl/workbook.xml')!.readBytes()!),
      contains('name="Lo que te deben"'),
    );
    // En los cambios, una venta se cobra.
    final cambios = (await repo.observarDetalle(venta).first)!.cambios;
    final pago = cambios.whereType<CambioPagado>().single;
    expect(pago.cobro, isTrue);
    expect(pago.parteCentimos, 2000);
    expect(
      Textos.tePagaron('Yape', '9 nov'),
      'Marcaste que ya cobraste: Yape, 9 nov',
    );
  });

  group('Entrega 44.2: deshacer el cobro o el pago', () {
    Future<int> saldo(TipoCuenta cuenta) => movimientos.saldoSiSeGuarda(
      NuevoMovimiento(
        tipo: TipoMovimiento.aporte,
        montoCentimos: 0,
        cuenta: cuenta,
      ),
    );

    Future<String> venta(int soles) async {
      final ingresos = await movimientos.categorias(TipoMovimiento.ingreso);
      return (await movimientos.registrar(
        NuevoMovimiento(
          tipo: TipoMovimiento.ingreso,
          montoCentimos: soles * 100,
          cuenta: TipoCuenta.efectivo,
          categoriaId: ingresos.first.id,
          pagado: false,
          contraparte: 'Doña Rosa',
        ),
      )).ids.single;
    }

    test('una venta cobrada vuelve a deberse y sale de la cuenta', () async {
      final yape = await saldo(TipoCuenta.yape);
      final id = await venta(100);
      expect(
        (await repo.observarDetalle(id).first)!.sePuedeDeshacerElPago,
        isFalse,
      );
      await repo.pagar(id, cuenta: TipoCuenta.yape, dia: ahora);
      final detalle = (await repo.observarDetalle(id).first)!;
      expect(detalle.sePuedeDeshacerElPago, isTrue);
      expect(detalle.saldoSiSeDeshaceElPagoCentimos, yape);
      expect(await repo.deshacerPago(id), yape);
      expect(await saldo(TipoCuenta.yape), yape);
      final deben = (await repo.observarLoQueTeDeben().first).single;
      expect(deben.id, id);
      expect(deben.montoCentimos, 10000);
      final despues = (await repo.observarDetalle(id).first)!;
      expect(despues.sePuedeDeshacerElPago, isFalse);
      expect(
        despues.cambios.whereType<CambioPagoDeshecho>().single.cobro,
        isTrue,
      );
      // Se puede volver a cobrar, y otra vez deshacer.
      await repo.pagar(id, cuenta: TipoCuenta.efectivo, dia: ahora);
      expect(
        (await repo.observarDetalle(id).first)!.sePuedeDeshacerElPago,
        isTrue,
      );
    });

    test(
      'una compra con comprobante pagada después vuelve a deberse',
      () async {
        final efectivo = await saldo(TipoCuenta.efectivo);
        final id = await compraQueSeDebe();
        await repo.pagar(id, cuenta: TipoCuenta.efectivo, dia: ahora);
        expect(await saldo(TipoCuenta.efectivo), efectivo - 98000);
        final detalle = (await repo.observarDetalle(id).first)!;
        expect(detalle.sePuedeDeshacerElPago, isTrue);
        // Dejaría el efectivo como estaba.
        expect(detalle.saldoSiSeDeshaceElPagoCentimos, efectivo);
        await repo.deshacerPago(id);
        expect(await saldo(TipoCuenta.efectivo), efectivo);
        expect((await repo.observarLoQueDebes().first).single.id, id);
      },
    );

    test('un gasto anotado ya pagado no lo tiene', () async {
      final id = await gasto(30);
      expect(
        (await repo.observarDetalle(id).first)!.sePuedeDeshacerElPago,
        isFalse,
      );
      expect(() => repo.deshacerPago(id), throwsStateError);
    });

    test('una deuda en partes cerrada con el resto se reabre', () async {
      final id = await venta(200);
      await repo.pagar(
        id,
        cuenta: TipoCuenta.efectivo,
        dia: ahora,
        parteCentimos: 5000,
      );
      await repo.pagar(id, cuenta: TipoCuenta.efectivo, dia: ahora);
      expect(await repo.observarLoQueTeDeben().first, isEmpty);
      final cerrada = (await repo.observarDetalle(id).first)!;
      expect(cerrada.sePuedeDeshacerElPago, isTrue);
      await repo.deshacerPago(id);
      expect(
        (await repo.observarLoQueTeDeben().first).single.montoCentimos,
        15000,
      );
      // Y ya se deshace la parte.
      final parte = (await repo.observarDetalle(id).first)!.partes.single;
      expect(
        (await repo.observarDetalle(parte.id).first)!.trabaAlDeshacer,
        isNull,
      );
      await repo.deshacer(parte.id);
      expect(
        (await repo.observarLoQueTeDeben().first).single.montoCentimos,
        20000,
      );
    });
  });

  group('Entrega 55: lo cobrado otro día sale el día del pago', () {
    Future<String> fiado(
      int soles, {
      TipoMovimiento tipo = TipoMovimiento.ingreso,
    }) async {
      final categorias = await movimientos.categorias(tipo);
      return (await movimientos.registrar(
        NuevoMovimiento(
          tipo: tipo,
          montoCentimos: soles * 100,
          cuenta: TipoCuenta.efectivo,
          categoriaId: categorias.first.id,
          pagado: false,
          contraparte: tipo == TipoMovimiento.ingreso
              ? 'Doña Rosa'
              : 'Don Pepe',
        ),
      )).ids.single;
    }

    Future<List<FilaHistorial>> filasDe(String id) async => [
      for (final f in (await repo.observarHistorial().first).filas)
        if (f.id == id) f,
    ];

    test('cobrado otro día: dos filas, la del pago suma ese día', () async {
      final id = await fiado(50);
      ahora = DateTime(2026, 10, 14, 10);
      await repo.pagar(id, cuenta: TipoCuenta.yape, dia: ahora);
      final filas = await filasDe(id);
      expect(filas, hasLength(2));
      final venta = filas.singleWhere((f) => !f.esPago);
      final pago = filas.singleWhere((f) => f.esPago);
      expect(venta.fecha.day, 12);
      expect(venta.pagadoOtroDia, isTrue);
      expect(pago.fecha, DateTime(2026, 10, 14, 10));
      expect(pago.pagadoOtroDia, isFalse);
      expect(pago.montoCentimos, 5000);
      expect(pago.cuenta, TipoCuenta.yape);
      // La del pago está más arriba: es más reciente.
      final todas = (await repo.observarHistorial().first).filas;
      expect(
        todas.indexWhere((f) => f.id == id && f.esPago),
        lessThan(todas.indexWhere((f) => f.id == id && !f.esPago)),
      );
      // En «Por subir» sale una sola vez.
      expect(
        filas.where((f) => f.cumple(Transaccion.porSubir)).length,
        lessThanOrEqualTo(1),
      );
    });

    test('cobrado el mismo día: una sola fila', () async {
      final id = await fiado(50);
      await repo.pagar(id, cuenta: TipoCuenta.efectivo, dia: ahora);
      final filas = await filasDe(id);
      expect(filas.single.pagadoOtroDia, isFalse);
      expect(filas.single.esPago, isFalse);
    });

    test('lo que debías, pagado otro día; y la deuda en partes', () async {
      final compra = await fiado(80, tipo: TipoMovimiento.egreso);
      final venta = await fiado(100);
      ahora = DateTime(2026, 10, 13, 10);
      await repo.pagar(
        venta,
        cuenta: TipoCuenta.efectivo,
        dia: ahora,
        parteCentimos: 3000,
      );
      ahora = DateTime(2026, 10, 15, 10);
      await repo.pagar(compra, cuenta: TipoCuenta.efectivo, dia: ahora);
      await repo.pagar(venta, cuenta: TipoCuenta.efectivo, dia: ahora);
      final pagoCompra = (await filasDe(compra)).singleWhere((f) => f.esPago);
      expect(pagoCompra.tipo, TipoMovimiento.egreso);
      expect(pagoCompra.fecha.day, 15);
      // La parte salió el 13; el resto, el 15, en la fila del pago.
      final filas = (await repo.observarHistorial().first).filas;
      final parte = filas.singleWhere((f) => f.parteDe == venta);
      expect(parte.fecha.day, 13);
      expect(parte.montoCentimos, 3000);
      final resto = (await filasDe(venta)).singleWhere((f) => f.esPago);
      expect(resto.montoCentimos, 7000);
      expect(resto.fecha.day, 15);
    });
  });

  group('Entrega 66: el documento y la institución', () {
    test('se guardan, se corrigen y quedan en los cambios', () async {
      final id = (await movimientos.registrar(
        NuevoMovimiento(
          tipo: TipoMovimiento.egreso,
          montoCentimos: 4500,
          cuenta: TipoCuenta.efectivo,
          categoriaId: mercaderia,
          documentoTipo: 'Factura',
          documentoNumero: ' 0045J ',
          institucion: 'Comercial Tarapoto',
        ),
      )).ids.single;
      var d = await detalle(id);
      expect(d.fila.documentoTipo, 'Factura');
      expect(d.fila.documentoNumero, '0045J');
      expect(d.fila.proveedor, 'Comercial Tarapoto');
      // Se sugiere la próxima vez.
      expect(await movimientos.nombresDeContrapartes(), ['Comercial Tarapoto']);
      // El buscador la encuentra por el número.
      final h = await historial();
      expect(
        h.filas.where(
          (f) =>
              const FiltrosDelHistorial(texto: '0045j')
                  .cumple(f, cuenta: (c) => c.name),
        ),
        hasLength(1),
      );

      final nuevo = (await repo.corregir(
        id,
        NuevoMovimiento(
          tipo: TipoMovimiento.egreso,
          montoCentimos: 4500,
          cuenta: TipoCuenta.efectivo,
          categoriaId: mercaderia,
          documentoTipo: 'Boleta',
          documentoNumero: 'B-12',
          institucion: 'Distribuidora Selva',
        ),
      )).ids.single;
      d = await detalle(nuevo);
      expect(d.fila.documentoTipo, 'Boleta');
      expect(d.fila.proveedor, 'Distribuidora Selva');
      // Entrega 69: el nombre corregido deja de sugerirse.
      expect(await movimientos.nombresDeContrapartes(), [
        'Distribuidora Selva',
      ]);
      final corregido = d.cambios.whereType<CambioCorregido>().single;
      expect(
        {for (final c in corregido.campos) c.campo: (c.anterior, c.nuevo)},
        {
          CampoMovimiento.documento: ('Factura 0045J', 'Boleta B-12'),
          CampoMovimiento.institucion: (
            'Comercial Tarapoto',
            'Distribuidora Selva',
          ),
        },
      );
    });

    test('una venta pagada guarda al cliente; un pase no lleva nada', () async {
      final ingresos = await movimientos.categorias(TipoMovimiento.ingreso);
      final venta = (await movimientos.registrar(
        NuevoMovimiento(
          tipo: TipoMovimiento.ingreso,
          montoCentimos: 9000,
          cuenta: TipoCuenta.yape,
          categoriaId: ingresos.first.id,
          institucion: 'Hotel Río Mayo',
        ),
      )).ids.single;
      expect((await detalle(venta)).fila.proveedor, 'Hotel Río Mayo');
      expect(await movimientos.nombresDeContrapartes(), ['Hotel Río Mayo']);
      // Lo que te deben no cambia: una venta pagada no es deuda.
      expect(await repo.observarLoQueTeDeben().first, isEmpty);

      final pase = (await movimientos.registrar(
        const NuevoMovimiento(
          tipo: TipoMovimiento.transferencia,
          montoCentimos: 1000,
          cuenta: TipoCuenta.efectivo,
          cuentaDestino: TipoCuenta.yape,
          documentoTipo: 'Factura',
          institucion: 'Nadie',
        ),
      )).ids.single;
      final p = (await detalle(pase)).fila;
      expect(p.documentoTipo, isNull);
      expect(p.proveedor, isNull);
    });

    test('con comprobante leído, se corrigen sin tocar el monto', () async {
      final id = await compraQueSeDebe();
      var d = await detalle(id);
      // Lo leído se muestra como documento.
      expect(d.fila.documentoTipo, 'Factura');
      expect(d.fila.documentoNumero, 'F001-12345');
      final nuevo = (await repo.corregir(
        id,
        NuevoMovimiento(
          tipo: TipoMovimiento.egreso,
          montoCentimos: 1,
          cuenta: TipoCuenta.efectivo,
          categoriaId: mercaderia,
          pagado: false,
          documentoTipo: 'Guía de remisión',
          documentoNumero: 'T001-9',
          institucion: 'San Martín SAC',
        ),
      )).ids.single;
      d = await detalle(nuevo);
      expect(d.fila.montoCentimos, 98000);
      expect(d.fila.documentoTipo, 'Guía de remisión');
      expect(d.fila.documentoNumero, 'T001-9');
      expect(d.fila.proveedor, 'San Martín SAC');
      expect(d.comprobante, isNotNull);
    });
  });
}
