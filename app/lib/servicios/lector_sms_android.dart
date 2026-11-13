import 'dart:async';

import 'package:flutter/services.dart';

import '../dominio/cuenta_real.dart';

/// SMS Retriever de Android, sin permiso para leer los mensajes
/// (entrega 14.7). El lado de Android está en MainActivity.kt.
class LectorSmsAndroid implements LectorCodigoSms {
  LectorSmsAndroid() {
    _canal.setMethodCallHandler((llamada) async {
      if (llamada.method == 'codigo' && llamada.arguments is String) {
        _codigos.add(llamada.arguments as String);
      }
    });
  }

  static const _canal = MethodChannel('pe.moca.app/sms');
  final _codigos = StreamController<String>.broadcast();

  @override
  Future<String?> marca() async {
    try {
      final marca = await _canal.invokeMethod<String>('marca');
      return marca != null && marca.length == 11 ? marca : null;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> esperar() async {
    try {
      await _canal.invokeMethod<bool>('esperar');
    } on Object {
      // Sin servicios de Google: se escribe a mano.
    }
  }

  @override
  Stream<String> get codigos => _codigos.stream;

  @override
  Future<void> dejarDeEsperar() async {
    try {
      await _canal.invokeMethod<void>('dejar');
    } on Object {
      // Ya no estaba escuchando.
    }
  }
}
