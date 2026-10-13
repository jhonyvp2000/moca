import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_comprobantes_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/comprobantes.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/primer_dia.dart';

void main() {
  late BaseLocal base;
  late RepositorioComprobantesLocal repo;
  late RepositorioMovimientosLocal movimientos;
  late String mercaderia;
  final ahora = DateTime(2026, 10, 12, 21);

  setUp(() async {
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
    repo = RepositorioComprobantesLocal(base, ahora: () => ahora);
    movimientos = RepositorioMovimientosLocal(base, ahora: () => ahora);
    mercaderia = (await movimientos.categorias(TipoMovimiento.egreso))
        .firstWhere((c) => c.nombre == 'Mercadería')
        .id;
  });

  tearDown(() => base.close());

  const qr = LecturaComprobante(
    origen: OrigenLectura.qr,
    emisorIdentificacion: '20100070970',
    tipo: 'Factura',
    serie: 'F001',
    numero: '12345',
    totalCentimos: 98000,
  );

  CompraConfirmada compra(
    LecturaComprobante l, {
    bool pagado = true,
    String? nombre,
  }) => CompraConfirmada(
    lectura: l,
    totalCentimos: l.totalCentimos!,
    cuenta: TipoCuenta.efectivo,
    pagado: pagado,
    categoriaId: mercaderia,
    emisorNombre: nombre,
    fecha: DateTime(2026, 10, 8),
  );

  test(
    'Una compra pagada baja el saldo y guarda comprobante y proveedor',
    () async {
      final guardado = await repo.guardarCompra(
        compra(qr, nombre: 'Distribuidora San Martín'),
      );
      expect(guardado.tienesHoyCentimos, 135000 - 98000);

      final m = await (base.select(
        base.movimientos,
      )..where((m) => m.id.equals(guardado.ids.single))).getSingle();
      expect(m.fuente, Fuente.qr);
      expect(m.nivelConfianza, NivelConfianza.b);
      expect(m.fechaComprobante, DateTime(2026, 10, 8));
      final proveedor = await base.select(base.contrapartes).getSingle();
      expect(proveedor.nombre, 'Distribuidora San Martín');
      expect(proveedor.identificacionFiscal, '20100070970');
    },
  );

  test('«Todavía lo debo» no baja el saldo ni cuenta como «salió»', () async {
    final guardado = await repo.guardarCompra(compra(qr, pagado: false));
    expect(guardado.tienesHoyCentimos, 135000);
    final inicio = await movimientos.observarInicio().first;
    expect(inicio.semanaSalioCentimos, 0);
    final m = await base.select(base.movimientos).get();
    final deuda = m.firstWhere((x) => x.comprobanteId != null);
    expect(deuda.estadoPago, EstadoPago.pendiente);
    expect(deuda.fechaPago, isNull);
  });

  test('Un comprobante no se anota dos veces; si se deshizo, sí', () async {
    expect(await repo.yaAnotado(qr), isFalse);
    final guardado = await repo.guardarCompra(compra(qr));
    expect(await repo.yaAnotado(qr), isTrue);
    expect(() => repo.guardarCompra(compra(qr)), throwsStateError);

    await movimientos.deshacer(guardado);
    expect(await repo.yaAnotado(qr), isFalse);
    await repo.guardarCompra(compra(qr));
    expect(await base.select(base.comprobantes).get(), hasLength(1));
  });

  test('Una foto ilegible completada a mano queda con nivel C', () async {
    const ilegible = LecturaComprobante(
      origen: OrigenLectura.foto,
      legible: false,
      totalCentimos: 98000,
    );
    final g = await repo.guardarCompra(compra(ilegible, nombre: 'Proveedor'));
    final m = await (base.select(
      base.movimientos,
    )..where((m) => m.id.equals(g.ids.single))).getSingle();
    expect(m.nivelConfianza, NivelConfianza.c);
    expect(m.fuente, Fuente.foto);
  });

  test('El mismo proveedor se reutiliza', () async {
    const foto1 = LecturaComprobante(
      origen: OrigenLectura.foto,
      emisorNombre: 'Distribuidora San Martín',
      totalCentimos: 10000,
    );
    const foto2 = LecturaComprobante(
      origen: OrigenLectura.foto,
      emisorNombre: 'distribuidora san martín',
      totalCentimos: 20000,
    );
    await repo.guardarCompra(compra(foto1));
    await repo.guardarCompra(compra(foto2));
    expect(await base.select(base.contrapartes).get(), hasLength(1));
  });
}
