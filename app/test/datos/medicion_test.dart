import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/acceso_local.dart';
import 'package:moca/datos/repositorios/medicion_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/medicion.dart';
import 'package:moca/dominio/modelos.dart';

void main() {
  late BaseLocal base;
  var ahora = DateTime(2026, 10, 12, 21);

  setUp(() => base = BaseLocal(NativeDatabase.memory()));
  tearDown(() => base.close());

  test('Mide cuánto tarda la venta y exporta sin montos', () async {
    final medicion = MedicionLocal(base, ahora: () => ahora);
    await medicion.anotar(EventoMedicion.ventaAbierta, {'modo': 'voz'});
    ahora = ahora.add(const Duration(seconds: 8));
    await RepositorioPrimerDiaLocal(
      base,
      ahora: () => ahora,
    ).anotarPrimeraVenta({TipoCuenta.efectivo: 35000}, fuente: Fuente.voz);
    await medicion.anotar(EventoMedicion.ventaGuardada, {'modo': 'voz'});

    final csv = await medicion.exportarCsv();
    final lineas = csv.split('\n');
    expect(lineas.first, 'fecha,evento,detalle');
    expect(csv, contains('ventaGuardada'));
    expect(csv, contains('""segundos"":8'));
    expect(csv, contains('registro_crear'));
    expect(csv, contains('""fuente"":""voz""'));
    // Ni montos ni nombres.
    expect(csv, isNot(contains('35000')));
    expect(csv, isNot(contains('montoCentimos')));
  });

  test('En la Demo no se mide', () async {
    await AccesoLocal(
      base,
      () => ahora,
    ).guardarAjuste(AccesoLocal.claveModo, AccesoLocal.modoDemo);
    await MedicionLocal(
      base,
      ahora: () => ahora,
    ).anotar(EventoMedicion.appAbierta);
    expect(await base.select(base.eventosMedicion).get(), isEmpty);
  });
}
