import 'package:flutter_test/flutter_test.dart';
import 'package:moca/pais/peru/formato.dart';

void main() {
  group('Soles', () {
    test('Soles enteros con el símbolo pegado y separador de miles', () {
      expect(formatearSoles(425000), 'S/ 4,250');
      expect(formatearSoles(0), 'S/ 0');
      expect(formatearSoles(123456700), 'S/ 1,234,567');
    });

    test('Los céntimos se redondean al sol', () {
      expect(formatearSoles(35049), 'S/ 350');
      expect(formatearSoles(35050), 'S/ 351');
    });

    test('Los negativos llevan el signo menos tipográfico', () {
      expect(formatearSoles(-98000), '−S/ 980');
    });

    test('Lo escrito en un campo se lee en céntimos', () {
      expect(leerSolesEnCentimos('1,200'), 120000);
      expect(leerSolesEnCentimos(''), isNull);
      expect(leerSolesEnCentimos('0'), 0);
    });
  });

  group('Celular', () {
    test('9 dígitos que empiezan con 9', () {
      expect(esCelularValido('987654321'), isTrue);
      expect(esCelularValido('887654321'), isFalse);
      expect(esCelularValido('98765432'), isFalse);
      expect(esCelularValido('9876543210'), isFalse);
    });

    test('Se muestra en grupos de tres', () {
      expect(formatearCelular('987654321'), '987 654 321');
      expect(formatearCelular('9876'), '987 6');
    });
  });

  test('La hora se muestra como en Perú', () {
    expect(formatearHora(21 * 60), '9:00 p. m.');
    expect(formatearHora(7 * 60 + 30), '7:30 a. m.');
    expect(formatearHora(12 * 60), '12:00 p. m.');
    expect(formatearHora(0), '12:00 a. m.');
  });

  test('Los días del Historial', () {
    final hoy = DateTime(2026, 10, 13, 21);
    expect(
      formatearDiaHistorial(DateTime(2026, 10, 13, 8), hoy),
      'Hoy · martes 13',
    );
    expect(
      formatearDiaHistorial(DateTime(2026, 10, 12), hoy),
      'Ayer · lunes 12',
    );
    expect(formatearDiaHistorial(DateTime(2026, 10, 9), hoy), 'Viernes 9');
    expect(
      formatearDiaHistorial(DateTime(2026, 9, 28), hoy),
      'Lunes 28 de setiembre',
    );
    expect(
      formatearDiaHistorial(DateTime(2025, 12, 29), hoy),
      'Lunes 29 de diciembre de 2025',
    );
    expect(
      formatearDiaHistorial(DateTime(2026, 11, 1), DateTime(2026, 11, 2)),
      'Ayer · domingo 1',
    );
    expect(
      formatearDiaHistorial(DateTime(2026, 10, 31), DateTime(2026, 11, 1)),
      'Ayer · sábado 31',
    );
  });
}
