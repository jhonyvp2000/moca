import 'dart:convert';

import '../../dominio/errores.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

/// Los errores que esperan subir (entrega 27), en un ajuste: son pocos.
class RepositorioErroresLocal {
  RepositorioErroresLocal(BaseLocal base, {DateTime Function()? ahora})
    : _a = AccesoLocal(base, ahora ?? DateTime.now);

  static const clave = 'errores_por_subir';

  /// Como máximo, tantos errores distintos esperando.
  static const maximo = 30;

  final AccesoLocal _a;

  Future<List<ErrorAnotado>> porSubir() async {
    final texto = await _a.leerAjuste(clave);
    if (texto == null) return const [];
    try {
      return [
        for (final e in jsonDecode(texto) as List)
          ErrorAnotado.desdeJson(e as Map<String, Object?>),
      ];
    } on Object {
      return const [];
    }
  }

  /// Si ya estaba el mismo error, suma una vez más.
  Future<void> guardar(ErrorAnotado nuevo) async {
    final lista = [...await porSubir()];
    final i = lista.indexWhere((e) => e.firma == nuevo.firma);
    if (i >= 0) {
      lista[i] = lista[i].otraVez(nuevo.ultima);
    } else if (lista.length < maximo) {
      lista.add(nuevo);
    } else {
      return;
    }
    await _a.guardarAjuste(
      clave,
      jsonEncode([for (final e in lista) e.json()]),
    );
  }

  /// Los que ya subieron: si vuelven a pasar, van con otro id.
  Future<void> quitar(Set<String> ids) async {
    final quedan = [
      for (final e in await porSubir())
        if (!ids.contains(e.id)) e,
    ];
    await _a.guardarAjuste(
      clave,
      jsonEncode([for (final e in quedan) e.json()]),
    );
  }
}
