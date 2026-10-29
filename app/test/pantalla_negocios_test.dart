import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moca/dominio/equipo.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/inyeccion.dart';
import 'package:moca/pantallas/equipo/pantalla_negocios.dart';
import 'package:moca/rutas.dart';
import 'package:moca/tema/tema.dart';
import 'package:moca/textos/textos.dart';

/// Un servidor de equipo de mentira: solo lo que usa «Mis negocios».
class _Equipo implements ServicioEquipo {
  List<NegocioDelUsuario>? negocios;
  List<InvitacionRecibida> invitaciones = const [];
  final cambios = <String>[];
  final aceptadas = <String>[];

  @override
  Future<List<NegocioDelUsuario>?> misNegocios() async => negocios;

  @override
  Future<List<InvitacionRecibida>?> buscarInvitaciones() async =>
      negocios == null ? null : invitaciones;

  @override
  Future<ResultadoEquipo> cambiarDeNegocio(String empresaId) async {
    cambios.add(empresaId);
    return ResultadoEquipo.listo;
  }

  @override
  Future<ResultadoEquipo> aceptar(String invitacionId) async {
    aceptadas.add(invitacionId);
    return ResultadoEquipo.vencida;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Equipo equipo;

  setUp(() => equipo = _Equipo());

  Future<void> abrir(WidgetTester tester) async {
    final rutas = GoRouter(
      initialLocation: '/negocios',
      routes: [
        GoRoute(path: '/negocios', builder: (_, _) => const PantallaNegocios()),
        GoRoute(
          path: Rutas.inicio,
          builder: (_, _) => const Scaffold(body: Text('Inicio')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [servicioEquipoProvider.overrideWithValue(equipo)],
        child: MaterialApp.router(theme: temaMoca(), routerConfig: rutas),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('El contador ve sus negocios y pasa a otro', (tester) async {
    equipo.negocios = const [
      NegocioDelUsuario(
        empresaId: 'a',
        nombre: 'Bodega Don Lucho',
        rol: Rol.contador,
        actual: true,
      ),
      NegocioDelUsuario(
        empresaId: 'b',
        nombre: 'Pollería Rosa',
        rol: Rol.contador,
      ),
    ];
    await abrir(tester);

    expect(find.text('Bodega Don Lucho'), findsOneWidget);
    expect(
      find.text('${Textos.nombreRol(Rol.contador)} · ${Textos.estasAqui}'),
      findsOneWidget,
    );
    // Solo el otro negocio tiene «Ver».
    expect(find.text(Textos.verEsteNegocio), findsOneWidget);

    await tester.tap(find.text(Textos.verEsteNegocio));
    await tester.pumpAndSettle();
    expect(equipo.cambios, ['b']);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text(Textos.ahoraVes('Pollería Rosa')), findsOneWidget);
  });

  testWidgets('Una invitación que venció lo dice y se queda en la pantalla', (
    tester,
  ) async {
    equipo
      ..negocios = const [
        NegocioDelUsuario(
          empresaId: 'a',
          nombre: 'Bodega Don Lucho',
          rol: Rol.dueno,
          actual: true,
        ),
      ]
      ..invitaciones = [
        InvitacionRecibida(
          id: 'inv',
          negocio: 'Pollería Rosa',
          rol: Rol.contador,
          venceEn: DateTime(2026, 11, 5),
        ),
      ];
    await abrir(tester);

    expect(find.text(Textos.teInvitaronA), findsOneWidget);
    expect(find.text(Textos.verEsteNegocio), findsNothing);
    await tester.tap(find.text(Textos.aceptar));
    await tester.pumpAndSettle();
    expect(equipo.aceptadas, ['inv']);
    expect(find.text(Textos.invitacionVencida), findsOneWidget);
    expect(find.text('Inicio'), findsNothing);
  });

  testWidgets('Sin señal lo dice y deja intentar otra vez', (tester) async {
    await abrir(tester);
    expect(find.text(Textos.necesitasSenalParaNegocios), findsOneWidget);
    equipo.negocios = const [
      NegocioDelUsuario(
        empresaId: 'a',
        nombre: 'Bodega Don Lucho',
        rol: Rol.dueno,
        actual: true,
      ),
    ];
    await tester.tap(find.text(Textos.intentarOtraVez));
    await tester.pumpAndSettle();
    expect(find.text('Bodega Don Lucho'), findsOneWidget);
    expect(find.text(Textos.necesitasSenalParaNegocios), findsNothing);
  });
}
