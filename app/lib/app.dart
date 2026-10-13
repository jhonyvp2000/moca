import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dominio/primer_dia.dart';
import 'inyeccion.dart';
import 'rutas.dart';
import 'tema/tema.dart';
import 'textos/textos.dart';

class MocaApp extends ConsumerStatefulWidget {
  const MocaApp({super.key});

  @override
  ConsumerState<MocaApp> createState() => _MocaAppState();
}

class _MocaAppState extends ConsumerState<MocaApp> {
  final _etapa = ValueNotifier<EtapaInicio?>(null);
  late final GoRouter _rutas = crearRutas(_etapa);

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      etapaInicioProvider,
      // Mientras se recalcula (por ejemplo, al adelantar el reloj del
      // operador) se mantiene la etapa anterior.
      (_, etapa) => _etapa.value = etapa.value ?? _etapa.value,
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
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
    );
  }
}
