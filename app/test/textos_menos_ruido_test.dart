import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_ajustes_local.dart';
import 'package:moca/textos/textos.dart';

void main() {
  test('«También…» bajo lo que entró y salió (entrega 59)', () {
    expect(
      Textos.tambien([
        Textos.retirastePara('S/ 3,030'),
        Textos.pusisteDeTuBolsilloMonto('S/ 500'),
      ]),
      'También retiraste S/ 3,030 para ti y pusiste S/ 500 de tu bolsillo.',
    );
    expect(
      Textos.tambien([Textos.enElArqueoFalto('S/ 20')]),
      'También en el arqueo faltaron S/ 20.',
    );
  });

  test('Cada teléfono recuerda si una sección quedó abierta', () async {
    final base = BaseLocal(NativeDatabase.memory());
    addTearDown(base.close);
    final ajustes = RepositorioAjustesLocal(base);
    expect(await ajustes.seccionAbierta('informe_mes'), isFalse);
    await ajustes.guardarSeccion('informe_mes', abierta: true);
    expect(await ajustes.seccionAbierta('informe_mes'), isTrue);
    expect(await ajustes.seccionAbierta('inicio_cuentas'), isFalse);
    await ajustes.guardarSeccion('informe_mes', abierta: false);
    expect(await ajustes.seccionAbierta('informe_mes'), isFalse);
  });

  test('Entrega 64: las cuentas del Inicio empiezan abiertas', () async {
    final base = BaseLocal(NativeDatabase.memory());
    addTearDown(base.close);
    final ajustes = RepositorioAjustesLocal(base);
    expect(
      await ajustes.seccionAbierta('inicio_cuentas', porDefecto: true),
      isTrue,
    );
    await ajustes.guardarSeccion('inicio_cuentas', abierta: false);
    expect(
      await ajustes.seccionAbierta('inicio_cuentas', porDefecto: true),
      isFalse,
    );
  });
}
