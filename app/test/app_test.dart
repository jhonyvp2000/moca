import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/app.dart';
import 'package:moca/comun/barra_inferior.dart';
import 'package:moca/comun/estructura.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/primer_dia.dart';
import 'package:moca/dominio/voz.dart';
import 'package:moca/inyeccion.dart';
import 'package:moca/pantallas/moca/pantalla_moca.dart';
import 'package:moca/textos/textos.dart';

final _ahora = DateTime(2026, 10, 12, 21, 5);

/// Lo que «dice» el dueño en la próxima grabación.
var _loQueDice = [const AlternativaVoz('hola')];
var _vozDisponible = DisponibilidadVoz.disponible;

class _VozFalsa implements ReconocedorVoz {
  @override
  Future<DisponibilidadVoz> preparar() async => _vozDisponible;

  @override
  Stream<EventoVoz> escuchar() => Stream.fromIterable([
    VozParcial(_loQueDice.first.texto),
    VozFinal(_loQueDice),
  ]);

  @override
  Future<void> detener() async {}
}

/// Abre la app con una base en memoria. Con `listo`, el camino del primer
/// día ya está hecho (venta de S/ 350 en efectivo y saldo de S/ 1,000).
Future<BaseLocal> abrirApp(WidgetTester tester, {bool listo = false}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  _loQueDice = [const AlternativaVoz('hola')];
  _vozDisponible = DisponibilidadVoz.disponible;
  // Tamaño del lienzo de los mockups: 390 × 844.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // En pruebas de pantalla, las consultas que se observan se cierran sin
  // temporizadores pendientes.
  final base = BaseLocal(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  if (listo) {
    await tester.runAsync(() async {
      final repo = RepositorioPrimerDiaLocal(base, ahora: () => _ahora);
      await repo.anotarPrimeraVenta({TipoCuenta.efectivo: 35000});
      await repo.seguirSinCuenta();
      await repo.completarAlta(
        const DatosAlta(
          nombre: 'Bodega Don Lucho',
          tipoNegocio: TipoNegocio.bodega,
          saldos: {TipoCuenta.efectivo: 100000},
          horaCierreMinutos: 21 * 60,
        ),
      );
    });
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        baseLocalProvider.overrideWithValue(base),
        relojProvider.overrideWithValue(() => _ahora),
        reconocedorVozProvider.overrideWith((ref) => _VozFalsa()),
      ],
      child: const MocaApp(),
    ),
  );
  await esperar(tester);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await base.close();
  });
  return base;
}

/// Deja que la base responda y que la interfaz termine de moverse.
Future<void> esperar(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}

Future<void> tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await esperar(tester);
}

/// Desde la Bienvenida, la primera venta escrita en lugar de dicha.
Future<void> abrirVentaEscrita(WidgetTester tester) async {
  await tocar(tester, find.text(Textos.anotarPrimeraVenta));
  await tocar(tester, find.text(Textos.prefieroEscribirlo));
}

void main() {
  group('Camino del primer día', () {
    testWidgets('Un teléfono nuevo abre en la Bienvenida', (tester) async {
      await abrirApp(tester);
      expect(find.text(Textos.anotarPrimeraVenta), findsOneWidget);
      expect(find.byType(BarraInferior), findsNothing);
    });

    testWidgets('Recorrido completo: venta, celular, código, alta, primer '
        'día', (tester) async {
      final base = await abrirApp(tester);

      // S00 → S07 escrita
      await abrirVentaEscrita(tester);
      expect(find.text(Textos.cuantoVendisteHoy), findsOneWidget);
      final guardar = find.widgetWithText(FilledButton, Textos.guardar);
      expect(tester.widget<FilledButton>(guardar).onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(0), '350');
      await tester.enterText(find.byType(TextField).at(1), '120');
      await tester.pump();
      expect(find.text('S/ 470'), findsOneWidget);
      await tocar(tester, guardar);

      // S01
      expect(find.text(Textos.primeraVentaAnotada), findsOneWidget);
      expect(find.text(Textos.hoyEntraron('S/ 470')), findsOneWidget);
      final enviar = find.widgetWithText(FilledButton, Textos.enviarmeCodigo);
      await tester.enterText(find.byType(TextField), '8');
      await tester.pump();
      expect(find.text(Textos.celularInvalido), findsOneWidget);
      await tester.enterText(find.byType(TextField), '987654321');
      await tester.pump();
      expect(find.text(Textos.celularInvalido), findsNothing);
      expect(find.text('987 654 321'), findsOneWidget);
      await tocar(tester, enviar);

      // Código
      expect(find.text(Textos.codigoEnPrueba), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123456');
      await esperar(tester);

      // S02
      expect(find.text(Textos.cuentaleDeTuNegocio), findsOneWidget);
      final listo = find.widgetWithText(FilledButton, Textos.listoEmpezar);
      expect(tester.widget<FilledButton>(listo).onPressed, isNull);
      await tester.enterText(find.byType(TextField).at(0), 'Bodega Don Lucho');
      await tocar(tester, find.text(Textos.bodega));
      await tester.enterText(find.byType(TextField).at(1), '1200');
      await tester.pump();
      expect(find.text('1,200'), findsOneWidget);
      await tocar(tester, listo);

      // S03
      expect(find.text(Textos.tuPrimerDia), findsOneWidget);
      expect(find.text('Bodega Don Lucho'), findsOneWidget);
      expect(find.text('S/ 1,670'), findsOneWidget);
      expect(find.text(Textos.mocaYaAnotaste), findsOneWidget);
      expect(find.text(Textos.pasoVentaCincoDias(1)), findsOneWidget);
      expect(find.byType(BarraInferior), findsOneWidget);

      final usuario = await tester.runAsync(
        () => base.select(base.usuarios).getSingle(),
      );
      expect(usuario!.celular, '987654321');
    });

    testWidgets('«Ahora no» y «lo pongo después» dejan el saldo pendiente, y '
        'el paso 1 lo pide', (tester) async {
      await abrirApp(tester);
      await abrirVentaEscrita(tester);
      await tester.enterText(find.byType(TextField).at(0), '350');
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tocar(tester, find.text(Textos.ahoraNo));

      await tester.enterText(find.byType(TextField).at(0), 'Taller Rojas');
      await tocar(tester, find.text(Textos.servicios));
      await tocar(tester, find.text(Textos.noSeCuantoTengo));

      expect(find.text(Textos.notaSaldoPendiente), findsOneWidget);
      expect(find.text('S/ 350'), findsOneWidget);

      await tocar(tester, find.text(Textos.pasoDecirPlata));
      expect(find.text(Textos.cuantoTeniasAlEmpezar), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), '500');
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.guardarSaldo),
      );
      expect(find.text(Textos.notaSaldoMasVenta), findsOneWidget);
      expect(find.text('S/ 850'), findsOneWidget);
    });

    testWidgets('Al volver a abrir la app, sigue en el paso pendiente', (
      tester,
    ) async {
      final base = await abrirApp(tester);
      await abrirVentaEscrita(tester);
      await tester.enterText(find.byType(TextField).at(0), '350');
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(find.text(Textos.guardaTuAvance), findsOneWidget);

      // Se cierra la app y se vuelve a abrir con la misma base.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            baseLocalProvider.overrideWithValue(base),
            relojProvider.overrideWithValue(() => _ahora),
          ],
          child: const MocaApp(),
        ),
      );
      await esperar(tester);
      expect(find.text(Textos.guardaTuAvance), findsOneWidget);
      final movimientos = await tester.runAsync(
        () => base.select(base.movimientos).get(),
      );
      expect(movimientos, hasLength(1));
    });

    testWidgets('«Ver una demo» y «Ya tengo cuenta» explican qué pasa', (
      tester,
    ) async {
      await abrirApp(tester);
      await tocar(tester, find.text(Textos.verDemo));
      expect(find.text(Textos.demoLlega), findsOneWidget);
      await tocar(tester, find.text(Textos.entendido));

      await tocar(tester, find.text(Textos.yaTengoCuenta));
      expect(find.text(Textos.cuentaEnTelefono), findsOneWidget);
      await tocar(tester, find.text(Textos.empezar));
      expect(find.text(Textos.microfonoExplicacion), findsOneWidget);
    });
  });

  group('Con el primer día hecho', () {
    testWidgets('Abre en el Inicio con la barra inferior completa', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      for (final etiqueta in [
        Textos.pestanaInicio,
        Textos.pestanaHistorial,
        Textos.pestanaInformes,
        Textos.pestanaMoca,
      ]) {
        expect(
          find.descendant(
            of: find.byType(BarraInferior),
            matching: find.text(etiqueta),
          ),
          findsOneWidget,
        );
      }
      expect(find.text('S/ 1,350'), findsOneWidget);
      expect(find.bySemanticsLabel(Textos.registrar), findsOneWidget);
    });

    testWidgets('La barra inferior ocupa solo su alto', (tester) async {
      await abrirApp(tester, listo: true);
      // Mockup: 8 + 60 (botón central) + 16 de relleno, más el borde.
      final alto = tester.getSize(find.byType(BarraInferior)).height;
      expect(alto, inInclusiveRange(84, 90));
    });

    testWidgets('Cada pestaña dice en qué entrega llega', (tester) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaHistorial));
      expect(find.text(Textos.llegaEnEntrega(6)), findsOneWidget);
      await tocar(tester, find.text(Textos.pestanaInformes));
      expect(find.text(Textos.llegaEnEntrega(8)), findsOneWidget);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(find.text(Textos.subtituloMoca), findsOneWidget);
    });

    testWidgets('El botón central abre Registrar; voz, foto y QR dicen en qué '
        'entrega llegan', (tester) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      expect(find.text(Textos.diloOMuestralo), findsOneWidget);
      expect(find.text(Textos.llegaEnLaEntrega(4)), findsNothing);
      expect(find.text(Textos.llegaEnLaEntrega(5)), findsNWidgets(2));
      await tocar(tester, find.text(Textos.escribirlo));
      expect(find.text(Textos.queFue), findsOneWidget);
    });

    Future<void> abrirEscribir(WidgetTester tester) async {
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
    }

    FilledButton botonGuardar(WidgetTester tester) =>
        tester.widget(find.widgetWithText(FilledButton, Textos.guardar));

    testWidgets('«Escribirlo» guarda un gasto, avisa cuánto tienes y se '
        'puede deshacer', (tester) async {
      final base = await abrirApp(tester, listo: true);
      await abrirEscribir(tester);

      await tocar(tester, find.text(Textos.salio));
      await tester.enterText(find.byType(TextField).first, '80');
      await tester.pump();
      // Un gasto necesita categoría.
      expect(botonGuardar(tester).onPressed, isNull);
      await tocar(tester, find.text('Otros'));
      expect(botonGuardar(tester).onPressed, isNotNull);
      await tester.enterText(find.byType(TextField).last, 'bolsas');
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));

      expect(find.text(Textos.guardadoAhoraTienes('S/ 1,270')), findsOneWidget);
      expect(find.text('S/ 1,270'), findsOneWidget);

      // «Tienes hoy» ya no es solo saldo más venta.
      expect(find.text(Textos.notaConMovimientos), findsOneWidget);

      await tocar(tester, find.text(Textos.deshacer));
      expect(find.text(Textos.seDeshizo), findsOneWidget);
      expect(find.text('S/ 1,350'), findsOneWidget);
      final anulados = await tester.runAsync(
        () => (base.select(
          base.movimientos,
        )..where((m) => m.estado.equalsValue(EstadoRegistro.anulado))).get(),
      );
      expect(anulados, hasLength(1));
    });

    testWidgets('Moca pregunta antes de dejar una cuenta en negativo', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirEscribir(tester);
      await tocar(tester, find.text(Textos.salio));
      await tester.enterText(find.byType(TextField).first, '80');
      await tocar(tester, find.text(Textos.yape));
      await tocar(tester, find.text('Otros'));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));

      expect(
        find.text(Textos.quedariaNegativo(Textos.yape, '−S/ 80')),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.revisar));
      expect(find.text(Textos.queFue), findsOneWidget);

      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tocar(tester, find.text(Textos.guardarIgual));
      expect(find.text(Textos.guardadoAhoraTienes('S/ 1,270')), findsOneWidget);
    });

    testWidgets('El retiro para mí no pide categoría', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirEscribir(tester);
      await tocar(tester, find.text(Textos.retiroParaMi));
      expect(find.text(Textos.retiroDetalle), findsOneWidget);
      expect(find.text(Textos.enQue), findsNothing);
      await tester.enterText(find.byType(TextField).first, '100');
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(find.text(Textos.guardadoAhoraTienes('S/ 1,250')), findsOneWidget);
    });

    testWidgets('«Anotar un gasto» del Primer día abre «Salió» elegido', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.anotarUnGasto));
      expect(find.text(Textos.enQue), findsOneWidget);
      expect(find.text('Mercadería'), findsOneWidget);
    });

    Future<void> abrirAjusteOculto(WidgetTester tester) async {
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      final gesto = await tester.startGesture(
        tester.getCenter(find.byKey(PantallaMoca.claveIsotipo)),
      );
      await tester.pump(PantallaMoca.esperaAjusteOculto);
      await gesto.up();
      await esperar(tester);
    }

    testWidgets('Un toque corto en el isotipo no abre el ajuste oculto', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      final gesto = await tester.startGesture(
        tester.getCenter(find.byKey(PantallaMoca.claveIsotipo)),
      );
      await tester.pump(const Duration(seconds: 1));
      await gesto.up();
      await esperar(tester);
      expect(find.text(Textos.tituloOperador), findsNothing);
    });

    testWidgets('«Borrar todo» pide confirmación y vacía el teléfono', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      expect(find.text(Textos.tituloOperador), findsOneWidget);
      expect(find.textContaining('registros guardados'), findsOneWidget);

      await tocar(tester, find.text(Textos.borrarTodo));
      await tocar(tester, find.text(Textos.cancelar));
      // La lista se desplazó: el conteo puede quedar fuera de la vista.
      expect(
        find.textContaining('registros guardados', skipOffstage: false),
        findsOneWidget,
      );

      await tocar(tester, find.text(Textos.borrarTodo));
      await tocar(tester, find.text(Textos.borrarTodoBoton));
      // Sin datos no hay negocio: la app vuelve a la Bienvenida.
      expect(find.text(Textos.seBorroTodo), findsOneWidget);
      expect(find.text(Textos.anotarPrimeraVenta), findsOneWidget);
    });

    testWidgets('«Empezar en Primer día» vuelve a la Bienvenida', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.empezarPrimerDia));
      await tocar(tester, find.text(Textos.empezarPrimerDiaBoton));
      expect(find.text(Textos.anotarPrimeraVenta), findsOneWidget);
    });

    testWidgets('Después de la primera semana se ve el Inicio completo; la '
        'venta de hoy se suma', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.saltarPrimeraSemana));
      expect(find.text(Textos.primeraSemanaSaltada), findsOneWidget);
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));

      expect(find.text(Textos.tuPrimerDia), findsNothing);
      // Toda la plata está en efectivo: el total y Efectivo coinciden.
      expect(find.text('S/\u00A01,350'), findsNWidgets(2));
      expect(find.text(Textos.efectivo), findsOneWidget);
      expect(find.text(Textos.entroSalio('S/ 350', 'S/ 0')), findsOneWidget);
      expect(find.text(Textos.mocaYaAnotasteHoy), findsOneWidget);

      // El ojo oculta los montos.
      await tocar(tester, find.byTooltip(Textos.ocultarMontos));
      expect(find.text('S/ 1,350'), findsNothing);
      expect(find.text(Textos.montoOculto), findsWidgets);
      await tocar(tester, find.byTooltip(Textos.mostrarMontos));

      await tocar(tester, find.text(Textos.anotarVentaDeHoy));
      await tocar(tester, find.text(Textos.prefieroEscribirlo));
      expect(find.text(Textos.hoyYaAnotaste('S/ 350')), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), '120');
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(find.text(Textos.guardadoAhoraTienes('S/ 1,470')), findsOneWidget);
      expect(find.text('S/ 1,470'), findsOneWidget);
    });

    testWidgets('Con la letra del sistema al 150 % nada se desborda', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      expect(tester.takeException(), isNull);
      for (final pestana in [
        Textos.pestanaHistorial,
        Textos.pestanaInformes,
        Textos.pestanaMoca,
      ]) {
        await tocar(tester, find.text(pestana).last);
        expect(tester.takeException(), isNull, reason: pestana);
      }
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      expect(tester.takeException(), isNull, reason: 'S06');
      await tocar(tester, find.text(Textos.escribirlo));
      await tocar(tester, find.text(Textos.salio));
      expect(tester.takeException(), isNull, reason: 'Escribirlo');
      await tocar(tester, find.byType(BotonVolver));

      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.saltarPrimeraSemana));
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));
      expect(find.text(Textos.tienesHoy), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'S04');
    });
  });

  group('Voz', () {
    Future<void> decir(WidgetTester tester, List<AlternativaVoz> frase) async {
      _loQueDice = frase;
      final explicacion = find.text(Textos.empezarAEscuchar);
      if (explicacion.evaluate().isNotEmpty) await tocar(tester, explicacion);
    }

    Future<void> abrirVozLibre(WidgetTester tester) async {
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.decirloConVoz));
    }

    testWidgets('La primera venta dicha por voz va por cuenta', (tester) async {
      final base = await abrirApp(tester);
      await tocar(tester, find.text(Textos.anotarPrimeraVenta));
      expect(find.text(Textos.microfonoExplicacion), findsOneWidget);
      await decir(tester, [
        const AlternativaVoz('Hoy vendí 350 en efectivo y 120 por Yape'),
      ]);

      expect(find.text(Textos.mocaEntendio), findsOneWidget);
      expect(find.text('S/\u00A0350'), findsOneWidget);
      expect(find.text('S/\u00A0120'), findsOneWidget);
      expect(find.text('S/\u00A0470'), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));

      expect(find.text(Textos.hoyEntraron('S/\u00A0470')), findsOneWidget);
      final movimientos = await tester.runAsync(
        () => base.select(base.movimientos).get(),
      );
      expect(movimientos!.map((m) => m.fuente).toSet(), {Fuente.voz});
    });

    testWidgets('Con duda del monto, Moca pregunta (S18) y no adivina', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [
        const AlternativaVoz('Pagué trescientos quince de mercadería', 0.4),
        const AlternativaVoz('Pagué trescientos cincuenta de mercadería'),
      ]);

      expect(find.text(Textos.noEscucheElMonto), findsOneWidget);
      expect(find.text(Textos.mocaNuncaAdivina), findsOneWidget);
      expect(find.text(Textos.otroMonto), findsOneWidget);
      await tocar(tester, find.text('S/\u00A0350'));

      expect(
        find.text(Textos.deDondeSalioMonto('S/\u00A0350')),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.efectivo));

      expect(find.text(Textos.mocaEntendio), findsOneWidget);
      expect(find.text('Mercadería'), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.guardadoAhoraTienes('S/\u00A01,000')),
        findsOneWidget,
      );
    });

    testWidgets('«Otro monto» deja escribirlo', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [const AlternativaVoz('Pagué trescientos… de luz')]);
      await tocar(tester, find.text(Textos.otroMonto));
      await tester.enterText(find.byType(TextField), '320');
      await tocar(tester, find.text(Textos.confirmarMonto));
      expect(
        find.text(Textos.deDondeSalioMonto('S/\u00A0320')),
        findsOneWidget,
      );
    });

    testWidgets('Si falta la cuenta la pregunta, y «Corregir un dato» abre '
        'la venta escrita con los montos', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [const AlternativaVoz('vendí 200')]);

      expect(find.text(Textos.dondeEntro('S/\u00A0200')), findsOneWidget);
      await tocar(tester, find.text(Textos.yape));
      expect(find.text('Venta del día'), findsOneWidget);

      await tocar(tester, find.text(Textos.corregirUnDato));
      expect(find.text(Textos.cuantoVendisteHoy), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('«Saqué 100 para mí» se guarda como retiro', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [
        const AlternativaVoz('Saqué 100 para mí del efectivo'),
      ]);
      expect(find.text(Textos.retiroParaMi), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.guardadoAhoraTienes('S/\u00A01,250')),
        findsOneWidget,
      );
    });

    testWidgets('Si no entiende, lo dice y deja intentar otra vez', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [const AlternativaVoz('hola, ¿cómo estás?')]);
      expect(find.text(Textos.noTeEntendi), findsOneWidget);

      _loQueDice = [const AlternativaVoz('pagué 80 de luz en efectivo')];
      await tocar(tester, find.text(Textos.decirloOtraVez));
      expect(find.text(Textos.mocaEntendio), findsOneWidget);
    });

    testWidgets('Sin permiso del micrófono, ofrece escribirlo', (tester) async {
      await abrirApp(tester, listo: true);
      _vozDisponible = DisponibilidadVoz.sinPermiso;
      await abrirVozLibre(tester);
      await decir(tester, [const AlternativaVoz('vendí 200')]);
      expect(find.text(Textos.sinPermisoMicrofono), findsOneWidget);
      await tocar(tester, find.text(Textos.prefieroEscribirlo));
      expect(find.text(Textos.queFue), findsOneWidget);
    });

    testWidgets('La voz no se desborda con letra grande', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      expect(tester.takeException(), isNull, reason: 'Explicación');
      await decir(tester, [
        const AlternativaVoz('Pagué trescientos quince de mercadería', 0.4),
        const AlternativaVoz('Pagué trescientos cincuenta de mercadería'),
      ]);
      expect(tester.takeException(), isNull, reason: 'S18');
      await tocar(tester, find.text('S/\u00A0350'));
      await tocar(tester, find.text(Textos.efectivo));
      expect(tester.takeException(), isNull, reason: 'Moca entendió');
    });
  });

  testWidgets('Las pantallas del primer día no se desbordan con letra grande', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await abrirApp(tester);
    expect(tester.takeException(), isNull, reason: 'S00');
    await tocar(tester, find.text(Textos.anotarPrimeraVenta));
    expect(tester.takeException(), isNull, reason: 'Voz');
    await tocar(tester, find.text(Textos.prefieroEscribirlo));
    expect(tester.takeException(), isNull, reason: 'S07');
    await tester.enterText(find.byType(TextField).at(0), '350');
    await tester.pump();
    await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
    expect(tester.takeException(), isNull, reason: 'S01');
    await tocar(tester, find.text(Textos.ahoraNo));
    expect(tester.takeException(), isNull, reason: 'S02');
  });
}
