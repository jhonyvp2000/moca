import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/historial.dart';
import 'package:moca/dominio/modelos.dart';

void main() {
  FilaHistorial fila({
    String? nota,
    String? proveedor,
    String? categoria,
    int centimos = 8000,
    TipoCuenta cuenta = TipoCuenta.efectivo,
    bool deOtro = false,
    String? autor,
  }) => FilaHistorial(
    id: 'x',
    tipo: TipoMovimiento.egreso,
    montoCentimos: centimos,
    fecha: DateTime(2026, 11, 9),
    cuenta: cuenta,
    loDebes: false,
    porSubir: false,
    nota: nota,
    proveedor: proveedor,
    categoria: categoria,
    deOtro: deOtro,
    autorNombre: autor,
  );
  bool busca(String texto, FilaHistorial f) =>
      FiltrosDelHistorial(texto: texto).cumple(f, cuenta: (c) => c.name);

  test('Cada palabra tiene que estar, en cualquier orden (entrega 39)', () {
    final jhony = fila(proveedor: 'Jhony Salar Vela');
    expect(busca('Jhony Vela', jhony), isTrue);
    expect(busca('vela jhony', jhony), isTrue);
    expect(busca('Jhony Paredes', jhony), isFalse);
    // Sin tildes ni mayúsculas, y en distintos lugares del registro.
    final luz = fila(nota: 'Recibo de luz', categoria: 'Servicios (luz, agua)');
    expect(busca('RECIBO servicios', luz), isTrue);
    expect(busca('mercaderia', fila(categoria: 'Mercadería')), isTrue);
    // El monto: «80» trae S/ 80 y S/ 80.50; «80.50», solo ese.
    expect(busca('luz 80', luz), isTrue);
    expect(busca('80', fila(centimos: 8050)), isTrue);
    expect(busca('80.50', fila(centimos: 8050)), isTrue);
    expect(busca('80,5', fila(centimos: 8050)), isTrue);
    expect(busca('80.50', fila(centimos: 8000)), isFalse);
    expect(busca('luz 90', luz), isFalse);
    // Quién lo anotó.
    expect(busca('rosa', fila(deOtro: true, autor: 'Rosa')), isTrue);
  });

  test('Los filtros de cuenta, categoría y persona se suman', () {
    final f = fila(
      categoria: 'Mercadería',
      cuenta: TipoCuenta.yape,
      deOtro: true,
      autor: 'Rosa',
    );
    bool cumple(FiltrosDelHistorial filtros) =>
        filtros.cumple(f, cuenta: (c) => c.name);
    expect(
      cumple(const FiltrosDelHistorial(cuentas: {TipoCuenta.yape})),
      isTrue,
    );
    expect(
      cumple(const FiltrosDelHistorial(cuentas: {TipoCuenta.efectivo})),
      isFalse,
    );
    expect(
      cumple(
        const FiltrosDelHistorial(
          cuentas: {TipoCuenta.yape},
          categorias: {'Mercadería'},
          personas: {'Rosa'},
        ),
      ),
      isTrue,
    );
    expect(cumple(const FiltrosDelHistorial(personas: {'yo'})), isFalse);
    const tres = FiltrosDelHistorial(
      texto: 'x',
      cuentas: {TipoCuenta.yape},
      categorias: {'a'},
      personas: {'yo'},
    );
    expect(tres.puestos, 3);
    expect(tres.sinHoja().puestos, 0);
    expect(const FiltrosDelHistorial().vacios, isTrue);
  });
}
