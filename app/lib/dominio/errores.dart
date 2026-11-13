// Los errores de la app (entrega 27): solo lo técnico, nada de lo anotado.

/// Un error como lo guarda el teléfono hasta subirlo. Los iguales (misma
/// firma) se juntan y cuentan.
class ErrorAnotado {
  const ErrorAnotado({
    required this.id,
    required this.firma,
    required this.mensaje,
    required this.veces,
    required this.primera,
    required this.ultima,
    this.pila,
    this.pantalla,
    this.entrega,
    this.armado,
  });

  factory ErrorAnotado.desdeJson(Map<String, Object?> j) => ErrorAnotado(
    id: j['id']! as String,
    firma: j['firma']! as String,
    mensaje: j['mensaje']! as String,
    pila: j['pila'] as String?,
    pantalla: j['pantalla'] as String?,
    entrega: j['entrega'] as String?,
    armado: j['armado'] as int?,
    veces: j['veces'] as int? ?? 1,
    primera: DateTime.parse(j['primera']! as String),
    ultima: DateTime.parse(j['ultima']! as String),
  );

  final String id;

  /// El mismo error en el mismo lugar tiene la misma firma.
  final String firma;
  final String mensaje;
  final String? pila;
  final String? pantalla;
  final String? entrega;
  final int? armado;
  final int veces;
  final DateTime primera;
  final DateTime ultima;

  ErrorAnotado otraVez(DateTime cuando) => ErrorAnotado(
    id: id,
    firma: firma,
    mensaje: mensaje,
    pila: pila,
    pantalla: pantalla,
    entrega: entrega,
    armado: armado,
    veces: veces + 1,
    primera: primera,
    ultima: cuando,
  );

  Map<String, Object?> json() => {
    'id': id,
    'firma': firma,
    'mensaje': mensaje,
    'pila': pila,
    'pantalla': pantalla,
    'entrega': entrega,
    'armado': armado,
    'veces': veces,
    'primera': primera.toUtc().toIso8601String(),
    'ultima': ultima.toUtc().toIso8601String(),
  };
}

/// Lo que ve Jhony: los iguales de todos los teléfonos, en una fila.
class ErrorAgrupado {
  const ErrorAgrupado({
    required this.mensaje,
    required this.veces,
    required this.negocios,
    required this.personas,
    required this.ultima,
    this.pila,
    this.pantalla,
    this.entrega,
    this.armado,
  });

  final String mensaje;
  final int veces;
  final int negocios;
  final int personas;
  final DateTime ultima;
  final String? pila;
  final String? pantalla;
  final String? entrega;
  final int? armado;
}

abstract interface class ServicioErrores {
  /// Sube los que esperan en el teléfono; falso sin cuenta o sin señal.
  Future<bool> subirErrores();

  /// Los de los últimos 90 días; nulo sin señal o sin permiso.
  Future<List<ErrorAgrupado>?> errores();
}
