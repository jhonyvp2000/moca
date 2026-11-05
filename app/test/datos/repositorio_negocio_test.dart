import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_aviso_cierre_local.dart';
import 'package:moca/datos/repositorios/repositorio_negocio_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/aviso_cierre.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/negocio.dart';
import 'package:moca/dominio/primer_dia.dart';

void main() {
  late BaseLocal base;
  late RepositorioNegocioLocal repo;
  // Lunes 12 de octubre de 2026, 10:00 a. m.
  final ahora = DateTime(2026, 10, 12, 10);

  setUp(() async {
    base = BaseLocal(NativeDatabase.memory());
    final primerDia = RepositorioPrimerDiaLocal(base, ahora: () => ahora);
    await primerDia.anotarPrimeraVenta({TipoCuenta.efectivo: 35000});
    await primerDia.seguirSinCuenta();
    await primerDia.completarAlta(
      const DatosAlta(
        nombre: 'Bodega Don Lucho',
        tipoNegocio: TipoNegocio.bodega,
        saldos: {TipoCuenta.efectivo: 100000},
        horaCierreMinutos: 21 * 60,
      ),
    );
    repo = RepositorioNegocioLocal(base, ahora: () => ahora);
  });

  tearDown(() => base.close());

  test('Guardar cambia el nombre y la hora, y queda en la bitácora', () async {
    await repo.guardar(
      const DatosDelNegocio(
        nombre: '  Bodega Lucho  ',
        horaCierreMinutos: 22 * 60 + 30,
      ),
    );
    final datos = await repo.observar().first;
    expect(datos!.nombre, 'Bodega Lucho');
    expect(datos.horaCierreMinutos, 22 * 60 + 30);
    final empresa = await base.select(base.empresas).getSingle();
    expect(empresa.tipoNegocio, TipoNegocio.bodega);
    final bitacora = await (base.select(
      base.bitacora,
    )..where((b) => b.entidad.equals('empresa'))).get();
    // La primera es la del alta.
    expect(bitacora, hasLength(2));
    final cambio = bitacora.last;
    expect(cambio.accion, AccionBitacora.editar);
    expect(cambio.valorAnterior, contains('Bodega Don Lucho'));
    expect(cambio.valorNuevo, contains('"nombre":"Bodega Lucho"'));
  });

  test('Sin cambios no anota nada; el nombre no queda vacío', () async {
    await repo.guardar(
      const DatosDelNegocio(
        nombre: 'Bodega Don Lucho',
        horaCierreMinutos: 21 * 60,
      ),
    );
    final bitacora = await (base.select(
      base.bitacora,
    )..where((b) => b.entidad.equals('empresa'))).get();
    expect(bitacora, hasLength(1), reason: 'Solo la del alta.');
    expect(
      () => repo.guardar(
        const DatosDelNegocio(nombre: '  ', horaCierreMinutos: 21 * 60),
      ),
      throwsArgumentError,
    );
  });

  test('El aviso de cierre se reprograma con la hora nueva', () async {
    final avisos = RepositorioAvisoCierreLocal(base, ahora: () => ahora);
    await repo.guardar(
      const DatosDelNegocio(
        nombre: 'Bodega Don Lucho',
        horaCierreMinutos: 19 * 60 + 15,
      ),
    );
    final cierres = (await avisos.plan()).where(
      (n) => n.tipo == TipoNotificacion.cierre,
    );
    expect(cierres.first.cuando, DateTime(2026, 10, 13, 19, 15));
  });
}
