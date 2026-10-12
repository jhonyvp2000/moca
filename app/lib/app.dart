import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'rutas.dart';
import 'tema/tema.dart';
import 'textos/textos.dart';

class MocaApp extends StatefulWidget {
  const MocaApp({super.key});

  @override
  State<MocaApp> createState() => _MocaAppState();
}

class _MocaAppState extends State<MocaApp> {
  late final GoRouter _rutas = crearRutas();

  @override
  void dispose() {
    _rutas.dispose();
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
