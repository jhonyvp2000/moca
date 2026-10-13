import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/voz.dart';

void main() {
  const validas = {'Venta del día', 'Otros'};

  test('Moca pregunta en orden: monto, tipo, cuenta y categoría', () {
    var l = const LecturaVoz(textoDicho: '…', montosPosibles: [31500, 35000]);
    expect(
      siguientePregunta(l, categoriasValidas: validas),
      isA<PreguntaMonto>(),
    );

    l = l.conMonto(35000);
    expect(
      siguientePregunta(l, categoriasValidas: validas),
      isA<PreguntaTipo>(),
    );

    l = l.conTipo(TipoMovimiento.egreso);
    final cuenta = siguientePregunta(l, categoriasValidas: validas);
    expect(cuenta, isA<PreguntaCuenta>());
    expect((cuenta! as PreguntaCuenta).indicePartida, 0);

    l = l.conCuenta(0, TipoCuenta.yape);
    expect(
      siguientePregunta(l, categoriasValidas: validas),
      isA<PreguntaCategoria>(),
    );

    l = l.conCategoria('Otros');
    expect(siguientePregunta(l, categoriasValidas: validas), isNull);
    expect(l.partidas.single.centimos, 35000);
    expect(l.partidas.single.cuenta, TipoCuenta.yape);
  });

  test('Un retiro no pide categoría', () {
    const l = LecturaVoz(
      textoDicho: 'saqué 100 para mí',
      tipo: TipoMovimiento.retiro,
      partidas: [PartidaVoz(10000, TipoCuenta.efectivo)],
    );
    expect(siguientePregunta(l, categoriasValidas: validas), isNull);
  });

  test('Una categoría que el negocio no tiene se pregunta', () {
    const l = LecturaVoz(
      textoDicho: 'pagué 40 de gas',
      tipo: TipoMovimiento.egreso,
      partidas: [PartidaVoz(4000, TipoCuenta.efectivo)],
      categoria: 'Gas',
    );
    expect(
      siguientePregunta(l, categoriasValidas: validas),
      isA<PreguntaCategoria>(),
    );
  });
}
