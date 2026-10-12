import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'datos/local/base_local.dart';
import 'datos/repositorios/repositorio_operador_local.dart';
import 'dominio/repositorio_operador.dart';

// El único lugar que elige qué implementación usa cada interfaz.
// En el prototipo todo es local; con el backend, cambian estas líneas y las
// pantallas no se tocan. Las pruebas reemplazan estos proveedores.

final baseLocalProvider = Provider<BaseLocal>((ref) {
  final base = BaseLocal();
  ref.onDispose(base.close);
  return base;
});

final repositorioOperadorProvider = Provider<RepositorioOperador>(
  (ref) => RepositorioOperadorLocal(ref.watch(baseLocalProvider)),
);
