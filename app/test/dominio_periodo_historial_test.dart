import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/historial.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/textos/textos.dart';

void main() {
  FilaHistorial fila(DateTime fecha) => FilaHistorial(
    id: '$fecha',
    tipo: TipoMovimiento.ingreso,
    montoCentimos: 100,
    fecha: fecha,
    cuenta: TipoCuenta.efectivo,
    loDebes: false,
    porSubir: false,
  );
  String cuenta(TipoCuenta c) => c.name;

  test('Un día: de medianoche a medianoche', () {
    final p = PeriodoHistorial.dia(DateTime(2026, 11, 10, 15));
    expect(p.contiene(DateTime(2026, 11, 10)), isTrue);
    expect(p.contiene(DateTime(2026, 11, 10, 23, 59)), isTrue);
    expect(p.contiene(DateTime(2026, 11, 11)), isFalse);
    expect(p.contiene(DateTime(2026, 11, 9, 23, 59)), isFalse);
    expect(p.mover(-1), PeriodoHistorial.dia(DateTime(2026, 11, 9)));
  });

  test('Un mes y un año, con el cambio de año', () {
    final dic = PeriodoHistorial.mes(DateTime(2026, 12, 5));
    expect(dic.contiene(DateTime(2026, 12, 31, 23)), isTrue);
    expect(dic.contiene(DateTime(2027, 1, 1)), isFalse);
    expect(dic.mover(1), PeriodoHistorial.mes(DateTime(2027)));
    final anio = PeriodoHistorial.anio(2026);
    expect(anio.contiene(DateTime(2026)), isTrue);
    expect(anio.contiene(DateTime(2027)), isFalse);
    expect(anio.mover(-1), PeriodoHistorial.anio(2025));
  });

  test('Entre fechas: los dos días incluidos, y no se mueve', () {
    final p = PeriodoHistorial.rango(
      DateTime(2026, 10, 28),
      DateTime(2026, 11, 3),
    );
    expect(p.contiene(DateTime(2026, 10, 28)), isTrue);
    expect(p.contiene(DateTime(2026, 11, 3, 22)), isTrue);
    expect(p.contiene(DateTime(2026, 11, 4)), isFalse);
    expect(p.ultimoDia, DateTime(2026, 11, 3));
    expect(p.mover(1), p);
  });

  test('El periodo cuenta en «Filtrar (N)» y filtra', () {
    final f = FiltrosDelHistorial(
      periodo: PeriodoHistorial.dia(DateTime(2026, 11, 10)),
    );
    expect(f.puestos, 1);
    expect(f.vacios, isFalse);
    expect(f.cumple(fila(DateTime(2026, 11, 10, 9)), cuenta: cuenta), isTrue);
    expect(f.cumple(fila(DateTime(2026, 11, 11, 9)), cuenta: cuenta), isFalse);
    expect(f.sinHoja().periodo, isNull);
    expect(f.con(sinPeriodo: true).puestos, 0);
  });

  test('«Del … al …» sin repetir el mes ni el año', () {
    expect(
      Textos.delAl(DateTime(2026, 11, 3), DateTime(2026, 11, 10)),
      'Del 3 al 10 de noviembre',
    );
    expect(
      Textos.delAl(DateTime(2026, 10, 28), DateTime(2026, 11, 3)),
      'Del 28 de octubre al 3 de noviembre',
    );
    expect(
      Textos.delAl(DateTime(2026, 12, 28), DateTime(2027, 1, 3)),
      'Del 28 de diciembre de 2026 al 3 de enero de 2027',
    );
    expect(
      Textos.delAl(DateTime(2026, 11, 3), DateTime(2026, 11, 3)),
      'El 3 de noviembre',
    );
  });
}
