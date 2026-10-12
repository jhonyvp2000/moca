import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'comun/barra_inferior.dart';
import 'dominio/modelos.dart';
import 'dominio/primer_dia.dart';
import 'operador/pantalla_operador.dart';
import 'pantallas/alta/pantalla_alta.dart';
import 'pantallas/bienvenida/pantalla_bienvenida.dart';
import 'pantallas/guardar_avance/pantalla_codigo.dart';
import 'pantallas/guardar_avance/pantalla_guardar_avance.dart';
import 'pantallas/historial/pantalla_historial.dart';
import 'pantallas/informe/pantalla_informe.dart';
import 'pantallas/inicio/pantalla_inicio.dart';
import 'pantallas/moca/pantalla_moca.dart';
import 'pantallas/registrar/pantalla_escribir.dart';
import 'pantallas/registrar/pantalla_registrar.dart';
import 'pantallas/venta_de_hoy/pantalla_venta_de_hoy.dart';
import 'tema/colores.dart';

abstract final class Rutas {
  static const cargando = '/cargando';
  static const bienvenida = '/bienvenida';
  static const ventaDeHoy = '/bienvenida/venta-de-hoy';
  static const guardarAvance = '/guardar-avance';
  static const codigo = '/guardar-avance/codigo';
  static const alta = '/alta';
  static const inicio = '/inicio';
  static const historial = '/historial';
  static const informes = '/informes';
  static const moca = '/moca';
  static const registrar = '/registrar';
  static const escribir = '/registrar/escribir';
  static const ventaDelDia = '/venta-del-dia';
  static const operador = '/operador';
}

/// Qué rutas se pueden ver en cada etapa del primer día. Si la ruta actual
/// no corresponde a la etapa, se va a la primera de la lista. Así la app
/// retoma el paso pendiente al volver a abrirse, y «atrás» no regresa a una
/// venta ya guardada.
const _rutasPorEtapa = {
  EtapaInicio.bienvenida: [Rutas.bienvenida, Rutas.ventaDeHoy],
  EtapaInicio.guardarAvance: [Rutas.guardarAvance, Rutas.codigo],
  EtapaInicio.alta: [Rutas.alta],
  EtapaInicio.listo: [
    Rutas.inicio,
    Rutas.historial,
    Rutas.informes,
    Rutas.moca,
    Rutas.registrar,
    Rutas.escribir,
    Rutas.ventaDelDia,
  ],
};

String? redirigirSegunEtapa(EtapaInicio? etapa, String ruta) {
  // El ajuste oculto se puede abrir siempre.
  if (ruta == Rutas.operador) return null;
  if (etapa == null) return ruta == Rutas.cargando ? null : Rutas.cargando;
  final permitidas = _rutasPorEtapa[etapa]!;
  return permitidas.contains(ruta) ? null : permitidas.first;
}

GoRouter crearRutas(ValueNotifier<EtapaInicio?> etapa) => GoRouter(
  initialLocation: Rutas.cargando,
  refreshListenable: etapa,
  redirect: (context, estado) =>
      redirigirSegunEtapa(etapa.value, estado.matchedLocation),
  routes: [
    GoRoute(
      path: Rutas.cargando,
      builder: (context, estado) =>
          const ColoredBox(color: Colores.fondo, child: SizedBox.expand()),
    ),
    GoRoute(
      path: Rutas.bienvenida,
      builder: (context, estado) => const PantallaBienvenida(),
      routes: [
        GoRoute(
          path: 'venta-de-hoy',
          builder: (context, estado) => const PantallaVentaDeHoy(),
        ),
      ],
    ),
    GoRoute(
      path: Rutas.guardarAvance,
      builder: (context, estado) => const PantallaGuardarAvance(),
      routes: [
        GoRoute(
          path: 'codigo',
          builder: (context, estado) =>
              PantallaCodigo(celular: estado.extra as String? ?? ''),
        ),
      ],
    ),
    GoRoute(
      path: Rutas.alta,
      builder: (context, estado) => const PantallaAlta(),
    ),
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
      path: Rutas.registrar,
      builder: (context, estado) => const PantallaRegistrar(),
      routes: [
        GoRoute(
          path: 'escribir',
          builder: (context, estado) {
            final tipo = estado.uri.queryParameters['tipo'];
            return PantallaEscribir(
              tipoInicial: tipo == null
                  ? null
                  : TipoMovimiento.values.asNameMap()[tipo],
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: Rutas.ventaDelDia,
      builder: (context, estado) =>
          const PantallaVentaDeHoy(primeraVenta: false),
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
        alRegistrar: () => context.push(Rutas.registrar),
      ),
    );
  }
}
