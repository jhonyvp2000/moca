import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'comun/barra_inferior.dart';
import 'dominio/comprobantes.dart';
import 'dominio/historial.dart';
import 'dominio/modelos.dart';
import 'dominio/movimientos.dart';
import 'dominio/primer_dia.dart';
import 'operador/pantalla_operador.dart';
import 'pantallas/alta/pantalla_alta.dart';
import 'pantallas/arqueo/pantalla_arqueo.dart';
import 'pantallas/bienvenida/pantalla_bienvenida.dart';
import 'pantallas/comprobantes/pantalla_confirmar_lectura.dart';
import 'pantallas/comprobantes/pantalla_escaner_qr.dart';
import 'pantallas/comprobantes/pantalla_foto.dart';
import 'pantallas/guardar_avance/pantalla_codigo.dart';
import 'pantallas/guardar_avance/pantalla_guardar_avance.dart';
import 'pantallas/historial/pantalla_detalle_movimiento.dart';
import 'pantallas/historial/pantalla_historial.dart';
import 'pantallas/informe/pantalla_informe.dart';
import 'pantallas/inicio/pantalla_inicio.dart';
import 'pantallas/moca/pantalla_moca.dart';
import 'pantallas/registrar/pantalla_escribir.dart';
import 'pantallas/registrar/pantalla_registrar.dart';
import 'pantallas/venta_de_hoy/pantalla_venta_de_hoy.dart';
import 'pantallas/voz/pantalla_voz.dart';
import 'tema/colores.dart';

abstract final class Rutas {
  static const cargando = '/cargando';
  static const bienvenida = '/bienvenida';
  static const ventaDeHoy = '/bienvenida/venta-de-hoy';
  static const vozPrimeraVenta = '/bienvenida/voz';
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
  static const voz = '/voz';
  static const foto = '/comprobante/foto';
  static const qr = '/comprobante/qr';
  static const confirmarLectura = '/comprobante/confirmar';
  static const movimiento = '/movimiento';
  static const corregir = '/movimiento/corregir';
  static const arqueo = '/arqueo';

  /// El detalle de un movimiento del Historial.
  static String detalleMovimiento(String id) =>
      Uri(path: movimiento, queryParameters: {'id': id}).toString();

  /// «Anotar la venta de hoy» por voz.
  static final vozVenta = Uri(
    path: voz,
    queryParameters: {'modo': ModoVoz.ventaDelDia.name},
  ).toString();
  static const operador = '/operador';
}

/// Qué rutas se pueden ver en cada etapa del primer día. Si la ruta actual
/// no corresponde a la etapa, se va a la primera de la lista. Así la app
/// retoma el paso pendiente al volver a abrirse, y «atrás» no regresa a una
/// venta ya guardada.
final _rutasPorEtapa = {
  EtapaInicio.bienvenida: [
    Rutas.bienvenida,
    Rutas.ventaDeHoy,
    Rutas.vozPrimeraVenta,
  ],
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
    Rutas.voz,
    Rutas.foto,
    Rutas.qr,
    Rutas.confirmarLectura,
    Rutas.movimiento,
    Rutas.corregir,
    Rutas.arqueo,
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
          builder: (context, estado) => PantallaVentaDeHoy(
            montosIniciales: estado.extra as Map<TipoCuenta, int>?,
          ),
        ),
        GoRoute(
          path: 'voz',
          builder: (context, estado) =>
              const PantallaVoz(modo: ModoVoz.primeraVenta),
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
              borrador: estado.extra as BorradorMovimiento?,
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: Rutas.ventaDelDia,
      builder: (context, estado) => PantallaVentaDeHoy(
        primeraVenta: false,
        montosIniciales: estado.extra as Map<TipoCuenta, int>?,
      ),
    ),
    GoRoute(
      path: Rutas.voz,
      builder: (context, estado) => PantallaVoz(
        modo: estado.uri.queryParameters['modo'] == ModoVoz.ventaDelDia.name
            ? ModoVoz.ventaDelDia
            : ModoVoz.libre,
      ),
    ),
    GoRoute(
      path: Rutas.foto,
      builder: (context, estado) => const PantallaFoto(),
    ),
    GoRoute(
      path: Rutas.qr,
      builder: (context, estado) => const PantallaEscanerQr(),
    ),
    GoRoute(
      path: Rutas.confirmarLectura,
      builder: (context, estado) => PantallaConfirmarLectura(
        lectura: estado.extra! as LecturaComprobante,
      ),
    ),
    GoRoute(
      path: Rutas.movimiento,
      builder: (context, estado) =>
          PantallaDetalleMovimiento(id: estado.uri.queryParameters['id'] ?? ''),
      routes: [
        GoRoute(
          path: 'corregir',
          builder: (context, estado) =>
              PantallaEscribir(corrigiendo: estado.extra! as DetalleMovimiento),
        ),
      ],
    ),
    GoRoute(
      path: Rutas.arqueo,
      builder: (context, estado) => const PantallaArqueo(),
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
