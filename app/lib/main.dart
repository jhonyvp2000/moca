import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'comun/pantalla_con_error.dart';
import 'servicios/registro_de_errores.dart';

void main() {
  // Todo error inesperado queda anotado para Jhony (entrega 27).
  final registro = RegistroDeErrores.instancia;
  FlutterError.onError = (detalles) {
    FlutterError.presentError(detalles);
    registro.anotar(detalles.exception, detalles.stack);
  };
  PlatformDispatcher.instance.onError = (error, pila) {
    registro.anotar(error, pila);
    return true;
  };
  // En vez del recuadro gris de Flutter, un aviso con «Volver».
  ErrorWidget.builder = (_) => const PantallaConError();
  runApp(const ProviderScope(child: MocaApp()));
}
