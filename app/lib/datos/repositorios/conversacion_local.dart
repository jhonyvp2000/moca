import 'dart:convert';

import '../../dominio/pregunta.dart';
import 'acceso_local.dart';

/// La conversación con Moca en los ajustes del teléfono (entrega 90), con el
/// negocio al que pertenece: si el teléfono ya muestra otro negocio, no se
/// lee y se borra. Salir de la cuenta o de la Demo borra los ajustes.
class ConversacionLocal implements ConversacionConMoca {
  ConversacionLocal(this._acceso);

  final AccesoLocal _acceso;

  static const clave = 'preguntale.conversacion';

  Future<String?> _negocio() async => (await _acceso.empresa())?.id;

  @override
  Future<List<Intercambio>> leer() async {
    final texto = await _acceso.leerAjuste(clave);
    if (texto == null) return const [];
    try {
      final guardada = jsonDecode(texto) as Map<String, Object?>;
      if (guardada['negocio'] != await _negocio()) {
        await borrar();
        return const [];
      }
      return [
        for (final j in guardada['intercambios']! as List<Object?>)
          ?Intercambio.desdeJson(j),
      ];
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> agregar(Intercambio intercambio) async {
    final todos = [...await leer(), intercambio];
    final ultimos = todos.length > ConversacionConMoca.maximo
        ? todos.sublist(todos.length - ConversacionConMoca.maximo)
        : todos;
    await _acceso.guardarAjuste(
      clave,
      jsonEncode({
        'negocio': await _negocio(),
        'intercambios': [for (final i in ultimos) i.aJson()],
      }),
    );
  }

  @override
  Future<void> borrar() => (_acceso.base.delete(
    _acceso.base.ajustes,
  )..where((a) => a.clave.equals(clave))).go();
}
