import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_arqueo_local.dart';
import 'package:moca/datos/repositorios/repositorio_comprobantes_local.dart';
import 'package:moca/datos/repositorios/repositorio_historial_local.dart';
import 'package:moca/datos/repositorios/repositorio_informe_local.dart';
import 'package:moca/datos/repositorios/repositorio_moca_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/arqueo.dart';
import 'package:moca/dominio/comprobantes.dart';
import 'package:moca/dominio/informe.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/moca.dart';
import 'package:moca/dominio/movimientos.dart';
import 'package:moca/dominio/primer_dia.dart';

void main() {
  late BaseLocal base;
  late RepositorioMovimientosLocal movimientos;
  late RepositorioInformeLocal informe;
  late RepositorioMocaLocal moca;
  late Map<String, String> categorias;
  // Lunes 12 de octubre de 2026.
  var ahora = DateTime(2026, 10, 12, 21);

  setUp(() async {
    ahora = DateTime(2026, 10, 12, 21);
    base = BaseLocal(NativeDatabase.memory());
    final primerDia = RepositorioPrimerDiaLocal(base, ahora: () => ahora);
    await primerDia.anotarPrimeraVenta({TipoCuenta.efectivo: 35000});
    await primerDia.seguirSinCuenta();
    await primerDia.completarAlta(
      const DatosAlta(
        nombre: 'Bodega Don Lucho',
        tipoNegocio: TipoNegocio.bodega,
        saldos: {TipoCuenta.efectivo: 500000},
        horaCierreMinutos: 21 * 60,
      ),
    );
    movimientos = RepositorioMovimientosLocal(base, ahora: () => ahora);
    informe = RepositorioInformeLocal(base, ahora: () => ahora);
    moca = RepositorioMocaLocal(base, ahora: () => ahora);
    categorias = {
      for (final tipo in [TipoMovimiento.ingreso, TipoMovimiento.egreso])
        for (final c in await movimientos.categorias(tipo)) c.nombre: c.id,
    };
  });

  tearDown(() => base.close());

  Future<String> anotar(
    TipoMovimiento tipo,
    int soles, {
    String? categoria,
    DateTime? el,
  }) async {
    if (el != null) ahora = el;
    final guardado = await movimientos.registrar(
      NuevoMovimiento(
        tipo: tipo,
        montoCentimos: soles * 100,
        cuenta: TipoCuenta.efectivo,
        categoriaId: categoria == null ? null : categorias[categoria],
      ),
    );
    return guardado.ids.single;
  }

  group('Informe del mes', () {
    test(
      'El primer mes: cómo se movió la plata, desde qué día y sustento',
      () async {
        await anotar(
          TipoMovimiento.egreso,
          80,
          categoria: 'Movilidad del negocio',
        );
        await anotar(TipoMovimiento.retiro, 100);
        final i = await informe.observarMes(null).first;
        expect(i.mes, DateTime(2026, 10));
        expect(i.enCurso, isTrue);
        expect(i.desdeDia, 12);
        expect(i.mesAnterior, isNull);
        expect(i.diferenciaConAnteriorCentimos, isNull);
        // Empezó con el saldo inicial; termina con «Tienes hoy».
        expect(i.inicioCentimos, 500000);
        expect(i.entroCentimos, 35000);
        expect(i.salioCentimos, 8000);
        expect(i.retirosCentimos, 10000);
        expect(i.ajustesCentimos, 0);
        expect(i.crecioCentimos, 17000);
        expect(i.finCentimos, 517000);
        final inicio = await movimientos.observarInicio().first;
        expect(i.finCentimos, inicio.tienesHoyCentimos);
        expect(i.gastos.single.nombre, 'Movilidad del negocio');
        expect(i.confianza?.sinPapel, 100);
        expect(i.mesPrevio, isNull);
        expect(i.mesSiguiente, isNull);
      },
    );

    test('Se compara con el mes anterior hasta el mismo día', () async {
      await anotar(
        TipoMovimiento.ingreso,
        200,
        categoria: 'Otro ingreso',
        el: DateTime(2026, 10, 20),
      );
      ahora = DateTime(2026, 11, 15, 10);
      await anotar(TipoMovimiento.ingreso, 900, categoria: 'Venta del día');
      final noviembre = await informe.observarMes(null).first;
      expect(noviembre.mesAnterior, DateTime(2026, 10));
      // Octubre hasta el 15: solo la venta del 12.
      expect(noviembre.diferenciaConAnteriorCentimos, 90000 - 35000);
      expect(noviembre.desdeDia, isNull);
      expect(noviembre.mesPrevio, DateTime(2026, 10));

      final octubre = await informe.observarMes(DateTime(2026, 10)).first;
      expect(octubre.enCurso, isFalse);
      expect(octubre.entroCentimos, 55000);
      expect(octubre.mesSiguiente, DateTime(2026, 11));
    });

    test('Flujo de caja: lo que se debe cuenta al pagarlo, el arqueo '
        'ajusta, y cada mes cuadra con el saldo (entrega 14.9)', () async {
      final mercaderia = categorias['Mercadería']!;
      // Una compra «todavía lo debo» el 14 de octubre, con boleta del 8.
      ahora = DateTime(2026, 10, 14, 18);
      await RepositorioComprobantesLocal(
        base,
        ahora: () => ahora,
      ).guardarCompra(
        CompraConfirmada(
          lectura: const LecturaComprobante(
            origen: OrigenLectura.qr,
            emisorIdentificacion: '20100070970',
            tipo: 'Factura',
            serie: 'F001',
            numero: '777',
            totalCentimos: 98000,
          ),
          totalCentimos: 98000,
          cuenta: TipoCuenta.efectivo,
          pagado: false,
          categoriaId: mercaderia,
          fecha: DateTime(2026, 10, 8),
        ),
      );
      // El 20 faltan S/ 30 en el efectivo y no sabe por qué.
      ahora = DateTime(2026, 10, 20, 21);
      await RepositorioArqueoLocal(base, ahora: () => ahora).guardar([
        const ConteoCuenta(
          cuenta: TipoCuenta.efectivo,
          contadoCentimos: 535000 - 3000,
          motivo: MotivoArqueo.noLoSe,
        ),
      ]);
      // La paga el 3 de noviembre.
      ahora = DateTime(2026, 11, 10, 12);
      final historial = RepositorioHistorialLocal(base, ahora: () => ahora);
      final deuda = (await base.select(base.movimientos).get()).firstWhere(
        (m) => m.estadoPago == EstadoPago.pendiente,
      );
      await historial.pagar(
        deuda.id,
        cuenta: TipoCuenta.efectivo,
        dia: DateTime(2026, 11, 3),
      );

      final octubre = await informe.observarMes(DateTime(2026, 10)).first;
      expect(octubre.inicioCentimos, 500000);
      expect(octubre.entroCentimos, 35000);
      // La deuda no salió en octubre, aunque la boleta sea de octubre.
      expect(octubre.salioCentimos, 0);
      expect(octubre.ajustesCentimos, -3000);
      expect(octubre.finCentimos, 532000);

      final noviembre = await informe.observarMes(null).first;
      expect(noviembre.inicioCentimos, octubre.finCentimos);
      expect(noviembre.salioCentimos, 98000);
      expect(noviembre.gastos.single.nombre, 'Mercadería');
      expect(noviembre.crecioCentimos, -98000);
      expect(noviembre.diferenciaConAnteriorCentimos, isNotNull);
      final inicio = await movimientos.observarInicio().first;
      expect(noviembre.finCentimos, inicio.tienesHoyCentimos);
    });

    test('Lo que puse de mi bolsillo sube la plata pero no es venta '
        '(entrega 14.11)', () async {
      await anotar(TipoMovimiento.aporte, 300);
      final i = await informe.observarMes(null).first;
      expect(i.entroCentimos, 35000);
      expect(i.aportesCentimos, 30000);
      expect(i.crecioCentimos, 35000 + 30000);
      final inicio = await movimientos.observarInicio().first;
      expect(i.finCentimos, inicio.tienesHoyCentimos);
      // En la semana tampoco cuenta como «Entró».
      expect(inicio.semanaEntroCentimos, 35000);
      expect(inicio.semanaAportesCentimos, 30000);
    });

    test('Más de cinco categorías se juntan en «Lo demás»', () async {
      for (final (i, c) in [
        'Alquiler',
        'Sueldos del personal',
        'Movilidad del negocio',
        'Mercadería',
        'Otros',
        'Bolsas y envases',
      ].indexed) {
        await anotar(TipoMovimiento.egreso, 100 + i * 10, categoria: c);
      }
      final i = await informe.observarMes(null).first;
      expect(i.gastos, hasLength(5));
      expect(i.gastos.first.nombre, 'Bolsas y envases');
      expect(i.gastos.last.nombre, isNull);
      expect(i.gastos.last.centimos, 10000 + 11000);
    });

    test('Cambio de categoría y advertencia de mercadería', () async {
      await anotar(
        TipoMovimiento.egreso,
        500,
        categoria: 'Mercadería',
        el: DateTime(2026, 10, 14),
      );
      ahora = DateTime(2026, 11, 20);
      await anotar(TipoMovimiento.egreso, 1200, categoria: 'Mercadería');
      final i = await informe.observarMes(null).first;
      expect(i.cambio?.nombre, 'Mercadería');
      expect(i.cambio?.centimos, 70000);
      expect(i.advertenciaMercaderia, isTrue);
    });

    test('Mes sin registros', () async {
      ahora = DateTime(2026, 11, 3);
      final i = await informe.observarMes(null).first;
      expect(i.sinRegistros, isTrue);
      expect(i.cambio, isNull);
    });
  });

  group('Flujo para la caja (entrega 14.15)', () {
    test(
      'Seis meses completos, filas por categoría y cuotas por entidad',
      () async {
        Future<void> en(
          DateTime dia,
          TipoMovimiento tipo,
          int soles, {
          String? categoria,
          String? nota,
        }) async {
          ahora = dia;
          await movimientos.registrar(
            NuevoMovimiento(
              tipo: tipo,
              montoCentimos: soles * 100,
              cuenta: TipoCuenta.efectivo,
              categoriaId: categoria == null ? null : categorias[categoria],
              nota: nota,
            ),
          );
        }

        final nov = DateTime(2026, 11, 5, 10);
        await en(nov, TipoMovimiento.ingreso, 1000, categoria: 'Venta del día');
        await en(nov, TipoMovimiento.ingreso, 50, categoria: 'Cobro de fiado');
        await en(nov, TipoMovimiento.aporte, 300);
        await en(nov, TipoMovimiento.retiro, 100);
        await en(nov, TipoMovimiento.egreso, 40, categoria: 'Flete');
        await en(nov, TipoMovimiento.egreso, 10, categoria: 'Otros');
        for (final (entidad, soles) in [
          ('Caja Piura', 450),
          ('Mibanco', 200),
          ('Caja Cusco', 100),
          ('Financiera Confianza', 50),
        ]) {
          await en(
            nov,
            TipoMovimiento.egreso,
            soles,
            categoria: 'Cuota de préstamo',
            nota: entidad,
          );
        }
        ahora = DateTime(2027, 1, 10, 12);

        final f = await informe.flujoParaCredito();
        expect(f.meses.map((m) => m.mes), [
          for (var m = 7; m <= 12; m++) DateTime(2026, m),
        ]);
        expect(f.meses.map((m) => m.estado), [
          ...List.filled(3, EstadoMesFlujo.antesDeMoca),
          EstadoMesFlujo.incompleto,
          EstadoMesFlujo.completo,
          EstadoMesFlujo.completo,
        ]);
        // Octubre: la primera venta del 12, en «Ventas al contado».
        expect(f.meses[3].centimos[FilaFlujo.ventasContado], 35000);

        final noviembre = f.meses[4];
        expect(noviembre.centimos, {
          FilaFlujo.ventasContado: 100000,
          FilaFlujo.ventasCreditoCobradas: 5000,
          FilaFlujo.fletes: 4000,
          FilaFlujo.otrosGastosFijos: 1000,
        });
        expect(noviembre.retirosCentimos, 10000);
        // Más de tres entidades: la tercera fila junta a las demás.
        expect(f.entidades, ['Caja Piura', 'Mibanco', 'Otras 2 entidades']);
        expect(noviembre.cuotas, [45000, 20000, 15000]);
        expect(f.meses[5].cuotas, [0, 0, 0]);
        expect(f.retirosPromedioCentimos, 5000);
        expect(f.categoriasPorFila[FilaFlujo.otrosGastosFijos], [
          'Movilidad del negocio',
          'Combustible',
          'Impuestos y trámites',
          'Otros',
        ]);
        expect(f.inicioMoca!.day, 12);
      },
    );
  });

  test('Sin ningún mes completo, va el mes en curso hasta hoy '
      '(entrega 14.15.1)', () async {
    final f = await informe.flujoParaCredito();
    expect(f.hayMesCompleto, isFalse);
    expect(f.meses.length, 6);
    expect(f.meses.first.mes, DateTime(2026, 5));
    final octubre = f.meses.last;
    expect(octubre.mes, DateTime(2026, 10));
    expect(octubre.estado, EstadoMesFlujo.enCurso);
    expect(octubre.centimos[FilaFlujo.ventasContado], 35000);
    expect(f.meses.take(5).map((m) => m.estado).toSet(), {
      EstadoMesFlujo.antesDeMoca,
    });
  });

  test('Un pase cambia la plata de cuenta, no el total ni el informe '
      '(entrega 21.1)', () async {
    final antes = await informe.observarMes(null).first;
    final inicioAntes = await movimientos.observarInicio().first;
    await movimientos.registrar(
      const NuevoMovimiento(
        tipo: TipoMovimiento.transferencia,
        montoCentimos: 20000,
        cuenta: TipoCuenta.efectivo,
        cuentaDestino: TipoCuenta.yape,
      ),
    );
    final despues = await informe.observarMes(null).first;
    final inicio = await movimientos.observarInicio().first;
    expect(
      inicio.saldosPorCuenta[TipoCuenta.efectivo],
      inicioAntes.saldosPorCuenta[TipoCuenta.efectivo]! - 20000,
    );
    expect(
      inicio.saldosPorCuenta[TipoCuenta.yape],
      (inicioAntes.saldosPorCuenta[TipoCuenta.yape] ?? 0) + 20000,
    );
    expect(inicio.tienesHoyCentimos, inicioAntes.tienesHoyCentimos);
    expect(inicio.semanaEntroCentimos, inicioAntes.semanaEntroCentimos);
    expect(inicio.semanaSalioCentimos, inicioAntes.semanaSalioCentimos);
    expect(despues.entroCentimos, antes.entroCentimos);
    expect(despues.salioCentimos, antes.salioCentimos);
    expect(despues.crecioCentimos, antes.crecioCentimos);
    expect(despues.finCentimos, inicio.tienesHoyCentimos);
    // A la misma cuenta, no.
    expect(
      () => movimientos.registrar(
        const NuevoMovimiento(
          tipo: TipoMovimiento.transferencia,
          montoCentimos: 100,
          cuenta: TipoCuenta.yape,
          cuentaDestino: TipoCuenta.yape,
        ),
      ),
      throwsArgumentError,
    );
  });

  group('Avisos', () {
    test('Dos días sin anotar dan aviso, y se va al anotar', () async {
      ahora = DateTime(2026, 10, 14, 9);
      expect(await moca.observarAvisos().first, isEmpty);
      ahora = DateTime(2026, 10, 15, 9);
      final avisos = await moca.observarAvisos().first;
      expect(avisos.single.tipo, TipoAviso.diasSinRegistrar);
      expect(avisos.single.dias, 2);
      await anotar(TipoMovimiento.ingreso, 100, categoria: 'Venta del día');
      expect(await moca.observarAvisos().first, isEmpty);
    });

    test('Gasto atípico, y «Entendido» lo quita', () async {
      for (final d in [5, 6, 7]) {
        await anotar(
          TipoMovimiento.egreso,
          100,
          categoria: 'Mercadería',
          el: DateTime(2026, 10, 12 + d - 5, 20),
        );
      }
      final id = await anotar(
        TipoMovimiento.egreso,
        300,
        categoria: 'Mercadería',
        el: DateTime(2026, 10, 15, 20),
      );
      final avisos = await moca.observarAvisos().first;
      final atipico = avisos.single;
      expect(atipico.tipo, TipoAviso.gastoAtipico);
      expect(atipico.destinoId, id);
      expect(atipico.categoria, 'Mercadería');
      expect(atipico.prioridad, PrioridadAlerta.paraTenerEnCuenta);
      await moca.descartar(atipico);
      expect(await moca.observarAvisos().first, isEmpty);
    });

    test(
      '«No lo sé» con S/ 10 o más avisa; falta el arqueo va primero',
      () async {
        await RepositorioArqueoLocal(base, ahora: () => ahora).guardar(const [
          ConteoCuenta(
            cuenta: TipoCuenta.efectivo,
            contadoCentimos: 520000,
            motivo: MotivoArqueo.noLoSe,
          ),
        ]);
        var avisos = await moca.observarAvisos().first;
        expect(avisos.single.tipo, TipoAviso.diferenciaArqueo);
        expect(avisos.single.montoCentimos, 15000);
        expect(avisos.single.cuenta, TipoCuenta.efectivo);

        // Dos semanas después, sin arqueo la semana anterior.
        ahora = DateTime(2026, 10, 26, 9);
        await anotar(TipoMovimiento.ingreso, 100, categoria: 'Venta del día');
        avisos = await moca.observarAvisos().first;
        expect(avisos.first.tipo, TipoAviso.faltaArqueo);
        expect(avisos.map((a) => a.tipo), contains(TipoAviso.diferenciaArqueo));
      },
    );
  });

  group('Resumen de la semana', () {
    test('La primera semana resume lo que va', () async {
      await anotar(
        TipoMovimiento.egreso,
        80,
        categoria: 'Movilidad del negocio',
      );
      final r = await moca.observarResumen().first;
      expect(r.semanaPasada, isFalse);
      expect(r.quedoCentimos, 27000);
      expect(r.categoriaTop, 'Movilidad del negocio');
      expect(r.diferenciaCentimos, isNull);
    });

    test('Después resume la semana pasada y la compara', () async {
      await anotar(
        TipoMovimiento.ingreso,
        100,
        categoria: 'Venta del día',
        el: DateTime(2026, 10, 20),
      );
      await anotar(
        TipoMovimiento.egreso,
        50,
        categoria: 'Sueldos del personal',
      );
      ahora = DateTime(2026, 10, 27);
      final r = await moca.observarResumen().first;
      expect(r.semanaPasada, isTrue);
      expect(r.quedoCentimos, 5000);
      expect(r.diferenciaCentimos, 5000 - 35000);
      expect(r.categoriaTop, 'Sueldos del personal');
    });
  });
}
