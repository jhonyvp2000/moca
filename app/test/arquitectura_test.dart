import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Las pantallas no conocen la fuente de datos (docs/prototipo-v1.md): hablan
/// con interfaces del dominio, y solo lib/inyeccion.dart elige la
/// implementación. Así, al llegar el backend, las pantallas no cambian.
void main() {
  List<(String, String)> importaciones(String carpeta) {
    final resultado = <(String, String)>[];
    final dir = Directory('lib/$carpeta');
    if (!dir.existsSync()) return resultado;
    for (final archivo in dir.listSync(recursive: true).whereType<File>()) {
      if (!archivo.path.endsWith('.dart')) continue;
      for (final linea in archivo.readAsLinesSync()) {
        final m = RegExp(r'''^import\s+['"]([^'"]+)['"]''').firstMatch(linea);
        if (m != null) resultado.add((archivo.path, m.group(1)!));
      }
    }
    return resultado;
  }

  bool apuntaA(String importacion, String carpeta) =>
      importacion.contains('/$carpeta/') ||
      importacion.startsWith('$carpeta/') ||
      importacion.startsWith('package:moca/$carpeta/');

  test('La interfaz no importa datos ni simulados', () {
    final faltas = [
      for (final carpeta in ['pantallas', 'comun', 'operador'])
        for (final (archivo, imp) in importaciones(carpeta))
          if (apuntaA(imp, 'datos') || apuntaA(imp, 'simulados'))
            '$archivo importa $imp',
    ];
    expect(faltas, isEmpty);
  });

  test('El dominio no depende de Flutter ni de los datos', () {
    final faltas = [
      for (final (archivo, imp) in importaciones('dominio'))
        if (imp.startsWith('package:flutter') ||
            imp.startsWith('package:drift') ||
            apuntaA(imp, 'datos'))
          '$archivo importa $imp',
    ];
    expect(faltas, isEmpty);
  });
}
