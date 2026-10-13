import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdatos;
import 'package:timezone/timezone.dart' as tz;

import '../datos/local/base_local.dart';
import '../datos/repositorios/medicion_local.dart';
import '../datos/repositorios/repositorio_aviso_cierre_local.dart';
import '../dominio/aviso_cierre.dart';
import '../dominio/medicion.dart';
import '../dominio/modelos.dart';
import '../dominio/servicios.dart';
import '../pais/peru/formato.dart';
import '../textos/textos.dart';

// El aviso de cierre (S05) con las notificaciones del teléfono. La venta se
// contesta escribiendo en la misma notificación; si la app no está abierta,
// Android despierta este código en segundo plano.

final _plugin = FlutterLocalNotificationsPlugin();

const _icono = 'ic_notificacion';
const _azul = Color(0xFF1D4ED8);

/// La notificación que va cambiando mientras se contesta.
const _idConversacion = 900;
const _idArqueo = 901;

const _accionDecir = 'decir';
const _accionHoyNoAbri = 'hoy_no_abri';
const _accionArqueo = 'hacer_arqueo';
String _accionEscribir(TipoCuenta c) => 'escribir_${c.name}';
String _accionNada(TipoCuenta c) => 'nada_${c.name}';

const _cargaCierre = 'cierre';
const _cargaEscrita = 'venta_escrita';
const _cargaArqueo = 'arqueo';
const _cargaRegistrar = 'registrar';
const _cargaMoca = 'moca';

AndroidNotificationDetails _detalles({
  List<AndroidNotificationAction> acciones = const [],
  bool importante = true,
}) => AndroidNotificationDetails(
  importante ? 'cierre' : 'avisos',
  importante ? Textos.canalCierre : Textos.canalAvisos,
  channelDescription: importante
      ? Textos.canalCierreDetalle
      : Textos.canalAvisosDetalle,
  importance: importante ? Importance.high : Importance.defaultImportance,
  priority: importante ? Priority.high : Priority.defaultPriority,
  icon: _icono,
  color: _azul,
  actions: acciones,
);

AndroidNotificationAction _escribir(TipoCuenta cuenta) =>
    AndroidNotificationAction(
      _accionEscribir(cuenta),
      Textos.escribirlo,
      inputs: const [AndroidNotificationActionInput(label: Textos.soles)],
    );

Future<void> _preguntar(TipoCuenta cuenta) => _plugin.show(
  id: _idConversacion,
  title: Textos.nombreApp,
  body: Textos.preguntaVentaCuenta(cuenta),
  payload: _cargaEscrita,
  notificationDetails: NotificationDetails(
    android: _detalles(
      acciones: [
        _escribir(cuenta),
        AndroidNotificationAction(_accionNada(cuenta), Textos.nadaPor(cuenta)),
      ],
    ),
  ),
);

/// Contesta una notificación con la base que se le pase: la de la app si
/// está abierta, o una propia en segundo plano. Devuelve a dónde ir si hay
/// que abrir la app.
Future<DestinoNotificacion?> procesarRespuesta(
  NotificationResponse r,
  BaseLocal base, {
  DateTime Function()? ahora,
}) async {
  final repo = RepositorioAvisoCierreLocal(base, ahora: ahora);
  final medicion = MedicionLocal(base, ahora: ahora);
  final accion = r.actionId;

  if (accion == null || accion.isEmpty) {
    await medicion.anotar(EventoMedicion.notificacionAbierta, {
      'tipo': r.payload,
    });
    return switch (r.payload) {
      _cargaCierre || _cargaEscrita => DestinoNotificacion.ventaEscrita,
      _cargaArqueo => DestinoNotificacion.arqueo,
      _cargaRegistrar => DestinoNotificacion.registrar,
      _cargaMoca => DestinoNotificacion.moca,
      _ => null,
    };
  }
  await medicion.anotar(EventoMedicion.notificacionRespondida, {
    'accion': accion,
  });
  if (accion == _accionDecir) return DestinoNotificacion.ventaPorVoz;
  if (accion == _accionArqueo) return DestinoNotificacion.arqueo;

  if (accion == _accionHoyNoAbri) {
    await repo.hoyNoAbri();
  } else {
    for (final cuenta in TipoCuenta.values) {
      final escribio = accion == _accionEscribir(cuenta);
      if (!escribio && accion != _accionNada(cuenta)) continue;
      final paso = await repo.responderVenta(cuenta, escribio ? r.input : null);
      switch (paso) {
        case PreguntarCuenta(:final cuenta):
          await _preguntar(cuenta);
        case MontoNoEntendido():
          await _plugin.show(
            id: _idConversacion,
            title: Textos.nombreApp,
            body: Textos.noEntendiElMonto,
            payload: _cargaEscrita,
            notificationDetails: NotificationDetails(android: _detalles()),
          );
        case VentaLista(:final ventaDeHoyCentimos, :final tocaArqueo):
          await _plugin.show(
            id: _idConversacion,
            title: Textos.nombreApp,
            body: Textos.listoHoyVendiste(formatearSoles(ventaDeHoyCentimos)),
            notificationDetails: NotificationDetails(
              android: _detalles(importante: false),
            ),
          );
          if (tocaArqueo) {
            await _plugin.show(
              id: _idArqueo,
              title: Textos.nombreApp,
              body: Textos.mocaTocaArqueo,
              payload: _cargaArqueo,
              notificationDetails: NotificationDetails(
                android: _detalles(
                  acciones: const [
                    AndroidNotificationAction(
                      _accionArqueo,
                      Textos.hacerArqueo,
                      showsUserInterface: true,
                    ),
                  ],
                ),
              ),
            );
          }
      }
    }
  }
  await _programar(await repo.plan());
  return null;
}

/// Android llama a esta función cuando se contesta una notificación con la
/// app cerrada. Corre aparte de la app: abre su propia conexión a la base.
@pragma('vm:entry-point')
Future<void> responderEnSegundoPlano(NotificationResponse r) async {
  DartPluginRegistrant.ensureInitialized();
  tzdatos.initializeTimeZones();
  final base = BaseLocal();
  try {
    await procesarRespuesta(r, base);
  } finally {
    await base.close();
  }
}

Future<void> _programar(List<NotificacionProgramada> plan) async {
  await _plugin.cancelAllPendingNotifications();
  for (final n in plan) {
    final (cuerpo, carga, acciones) = switch (n.tipo) {
      TipoNotificacion.cierre => (
        Textos.preguntaVentaCuenta(TipoCuenta.efectivo),
        _cargaCierre,
        [
          const AndroidNotificationAction(
            _accionDecir,
            Textos.decirlo,
            showsUserInterface: true,
          ),
          _escribir(TipoCuenta.efectivo),
          const AndroidNotificationAction(_accionHoyNoAbri, Textos.hoyNoAbri),
        ],
      ),
      TipoNotificacion.faltaArqueo => (
        Textos.mocaFaltaArqueo,
        _cargaArqueo,
        const <AndroidNotificationAction>[],
      ),
      TipoNotificacion.diasSinAnotar => (
        '${Textos.avisoDias(n.dias ?? 2)}.',
        _cargaRegistrar,
        const <AndroidNotificationAction>[],
      ),
      TipoNotificacion.resumenSemanal => (
        Textos.resumenListo,
        _cargaMoca,
        const <AndroidNotificationAction>[],
      ),
    };
    await _plugin.zonedSchedule(
      id: n.id,
      title: Textos.nombreApp,
      body: cuerpo,
      payload: carga,
      // El aviso puede llegar unos minutos tarde: así no hace falta el
      // permiso de alarmas exactas.
      scheduledDate: tz.TZDateTime.from(n.cuando, tz.UTC),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: _detalles(
          acciones: acciones,
          importante: n.tipo == TipoNotificacion.cierre,
        ),
      ),
    );
  }
}

class NotificadorAndroid implements Notificador {
  NotificadorAndroid(this._base);

  final BaseLocal _base;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> iniciar({
    required void Function(DestinoNotificacion destino) alAbrir,
  }) async {
    try {
      tzdatos.initializeTimeZones();
      Future<void> responder(NotificationResponse r) async {
        final destino = await procesarRespuesta(r, _base);
        if (destino != null) alAbrir(destino);
      }

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_icono),
        ),
        onDidReceiveNotificationResponse: responder,
        onDidReceiveBackgroundNotificationResponse: responderEnSegundoPlano,
      );
      // Si la app se abrió tocando una notificación.
      final inicio = await _plugin.getNotificationAppLaunchDetails();
      final respuesta = inicio?.notificationResponse;
      if (inicio?.didNotificationLaunchApp == true && respuesta != null) {
        await responder(respuesta);
      }
    } on Exception {
      // Sin notificaciones (por ejemplo, en pruebas): la app sigue igual.
    }
  }

  @override
  Future<bool> pedirPermiso() async {
    try {
      return await _android?.requestNotificationsPermission() ?? false;
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> programar(List<NotificacionProgramada> plan) async {
    try {
      await _programar(plan);
    } on Exception {
      return;
    }
  }
}
