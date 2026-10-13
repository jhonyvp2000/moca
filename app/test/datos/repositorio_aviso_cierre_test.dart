import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_aviso_cierre_local.dart';
import 'package:moca/datos/repositorios/repositorio_moca_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/aviso_cierre.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/primer_dia.dart';

void main() {
  late BaseLocal base;
  late RepositorioAvisoCierreLocal repo;
  // Lunes 12 de octubre de 2026, 10:00 a. m.
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
    repo = RepositorioAvisoCierreLocal(base, ahora: () => ahora);
  });

  tearDown(() => base.close());

  test('El aviso de cierre no llega el día que ya hay venta', () async {
    final plan = await repo.plan();
    final cierres = plan.where((n) => n.tipo == TipoNotificacion.cierre);
    // Hoy ya hay venta: del martes al domingo.
    expect(cierres.first.cuando, DateTime(2026, 10, 13, 21));
    expect(cierres, hasLength(6));
    // Sin registros desde hoy, el jueves a las 8:00 avisa dos días.
    final dias = plan.firstWhere(
      (n) => n.tipo == TipoNotificacion.diasSinAnotar,
    );
    expect(dias.cuando, DateTime(2026, 10, 15, 8));
    expect(dias.dias, 2);
    // El lunes siguiente falta el arqueo.
    expect(
      plan.any(
        (n) =>
            n.tipo == TipoNotificacion.faltaArqueo &&
            n.cuando == DateTime(2026, 10, 19, 8),
      ),
      isFalse,
      reason: 'El 19 ya se pasa de los siete días del plan.',
    );
  });

  test(
    'Contestar efectivo, Yape y listo; el monto raro no se guarda',
    () async {
      ahora = DateTime(2026, 10, 13, 21, 5);
      expect(
        await repo.responderVenta(TipoCuenta.efectivo, 'mucho'),
        isA<MontoNoEntendido>(),
      );
      final yape = await repo.responderVenta(TipoCuenta.efectivo, 'S/ 350');
      expect((yape as PreguntarCuenta).cuenta, TipoCuenta.yape);
      final listo = await repo.responderVenta(TipoCuenta.yape, '120');
      expect((listo as VentaLista).ventaDeHoyCentimos, 47000);
      expect(listo.tocaArqueo, isFalse);
      // Con venta hoy, ya no hay aviso de cierre para hoy.
      final plan = await repo.plan();
      expect(
        plan.where(
          (n) => n.cuando.day == 13 && n.tipo == TipoNotificacion.cierre,
        ),
        isEmpty,
      );
    },
  );

  test('Banco se pregunta solo si hubo ventas al banco', () async {
    await RepositorioMovimientosLocal(
      base,
      ahora: () => ahora,
    ).anotarVentaDelDia({TipoCuenta.banco: 5000});
    ahora = DateTime(2026, 10, 18, 21, 5);
    final paso = await repo.responderVenta(TipoCuenta.yape, null);
    expect((paso as PreguntarCuenta).cuenta, TipoCuenta.banco);
    // Es domingo y no hay arqueo: lo ofrece.
    final listo = await repo.responderVenta(TipoCuenta.banco, null);
    expect((listo as VentaLista).tocaArqueo, isTrue);
  });

  test('«Hoy no abrí» cuenta como día con registro', () async {
    ahora = DateTime(2026, 10, 13, 21, 5);
    await repo.hoyNoAbri();
    await repo.hoyNoAbri();
    expect(await base.select(base.diasCerrados).get(), hasLength(1));
    ahora = DateTime(2026, 10, 15, 9);
    final avisos = await RepositorioMocaLocal(
      base,
      ahora: () => ahora,
    ).observarAvisos().first;
    expect(avisos, isEmpty);
    // El aviso de cierre de un día cerrado no llega.
    ahora = DateTime(2026, 10, 13, 10);
    expect(
      (await repo.plan()).where(
        (n) => n.cuando.day == 13 && n.tipo == TipoNotificacion.cierre,
      ),
      isEmpty,
    );
  });

  test('El permiso de avisos se pregunta una vez', () async {
    expect(await repo.permisoPreguntado(), isFalse);
    await repo.marcarPermisoPreguntado();
    expect(await repo.permisoPreguntado(), isTrue);
  });
}
