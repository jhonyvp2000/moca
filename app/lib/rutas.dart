import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'comun/barra_inferior.dart';
import 'operador/pantalla_operador.dart';
import 'pantallas/historial/pantalla_historial.dart';
import 'pantallas/informe/pantalla_informe.dart';
import 'pantallas/inicio/pantalla_inicio.dart';
import 'pantallas/moca/pantalla_moca.dart';
import 'pantallas/registrar/hoja_registrar.dart';

abstract final class Rutas {
  static const inicio = '/inicio';
  static const historial = '/historial';
  static const informes = '/informes';
  static const moca = '/moca';
  static const operador = '/operador';
}

GoRouter crearRutas() => GoRouter(
  initialLocation: Rutas.inicio,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, estado, ramas) => _ConBarraInferior(ramas: ramas),
      branches: [
        _rama(Rutas.inicio, const PantallaInicio()),
        _rama(Rutas.historial, const PantallaHistorial()),
        _rama(Rutas.informes, const PantallaInforme()),
        _rama(Rutas.moca, const PantallaMoca()),
      ],
    ),
    GoRoute(
      path: Rutas.operador,
      builder: (context, estado) => const PantallaOperador(),
    ),
  ],
);

StatefulShellBranch _rama(String ruta, Widget pantalla) => StatefulShellBranch(
  routes: [GoRoute(path: ruta, builder: (context, estado) => pantalla)],
);

class _ConBarraInferior extends StatelessWidget {
  const _ConBarraInferior({required this.ramas});

  final StatefulNavigationShell ramas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ramas,
      bottomNavigationBar: BarraInferior(
        pestanaActual: ramas.currentIndex,
        alElegirPestana: (indice) => ramas.goBranch(
          indice,
          initialLocation: indice == ramas.currentIndex,
        ),
        alRegistrar: () => mostrarHojaRegistrar(context),
      ),
    );
  }
}
