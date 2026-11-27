import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/informe.dart';
import 'package:moca/pais/peru/flujo_credito.dart';
import 'package:moca/textos/textos.dart';

/// Todo el texto de un .xlsx, para buscar en él.
String textoDelXlsx(List<int> bytes) => ZipDecoder()
    .decodeBytes(bytes)
    .files
    .where((f) => f.isFile && f.name.endsWith('.xml'))
    .map((f) => utf8.decode(f.content as List<int>))
    .join('\n');

void main() {
  test('Entrega 95: el flujo de caja lleva la página de Moca al pie', () {
    final flujo = FlujoParaCredito(
      meses: [
        for (var m = 5; m <= 10; m++)
          MesDelFlujo(mes: DateTime(2026, m), estado: EstadoMesFlujo.completo),
      ],
    );
    final texto = textoDelXlsx(
      armarFlujoParaCredito(
        flujo,
        nombreNegocio: 'Comercial Terra',
        hoy: DateTime(2026, 11, 24),
      ),
    );
    expect(
      texto,
      contains(
        'Comercial Terra · Hecho con Moca el martes 24 de noviembre · '
        'mocanegocios.com',
      ),
    );
    expect(
      texto,
      contains('Hecho con Moca el martes 24 de noviembre · mocanegocios.com'),
    );
  });

  test('Entrega 95: el pie del informe (PDF y Excel) lleva la página', () {
    expect(Textos.pieDelPdf, endsWith('· mocanegocios.com'));
  });
}
