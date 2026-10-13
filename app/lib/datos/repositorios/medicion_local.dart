import 'dart:convert';

import 'package:drift/drift.dart';

import '../../dominio/medicion.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

class MedicionLocal implements Medicion {
  MedicionLocal(BaseLocal base, {DateTime Function()? ahora})
    : _a = AccesoLocal(base, ahora ?? DateTime.now);

  final AccesoLocal _a;
  BaseLocal get _base => _a.base;

  /// Cuándo se abrió «Anotar la venta», para medir cuánto tomó guardarla.
  DateTime? _inicioVenta;

  @override
  Future<void> anotar(
    EventoMedicion evento, [
    Map<String, Object?> datos = const {},
  ]) async {
    if (await _a.enDemo()) return;
    final ahora = _a.ahora();
    var detalle = datos;
    switch (evento) {
      case EventoMedicion.ventaAbierta:
        _inicioVenta ??= ahora;
      case EventoMedicion.ventaGuardada:
        if (_inicioVenta case final inicio?) {
          detalle = {...datos, 'segundos': ahora.difference(inicio).inSeconds};
        }
        _inicioVenta = null;
      default:
        break;
    }
    await _base
        .into(_base.eventosMedicion)
        .insert(
          EventosMedicionCompanion.insert(
            id: _a.nuevoId(),
            nombre: evento.name,
            fecha: ahora,
            datos: Value(detalle.isEmpty ? null : jsonEncode(detalle)),
          ),
        );
  }

  @override
  Future<String> exportarCsv() async {
    final filas = <(DateTime, String, String)>[];
    for (final e in await _base.select(_base.eventosMedicion).get()) {
      filas.add((e.fecha, e.nombre, e.datos ?? ''));
    }
    // De la bitácora salen solo la acción, la entidad y el tipo o la
    // fuente: nunca montos ni notas.
    for (final b in await _base.select(_base.bitacora).get()) {
      final nuevo = b.valorNuevo == null
          ? const <String, Object?>{}
          : (jsonDecode(b.valorNuevo!) as Map).cast<String, Object?>();
      final detalle = <String, Object?>{
        'entidad': b.entidad,
        'tipo': ?nuevo['tipo'],
        'fuente': ?nuevo['fuente'],
        if (nuevo['cuentas'] case final List<Object?> cuentas)
          'motivos': [
            for (final c in cuentas)
              if (c is Map && c['motivo'] != null) c['motivo'],
          ],
      };
      filas.add((b.fecha, 'registro_${b.accion.name}', jsonEncode(detalle)));
    }
    filas.sort((a, b) => a.$1.compareTo(b.$1));
    String celda(String texto) => '"${texto.replaceAll('"', '""')}"';
    return [
      'fecha,evento,detalle',
      for (final (fecha, evento, detalle) in filas)
        '${fecha.toIso8601String()},$evento,${celda(detalle)}',
    ].join('\n');
  }
}
