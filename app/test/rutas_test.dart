import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/primer_dia.dart';
import 'package:moca/rutas.dart';

void main() {
  test('Mientras se lee la etapa, se espera en blanco', () {
    expect(redirigirSegunEtapa(null, Rutas.inicio), Rutas.cargando);
    expect(redirigirSegunEtapa(null, Rutas.cargando), isNull);
  });

  test('Cada etapa lleva a su pantalla y no deja salir del camino', () {
    expect(
      redirigirSegunEtapa(EtapaInicio.bienvenida, Rutas.inicio),
      Rutas.bienvenida,
    );
    expect(
      redirigirSegunEtapa(EtapaInicio.bienvenida, Rutas.ventaDeHoy),
      isNull,
    );
    // Con la venta guardada, «atrás» no vuelve a S07.
    expect(
      redirigirSegunEtapa(EtapaInicio.guardarAvance, Rutas.ventaDeHoy),
      Rutas.guardarAvance,
    );
    expect(
      redirigirSegunEtapa(EtapaInicio.guardarAvance, Rutas.codigo),
      isNull,
    );
    expect(
      redirigirSegunEtapa(EtapaInicio.alta, Rutas.guardarAvance),
      Rutas.alta,
    );
    expect(redirigirSegunEtapa(EtapaInicio.listo, Rutas.alta), Rutas.inicio);
    expect(redirigirSegunEtapa(EtapaInicio.listo, Rutas.moca), isNull);
  });

  test('El ajuste oculto se puede abrir en cualquier etapa', () {
    for (final etapa in [null, ...EtapaInicio.values]) {
      expect(redirigirSegunEtapa(etapa, Rutas.operador), isNull);
    }
  });
}
