import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'datos/local/base_local.dart';
import 'datos/remoto/lector_foto_remoto.dart';
import 'datos/repositorios/repositorio_categorias_local.dart';
import 'datos/repositorios/repositorio_negocio_local.dart';
import 'datos/repositorios/repositorio_errores_local.dart';
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
import 'dominio/categorias.dart';
import 'dominio/negocio.dart';
import 'dominio/errores.dart';
import 'dominio/version.dart';
import 'dominio/cobro.dart';
import 'dominio/cerradura.dart';
import 'dominio/ajustes.dart';
import 'dominio/arqueo.dart';
import 'dominio/aviso_cierre.dart';
import 'dominio/medicion.dart';
import 'dominio/comprobantes.dart';
import 'dominio/conexion.dart';
import 'dominio/cuenta_real.dart';
import 'dominio/equipo.dart';
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
import 'servicios/cerradura_android.dart';
import 'servicios/abridor_android.dart';
import 'servicios/buscador_qr_android.dart';
import 'servicios/camara_android.dart';
import 'servicios/compartidor_android.dart';
import 'servicios/conexion_android.dart';
import 'servicios/lector_sms_android.dart';
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
    .family<List<CategoriaVista>, TipoMovimiento>((ref, tipo) {
      // Al agregar o cambiar una propia (entrega 31), se vuelve a leer.
      ref.watch(categoriasDelNegocioProvider);
      return ref.watch(repositorioMovimientosProvider).categorias(tipo);
    });

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

/// «Lo que te deben» (entrega 42): las ventas a crédito sin cobrar.
final loQueTeDebenProvider = StreamProvider.autoDispose<List<FilaHistorial>>(
  (ref) => ref.watch(repositorioHistorialProvider).observarLoQueTeDeben(),
);

/// El resumen de un año (entrega 40); nulo es el actual.
final resumenAnioProvider = StreamProvider.autoDispose
    .family<ResumenAnio, int?>(
      (ref, anio) => ref.watch(repositorioInformeProvider).observarAnio(anio),
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
  (ref) {
    // Los avisos de cierre y del día son del dueño (entrega 20): a los demás
    // no se les programa nada.
    final permisos = ref.watch(permisosProvider).value;
    if (permisos != null && !permisos.recibeAvisos) {
      return Stream.value(const <NotificacionProgramada>[]);
    }
    // Tres días antes de que termine la prueba, a las 9 (entrega 25).
    final cobro = ref.watch(cobroProvider).value;
    final hasta = cobro?.hasta;
    final aviso =
        cobro != null &&
            cobro.estado == EstadoDelCobro.prueba &&
            hasta != null &&
            !(permisos?.soloAnotar ?? false)
        ? DateTime(hasta.year, hasta.month, hasta.day - 3, 9)
        : null;
    final ahora = ref.watch(relojProvider)();
    return ref
        .watch(repositorioAvisoCierreProvider)
        .observarPlan()
        .map(
          (plan) => [
            ...plan,
            if (aviso != null && aviso.isAfter(ahora))
              NotificacionProgramada(
                id: idAvisoDelCobro,
                cuando: aviso,
                tipo: TipoNotificacion.cobroPorVencer,
              ),
          ],
        );
  },
);

/// El id del aviso de la prueba: no choca con los de cierre ni del día.
const idAvisoDelCobro = 700001;

final permisoAvisosPreguntadoProvider = FutureProvider<bool>(
  (ref) => ref.watch(repositorioAvisoCierreProvider).permisoPreguntado(),
);

/// La huella o el bloqueo del teléfono (entrega 16.3).
final cerraduraProvider = Provider<Cerradura>((ref) => CerraduraAndroid());

/// Si este teléfono pide la huella al abrir Moca (entrega 16.3). No se sube:
/// cada teléfono decide.
final pedirHuellaProvider = StreamProvider<bool>((ref) {
  final acceso = AccesoLocal(
    ref.watch(baseLocalProvider),
    ref.watch(relojProvider),
  );
  return acceso.cambios().asyncMap(
    (_) async => await acceso.leerAjuste(AccesoLocal.clavePedirHuella) == 'si',
  );
});

/// Enciende o apaga «Pedir huella al abrir Moca» en este teléfono.
final guardarPedirHuellaProvider = Provider<Future<void> Function(bool)>(
  (ref) =>
      (pedir) => AccesoLocal(
        ref.read(baseLocalProvider),
        ref.read(relojProvider),
      ).guardarAjuste(AccesoLocal.clavePedirHuella, pedir ? 'si' : 'no'),
);

final notificadorProvider = Provider<Notificador>(
  (ref) => NotificadorAndroid(ref.watch(baseLocalProvider)),
);

/// El rol con que se simula la app desde el ajuste oculto (entrega 20.1).
final verComoProvider = StreamProvider<Rol?>(
  (ref) => ref.watch(repositorioOperadorProvider).observarVerComo(),
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
  // El encargado y el ayudante anotan solo en sus cajas (entrega 21).
  final permisos = ref.watch(permisosProvider).value ?? Permisos.delDueno;
  return [
    for (final c in cuentas)
      if (permisos.puedeUsar(c.tipo)) c.tipo,
  ];
});

// --- Cuenta real (entrega 11) ------------------------------------------------

final llaveroProvider = Provider<Llavero>((ref) => LlaveroAndroid());

/// Lee solo el SMS del código (entrega 14.7).
final lectorCodigoSmsProvider = Provider<LectorCodigoSms>(
  (ref) => LectorSmsAndroid(),
);

final servicioCuentaProvider = Provider<ServicioCuenta>(
  (ref) => ServicioCuentaRemoto(
    ref.watch(baseLocalProvider),
    llavero: ref.watch(llaveroProvider),
    lectorSms: ref.watch(lectorCodigoSmsProvider),
    ahora: ref.watch(relojProvider),
    hayConexion: ref.watch(conexionProvider).hayConexion,
  ),
);

/// El equipo del negocio (entrega 19): lo lleva el mismo servicio de la
/// cuenta, con la misma llave.
final servicioEquipoProvider = Provider<ServicioEquipo>(
  (ref) => ref.watch(servicioCuentaProvider) as ServicioEquipo,
);

/// El estado del cobro del negocio (entrega 25): el último que mandó el
/// servidor, puesto al día con la fecha. Sin cuenta, no se cobra.
final cobroProvider = StreamProvider<Cobro>((ref) {
  final reloj = ref.watch(relojProvider);
  final acceso = AccesoLocal(ref.watch(baseLocalProvider), reloj);
  return acceso.cambios().asyncMap((_) async {
    final guardado = await acceso.leerAjuste(AccesoLocal.claveCobro);
    if (guardado == null) return Cobro.sinCobro;
    try {
      return Cobro.desdeServidor(jsonDecode(guardado) as Map<String, Object?>)
          .alDia(reloj());
    } on FormatException {
      return Cobro.sinCobro;
    }
  });
});

/// La pantalla de cobros de Jhony (entrega 26), con la misma llave.
final servicioPagosProvider = Provider<ServicioPagos>(
  (ref) => ref.watch(servicioCuentaProvider) as ServicioPagos,
);

/// Los errores de la app (entrega 27): se suben y Jhony los ve.
final servicioErroresProvider = Provider<ServicioErrores>(
  (ref) => ref.watch(servicioCuentaProvider) as ServicioErrores,
);

/// Dónde se guardan los errores hasta subirlos.
final repositorioErroresProvider = Provider<RepositorioErroresLocal>(
  (ref) => RepositorioErroresLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
  ),
);

/// El enlace fijo para bajar Moca, que va en la invitación (entrega 30).
final enlaceDescargaProvider = Provider<String>(
  (ref) => '$direccionServidor/descargar',
);

/// «Mis categorías» (entrega 31).
final repositorioCategoriasProvider = Provider<RepositorioCategorias>(
  (ref) => RepositorioCategoriasLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
  ),
);

final categoriasDelNegocioProvider = StreamProvider<List<CategoriaDelNegocio>>(
  (ref) => ref.watch(repositorioCategoriasProvider).observar(),
);

/// Por qué el teléfono perdió el acceso al negocio (entrega 37); nulo si
/// lo tiene.
final sinAccesoProvider = StreamProvider<SinAcceso?>((ref) {
  final acceso = AccesoLocal(
    ref.watch(baseLocalProvider),
    ref.watch(relojProvider),
  );
  return acceso.cambios().asyncMap((_) async {
    final guardado = await acceso.leerAjuste(AccesoLocal.claveSinAcceso);
    if (guardado == null) return null;
    try {
      return SinAcceso.desdeJson(jsonDecode(guardado) as Map<String, Object?>);
    } on FormatException {
      return const SinAcceso(motivo: MotivoSinAcceso.sinNegocio, negocio: '');
    }
  });
});

/// «Datos del negocio» (entrega 29.1).
final repositorioNegocioProvider = Provider<RepositorioNegocio>(
  (ref) => RepositorioNegocioLocal(
    ref.watch(baseLocalProvider),
    ahora: ref.watch(relojProvider),
  ),
);

/// La versión instalada (entrega 26.3); las pruebas la fijan.
final versionInstaladaProvider = Provider<VersionInstalada>(
  (ref) => VersionInstalada.delArmado(),
);

/// Pregunta al servidor por la última versión publicada.
final servicioVersionProvider = Provider<ServicioVersion>(
  (ref) => ref.watch(servicioCuentaProvider) as ServicioVersion,
);

/// La última versión que se supo y si hoy se dijo «Ahora no».
final versionPublicadaProvider =
    StreamProvider<(EstadoDeVersion, bool ahoraNo)>((ref) {
      final reloj = ref.watch(relojProvider);
      final acceso = AccesoLocal(ref.watch(baseLocalProvider), reloj);
      return acceso.cambios().asyncMap((_) async {
        final hoy = reloj().toIso8601String().substring(0, 10);
        final ahoraNo =
            await acceso.leerAjuste(AccesoLocal.claveVersionAhoraNo) == hoy;
        final guardada = await acceso.leerAjuste(AccesoLocal.claveVersion);
        if (guardada == null) return (const EstadoDeVersion(), ahoraNo);
        try {
          final v = jsonDecode(guardada) as Map<String, Object?>;
          return (
            EstadoDeVersion(
              minima: v['minima'] as int?,
              obligatoriaDesde: v['obligatoria_desde'] as String?,
              ultima: v['armado'] == null
                  ? null
                  : VersionPublicada(
                      nombre: v['nombre'] as String? ?? '',
                      armado: v['armado']! as int,
                      arm64: v['arm64'] as String?,
                      v7a: v['v7a'] as String?,
                    ),
            ),
            ahoraNo,
          );
        } on FormatException {
          return (const EstadoDeVersion(), ahoraNo);
        }
      });
    });

/// Si una versión obligatoria deja anotar (entrega 34).
final bloqueoPorVersionProvider = Provider<BloqueoPorVersion>((ref) {
  final (estado, _) =
      ref.watch(versionPublicadaProvider).value ??
      (const EstadoDeVersion(), false);
  return estado.bloqueo(
    ref.watch(versionInstaladaProvider),
    hoy: ref.watch(relojProvider)().toIso8601String().substring(0, 10),
    admin: ref.watch(cobroProvider).value?.admin ?? false,
    conSenal: ref.watch(hayConexionProvider).value ?? true,
  );
});

/// «Ahora no»: el aviso se esconde hasta mañana.
final guardarAhoraNoVersionProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => AccesoLocal(ref.read(baseLocalProvider), ref.read(relojProvider))
          .guardarAjuste(
            AccesoLocal.claveVersionAhoraNo,
            ref.read(relojProvider)().toIso8601String().substring(0, 10),
          ),
);

/// Pregunta por la última versión cada vez que se abre o se vuelve a la
/// app, con señal (entrega 34; antes, una vez al día), y la guarda.
final revisarVersionProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final reloj = ref.read(relojProvider);
    final acceso = AccesoLocal(ref.read(baseLocalProvider), reloj);
    final hoy = reloj().toIso8601String().substring(0, 10);
    final estado = await ref
        .read(servicioVersionProvider)
        // Jhony ve también las entregas: se espera a saber si es su teléfono.
        .buscarVersion(todas: (await ref.read(cobroProvider.future)).admin);
    if (estado == null) return;
    final u = estado.ultima;
    // El día en que se supo de esta mínima: se conserva mientras no cambie.
    // El día en que se supo de esta mínima: se conserva mientras no cambie.
    // Sale de lo que ya se leyó, sin volver a leer la base.
    final (antes, _) =
        ref.read(versionPublicadaProvider).value ??
        (const EstadoDeVersion(), false);
    final desde = antes.minima == estado.minima ? antes.obligatoriaDesde : null;
    await acceso.guardarAjuste(
      AccesoLocal.claveVersion,
      jsonEncode({
        'minima': estado.minima,
        if (estado.minima != null) 'obligatoria_desde': desde ?? hoy,
        if (u != null) ...{
          'nombre': u.nombre,
          'armado': u.armado,
          'arm64': u.arm64,
          'v7a': u.v7a,
        },
      }),
    );
    await acceso.guardarAjuste(AccesoLocal.claveVersionRevisada, hoy);
  };
});

/// La pregunta del día 10: la lleva el mismo servicio de la cuenta.
final servicioCobroProvider = Provider<ServicioCobro>(
  (ref) => ref.watch(servicioCuentaProvider) as ServicioCobro,
);

/// Lo que el rol de quien usa el teléfono le deja ver y hacer (entrega 20).
final permisosProvider = StreamProvider<Permisos>((ref) {
  final reloj = ref.watch(relojProvider);
  final acceso = AccesoLocal(ref.watch(baseLocalProvider), reloj);
  return acceso.cambios().asyncMap((_) async {
    final cobro = await acceso.leerAjuste(AccesoLocal.claveCobro);
    var soloAnotar = false;
    if (cobro != null) {
      try {
        soloAnotar = Cobro.desdeServidor(
          jsonDecode(cobro) as Map<String, Object?>,
        ).alDia(reloj()).soloAnotar;
      } on FormatException {
        soloAnotar = false;
      }
    }
    return Permisos(
      await acceso.miRol(),
      misCajas: await acceso.misCajas(),
      titular: await acceso.soyTitular(),
      soloAnotar: soloAnotar,
    );
  });
});

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
