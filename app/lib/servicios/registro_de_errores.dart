import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../dominio/errores.dart';

/// Recibe todo error inesperado de la app (entrega 27). Funciona antes de
/// que exista la base: guarda en memoria hasta que la app lo conecta.
class RegistroDeErrores {
  RegistroDeErrores({DateTime Function()? ahora})
    : _ahora = ahora ?? DateTime.now;

  static final instancia = RegistroDeErrores();

  final DateTime Function() _ahora;

  /// Dónde estaba la persona, para saber en qué pantalla falló.
  String pantalla = '';
  String? entrega;
  int? armado;

  Future<void> Function(ErrorAnotado)? _guardar;
  final _enEspera = <ErrorAnotado>[];

  /// Desde aquí, cada error va a [guardar].
  void conectar(Future<void> Function(ErrorAnotado) guardar) {
    _guardar = guardar;
    for (final e in List.of(_enEspera)) {
      guardar(e);
    }
    _enEspera.clear();
  }

  /// Los números largos se tapan: podrían ser un celular o un monto.
  static String tapar(String texto) => texto.replaceAllMapped(
    RegExp(r'\d{6,}'),
    (m) => '${m[0]!.substring(0, 3)}***',
  );

  /// Las primeras líneas de la pila, tapadas.
  static String? pilaCorta(StackTrace? pila) {
    if (pila == null) return null;
    final lineas = pila.toString().split('\n').take(15).join('\n');
    return tapar(lineas.substring(0, min(lineas.length, 3000)));
  }

  /// El error a guardar: nunca falla, para no causar otro error.
  ErrorAnotado? describir(Object error, StackTrace? pila) {
    try {
      final completo = tapar(error.toString());
      final mensaje = completo.substring(0, min(completo.length, 300));
      final corta = pilaCorta(pila);
      // El primer lugar de Moca en la pila: es lo que distingue un error.
      final lugar =
          corta
              ?.split('\n')
              .firstWhere(
                (l) => l.contains('package:moca/'),
                orElse: () => '',
              ) ??
          '';
      final firma = sha1
          .convert(
            utf8.encode(
              '${error.runtimeType}|'
              '${mensaje.substring(0, min(mensaje.length, 120))}|$lugar',
            ),
          )
          .toString()
          .substring(0, 16);
      final cuando = _ahora();
      return ErrorAnotado(
        id: const Uuid().v4(),
        firma: firma,
        mensaje: mensaje,
        pila: corta,
        pantalla: pantalla.isEmpty ? null : pantalla,
        entrega: entrega,
        armado: armado,
        veces: 1,
        primera: cuando,
        ultima: cuando,
      );
    } on Object {
      return null;
    }
  }

  void anotar(Object error, StackTrace? pila) {
    final e = describir(error, pila);
    if (e == null) return;
    final guardar = _guardar;
    if (guardar == null) {
      if (_enEspera.length < 20) _enEspera.add(e);
      return;
    }
    guardar(e).catchError((Object _) {});
  }
}
