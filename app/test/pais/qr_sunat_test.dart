import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/pais/peru/formato.dart';
import 'package:moca/pais/peru/qr_sunat.dart';

void main() {
  // RUC con dígito verificador válido.
  const ruc = '20100070970';

  test('El RUC se valida con su dígito verificador', () {
    expect(esRucValido(ruc), isTrue);
    expect(esRucValido('20100070971'), isFalse);
    expect(esRucValido('2010007097'), isFalse);
    expect(esRucValido('30100070970'), isFalse);
  });

  test('Lee el QR de una factura', () {
    final l = leerQrSunat(
      '$ruc|01|F001|00012345|149.49|980.00|2026-10-08|6|20481234567|',
    )!;
    expect(l.origen, OrigenLectura.qr);
    expect(l.emisorIdentificacion, ruc);
    expect(l.tipo, 'Factura');
    expect(l.serie, 'F001');
    expect(l.numero, '12345');
    expect(l.impuestoCentimos, 14949);
    expect(l.totalCentimos, 98000);
    expect(l.fechaEmision, DateTime(2026, 10, 8));
    expect(l.identificable, isTrue);
  });

  test('Acepta la fecha en formato peruano y la boleta', () {
    final l = leerQrSunat('$ruc|03|B002|851|0.00|35.5|08/10/2026|1|-|')!;
    expect(l.tipo, 'Boleta');
    expect(l.totalCentimos, 3550);
    expect(l.fechaEmision, DateTime(2026, 10, 8));
  });

  test('Un código que no es de un comprobante no se lee', () {
    expect(leerQrSunat('https://ejemplo.pe'), isNull);
    expect(leerQrSunat('20100070971|01|F001|1|0|10.00|2026-10-08'), isNull);
    expect(leerQrSunat('$ruc|99|F001|1|0|10.00|2026-10-08'), isNull);
    expect(leerQrSunat('$ruc|01|F001|1|0|0.00|2026-10-08'), isNull);
    expect(leerQrSunat('$ruc|01|F001|1|0|10.00|ayer'), isNull);
  });

  test('Montos y fechas dentro del comprobante', () {
    expect(formatearSolesComprobante(98000), 'S/ 980');
    expect(formatearSolesComprobante(14230), 'S/ 142.30');
    expect(formatearSolesComprobante(123456705), 'S/ 1,234,567.05');
    expect(formatearFechaLarga(DateTime(2026, 10, 8)), 'jueves 8 de octubre');
    expect(leerSolesConCentimos('980.5'), 98050);
    expect(leerSolesConCentimos('1,200'), 120000);
    expect(leerSolesConCentimos('abc'), isNull);
  });
}
