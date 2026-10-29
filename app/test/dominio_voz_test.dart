import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/equipo.dart';
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

  test('«Por Plin» sin Plin en el negocio se pregunta', () {
    const l = LecturaVoz(
      textoDicho: 'vendí 300 por plin',
      tipo: TipoMovimiento.ingreso,
      partidas: [PartidaVoz(30000, TipoCuenta.plin)],
      categoria: 'Otros',
    );
    expect(
      siguientePregunta(
        l,
        categoriasValidas: validas,
        cuentasValidas: {...TipoCuenta.basicas},
      ),
      isA<PreguntaCuenta>(),
    );
    expect(
      siguientePregunta(
        l,
        categoriasValidas: validas,
        cuentasValidas: {...TipoCuenta.basicas, TipoCuenta.plin},
      ),
      isNull,
    );
  });

  test('Lo que ve y hace cada rol (entrega 20)', () {
    const dueno = Permisos(Rol.dueno);
    const encargado = Permisos(Rol.encargado);
    const ayudante = Permisos(Rol.ayudante);
    const contador = Permisos(Rol.contador);
    expect([dueno, encargado, ayudante, contador].map((p) => p.anota), [
      true,
      true,
      true,
      false,
    ]);
    expect([dueno, encargado, ayudante, contador].map((p) => p.veInformes), [
      true,
      false,
      false,
      true,
    ]);
    // El encargado y el ayudante ven sus cajas, no todo (entrega 21).
    expect([dueno, encargado, ayudante, contador].map((p) => p.veSaldos), [
      true,
      false,
      false,
      true,
    ]);
    expect(ayudante.misCajas, {TipoCuenta.efectivo});
    expect(dueno.misCajas, isNull);
    const conDelivery = Permisos(Rol.ayudante, misCajas: {TipoCuenta.caja2});
    expect(conDelivery.puedeUsar(TipoCuenta.caja2), isTrue);
    expect(conDelivery.puedeUsar(TipoCuenta.efectivo), isFalse);
    expect(conDelivery.puedeUsar(TipoCuenta.yape), isTrue);
    expect(dueno.puedeUsar(TipoCuenta.caja3), isTrue);
    expect([dueno, encargado, ayudante, contador].map((p) => p.haceArqueo), [
      true,
      true,
      false,
      false,
    ]);
    expect(dueno.puedeCambiar(deOtro: true, delDia: false), isTrue);
    expect(encargado.puedeCambiar(deOtro: true, delDia: false), isTrue);
    expect(ayudante.puedeCambiar(deOtro: false, delDia: true), isTrue);
    expect(ayudante.puedeCambiar(deOtro: false, delDia: false), isFalse);
    expect(ayudante.puedeCambiar(deOtro: true, delDia: true), isFalse);
    expect(contador.puedeCambiar(deOtro: false, delDia: true), isFalse);
    expect(ayudante.soloLoDeHoy, isTrue);
    expect(encargado.anotaLoDelDueno, isFalse);
  });
}
