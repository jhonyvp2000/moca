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
import 'package:moca/dominio/arqueo.dart';
import 'package:moca/dominio/informe.dart';
import 'package:moca/dominio/moca.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/primer_dia.dart';
import 'package:moca/pantallas/informe/excel_informe.dart';
import 'package:moca/pantallas/informe/pdf_informe.dart';

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
    expect(operaciones, contains('<c r="A2" s="2"><v>46266</v></c>'));
    expect(
      nombreDelExcel('Bodega Don Lucho', DateTime(2026, 9)),
      'Moca-Bodega-Don-Lucho-operaciones-setiembre-2026.xlsx',
    );
  });
}
