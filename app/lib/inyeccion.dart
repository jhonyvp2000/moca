import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'datos/local/base_local.dart';
import 'datos/repositorios/repositorio_ajustes_local.dart';
import 'datos/repositorios/repositorio_movimientos_local.dart';
import 'datos/repositorios/repositorio_operador_local.dart';
import 'datos/repositorios/repositorio_primer_dia_local.dart';
import 'datos/simulados/frases_ejemplo.dart';
import 'dominio/ajustes.dart';
import 'dominio/modelos.dart';
import 'dominio/movimientos.dart';
import 'dominio/primer_dia.dart';
import 'dominio/repositorio_operador.dart';
import 'dominio/voz.dart';
import 'servicios/voz_android.dart';

// El único lugar que elige qué implementación usa cada interfaz.
// En el prototipo todo es local; con el backend, cambian estas líneas y las
// pantallas no se tocan. Las pruebas reemplazan estos proveedores.

final baseLocalProvider = Provider<BaseLocal>((ref) {
  final base = BaseLocal();
  ref.onDispose(base.close);
  return base;
});

/// La hora actual. Las pruebas la fijan para que los resultados no dependan
/// del día en que se corren.
final relojProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final repositorioOperadorProvider = Provider<RepositorioOperador>(
  (ref) => RepositorioOperadorLocal(ref.watch(baseLocalProvider)),
);

final repositorioPrimerDiaProvider = Provider<RepositorioPrimerDia>(
  (ref) => RepositorioPrimerDiaLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
  ),
);

final etapaInicioProvider = StreamProvider<EtapaInicio>(
  (ref) => ref.watch(repositorioPrimerDiaProvider).observarEtapa(),
);

final resumenPrimerDiaProvider = StreamProvider<ResumenPrimerDia>(
  (ref) => ref.watch(repositorioPrimerDiaProvider).observarResumen(),
);

final repositorioMovimientosProvider = Provider<RepositorioMovimientos>(
  (ref) => RepositorioMovimientosLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
  ),
);

final resumenInicioProvider = StreamProvider<ResumenInicio>(
  (ref) => ref.watch(repositorioMovimientosProvider).observarInicio(),
);

/// Categorías de entró o salió, para «Escribirlo».
final categoriasProvider = FutureProvider.autoDispose
    .family<List<CategoriaVista>, TipoMovimiento>(
      (ref, tipo) => ref.watch(repositorioMovimientosProvider).categorias(tipo),
    );

final repositorioAjustesProvider = Provider<RepositorioAjustes>(
  (ref) => RepositorioAjustesLocal(ref.watch(baseLocalProvider)),
);

// --- Voz ---------------------------------------------------------------------

final frasesDeEjemploProvider = Provider<List<FraseEjemplo>>(
  (ref) => frasesEjemplo,
);

/// La frase que el operador eligió para la próxima grabación. Se usa una vez.
final fraseElegidaProvider = NotifierProvider<FraseElegida, FraseEjemplo?>(
  FraseElegida.new,
);

class FraseElegida extends Notifier<FraseEjemplo?> {
  @override
  FraseEjemplo? build() => null;

  void elegir(FraseEjemplo frase) => state = frase;

  void usar() => state = null;
}

final _reconocedorAndroidProvider = Provider<ReconocedorVoz>(
  (ref) => ReconocedorVozAndroid(),
);

/// El reconocimiento de voz de Android, salvo que el operador haya elegido una
/// frase de ejemplo para la próxima grabación.
final reconocedorVozProvider = Provider<ReconocedorVoz>((ref) {
  final frase = ref.watch(fraseElegidaProvider);
  return frase == null
      ? ref.watch(_reconocedorAndroidProvider)
      : ReconocedorFrase(frase);
});
