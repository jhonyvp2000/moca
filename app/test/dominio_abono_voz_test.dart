import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/historial.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/voz.dart';

// Entrega 50: «Cobré el fiado» descuenta la deuda.

FilaHistorial deuda(String id, String? quien, int centimos) => FilaHistorial(
  id: id,
  tipo: TipoMovimiento.ingreso,
  montoCentimos: centimos,
  fecha: DateTime(2026, 11, 1),
  cuenta: TipoCuenta.efectivo,
  loDebes: true,
  porSubir: false,
  proveedor: quien,
);

LecturaVoz cobro(int centimos, {String? quien, bool fiado = false}) =>
    LecturaVoz(
      textoDicho: '…',
      tipo: TipoMovimiento.ingreso,
      partidas: [PartidaVoz(centimos, TipoCuenta.efectivo)],
      contraparte: quien,
      pagaDeuda: fiado,
      categoria: fiado ? 'Cobro de fiado' : null,
    );

void main() {
  final deudas = agruparDeudas([
    deuda('a', 'Doña Rosa', 3000),
    deuda('b', 'Juan Pérez', 8000),
    deuda('c', 'doña rosa', 5000),
    deuda('d', null, 1000),
    deuda('e', 'Rosa María', 2000),
  ]);

  test('Se juntan por nombre, sin tildes ni mayúsculas; sin nombre no', () {
    expect(deudas.map((d) => d.nombre), [
      'Doña Rosa',
      'Juan Pérez',
      'Rosa María',
    ]);
    expect(deudas.first.deudas.map((d) => d.id), ['a', 'c']);
    expect(deudas.first.totalCentimos, 8000);
  });

  test('El nombre coincide sin «doña», sin tildes y por partes', () {
    expect(mismoNombre('Rosa', 'Doña Rosa'), isTrue);
    expect(mismoNombre('doña rosa', 'Doña Rosa'), isTrue);
    expect(mismoNombre('Juan', 'Juan Pérez'), isTrue);
    expect(mismoNombre('juan perez', 'Juan Pérez'), isTrue);
    expect(mismoNombre('Pepe', 'Doña Rosa'), isFalse);
    expect(mismoNombre('Doña', 'Doña Rosa'), isFalse);
  });

  test('Con nombre, las de esa persona; dos Rosas se eligen', () {
    expect(
      deudasPosibles(cobro(3000, quien: 'Juan'), deudas).map((d) => d.nombre),
      ['Juan Pérez'],
    );
    expect(deudasPosibles(cobro(3000, quien: 'Rosa'), deudas), hasLength(2));
  });

  test('Sin nombre o con otro nombre: todas si dijo fiado; si no, ninguna', () {
    expect(deudasPosibles(cobro(3000, fiado: true), deudas), hasLength(3));
    expect(
      deudasPosibles(cobro(3000, quien: 'Pepe', fiado: true), deudas),
      hasLength(3),
    );
    expect(deudasPosibles(cobro(3000, quien: 'Pepe'), deudas), isEmpty);
    expect(deudasPosibles(cobro(3000), deudas), isEmpty);
  });

  test('Una venta, un retiro o varios montos no buscan deuda', () {
    const varios = LecturaVoz(
      textoDicho: '…',
      tipo: TipoMovimiento.ingreso,
      partidas: [
        PartidaVoz(1000, TipoCuenta.efectivo),
        PartidaVoz(2000, TipoCuenta.yape),
      ],
      pagaDeuda: true,
    );
    expect(varios.buscaDeuda, isFalse);
    expect(cobro(3000, fiado: true).comoAparte().buscaDeuda, isFalse);
  });

  test('Se reparte desde la más antigua; la última, en parte', () {
    final rosa = deudas.first;
    List<(String, int?)> reparto(int c) => [
      for (final (f, parte) in repartirAbono(rosa, c)) (f.id, parte),
    ];
    expect(reparto(2000), [('a', 2000)]);
    expect(reparto(3000), [('a', null)]);
    expect(reparto(5000), [('a', null), ('c', 2000)]);
    expect(reparto(8000), [('a', null), ('c', null)]);
  });

  test('Moca pregunta la deuda después de la cuenta, y el monto de más', () {
    var l = cobro(3000, quien: 'Juan');
    final posibles = deudasPosibles(l, deudas);
    final p = siguientePregunta(
      l,
      categoriasValidas: const {},
      deudasPosibles: posibles,
    );
    expect(p, isA<PreguntaDeuda>());

    l = l.conAbono(posibles.single);
    expect(siguientePregunta(l, categoriasValidas: const {}), isNull);

    final demas = cobro(10000, quien: 'Juan').conAbono(posibles.single);
    expect(
      siguientePregunta(demas, categoriasValidas: const {}),
      isA<PreguntaMasDeLoQueSeDebe>(),
    );
    expect(
      siguientePregunta(demas.conMonto(8000), categoriasValidas: const {}),
      isNull,
    );

    // Aparte: como siempre, con su categoría.
    final aparte = cobro(3000, quien: 'Juan').comoAparte();
    expect(
      siguientePregunta(aparte, categoriasValidas: const {'Otros'}),
      isA<PreguntaCategoria>(),
    );
  });
}
