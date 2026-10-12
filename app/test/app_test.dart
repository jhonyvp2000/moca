import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/app.dart';
import 'package:moca/comun/barra_inferior.dart';
import 'package:moca/dominio/repositorio_operador.dart';
import 'package:moca/inyeccion.dart';
import 'package:moca/pantallas/moca/pantalla_moca.dart';
import 'package:moca/textos/textos.dart';

class _RepositorioFalso implements RepositorioOperador {
  _RepositorioFalso(this.registros);

  int registros;

  @override
  Future<int> contarRegistros() async => registros;

  @override
  Future<void> borrarTodo() async => registros = 0;
}

void main() {
  late _RepositorioFalso repositorio;

  Future<void> abrirApp(WidgetTester tester) async {
    // Tamaño del lienzo de los mockups: 390 × 844.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repositorio = _RepositorioFalso(7);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositorioOperadorProvider.overrideWithValue(repositorio)],
        child: const MocaApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Abre en Inicio con la barra inferior completa', (tester) async {
    await abrirApp(tester);

    for (final etiqueta in [
      Textos.pestanaHistorial,
      Textos.pestanaInformes,
      Textos.pestanaMoca,
    ]) {
      expect(find.text(etiqueta), findsOneWidget);
    }
    // «Inicio» aparece en la barra y como título de la pantalla.
    expect(find.text(Textos.pestanaInicio), findsNWidgets(2));
    expect(find.text(Textos.llegaEnEntrega(3)), findsOneWidget);
    expect(find.bySemanticsLabel(Textos.registrar), findsOneWidget);
  });

  testWidgets('La barra inferior ocupa solo su alto y no tapa la pantalla', (
    tester,
  ) async {
    await abrirApp(tester);
    // Mockup: 8 + 60 (botón central) + 16 de relleno, más el borde.
    final alto = tester.getSize(find.byType(BarraInferior)).height;
    expect(alto, inInclusiveRange(84, 90));
  });

  testWidgets('Cada pestaña dice en qué entrega llega', (tester) async {
    await abrirApp(tester);

    await tester.tap(find.text(Textos.pestanaHistorial));
    await tester.pumpAndSettle();
    expect(find.text(Textos.llegaEnEntrega(6)), findsOneWidget);

    await tester.tap(find.text(Textos.pestanaInformes));
    await tester.pumpAndSettle();
    expect(find.text(Textos.tituloInforme), findsOneWidget);
    expect(find.text(Textos.llegaEnEntrega(8)), findsOneWidget);

    await tester.tap(find.text(Textos.pestanaMoca).last);
    await tester.pumpAndSettle();
    expect(find.text(Textos.subtituloMoca), findsOneWidget);
  });

  testWidgets('El botón central abre la hoja de Registrar', (tester) async {
    await abrirApp(tester);

    await tester.tap(find.bySemanticsLabel(Textos.registrar));
    await tester.pumpAndSettle();
    expect(find.text(Textos.registrarLlegaEnEntrega(3)), findsOneWidget);

    await tester.tap(find.text(Textos.entendido));
    await tester.pumpAndSettle();
    expect(find.text(Textos.registrarLlegaEnEntrega(3)), findsNothing);
  });

  testWidgets('Un toque corto en el isotipo no abre el ajuste oculto', (
    tester,
  ) async {
    await abrirApp(tester);
    await tester.tap(find.text(Textos.pestanaMoca).last);
    await tester.pumpAndSettle();

    final gesto = await tester.startGesture(
      tester.getCenter(find.byKey(PantallaMoca.claveIsotipo)),
    );
    await tester.pump(const Duration(seconds: 1));
    await gesto.up();
    await tester.pumpAndSettle();
    expect(find.text(Textos.tituloOperador), findsNothing);
  });

  testWidgets('3 segundos sobre el isotipo abren el ajuste oculto, y '
      '«Borrar todo» pide confirmación', (tester) async {
    await abrirApp(tester);
    await tester.tap(find.text(Textos.pestanaMoca).last);
    await tester.pumpAndSettle();

    final gesto = await tester.startGesture(
      tester.getCenter(find.byKey(PantallaMoca.claveIsotipo)),
    );
    await tester.pump(PantallaMoca.esperaAjusteOculto);
    await gesto.up();
    await tester.pumpAndSettle();
    expect(find.text(Textos.tituloOperador), findsOneWidget);
    expect(find.text(Textos.registrosGuardados(7)), findsOneWidget);

    // Cancelar no borra nada.
    await tester.tap(find.text(Textos.borrarTodo));
    await tester.pumpAndSettle();
    expect(find.text(Textos.confirmarBorrarTitulo), findsOneWidget);
    await tester.tap(find.text(Textos.cancelar));
    await tester.pumpAndSettle();
    expect(repositorio.registros, 7);

    // Confirmar sí.
    await tester.tap(find.text(Textos.borrarTodo));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Textos.borrarTodoBoton));
    await tester.pumpAndSettle();
    expect(repositorio.registros, 0);
    expect(find.text(Textos.seBorroTodo), findsOneWidget);
    expect(find.text(Textos.registrosGuardados(0)), findsOneWidget);
  });

  testWidgets('Con la letra del sistema al 150 % nada se desborda', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await abrirApp(tester);
    for (final pestana in [
      Textos.pestanaHistorial,
      Textos.pestanaInformes,
      Textos.pestanaMoca,
    ]) {
      await tester.tap(find.text(pestana).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: pestana);
    }
  });
}
