import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/voz.dart';
import 'package:moca/pais/peru/interprete_voz.dart';

LecturaVoz leer(
  String texto, {
  double? confianza,
  List<String> otras = const [],
  bool soloVenta = false,
}) => interpretarVoz([
  AlternativaVoz(texto, confianza),
  for (final otra in otras) AlternativaVoz(otra),
], soloVenta: soloVenta);

List<(int, TipoCuenta?)> partidas(LecturaVoz l) => [
  for (final p in l.partidas) (p.centimos, p.cuenta),
];

void main() {
  group('Ventas', () {
    test('«Hoy vendí 350 en efectivo y 120 por Yape»', () {
      final l = leer('Hoy vendí 350 en efectivo y 120 por Yape');
      expect(l.tipo, TipoMovimiento.ingreso);
      expect(l.categoria, 'Venta del día');
      expect(partidas(l), [
        (35000, TipoCuenta.efectivo),
        (12000, TipoCuenta.yape),
      ]);
    });

    test('La cuenta antes del monto: «En efectivo, trescientos cincuenta»', () {
      final l = leer('En efectivo, trescientos cincuenta', soloVenta: true);
      expect(l.tipo, TipoMovimiento.ingreso);
      expect(partidas(l), [(35000, TipoCuenta.efectivo)]);
    });

    test('Sin cuenta, el monto queda sin cuenta para preguntarla', () {
      final l = leer('hoy vendí 480');
      expect(partidas(l), [(48000, null)]);
    });

    test('«Me yapearon 50» entró por Yape', () {
      final l = leer('me yapearon 50');
      expect(l.tipo, TipoMovimiento.ingreso);
      expect(partidas(l), [(5000, TipoCuenta.yape)]);
    });

    test('Con S/ y soles', () {
      expect(partidas(leer('vendí S/ 1,200 en efectivo')), [
        (120000, TipoCuenta.efectivo),
      ]);
      expect(partidas(leer('vendí 300 soles por plin')), [
        (30000, TipoCuenta.plin),
      ]);
      expect(partidas(leer('vendí 90 por sip')), [(9000, TipoCuenta.sip)]);
      // «Sip» suelto es «sí», no la billetera.
      expect(partidas(leer('sip vendí 90')), [(9000, null)]);
    });
  });

  group('Gastos y retiros', () {
    test('«Pagué 80 de luz»', () {
      final l = leer('Pagué 80 de luz');
      expect(l.tipo, TipoMovimiento.egreso);
      expect(l.categoria, 'Servicios (luz, agua, internet, teléfono)');
      expect(partidas(l), [(8000, null)]);
    });

    test('«Compré mercadería por 950 con Yape»', () {
      final l = leer('Compré mercadería por 950 con Yape');
      expect(l.tipo, TipoMovimiento.egreso);
      expect(l.categoria, 'Mercadería');
      expect(partidas(l), [(95000, TipoCuenta.yape)]);
    });

    test('Un gasto sin categoría conocida la deja vacía', () {
      expect(leer('pagué 40 de una cosa').categoria, isNull);
    });

    test('«Saqué 100 para mí» es un retiro', () {
      final l = leer('Saqué 100 para mí del efectivo');
      expect(l.tipo, TipoMovimiento.retiro);
      expect(l.categoria, isNull);
      expect(partidas(l), [(10000, TipoCuenta.efectivo)]);
    });

    test('«Me pagaron» es ingreso aunque diga «pag»', () {
      expect(leer('me pagaron 200').tipo, TipoMovimiento.ingreso);
    });

    test('Sin verbo, no se sabe si entró o salió', () {
      expect(leer('350 en efectivo').tipo, isNull);
    });
  });

  group('Números', () {
    final casos = {
      'pagué ochenta': 8000,
      'pagué trescientos cincuenta': 35000,
      'pagué ciento veinte': 12000,
      'pagué treinta y cinco': 3500,
      'pagué dos mil quinientos': 250000,
      'pagué mil doscientos': 120000,
      'pagué un mil': 100000,
      'pagué 2 mil': 200000,
      'pagué veintidós': 2200,
      'pagué 80.50': 8050,
      'pagué 350 con 50': 35050,
      'pagué 1.200': 120000,
      'pagué cien': 10000,
    };
    for (final MapEntry(key: frase, value: centimos) in casos.entries) {
      test(frase, () {
        expect(partidas(leer(frase)).map((p) => p.$1), [centimos]);
      });
    }

    test('«un» suelto no es un monto', () {
      expect(partidas(leer('pagué un recibo de 40')), [(4000, null)]);
    });
  });

  group('Moca duda del monto (S18)', () {
    test('Dos lecturas con montos distintos', () {
      final l = leer(
        'Pagué trescientos quince de mercadería',
        otras: ['Pagué trescientos cincuenta de mercadería'],
      );
      expect(l.montoDudoso, isTrue);
      expect(l.montosPosibles, [31500, 35000]);
      expect(l.categoria, 'Mercadería');
    });

    test('La duda conserva la cuenta que sí se dijo', () {
      final l = leer('pagué 315 con yape', otras: ['pagué 350 con yape']);
      expect(l.montoDudoso, isTrue);
      expect(l.conMonto(35000).partidas.single.cuenta, TipoCuenta.yape);
    });

    test('La frase quedó cortada', () {
      final l = leer('Pagué trescientos… de mercadería');
      expect(l.montoDudoso, isTrue);
      expect(l.montosPosibles, [30000]);
    });

    test('Confianza baja', () {
      expect(leer('vendí 350', confianza: 0.3).montoDudoso, isTrue);
      expect(leer('vendí 350', confianza: 0.9).montoDudoso, isFalse);
    });

    test('Lecturas iguales no son duda', () {
      expect(
        leer('vendí 350', otras: ['vendí trescientos cincuenta']).montoDudoso,
        isFalse,
      );
    });
  });

  test('Si no hay monto, no se entendió', () {
    expect(leer('hola cómo estás').entendida, isFalse);
    expect(interpretarVoz(const []).entendida, isFalse);
  });

  group('Entrega 14.1: bancos', () {
    test('Cada banco por su nombre', () {
      expect(partidas(leer('vendí 200 por Interbank')), [
        (20000, TipoCuenta.interbank),
      ]);
      expect(partidas(leer('vendí 200 por BBVA')), [(20000, TipoCuenta.bbva)]);
      expect(partidas(leer('vendí 200 por Scotiabank')), [
        (20000, TipoCuenta.scotiabank),
      ]);
      expect(partidas(leer('vendí 200 por BCP')), [(20000, TipoCuenta.banco)]);
    });

    test('«Por transferencia» va al banco sin decir cuál', () {
      final l = leer('me pagaron 200 por transferencia');
      expect(partidas(l), [(20000, TipoCuenta.banco)]);
      expect(l.partidas.single.bancoSinNombre, isTrue);
      expect(leer('vendí 200 por BCP').partidas.single.bancoSinNombre, isFalse);
    });

    test('Con un solo banco no pregunta; con varios, pregunta cuál', () {
      final l = leer('hoy vendí 200 por transferencia');
      const basicas = {TipoCuenta.efectivo, TipoCuenta.yape, TipoCuenta.banco};
      expect(
        siguientePregunta(
          l,
          categoriasValidas: {l.categoria!},
          cuentasValidas: basicas,
        ),
        isNull,
      );
      expect(
        siguientePregunta(
          l,
          categoriasValidas: {l.categoria!},
          cuentasValidas: {...basicas, TipoCuenta.interbank},
        ),
        isA<PreguntaCuenta>(),
      );
      // Nombrar un banco que el negocio no tiene también se pregunta.
      final bbva = leer('hoy vendí 200 por BBVA');
      expect(
        siguientePregunta(
          bbva,
          categoriasValidas: {bbva.categoria!},
          cuentasValidas: basicas,
        ),
        isA<PreguntaCuenta>(),
      );
    });
  });

  group('Entrega 14.10: billeteras Plin', () {
    test('Plin con su banco, antes o después', () {
      expect(partidas(leer('vendí 200 por BBVA Plin')), [
        (20000, TipoCuenta.bbvaPlin),
      ]);
      expect(partidas(leer('vendí 200 por Plin de Scotiabank')), [
        (20000, TipoCuenta.scotiabankPlin),
      ]);
      expect(partidas(leer('vendí 200 por Interbank Plin')), [
        (20000, TipoCuenta.plin),
      ]);
      expect(
        leer('vendí 200 por BBVA Plin').partidas.single.plinSinBanco,
        isFalse,
      );
      // El banco solo sigue siendo el banco.
      expect(partidas(leer('vendí 200 por BBVA')), [(20000, TipoCuenta.bbva)]);
    });

    test('«Por Plin» va al único Plin del negocio; con varios, pregunta', () {
      final l = leer('hoy vendí 200 por Plin');
      expect(l.partidas.single.plinSinBanco, isTrue);
      const conBbvaPlin = {
        TipoCuenta.efectivo,
        TipoCuenta.yape,
        TipoCuenta.banco,
        TipoCuenta.bbvaPlin,
      };
      final una = l.conPlinDelNegocio(conBbvaPlin);
      expect(partidas(una), [(20000, TipoCuenta.bbvaPlin)]);
      expect(
        siguientePregunta(
          una,
          categoriasValidas: {una.categoria!},
          cuentasValidas: conBbvaPlin,
        ),
        isNull,
      );

      const conDos = {...conBbvaPlin, TipoCuenta.plin};
      final dos = l.conPlinDelNegocio(conDos);
      expect(
        siguientePregunta(
          dos,
          categoriasValidas: {dos.categoria!},
          cuentasValidas: conDos,
        ),
        isA<PreguntaCuenta>(),
      );
      // Al elegir, ya no pregunta.
      final elegida = dos.conCuenta(0, TipoCuenta.plin);
      expect(
        siguientePregunta(
          elegida,
          categoriasValidas: {elegida.categoria!},
          cuentasValidas: conDos,
        ),
        isNull,
      );
    });
  });
}
