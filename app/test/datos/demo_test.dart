import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_historial_local.dart';
import 'package:moca/datos/repositorios/repositorio_informe_local.dart';
import 'package:moca/datos/repositorios/repositorio_moca_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_operador_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/datos/simulados/demo.dart';
import 'package:moca/dominio/arqueo.dart';
import 'package:moca/dominio/historial.dart';
import 'package:moca/dominio/informe.dart';
import 'package:moca/dominio/moca.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/primer_dia.dart';
import 'package:moca/pantallas/informe/excel_informe.dart';
import 'package:moca/pantallas/informe/pdf_informe.dart';
import 'package:moca/pais/peru/flujo_credito.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BaseLocal base;
  // Martes 13 de octubre de 2026, a mediodía.
  final ahora = DateTime(2026, 10, 13, 12);

  setUp(() => base = BaseLocal(NativeDatabase.memory()));
  tearDown(() => base.close());

  test(
    'La Demo trae diez semanas que terminan hoy, sin la venta de hoy',
    () async {
      final operador = RepositorioOperadorLocal(base, ahora: () => ahora);
      final reloj = Stopwatch()..start();
      await operador.cargarDemo();
      // En el teléfono debe tardar poco.
      expect(reloj.elapsed, lessThan(const Duration(seconds: 20)));

      expect(await operador.observarDemo().first, isTrue);
      expect(
        await RepositorioPrimerDiaLocal(
          base,
          ahora: () => ahora,
        ).observarEtapa().first,
        EtapaInicio.listo,
      );
      final inicio = await RepositorioMovimientosLocal(
        base,
        ahora: () => ahora,
      ).observarInicio().first;
      expect(inicio.mostrarPrimerDia, isFalse);
      expect(inicio.ventaDeHoyCentimos, 0);
      expect(inicio.estadoArqueo, EstadoArqueo.nada);
      for (final saldo in inicio.saldosPorCuenta.values) {
        expect(saldo, greaterThan(0));
      }

      final historial = await RepositorioHistorialLocal(
        base,
        ahora: () => ahora,
      ).observarHistorial().first;
      expect(historial.porSubir, greaterThanOrEqualTo(2));
      expect(historial.filas.where((f) => f.loDebes), isNotEmpty);

      final informe = await RepositorioInformeLocal(
        base,
        ahora: () => ahora,
      ).observarMes(null).first;
      expect(informe.mesAnterior, DateTime(2026, 9));
      expect(informe.confianza?.conComprobante, greaterThan(0));
      expect(informe.confianza?.conFoto, greaterThan(0));

      final avisos = await RepositorioMocaLocal(
        base,
        ahora: () => ahora,
      ).observarAvisos().first;
      expect(
        avisos.map((a) => a.tipo),
        containsAll([TipoAviso.gastoAtipico, TipoAviso.diferenciaArqueo]),
      );

      // Al salir de la Demo se borra todo.
      await operador.borrarTodo();
      expect(await operador.observarDemo().first, isFalse);
    },
  );

  test('El PDF en sus tres versiones, con la Demo (entrega 14.12)', () async {
    await RepositorioOperadorLocal(base, ahora: () => ahora).cargarDemo();
    final repositorio = RepositorioInformeLocal(base, ahora: () => ahora);

    int paginas(List<int> bytes) =>
        RegExp(r'/Type\s*/Page[^s]')
            .allMatches(String.fromCharCodes(bytes))
            .length;

    for (final mes in [null, DateTime(2026, 9)]) {
      final informe = await repositorio.observarMes(mes).first;
      final d = await repositorio.detalleParaPdf(informe);
      // Las cuentas al cierre suman lo que dice el flujo de caja.
      expect(
        d.saldosAlCierre.values.fold(0, (s, v) => s + v),
        informe.finCentimos,
      );
      expect(d.meses.last.mes, informe.mes);
      expect(d.meses.length, inInclusiveRange(2, 6));
      expect(
        d.deudas.fold(0, (s, x) => s + x.centimos),
        informe.loQueDebesCentimos,
      );
      expect(
        d.ingresos.fold(0, (s, g) => s + g.centimos),
        informe.entroCentimos,
      );
      for (final c in d.comprobantes) {
        expect(c.fecha.month, informe.mes.month);
      }
      if (mes == null) {
        expect(d.hasta, DateTime(2026, 10, 13));
        expect(d.comprobantes, isNotEmpty);
      } else {
        expect(d.desde, DateTime(2026, 9));
        expect(d.hasta, DateTime(2026, 9, 30));
      }

      for (final destino in DestinoInforme.values) {
        final bytes = await armarPdfDelInforme(
          informe,
          d,
          destino: destino,
          nombreNegocio: 'Bodega Don Lucho',
          hoy: ahora,
        );
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
        // La del dueño cabe en una hoja.
        if (destino == DestinoInforme.dueno) expect(paginas(bytes), 1);
      }
    }
    expect(
      nombreDelPdf(
        'Bodega Don Lucho',
        DateTime(2026, 10),
        destino: DestinoInforme.contador,
      ),
      'Moca-Bodega-Don-Lucho-contador-octubre-2026.pdf',
    );
  });

  test('El Excel de las operaciones, con la Demo (entrega 14.13)', () async {
    await RepositorioOperadorLocal(base, ahora: () => ahora).cargarDemo();
    final repositorio = RepositorioInformeLocal(base, ahora: () => ahora);
    final informe = await repositorio.observarMes(DateTime(2026, 9)).first;
    final d = await repositorio.detalleParaPdf(informe);

    // Las operaciones del mes, en orden; en la Demo todo lo de setiembre se
    // pagó en setiembre, así que suman lo mismo que el informe.
    expect(d.operaciones, isNotEmpty);
    for (final (n, o) in d.operaciones.indexed) {
      expect(o.fecha.month, 9);
      if (n > 0) {
        expect(o.fecha.isBefore(d.operaciones[n - 1].fecha), isFalse);
      }
    }
    int suma(TipoMovimiento tipo) => d.operaciones
        .where((o) => o.tipo == tipo)
        .fold(0, (s, o) => s + o.centimos);
    expect(suma(TipoMovimiento.ingreso), informe.entroCentimos);
    expect(suma(TipoMovimiento.egreso), informe.salioCentimos);
    expect(suma(TipoMovimiento.retiro), informe.retirosCentimos);
    expect(suma(TipoMovimiento.aporte), informe.aportesCentimos);
    expect(
      d.operaciones.where((o) => o.comprobante != null && o.ruc != null),
      isNotEmpty,
    );

    final bytes = armarExcelDelInforme(
      informe,
      d,
      nombreNegocio: 'Bodega Don Lucho',
      hoy: ahora,
    );
    final zip = ZipDecoder().decodeBytes(bytes);
    String xml(String nombre) =>
        utf8.decode(zip.findFile(nombre)!.readBytes()!);
    expect(
      xml('xl/workbook.xml'),
      allOf(
        contains('name="Operaciones"'),
        contains('name="Resumen"'),
        contains('name="Saldos por cuenta"'),
        contains('name="Lo que debes"'),
      ),
    );
    final operaciones = xml('xl/worksheets/sheet1.xml');
    // Encabezado más una fila por operación, con filtro y fijo al bajar.
    expect('<row '.allMatches(operaciones).length, d.operaciones.length + 1);
    expect(operaciones, contains('state="frozen"'));
    expect(operaciones, contains('<autoFilter'));
    // La primera operación: el 1 de setiembre es el día 46266 de Excel.
    expect(operaciones, matches(RegExp(r'<c r="A2" s="\d+"><v>46266</v></c>')));
    expect(
      nombreDelExcel('Bodega Don Lucho', DateTime(2026, 9)),
      'Moca-Bodega-Don-Lucho-operaciones-setiembre-2026.xlsx',
    );
  });

  test('El flujo para la caja, con la Demo (entrega 14.15)', () async {
    await RepositorioOperadorLocal(base, ahora: () => ahora).cargarDemo();
    final repositorio = RepositorioInformeLocal(base, ahora: () => ahora);
    final f = await repositorio.flujoParaCredito();
    expect(f.meses.last.mes, DateTime(2026, 9));
    expect(f.meses.last.estado, EstadoMesFlujo.completo);
    expect(f.conMoca.length, 2);

    // Setiembre cuadra con el informe: todo lo que entró y salió.
    final setiembre = await repositorio.observarMes(DateTime(2026, 9)).first;
    final m = f.meses.last;
    int suma(Iterable<FilaFlujo> filas) =>
        filas.fold(0, (s, x) => s + (m.centimos[x] ?? 0));
    const entradas = [
      FilaFlujo.ventasContado,
      FilaFlujo.ventasCreditoCobradas,
      FilaFlujo.otrosIngresos,
      FilaFlujo.ingresosExtraordinarios,
    ];
    expect(suma(entradas), setiembre.entroCentimos);
    expect(
      suma(FilaFlujo.values.where((x) => !entradas.contains(x))) +
          m.cuotas.fold(0, (s, c) => s + c),
      setiembre.salioCentimos,
    );
    expect(m.retirosCentimos, setiembre.retirosCentimos);

    final zip = ZipDecoder().decodeBytes(
      armarFlujoParaCredito(f, nombreNegocio: 'Bodega Don Lucho', hoy: ahora),
    );
    String xml(String nombre) =>
        utf8.decode(zip.findFile(nombre)!.readBytes()!);
    expect(
      xml('xl/workbook.xml'),
      allOf(
        contains('name="INSTRUCCIONES"'),
        contains('name="FLUJO_MENSUAL"'),
        contains('name="EXCEDENTE_FAMILIAR"'),
        contains('name="RESUMEN_CREDITO"'),
        contains('fullCalcOnLoad="1"'),
      ),
    );
    final flujo = xml('xl/worksheets/sheet2.xml');
    // Las otras hojas leen las filas 31 y 34: tienen que seguir ahí.
    expect(flujo, contains('<c r="A31" t="inlineStr"'));
    expect(flujo, contains('TOTAL DEUDAS ACTUALES</t></is></c><c r="B31"'));
    expect(
      flujo,
      contains('EXCEDENTE BRUTO DEL NEGOCIO</t></is></c><c r="B34"'),
    );
    // El promedio deja fuera agosto (incompleto, columna F).
    expect(
      flujo,
      contains('<f>IFERROR(AVERAGE(B34,C34,D34,E34,G34),&quot;&quot;)</f>'),
    );
    // El excedente es antes de las cuotas.
    expect(flujo, isNot(contains('B28:B30)</f></c><c r="C34"')));
    // Cada fórmula lleva su resultado, para los visores que no calculan
    // (entrega 14.15.1): el excedente de setiembre, ya sin agosto.
    final excedente =
        (m.centimos.entries
                .where((e) => entradas.contains(e.key))
                .fold(0, (s, e) => s + e.value) -
            m.centimos.entries
                .where((e) => !entradas.contains(e.key))
                .fold(0, (s, e) => s + e.value)) /
        100;
    expect(flujo, contains('<v>$excedente</v></c><c r="I34"'));
    final hogar = xml('xl/worksheets/sheet3.xml');
    expect(hogar, contains('<f>N(FLUJO_MENSUAL!H34)</f><v>$excedente</v>'));
    expect(hogar, contains('<f>N(FLUJO_MENSUAL!H34)</f>'));
    expect(hogar, contains('<f>MAX(0,B18*0.4-B21)</f>'));
    final resumen = xml('xl/worksheets/sheet4.xml');
    expect(resumen, contains('<f>MAX(0,B6*0.4-B7)</f>'));
    expect(
      nombreDelFlujoParaCredito('Bodega Don Lucho', ahora),
      'Moca-Bodega-Don-Lucho-flujo-credito-octubre-2026.xlsx',
    );
  });

  test(
    'Entrega 28.1: la Demo usa todas las categorías y todos los tipos',
    () async {
      final base = BaseLocal(NativeDatabase.memory());
      addTearDown(base.close);
      await cargarDemo(base, DateTime(2026, 10, 13, 9));
      final usadas = {
        for (final m in await base.select(base.movimientos).get())
          ?m.categoriaId,
      };
      final categorias = await base.select(base.categorias).get();
      final sinUsar = [
        for (final c in categorias)
          if (c.activa && !usadas.contains(c.id)) c.nombre,
      ];
      // Las de bodega y las comunes, todas; «Mercadería» y «Bolsas» incluidas.
      expect(sinUsar, isEmpty);
      final tipos = {
        for (final m in await base.select(base.movimientos).get()) m.tipo,
      };
      expect(tipos, TipoMovimiento.values.toSet());
      // Una deuda pagada después y otra que todavía se debe.
      final compras = await (base.select(
        base.movimientos,
      )..where((m) => m.tipo.equalsValue(TipoMovimiento.egreso))).get();
      expect(
        compras.where((m) => m.estadoPago == EstadoPago.pendiente),
        isNotEmpty,
      );
      expect(
        compras.where(
          (m) =>
              m.estadoPago == EstadoPago.pagado &&
              m.fechaPago != null &&
              m.fechaPago!.difference(m.fechaMovimiento).inDays >= 3,
        ),
        isNotEmpty,
      );
      // Ninguna fecha en el futuro.
      expect(
        (await base.select(base.movimientos).get()).where(
          (m) => m.fechaMovimiento.isAfter(DateTime(2026, 10, 13, 9)),
        ),
        isEmpty,
      );
    },
  );

  test(
    'Entrega 38: cada barra del informe suma lo mismo que sus registros',
    () async {
      await RepositorioOperadorLocal(base, ahora: () => ahora).cargarDemo();
      final informe = RepositorioInformeLocal(base, ahora: () => ahora);
      final historial = RepositorioHistorialLocal(base, ahora: () => ahora);
      for (final mes in [DateTime(2026, 10), DateTime(2026, 9)]) {
        final i = await informe.observarMes(mes).first;
        for (final (tipo, filas) in [
          (TipoMovimiento.egreso, i.gastos),
          (TipoMovimiento.ingreso, i.ingresos),
        ]) {
          expect(filas, isNotEmpty);
          for (final g in filas) {
            final registros = await historial
                .observarDeCategoria(
                  ConsultaDeCategoria(
                    mes: i.mes,
                    tipo: tipo,
                    titulo: g.nombre ?? 'Lo demás',
                    nombres: g.nombre == null ? null : {g.nombre!},
                    salvo: {
                      for (final o in filas)
                        if (o.nombre != null) o.nombre!,
                    },
                  ),
                )
                .first;
            expect(
              registros.fold(0, (s, f) => s + f.montoCentimos),
              g.centimos,
              reason: '${g.nombre ?? "Lo demás"} en $mes',
            );
          }
        }
      }
      // Y lo que debes suma lo mismo que su total.
      final i = await informe.observarMes(null).first;
      final deudas = await historial.observarLoQueDebes().first;
      expect(
        deudas.fold(0, (s, f) => s + f.montoCentimos),
        i.loQueDebesCentimos,
      );
    },
  );

  test('Entrega 40: el año suma lo mismo que sus meses, con la Demo', () async {
    await RepositorioOperadorLocal(base, ahora: () => ahora).cargarDemo();
    final informe = RepositorioInformeLocal(base, ahora: () => ahora);
    final historial = RepositorioHistorialLocal(base, ahora: () => ahora);
    final r = await informe.observarAnio(null).first;
    expect(r.anio, 2026);
    expect(r.enCurso, isTrue);
    expect(r.meses, hasLength(12));
    // Antes de Moca, los meses con Moca, el actual hasta hoy y lo que viene.
    final primero = (await informe.observarMes(DateTime(1900)).first).mes;
    for (final m in r.meses) {
      expect(
        m.estado,
        m.mes.isBefore(primero)
            ? EstadoMesDelAnio.antesDeMoca
            : m.mes == DateTime(2026, 10)
            ? EstadoMesDelAnio.enCurso
            : m.mes.isAfter(DateTime(2026, 10))
            ? EstadoMesDelAnio.porVenir
            : EstadoMesDelAnio.completo,
        reason: '${m.mes}',
      );
    }
    // Cada mes es igual a su informe, y el año es la suma de los meses.
    var entro = 0, salio = 0, crecio = 0, retiros = 0, aportes = 0;
    for (final m in r.meses.where((m) => m.cuenta)) {
      final i = await informe.observarMes(m.mes).first;
      expect(i.mes, m.mes);
      expect(m.entroCentimos, i.entroCentimos);
      expect(m.salioCentimos, i.salioCentimos);
      expect(m.crecioCentimos, i.crecioCentimos, reason: '${m.mes}');
      entro += i.entroCentimos;
      salio += i.salioCentimos;
      crecio += i.crecioCentimos;
      retiros += i.retirosCentimos;
      aportes += i.aportesCentimos;
    }
    expect(entro, greaterThan(0));
    expect(r.entroCentimos, entro);
    expect(r.salioCentimos, salio);
    expect(r.crecioCentimos, crecio);
    expect(r.retirosCentimos, retiros);
    expect(r.aportesCentimos, aportes);
    // Las categorías del año suman lo que entró y lo que salió.
    expect(r.ingresos.fold(0, (s, g) => s + g.centimos), entro);
    expect(r.gastos.fold(0, (s, g) => s + g.centimos), salio);
    expect(r.gastos.length, lessThanOrEqualTo(5));
    // Y cada barra, lo mismo que sus registros del año.
    for (final (tipo, filas) in [
      (TipoMovimiento.egreso, r.gastos),
      (TipoMovimiento.ingreso, r.ingresos),
    ]) {
      for (final g in filas) {
        final registros = await historial
            .observarDeCategoria(
              ConsultaDeCategoria(
                mes: r.desde,
                anual: true,
                tipo: tipo,
                titulo: g.nombre ?? 'Lo demás',
                nombres: g.nombre == null ? null : {g.nombre!},
                salvo: {
                  for (final o in filas)
                    if (o.nombre != null) o.nombre!,
                },
              ),
            )
            .first;
        expect(
          registros.fold(0, (s, f) => s + f.montoCentimos),
          g.centimos,
          reason: g.nombre ?? 'Lo demás',
        );
      }
    }
    // Las flechas: no hay año antes de Moca ni después de hoy.
    expect(r.anioPrevio, isNull);
    expect(r.anioSiguiente, isNull);
    expect((await informe.observarAnio(2019).first).anio, 2026);
    expect((await informe.observarAnio(2031).first).anio, 2026);
  });

  test('Entrega 40: el año siguiente, y las flechas entre los dos', () async {
    await RepositorioOperadorLocal(base, ahora: () => ahora).cargarDemo();
    final despues = DateTime(2027, 2, 3, 12);
    final informe = RepositorioInformeLocal(base, ahora: () => despues);
    final r = await informe.observarAnio(null).first;
    expect(r.anio, 2027);
    expect(r.anioPrevio, 2026);
    expect(r.anioSiguiente, isNull);
    expect(r.desde, DateTime(2027));
    expect(r.meses[0].estado, EstadoMesDelAnio.completo);
    expect(r.meses[1].estado, EstadoMesDelAnio.enCurso);
    expect(r.meses[2].estado, EstadoMesDelAnio.porVenir);
    final antes = await informe.observarAnio(2026).first;
    expect(antes.enCurso, isFalse);
    expect(antes.anioPrevio, isNull);
    expect(antes.anioSiguiente, 2027);
    expect(antes.meses.last.estado, EstadoMesDelAnio.completo);
    expect(antes.desde.isAfter(DateTime(2026)), isTrue);
  });
}
