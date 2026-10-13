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
import 'package:moca/dominio/moca.dart';
import 'package:moca/dominio/primer_dia.dart';

void main() {
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
}
