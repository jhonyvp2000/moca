import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dominio/aviso_cierre.dart';
import 'dominio/cuenta_real.dart';
import 'dominio/cuentas.dart';
import 'dominio/medicion.dart';
import 'dominio/primer_dia.dart';
import 'inyeccion.dart';
import 'rutas.dart';
import 'tema/colores.dart';
import 'tema/medidas.dart';
import 'tema/tipografia.dart';
import 'tema/tema.dart';
import 'textos/textos.dart';

class MocaApp extends ConsumerStatefulWidget {
  const MocaApp({super.key});

  @override
  ConsumerState<MocaApp> createState() => _MocaAppState();
}

class _MocaAppState extends ConsumerState<MocaApp> with WidgetsBindingObserver {
  final _etapa = ValueNotifier<EtapaInicio?>(null);
  late final GoRouter _rutas = crearRutas(_etapa);

  /// A dónde ir cuando se tocó una notificación antes de que la app
  /// terminara de abrir.
  DestinoNotificacion? _destinoPendiente;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(
      etapaInicioProvider,
      // Mientras se recalcula (por ejemplo, al adelantar el reloj del
      // operador) se mantiene la etapa anterior.
      (_, etapa) {
        _etapa.value = etapa.value ?? _etapa.value;
        _abrirPendiente();
      },
      fireImmediately: true,
    );
    // Las notificaciones se vuelven a programar cada vez que cambian los
    // datos.
    ref.listenManual(planNotificacionesProvider, (_, plan) {
      if (plan.value case final p?) ref.read(notificadorProvider).programar(p);
    }, fireImmediately: true);
    // El nombre que el dueño le puso a su otra billetera.
    ref.listenManual(cuentasProvider, (_, cuentas) {
      Textos.recordarNombres([
        for (final c in cuentas.value ?? const <CuentaVista>[])
          (tipo: c.tipo, nombre: c.nombre),
      ]);
    }, fireImmediately: true);
    // Con cuenta, lo anotado se sube solo unos segundos después de cada
    // cambio, al abrir la app y al volver a ella (entrega 11).
    // Desde la entrega 18 también baja lo que anotaron los demás: al abrir,
    // al volver a la app y cada pocos minutos.
    ref.listenManual(situacionCuentaProvider, (_, situacion) {
      if (situacion.value?.estado != EstadoCuenta.guardada) {
        _paraTraer?.cancel();
        _paraTraer = null;
        return;
      }
      _paraTraer ??= Timer.periodic(cadaCuantoTraer, (_) => _sincronizar());
      _subida?.cancel();
      // La primera vez, tras la espera, también baja lo de los demás.
      _subida = Timer(
        esperaParaSubir,
        () => _yaTrajo ? _subirSiHaceFalta() : _sincronizar(),
      );
    }, fireImmediately: true);
    ref.read(notificadorProvider).iniciar(alAbrir: _abrir);
    ref.read(medicionProvider).anotar(EventoMedicion.appAbierta);
  }

  /// Tiempo sin cambios antes de subir: junta varios registros seguidos.
  static const esperaParaSubir = Duration(seconds: 5);
  Timer? _subida;

  /// Cada cuánto se baja lo de los demás con la app abierta (entrega 18).
  static const cadaCuantoTraer = Duration(minutes: 5);
  Timer? _paraTraer;

  bool _yaTrajo = false;

  /// Sube lo propio, baja lo de los demás y, si hace falta, pide las cifras.
  Future<void> _sincronizar() async {
    _yaTrajo = true;
    final servicio = ref.read(servicioCuentaProvider);
    if (await servicio.hayCambiosSinSubir()) await servicio.subirTodo();
    await servicio.traerCambios();
    await servicio.actualizarCifras();
  }

  Future<void> _subirSiHaceFalta() async {
    final servicio = ref.read(servicioCuentaProvider);
    // Las cifras llegan con la subida; sin nada que subir, se piden.
    if (await servicio.hayCambiosSinSubir()) {
      await servicio.subirTodo();
    } else {
      await servicio.actualizarCifras();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    // La notificación pudo guardar una venta en segundo plano: se vuelve a
    // leer todo al volver a la app.
    if (estado == AppLifecycleState.resumed) {
      final base = ref.read(baseLocalProvider);
      base.markTablesUpdated(base.allTables);
      if (_paraTraer != null) _sincronizar();
    }
  }

  void _abrir(DestinoNotificacion destino) {
    _destinoPendiente = destino;
    _abrirPendiente();
  }

  void _abrirPendiente() {
    final destino = _destinoPendiente;
    if (destino == null || _etapa.value != EtapaInicio.listo) return;
    _destinoPendiente = null;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _ir(destino))
      ..ensureVisualUpdate();
  }

  void _ir(DestinoNotificacion destino) {
    switch (destino) {
      case DestinoNotificacion.moca:
        _rutas.go(Rutas.moca);
      case DestinoNotificacion.ventaPorVoz:
        _rutas.push(Rutas.vozVenta);
      case DestinoNotificacion.ventaEscrita:
        _rutas.push(Rutas.ventaDelDia);
      case DestinoNotificacion.arqueo:
        _rutas.push(Rutas.arqueo);
      case DestinoNotificacion.registrar:
        _rutas.push(Rutas.registrar);
    }
  }

  Future<void> _salirDeLaDemo() async {
    final contexto = _rutas.routerDelegate.navigatorKey.currentContext;
    if (contexto == null) return;
    final salir = await showDialog<bool>(
      context: contexto,
      builder: (context) => AlertDialog(
        title: const Text(Textos.salirDeLaDemoTitulo),
        content: const Text(Textos.salirDeLaDemoTexto),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Textos.salir),
          ),
        ],
      ),
    );
    if (salir != true) return;
    await ref.read(repositorioOperadorProvider).borrarTodo();
    _rutas.go(Rutas.bienvenida);
  }

  @override
  void dispose() {
    _subida?.cancel();
    _paraTraer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _rutas.dispose();
    _etapa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Textos.nombreApp,
      debugShowCheckedModeBanner: false,
      theme: temaMoca(),
      routerConfig: _rutas,
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, hijo) =>
          _ConFranjaDemo(alSalir: _salirDeLaDemo, child: hijo!),
    );
  }
}

/// «Estás viendo una demo · Salir», arriba de todas las pantallas.
class _ConFranjaDemo extends ConsumerWidget {
  const _ConFranjaDemo({required this.alSalir, required this.child});

  final VoidCallback alSalir;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(enDemoProvider).value != true) return child;
    final arriba = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        Material(
          color: Colores.azulOscuro,
          child: Padding(
            padding: EdgeInsets.fromLTRB(Medidas.margenLateral, arriba, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    Textos.estasViendoUnaDemo,
                    style: TextStyle(
                      fontFamily: Tipografia.familia,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colores.sobreMarca,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: alSalir,
                  style: TextButton.styleFrom(
                    foregroundColor: Colores.sobreMarca,
                    minimumSize: const Size(0, Medidas.objetivoTactilMinimo),
                    textStyle: Tipografia.textoFuerte,
                  ),
                  child: const Text(Textos.salir),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          // La franja ya ocupa la barra de estado.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
