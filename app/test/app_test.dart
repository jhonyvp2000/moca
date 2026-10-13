import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/app.dart';
import 'package:moca/comun/barra_inferior.dart';
import 'package:moca/comun/estructura.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_comprobantes_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/datos/simulados/lector_foto_simulado.dart';
import 'package:moca/dominio/comprobantes.dart';
import 'package:moca/dominio/conexion.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/movimientos.dart';
import 'package:moca/dominio/primer_dia.dart';
import 'package:moca/dominio/servicios.dart';
import 'package:moca/dominio/voz.dart';
import 'package:moca/inyeccion.dart';
import 'package:moca/pantallas/informe/pdf_informe.dart';
import 'package:moca/pantallas/moca/pantalla_moca.dart';
import 'package:moca/rutas.dart';
import 'package:moca/textos/textos.dart';
import 'package:go_router/go_router.dart';

final _ahora = DateTime(2026, 10, 12, 21, 5);

/// Lo que «dice» el dueño en la próxima grabación.
var _loQueDice = [const AlternativaVoz('hola')];
var _vozDisponible = DisponibilidadVoz.disponible;

/// Si el teléfono «tiene señal».
var _conSenal = true;

class _SenalFalsa implements Conexion {
  @override
  Future<bool> hayConexion() async => _conSenal;

  @override
  Stream<bool> observar() => Stream.value(_conSenal);
}

/// Lo que leyó la voz sintética y si el teléfono «tiene» voz en español.
final _loQueDijo = <String>[];
var _hayVoz = true;

class _LocutorFalso implements Locutor {
  @override
  Future<bool> disponible() async => _hayVoz;

  @override
  Future<void> decir(String texto) async => _loQueDijo.add(texto);

  @override
  Future<void> detener() async {}
}

class _CompartidorFalso implements Compartidor {
  @override
  Future<void> compartirArchivo(String ruta, {required String asunto}) async {}
}

/// Lo que devuelve la cámara en la próxima foto.
ResultadoCamara _camara = const FotoTomada('/no/existe.jpg');

class _CamaraFalsa implements Camara {
  @override
  Future<ResultadoCamara> tomarFoto() async => _camara;
}

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
  _camara = const FotoTomada('/no/existe.jpg');
  _conSenal = true;
  _loQueDijo.clear();
  _hayVoz = true;
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
        conexionTelefonoProvider.overrideWithValue(_SenalFalsa()),
        locutorProvider.overrideWithValue(_LocutorFalso()),
        compartidorProvider.overrideWithValue(_CompartidorFalso()),
        reconocedorVozProvider.overrideWith((ref) => _VozFalsa()),
        camaraProvider.overrideWithValue(_CamaraFalsa()),
        lectorFotoProvider.overrideWith(
          (ref) => LectorFotoSimulado(
            ahora: () => _ahora,
            espera: Duration.zero,
            forzarIlegible: () =>
                ref.read(forzarIlegibleProvider.notifier).usar(),
          ),
        ),
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

/// Mantiene presionado el isotipo de la pestaña Moca hasta abrir el ajuste
/// oculto.
Future<void> abrirAjusteOculto(WidgetTester tester) async {
  await tocar(tester, find.text(Textos.pestanaMoca).last);
  final gesto = await tester.startGesture(
    tester.getCenter(find.byKey(PantallaMoca.claveIsotipo)),
  );
  await tester.pump(PantallaMoca.esperaAjusteOculto);
  await gesto.up();
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
            conexionTelefonoProvider.overrideWithValue(_SenalFalsa()),
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
      expect(find.text(Textos.filtroTodo), findsOneWidget);
      await tocar(tester, find.text(Textos.pestanaInformes));
      expect(find.text(Textos.compartirPdf), findsOneWidget);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(find.text(Textos.subtituloMoca), findsOneWidget);
    });

    testWidgets('El botón central abre Registrar; voz, foto y QR dicen en qué '
        'entrega llegan', (tester) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      expect(find.text(Textos.diloOMuestralo), findsOneWidget);
      expect(find.text(Textos.tomarFotoDetalle), findsOneWidget);
      expect(find.text(Textos.leerQrDetalle), findsOneWidget);
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

  group('Foto y QR', () {
    Future<void> tomarFoto(WidgetTester tester) async {
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.tomarFoto));
    }

    FilledButton guardar(WidgetTester tester) =>
        tester.widget(find.widgetWithText(FilledButton, Textos.guardar));

    testWidgets('La foto se lee y se confirma en S08; nada se guarda sin '
        'elegir cuenta y si ya se pagó', (tester) async {
      await abrirApp(tester, listo: true);
      await tomarFoto(tester);

      expect(find.text(Textos.revisaLaLectura), findsOneWidget);
      expect(find.text('Distribuidora San Martín'), findsOneWidget);
      expect(find.text('S/\u00A0980'), findsOneWidget);
      expect(find.text(Textos.productos(12)), findsOneWidget);
      expect(find.text('Mercadería'), findsOneWidget);
      expect(guardar(tester).onPressed, isNull);

      await tocar(tester, find.text(Textos.efectivo));
      expect(guardar(tester).onPressed, isNull);
      await tocar(tester, find.text(Textos.siPagado));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.guardadoAhoraTienes('S/\u00A0370')),
        findsOneWidget,
      );
    });

    testWidgets('«Todavía lo debo» no baja el saldo ni pregunta por '
        'negativo', (tester) async {
      final base = await abrirApp(tester, listo: true);
      await tomarFoto(tester);
      await tocar(tester, find.text(Textos.yape));
      await tocar(tester, find.text(Textos.todaviaLoDebo));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.guardadoAhoraTienes('S/\u00A01,350')),
        findsOneWidget,
      );
      final deudas = await tester.runAsync(
        () => (base.select(
          base.movimientos,
        )..where((m) => m.estadoPago.equalsValue(EstadoPago.pendiente))).get(),
      );
      expect(deudas, hasLength(1));
    });

    testWidgets('Pagado desde una cuenta sin plata, Moca pregunta', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await tomarFoto(tester);
      await tocar(tester, find.text(Textos.yape));
      await tocar(tester, find.text(Textos.siPagado));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(find.text(Textos.quedariaNegativoTitulo), findsOneWidget);
    });

    testWidgets('Foto ilegible (S17): lo que se leyó, consejos y completar '
        'a mano', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.forzarFotoIlegible));
      expect(find.text(Textos.fotoIlegibleForzada), findsOneWidget);
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));

      await tomarFoto(tester);
      expect(find.text(Textos.fotoBorrosa), findsOneWidget);
      expect(find.text('S/\u00A0980'), findsOneWidget);
      expect(find.text(Textos.noSeLee), findsNWidgets(2));
      expect(find.text(Textos.consejoSombra), findsOneWidget);

      await tocar(tester, find.text(Textos.completarAMano));
      expect(find.text(Textos.completadoAMano), findsOneWidget);
      expect(find.text(Textos.eligeTipoDeGasto), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'Bodega Mayorista');
      await tocar(tester, find.text(Textos.eligeTipoDeGasto));
      await tocar(tester, find.text('Otros'));
      await tocar(tester, find.text(Textos.efectivo));
      await tocar(tester, find.text(Textos.siPagado));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.guardadoAhoraTienes('S/\u00A0370')),
        findsOneWidget,
      );

      // La siguiente foto ya se lee bien.
      await tomarFoto(tester);
      expect(find.text(Textos.fotoBorrosa), findsNothing);
    });

    testWidgets('Si se cancela la cámara, vuelve a Registrar', (tester) async {
      await abrirApp(tester, listo: true);
      _camara = const FotoCancelada();
      await tomarFoto(tester);
      expect(find.text(Textos.diloOMuestralo), findsOneWidget);
    });

    testWidgets('Sin permiso de cámara, ofrece escribirlo', (tester) async {
      await abrirApp(tester, listo: true);
      _camara = const CamaraSinPermiso();
      await tomarFoto(tester);
      expect(find.text(Textos.sinPermisoCamara), findsOneWidget);
      await tocar(tester, find.text(Textos.escribirlo));
      expect(find.text(Textos.queFue), findsOneWidget);
    });

    testWidgets('Un QR leído pide el tipo de gasto y muestra el RUC', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      final contexto = tester.element(find.byType(BarraInferior));
      GoRouter.of(contexto).push(
        Rutas.confirmarLectura,
        extra: LecturaComprobante(
          origen: OrigenLectura.qr,
          emisorIdentificacion: '20100070970',
          tipo: 'Factura',
          serie: 'F001',
          numero: '12345',
          totalCentimos: 14230,
          fechaEmision: DateTime(2026, 10, 8),
        ),
      );
      await esperar(tester);

      expect(find.text('S/\u00A0142.30'), findsOneWidget);
      expect(find.text('Factura · jueves 8 de octubre'), findsOneWidget);
      expect(find.text(Textos.rucDe('20100070970')), findsOneWidget);
      expect(find.text(Textos.leidoDelQr), findsOneWidget);
      await tocar(tester, find.text(Textos.efectivo));
      await tocar(tester, find.text(Textos.siPagado));
      expect(guardar(tester).onPressed, isNull);
      await tocar(tester, find.text(Textos.eligeTipoDeGasto));
      await tocar(
        tester,
        find.text('Servicios (luz, agua, internet, teléfono)'),
      );
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.guardadoAhoraTienes('S/\u00A01,208')),
        findsOneWidget,
      );
    });

    testWidgets('S08 y S17 no se desbordan con letra grande', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      await tomarFoto(tester);
      expect(tester.takeException(), isNull, reason: 'S08');
      await tocar(tester, find.byType(BotonVolver));
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.forzarFotoIlegible));
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));
      await tomarFoto(tester);
      expect(find.text(Textos.fotoBorrosa), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'S17');
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

  group('Historial', () {
    Future<void> abrirHistorial(WidgetTester tester) =>
        tocar(tester, find.text(Textos.pestanaHistorial));

    Future<void> anotarGasto(WidgetTester tester, String monto) async {
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      await tocar(tester, find.text(Textos.salio));
      await tester.enterText(find.byType(TextField).first, monto);
      await tester.pump();
      await tocar(tester, find.text('Otros'));
      await tester.enterText(find.byType(TextField).last, 'Bolsas');
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
    }

    testWidgets('Muestra lo anotado por día, con filtros', (tester) async {
      await abrirApp(tester, listo: true);
      await anotarGasto(tester, '80');
      await abrirHistorial(tester);

      expect(find.text('Hoy · lunes 12'), findsOneWidget);
      expect(find.text('Venta del día'), findsOneWidget);
      expect(find.text('+ S/ 350'), findsOneWidget);
      expect(find.text('Bolsas'), findsOneWidget);
      expect(find.text('Otros · Efectivo'), findsOneWidget);
      expect(find.text('− S/ 80'), findsOneWidget);

      await tocar(tester, find.text(Textos.entro));
      expect(find.text('Bolsas'), findsNothing);
      expect(find.text('Venta del día'), findsOneWidget);
      await tocar(tester, find.text(Textos.salio));
      expect(find.text('Venta del día'), findsNothing);
      await tocar(tester, find.text(Textos.filtroPorSubir(0)));
      expect(find.text(Textos.nadaPorSubir), findsOneWidget);
    });

    testWidgets('Sin señal se avisa y lo guardado queda por subir', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      _conSenal = false;
      // La señal se lee al abrir: se simula desde el ajuste oculto.
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.simularSinSenal));
      expect(find.text(Textos.sinSenalSimulada), findsOneWidget);
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));

      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      expect(find.text(Textos.sinSenal), findsOneWidget);
      await tocar(tester, find.text(Textos.escribirlo));
      expect(find.text(Textos.sinSenal), findsOneWidget);
      await tocar(tester, find.text(Textos.salio));
      await tester.enterText(find.byType(TextField).first, '80');
      await tocar(tester, find.text('Otros'));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));

      await abrirHistorial(tester);
      expect(find.text(Textos.filtroPorSubir(1)), findsOneWidget);
      expect(find.text('Efectivo · por subir'), findsOneWidget);
      await tocar(tester, find.text('Otros'));
      expect(find.text(Textos.guardadoPorSubir), findsOneWidget);
    });

    testWidgets('Corregir guarda los cambios y los muestra en «Cambios»', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirHistorial(tester);
      await tocar(tester, find.text('Venta del día'));

      expect(find.text(Textos.tituloDetalle), findsOneWidget);
      expect(find.text(Textos.comoSeAnoto(Fuente.texto)), findsOneWidget);
      expect(find.text(Textos.anotado(Fuente.texto)), findsOneWidget);

      await tocar(tester, find.text(Textos.corregir));
      expect(find.text(Textos.corregirRegistro), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '400');
      await tocar(tester, find.text(Textos.yape));
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.guardarCambios),
      );

      expect(find.text(Textos.cambiosGuardados('S/ 1,400')), findsOneWidget);
      expect(find.text('+ S/ 400'), findsOneWidget);
      expect(
        find.text(Textos.cambiasteMonto('S/ 350', 'S/ 400')),
        findsOneWidget,
      );
      expect(
        find.text(Textos.cambiasteCuenta(Textos.efectivo, Textos.yape)),
        findsOneWidget,
      );

      await tocar(tester, find.byType(BotonVolver));
      expect(find.text('+ S/ 400'), findsOneWidget);
      expect(find.text('+ S/ 350'), findsNothing);
    });

    testWidgets('Deshacer desde el detalle pregunta y quita el registro', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await anotarGasto(tester, '80');
      await abrirHistorial(tester);
      await tocar(tester, find.text('Bolsas'));
      await tocar(tester, find.text(Textos.deshacerRegistro));
      expect(
        find.text(Textos.deshacerConSaldo(Textos.efectivo, 'S/ 1,350')),
        findsOneWidget,
      );
      await tocar(tester, find.widgetWithText(TextButton, Textos.deshacer));
      expect(find.text(Textos.registroDeshecho), findsOneWidget);
      expect(find.text('Bolsas'), findsNothing);
      expect(find.text(Textos.filtroTodo), findsOneWidget);
    });

    testWidgets('«Ya lo pagué» pide cuenta y día y quita «Lo debes»', (
      tester,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        final egresos = await base.select(base.categorias).get();
        await RepositorioComprobantesLocal(
          base,
          ahora: () => _ahora,
        ).guardarCompra(
          CompraConfirmada(
            lectura: const LecturaComprobante(
              origen: OrigenLectura.qr,
              emisorIdentificacion: '20100070970',
              tipo: 'Factura',
              serie: 'F001',
              numero: '12345',
              totalCentimos: 98050,
            ),
            totalCentimos: 98050,
            cuenta: TipoCuenta.efectivo,
            pagado: false,
            categoriaId: egresos.firstWhere((c) => c.nombre == 'Mercadería').id,
            emisorNombre: 'Distribuidora San Martín',
            fecha: DateTime(2026, 10, 8),
          ),
        );
      });
      await abrirHistorial(tester);
      expect(find.text('Distribuidora San Martín'), findsOneWidget);
      expect(find.textContaining(Textos.loDebes), findsOneWidget);

      await tocar(tester, find.text('Distribuidora San Martín'));
      expect(find.text(Textos.todaviaLoDebes), findsOneWidget);
      expect(find.text('Total S/ 980.50'), findsOneWidget);
      expect(find.text('Factura F001-12345'), findsOneWidget);

      await tocar(tester, find.widgetWithText(FilledButton, Textos.yaLoPague));
      expect(find.text(Textos.conQuePagaste), findsOneWidget);
      // El primer día de pago es hoy: no se ofrece «Ayer».
      expect(find.text(Textos.ayer), findsNothing);
      await tocar(tester, find.text(Textos.yape).last);
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.yaLoPague).last,
      );
      // Yape no tiene plata: Moca pregunta.
      await tocar(tester, find.text(Textos.guardarIgual));

      expect(
        find.text(Textos.pagadoAhoraTienes('−S/ 981', Textos.yape)),
        findsOneWidget,
      );
      expect(find.text(Textos.todaviaLoDebes), findsNothing);
      expect(
        find.text(Textos.pagaste(Textos.yape, '12 de octubre')),
        findsOneWidget,
      );
      expect(find.text(Textos.yaLoPague), findsNothing);
    });

    testWidgets('El Historial y el detalle no se desbordan con letra grande', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      await anotarGasto(tester, '80');
      await abrirHistorial(tester);
      expect(tester.takeException(), isNull, reason: 'S10');
      await tocar(tester, find.text('Bolsas'));
      expect(tester.takeException(), isNull, reason: 'Detalle');
      await tocar(tester, find.text(Textos.corregir));
      expect(tester.takeException(), isNull, reason: 'Corregir');
    });
  });

  group('Arqueo', () {
    Future<void> abrirArqueoDesdeElPrimerDia(WidgetTester tester) async {
      // Con letra grande, el paso queda más abajo de la pantalla.
      await tester.scrollUntilVisible(
        find.text(Textos.pasoPrimerArqueo),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text(Textos.pasoPrimerArqueo));
      expect(find.text(Textos.arqueoDeLaSemana), findsOneWidget);
    }

    FilledButton guardarArqueo(WidgetTester tester) =>
        tester.widget(find.widgetWithText(FilledButton, Textos.guardarArqueo));

    testWidgets('Propone lo calculado; una diferencia se explica y se guarda', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirArqueoDesdeElPrimerDia(tester);

      expect(find.text(Textos.arqueoDetalle), findsOneWidget);
      expect(find.text(Textos.cuadra), findsNWidgets(3));
      expect(guardarArqueo(tester).onPressed, isNotNull);

      await tester.enterText(find.byType(TextField).first, '1270');
      await esperar(tester);
      expect(find.text(Textos.faltan('S/ 80')), findsOneWidget);
      expect(
        find.text(Textos.preguntaFaltan('S/ 80', Textos.efectivo)),
        findsOneWidget,
      );
      expect(guardarArqueo(tester).onPressed, isNull);

      await tocar(
        tester,
        find.text(Textos.motivoArqueo(MotivoArqueo.retiroParaMi)),
      );
      expect(
        find.text(Textos.notaMotivo(MotivoArqueo.retiroParaMi, faltan: true)),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.guardarArqueo));

      expect(find.text(Textos.arqueoGuardado('S/ 1,270')), findsOneWidget);
      // Con el primer arqueo, el Inicio pasa a ser el completo (S04).
      expect(find.text(Textos.tienesHoy), findsOneWidget);
      expect(find.text(Textos.hacerArqueo), findsOneWidget);
      expect(find.textContaining(Textos.mocaArqueoHecho), findsOneWidget);
      await tocar(tester, find.text(Textos.pestanaHistorial));
      expect(find.text(Textos.retiroParaMi), findsOneWidget);
    });

    testWidgets('«Un gasto que olvidé» pide la categoría', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirArqueoDesdeElPrimerDia(tester);
      await tester.enterText(find.byType(TextField).first, '1270');
      await esperar(tester);
      await tocar(
        tester,
        find.text(Textos.motivoArqueo(MotivoArqueo.gastoOlvidado)),
      );
      expect(guardarArqueo(tester).onPressed, isNull);
      await tocar(tester, find.text('Otros'));
      expect(guardarArqueo(tester).onPressed, isNotNull);
    });

    testWidgets('Si sobra plata, ofrece «Una venta que no anoté»', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirArqueoDesdeElPrimerDia(tester);
      await tester.enterText(find.byType(TextField).at(1), '50');
      await esperar(tester);
      expect(find.text(Textos.sobran('S/ 50')), findsOneWidget);
      expect(
        find.text(Textos.motivoArqueo(MotivoArqueo.ventaNoAnotada)),
        findsOneWidget,
      );
      expect(
        find.text(Textos.motivoArqueo(MotivoArqueo.retiroParaMi)),
        findsNothing,
      );
    });

    testWidgets('«No lo sé» deja un ajuste en el Historial que no se corrige', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirArqueoDesdeElPrimerDia(tester);
      await tester.enterText(find.byType(TextField).first, '1270');
      await esperar(tester);
      await tocar(tester, find.text(Textos.motivoArqueo(MotivoArqueo.noLoSe)));
      await tocar(tester, find.text(Textos.guardarArqueo));

      await tocar(tester, find.text(Textos.pestanaHistorial));
      expect(find.text(Textos.ajusteDelArqueo), findsOneWidget);
      expect(
        find.text('${Textos.ajusteNoCuenta} · ${Textos.efectivo}'),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.salio));
      expect(find.text(Textos.ajusteDelArqueo), findsNothing);
      await tocar(tester, find.text(Textos.filtroTodo));

      await tocar(tester, find.text(Textos.ajusteDelArqueo));
      expect(find.text(Textos.ajusteExplicacion), findsOneWidget);
      expect(
        find.text(Textos.motivoArqueo(MotivoArqueo.noLoSe)),
        findsOneWidget,
      );
      expect(find.text(Textos.corregir), findsNothing);
      expect(find.text(Textos.deshacerRegistro), findsNothing);
    });

    testWidgets('«Pedir el arqueo ahora» muestra la tarjeta en el Inicio', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.saltarPrimeraSemana));
      await tocar(tester, find.text(Textos.pedirArqueo));
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));

      expect(find.text(Textos.mocaTocaArqueo), findsOneWidget);
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.hacerArqueo),
      );
      expect(find.text(Textos.arqueoDeLaSemana), findsOneWidget);
    });

    testWidgets('El arqueo no se desborda con letra grande', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      await abrirArqueoDesdeElPrimerDia(tester);
      await tester.enterText(find.byType(TextField).first, '1270');
      await esperar(tester);
      await tocar(
        tester,
        find.text(Textos.motivoArqueo(MotivoArqueo.gastoOlvidado)),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Informe y Moca', () {
    testWidgets('El informe del primer mes', (tester) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaInformes));
      expect(find.text('Octubre'), findsOneWidget);
      expect(find.text(Textos.desdeElDiaHastaHoy(12)), findsOneWidget);
      expect(find.text(Textos.ganaste), findsOneWidget);
      expect(find.text(Textos.primerMesConMoca), findsOneWidget);
      expect(find.text(Textos.loQueGanasteYRetiraste), findsOneWidget);
      final anterior = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(Textos.mesAnterior),
          matching: find.byType(IconButton),
        ),
      );
      expect(anterior.onPressed, isNull);
      expect(find.text(Textos.compartirPdf), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(Textos.sinPapel(100)),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(Textos.sinPapel(100)), findsOneWidget);
    });

    testWidgets('El PDF del informe se arma en el teléfono', (tester) async {
      final base = await abrirApp(tester, listo: true);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final informe = await tester.runAsync(
        () =>
            container.read(repositorioInformeProvider).observarMes(null).first,
      );
      final bytes = await tester.runAsync(
        () => armarPdfDelInforme(
          informe!,
          nombreNegocio: 'Bodega Don Lucho',
          hoy: _ahora,
        ),
      );
      expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
      expect(
        nombreDelPdf('Bodega Don Lucho', DateTime(2026, 10)),
        'Moca-Bodega-Don-Lucho-octubre-2026.pdf',
      );
      expect(base, isNotNull);
    });

    testWidgets('Moca resume la semana y la lee en voz alta', (tester) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      final texto = '${Textos.estaSemanaQueda('S/ 350')}.';
      expect(find.text(texto), findsOneWidget);
      expect(find.text(Textos.sinAvisos), findsOneWidget);
      await tocar(tester, find.byKey(PantallaMoca.claveEscuchar));
      expect(_loQueDijo, [texto]);
    });

    testWidgets('Sin voz en español, lo dice', (tester) async {
      await abrirApp(tester, listo: true);
      _hayVoz = false;
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      await tocar(tester, find.byKey(PantallaMoca.claveEscuchar));
      expect(find.text(Textos.sinVozEnEspanol), findsOneWidget);
    });

    testWidgets('Un gasto atípico avisa en Moca y en el Inicio', (
      tester,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        var minuto = 0;
        final repo = RepositorioMovimientosLocal(
          base,
          ahora: () => DateTime(2026, 10, 12, 20, minuto++),
        );
        final mercaderia = (await repo.categorias(TipoMovimiento.egreso))
            .firstWhere((c) => c.nombre == 'Mercadería')
            .id;
        for (final soles in [100, 100, 100, 300]) {
          await repo.registrar(
            NuevoMovimiento(
              tipo: TipoMovimiento.egreso,
              montoCentimos: soles * 100,
              cuenta: TipoCuenta.efectivo,
              categoriaId: mercaderia,
            ),
          );
        }
      });
      final texto = Textos.avisoAtipico('S/ 300', 'Mercadería');

      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.saltarPrimeraSemana));
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));
      expect(find.text('$texto.'), findsOneWidget);
      expect(find.text(Textos.verElGasto), findsOneWidget);

      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(find.text(texto), findsOneWidget);
      expect(find.text(Textos.paraTenerEnCuenta), findsOneWidget);
      await tocar(tester, find.text(texto));
      expect(find.text(Textos.tituloDetalle), findsOneWidget);
      await tocar(tester, find.byType(BotonVolver));

      await tocar(tester, find.text(Textos.entendido));
      expect(find.text(texto), findsNothing);
      expect(find.text(Textos.sinAvisos), findsOneWidget);
    });

    testWidgets('Informe y Moca no se desbordan con letra grande', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaInformes).last);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await esperar(tester);
      expect(tester.takeException(), isNull, reason: 'S14');
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(tester.takeException(), isNull, reason: 'S16');
    });
  });
}
