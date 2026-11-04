import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/comun/pantalla_con_error.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_errores_local.dart';
import 'package:moca/dominio/errores.dart';
import 'package:moca/servicios/registro_de_errores.dart';
import 'package:moca/textos/textos.dart';

void main() {
  final ahora = DateTime(2026, 11, 4, 10);

  test('Los números largos se tapan: podrían ser un celular o un monto', () {
    expect(
      RegistroDeErrores.tapar('No se pudo con 987654321 y 12345'),
      'No se pudo con 987*** y 12345',
    );
  });

  test('El mismo error en el mismo lugar tiene la misma firma', () {
    final registro = RegistroDeErrores(ahora: () => ahora)
      ..pantalla = '/inicio'
      ..entrega = 'piloto-1'
      ..armado = 120;
    final pila = StackTrace.fromString(
      '#0 abrir (package:moca/pantallas/inicio/pantalla_inicio.dart:10:3)\n'
      '#1 main (package:moca/main.dart:5:1)',
    );
    final uno = registro.describir(StateError('se rompió 987654321'), pila)!;
    final dos = registro.describir(StateError('se rompió 987654321'), pila)!;
    expect(uno.firma, dos.firma);
    expect(uno.id, isNot(dos.id));
    expect(uno.mensaje, 'Bad state: se rompió 987***');
    expect(uno.pantalla, '/inicio');
    expect(uno.armado, 120);
    final otro = registro.describir(StateError('otra cosa'), pila)!;
    expect(otro.firma, isNot(uno.firma));
  });

  test(
    'Antes de conectarse espera en memoria; después, va a guardar',
    () async {
      final registro = RegistroDeErrores(ahora: () => ahora);
      final guardados = <ErrorAnotado>[];
      registro.anotar(StateError('temprano'), null);
      expect(guardados, isEmpty);
      registro.conectar((e) async => guardados.add(e));
      expect(guardados.single.mensaje, 'Bad state: temprano');
      registro.anotar(StateError('después'), null);
      expect(guardados, hasLength(2));
    },
  );

  test('En el teléfono, los iguales se juntan y se cuentan', () async {
    final base = BaseLocal(NativeDatabase.memory());
    addTearDown(base.close);
    final repo = RepositorioErroresLocal(base, ahora: () => ahora);
    final registro = RegistroDeErrores(ahora: () => ahora);
    final e = registro.describir(StateError('x'), null)!;
    await repo.guardar(e);
    await repo.guardar(registro.describir(StateError('x'), null)!);
    await repo.guardar(registro.describir(StateError('y'), null)!);
    final lista = await repo.porSubir();
    expect(lista.map((x) => (x.mensaje, x.veces)), [
      ('Bad state: x', 2),
      ('Bad state: y', 1),
    ]);
    await repo.quitar({e.id});
    expect((await repo.porSubir()).single.mensaje, 'Bad state: y');
  });

  testWidgets('La pantalla amable, con «Volver» si se puede volver', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: PantallaConError()),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text(Textos.algoSalioMal), findsOneWidget);
    await tester.tap(find.text(Textos.volver));
    await tester.pumpAndSettle();
    expect(find.text('abrir'), findsOneWidget);
  });
}
