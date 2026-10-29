/// Lo que se mide en la prueba con pilotos (docs/prototipo-v1.md,
/// «Medición»). Nunca se guardan montos, nombres ni números de celular.
enum EventoMedicion {
  appAbierta,

  /// Se abrió «Anotar la venta» (por voz o escrita).
  ventaAbierta,

  /// Se guardó la venta del día; lleva los segundos desde que se abrió.
  ventaGuardada,
  vozConDuda,
  vozCorregida,
  fotoIlegible,
  arqueoAbierto,
  informeAbierto,

  /// Lleva para quién era el PDF (entrega 14.12).
  pdfCompartido,

  /// Se compartió el Excel de las operaciones (entrega 14.13).
  excelCompartido,
  mocaAbierta,
  resumenEscuchado,
  avisoTocado,

  /// Respuesta al aviso de cierre desde la notificación.
  notificacionRespondida,
  notificacionAbierta,

  /// Se abrió un video de ayuda; lleva su número y desde dónde (entrega
  /// 14.6). Es lo único de la medición que se sube al servidor.
  videoAbierto,

  /// Se comprobó el código de la cuenta; lleva si llegó solo del SMS
  /// (entrega 14.7).
  codigoComprobado,
}

abstract interface class Medicion {
  /// No hace nada en la Demo.
  Future<void> anotar(EventoMedicion evento, [Map<String, Object?> datos]);

  /// Los eventos y los cambios de la bitácora (sin montos), en CSV.
  Future<String> exportarCsv();
}
