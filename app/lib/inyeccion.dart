import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'datos/local/base_local.dart';
import 'datos/remoto/lector_foto_remoto.dart';
import 'datos/repositorios/acceso_local.dart';
import 'datos/remoto/servicio_cuenta_remoto.dart';
import 'datos/repositorios/repositorio_ajustes_local.dart';
import 'datos/repositorios/medicion_local.dart';
import 'datos/repositorios/repositorio_arqueo_local.dart';
import 'datos/repositorios/repositorio_aviso_cierre_local.dart';
import 'datos/repositorios/repositorio_comprobantes_local.dart';
import 'datos/repositorios/repositorio_cuentas_local.dart';
import 'datos/repositorios/repositorio_historial_local.dart';
import 'datos/repositorios/repositorio_informe_local.dart';
import 'datos/repositorios/repositorio_moca_local.dart';
import 'datos/repositorios/repositorio_movimientos_local.dart';
import 'datos/repositorios/repositorio_operador_local.dart';
import 'datos/repositorios/repositorio_primer_dia_local.dart';
import 'datos/repositorios/repositorio_tutoria_local.dart';
import 'datos/simulados/frases_ejemplo.dart';
import 'datos/simulados/lector_foto_simulado.dart';
import 'dominio/ajustes.dart';
import 'dominio/arqueo.dart';
import 'dominio/aviso_cierre.dart';
import 'dominio/medicion.dart';
import 'dominio/comprobantes.dart';
import 'dominio/conexion.dart';
import 'dominio/cuenta_real.dart';
import 'dominio/cuentas.dart';
import 'dominio/historial.dart';
import 'dominio/informe.dart';
import 'dominio/moca.dart';
import 'dominio/modelos.dart';
import 'dominio/movimientos.dart';
import 'dominio/primer_dia.dart';
import 'dominio/repositorio_operador.dart';
import 'dominio/servicios.dart';
import 'dominio/tutoria.dart';
import 'dominio/voz.dart';
import 'servicios/abridor_android.dart';
import 'servicios/buscador_qr_android.dart';
import 'servicios/camara_android.dart';
import 'servicios/compartidor_android.dart';
import 'servicios/conexion_android.dart';
import 'servicios/llavero_android.dart';
import 'servicios/locutor_android.dart';
import 'servicios/notificador_android.dart';
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
final relojProvider = Provider<DateTime Function()>((ref) {
  final dias = ref.watch(adelantoDelRelojProvider);
  return dias == 0
      ? DateTime.now
      : () => DateTime.now().add(Duration(days: dias));
});

/// «Adelantar el reloj un día», del ajuste oculto: días que se suman a la
/// hora real. Dura mientras la app esté abierta.
final adelantoDelRelojProvider = NotifierProvider<AdelantoDelReloj, int>(
  AdelantoDelReloj.new,
);

class AdelantoDelReloj extends Notifier<int> {
  @override
  int build() => 0;

  void adelantarUnDia() => state++;

  void volverALaHoraReal() => state = 0;
}

// --- Señal ---------------------------------------------------------------------

/// La señal real del teléfono. Las pruebas la reemplazan.
final conexionTelefonoProvider = Provider<Conexion>((ref) => ConexionAndroid());

/// «Simular sin señal», del ajuste oculto. Dura mientras la app esté abierta.
final simularSinSenalProvider = NotifierProvider<SimularSinSenal, bool>(
  SimularSinSenal.new,
);

class SimularSinSenal extends Notifier<bool> {
  @override
  bool build() => false;

  void cambiar() => state = !state;
}

final conexionProvider = Provider<Conexion>(
  (ref) => ref.watch(simularSinSenalProvider)
      ? const ConexionSimuladaSinSenal()
      : ref.watch(conexionTelefonoProvider),
);

final hayConexionProvider = StreamProvider<bool>(
  (ref) => ref.watch(conexionProvider).observar(),
);

// --- Repositorios ----------------------------------------------------------------

final repositorioOperadorProvider = Provider<RepositorioOperador>(
  (ref) => RepositorioOperadorLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
  ),
);

final repositorioPrimerDiaProvider = Provider<RepositorioPrimerDia>(
  (ref) => RepositorioPrimerDiaLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
    hayConexion: ref.watch(conexionProvider).hayConexion,
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
    hayConexion: ref.watch(conexionProvider).hayConexion,
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

// --- Historial -----------------------------------------------------------------

final repositorioHistorialProvider = Provider<RepositorioHistorial>(
  (ref) => RepositorioHistorialLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
    hayConexion: ref.watch(conexionProvider).hayConexion,
  ),
);

final historialProvider = StreamProvider<ResumenHistorial>(
  (ref) => ref.watch(repositorioHistorialProvider).observarHistorial(),
);

final detalleMovimientoProvider = StreamProvider.autoDispose
    .family<DetalleMovimiento?, String>(
      (ref, id) => ref.watch(repositorioHistorialProvider).observarDetalle(id),
    );

// --- Arqueo --------------------------------------------------------------------

final repositorioArqueoProvider = Provider<RepositorioArqueo>(
  (ref) => RepositorioArqueoLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
    hayConexion: ref.watch(conexionProvider).hayConexion,
  ),
);

// --- Informe y Moca -----------------------------------------------------------

final repositorioInformeProvider = Provider<RepositorioInforme>(
  (ref) => RepositorioInformeLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
  ),
);

/// El informe de un mes; nulo es el mes en curso.
final informeProvider = StreamProvider.autoDispose
    .family<InformeMes, DateTime?>(
      (ref, mes) => ref.watch(repositorioInformeProvider).observarMes(mes),
    );

final repositorioMocaProvider = Provider<RepositorioMoca>(
  (ref) => RepositorioMocaLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
  ),
);

final avisosProvider = StreamProvider<List<Aviso>>(
  (ref) => ref.watch(repositorioMocaProvider).observarAvisos(),
);

final resumenSemanaProvider = StreamProvider<ResumenSemana>(
  (ref) => ref.watch(repositorioMocaProvider).observarResumen(),
);

final locutorProvider = Provider<Locutor>((ref) => LocutorAndroid());

final compartidorProvider = Provider<Compartidor>(
  (ref) => CompartidorAndroid(),
);

// --- Aviso de cierre, Demo y medición -----------------------------------------

final repositorioAvisoCierreProvider = Provider<RepositorioAvisoCierre>(
  (ref) => RepositorioAvisoCierreLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
    hayConexion: ref.watch(conexionProvider).hayConexion,
  ),
);

final planNotificacionesProvider = StreamProvider<List<NotificacionProgramada>>(
  (ref) => ref.watch(repositorioAvisoCierreProvider).observarPlan(),
);

final permisoAvisosPreguntadoProvider = FutureProvider<bool>(
  (ref) => ref.watch(repositorioAvisoCierreProvider).permisoPreguntado(),
);

final notificadorProvider = Provider<Notificador>(
  (ref) => NotificadorAndroid(ref.watch(baseLocalProvider)),
);

final enDemoProvider = StreamProvider<bool>(
  (ref) => ref.watch(repositorioOperadorProvider).observarDemo(),
);

final medicionProvider = Provider<Medicion>(
  (ref) => MedicionLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
  ),
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

// --- Comprobantes -----------------------------------------------------------

final repositorioComprobantesProvider = Provider<RepositorioComprobantes>(
  (ref) => RepositorioComprobantesLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
    hayConexion: ref.watch(conexionProvider).hayConexion,
  ),
);

final camaraProvider = Provider<Camara>((ref) => CamaraAndroid());

/// Si el operador forzó que la próxima foto salga ilegible (S17).
final forzarIlegibleProvider = NotifierProvider<ForzarIlegible, bool>(
  ForzarIlegible.new,
);

class ForzarIlegible extends Notifier<bool> {
  @override
  bool build() => false;

  void forzar() => state = true;

  /// Devuelve si estaba forzada y la apaga: vale para una sola foto.
  bool usar() {
    final forzada = state;
    state = false;
    return forzada;
  }
}

final buscadorQrProvider = Provider<BuscadorQr>((ref) => BuscadorQrAndroid());

/// Las fotos de prueba que le quedan al teléfono sin cuenta; nulo con cuenta
/// o en la Demo (entrega 14.2).
final fotosDePruebaProvider = StreamProvider<int?>((ref) {
  final acceso = AccesoLocal(
    ref.watch(baseLocalProvider),
    ref.watch(relojProvider),
  );
  return acceso.cambios().asyncMap((_) => acceso.fotosDePrueba());
});

/// QR dentro de la foto, y si no hay, la IA del servidor (entrega 14). En
/// la Demo, los comprobantes de ejemplo.
final lectorFotoProvider = Provider<LectorFoto>(
  (ref) => LectorFotoRemoto(
    ref.watch(baseLocalProvider),
    llavero: ref.watch(llaveroProvider),
    buscadorQr: ref.watch(buscadorQrProvider),
    deEjemplo: LectorFotoSimulado(
      ahora: ref.watch(relojProvider),
      forzarIlegible: () => ref.read(forzarIlegibleProvider.notifier).usar(),
    ),
    ahora: ref.watch(relojProvider),
    hayConexion: ref.watch(conexionProvider).hayConexion,
  ),
);

// --- Cuentas -----------------------------------------------------------------

final repositorioCuentasProvider = Provider<RepositorioCuentas>(
  (ref) => RepositorioCuentasLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
  ),
);

final cuentasProvider = StreamProvider<List<CuentaVista>>(
  (ref) => ref.watch(repositorioCuentasProvider).observar(),
);

/// Las cuentas que el dueño usa, en orden. Mientras cargan, las tres básicas.
final tiposDeCuentaProvider = Provider<List<TipoCuenta>>((ref) {
  final cuentas = ref.watch(cuentasProvider).value;
  if (cuentas == null || cuentas.isEmpty) return TipoCuenta.basicas;
  return [for (final c in cuentas) c.tipo];
});

// --- Cuenta real (entrega 11) ------------------------------------------------

final llaveroProvider = Provider<Llavero>((ref) => LlaveroAndroid());

final servicioCuentaProvider = Provider<ServicioCuenta>(
  (ref) => ServicioCuentaRemoto(
    ref.watch(baseLocalProvider),
    llavero: ref.watch(llaveroProvider),
    ahora: ref.watch(relojProvider),
    hayConexion: ref.watch(conexionProvider).hayConexion,
  ),
);

final situacionCuentaProvider = StreamProvider<SituacionCuenta>(
  (ref) => ref.watch(servicioCuentaProvider).observar(),
);

// --- Videos de ayuda (entrega 14.6) -----------------------------------------

final repositorioTutoriaProvider = Provider<RepositorioTutoria>(
  (ref) => RepositorioTutoriaLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
  ),
);

final abridorProvider = Provider<AbridorDeEnlaces>((ref) => AbridorAndroid());

/// Los enlaces de los videos. Las pruebas ponen los suyos.
final enlacesDeVideosProvider = Provider<Map<VideoTutoria, String>>(
  (ref) => enlacesDeVideos,
);

/// «Ver los videos sin enlace», del ajuste oculto. Dura mientras la app esté
/// abierta.
final videosSinEnlaceProvider = NotifierProvider<VideosSinEnlace, bool>(
  VideosSinEnlace.new,
);

class VideosSinEnlace extends Notifier<bool> {
  @override
  bool build() => false;

  void cambiar() => state = !state;
}

final _vistosProvider = StreamProvider<EstadoTutoria>(
  (ref) => ref.watch(repositorioTutoriaProvider).observar(),
);

/// Qué videos hay, cuáles se vieron y qué tarjetas se cerraron. Mientras
/// carga, ninguno se muestra.
final estadoTutoriaProvider = Provider<EstadoTutoria?>((ref) {
  final estado = ref.watch(_vistosProvider).value;
  return estado?.con(
    enlaces: ref.watch(enlacesDeVideosProvider),
    sinEnlace: ref.watch(videosSinEnlaceProvider),
  );
});
