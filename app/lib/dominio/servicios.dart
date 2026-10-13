import 'aviso_cierre.dart';

/// La voz sintética del teléfono, para escuchar el resumen de la semana.
abstract interface class Locutor {
  /// Falso si el teléfono no tiene voz en español.
  Future<bool> disponible();

  /// Lee el texto; el futuro termina cuando acaba de hablar o se detiene.
  Future<void> decir(String texto);

  Future<void> detener();
}

/// Comparte un archivo con el menú de Android (WhatsApp, correo…).
abstract interface class Compartidor {
  Future<void> compartirArchivo(
    String ruta, {
    required String asunto,
    String tipo = 'application/pdf',
  });
}

/// Las notificaciones del teléfono: el aviso de cierre y un aviso al día.
abstract interface class Notificador {
  /// [alAbrir] recibe a dónde ir cuando el dueño toca una notificación,
  /// también si la app estaba cerrada.
  Future<void> iniciar({
    required void Function(DestinoNotificacion destino) alAbrir,
  });

  /// Pide el permiso de notificaciones (Android 13 o superior). Devuelve si
  /// quedó permitido.
  Future<bool> pedirPermiso();

  /// Reemplaza lo programado por este plan.
  Future<void> programar(List<NotificacionProgramada> plan);
}
