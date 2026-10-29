import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/local/categorias_al_dia.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/pais/peru/categorias.dart';

void main() {
  late BaseLocal base;
  var n = 0;
  String id() => 'id-${n++}';

  setUp(() async {
    base = BaseLocal(NativeDatabase.memory());
    await base
        .into(base.empresas)
        .insert(
          EmpresasCompanion.insert(
            id: 'e',
            nombre: 'Bodega',
            tipoNegocio: TipoNegocio.bodega,
            modo: ModoEmpresa.simple,
            pais: 'PE',
            moneda: 'PEN',
            horaCierreMinutos: 1260,
            creadoEn: DateTime(2026, 10),
          ),
        );
    Future<void> categoria(String cid, String nombre, TipoMovimiento tipo) =>
        base
            .into(base.categorias)
            .insert(
              CategoriasCompanion.insert(
                id: cid,
                empresaId: 'e',
                nombre: nombre,
                tipoMovimiento: tipo,
                orden: n++,
              ),
            );
    // Lo que tenía un teléfono antes de la entrega 14.14.
    await categoria('venta', 'Venta del día', TipoMovimiento.ingreso);
    await categoria('personal', 'Personal', TipoMovimiento.egreso);
    await categoria('transporte', 'Transporte', TipoMovimiento.egreso);
    await categoria('mercaderia', 'Mercadería', TipoMovimiento.egreso);
  });
  tearDown(() => base.close());

  Future<Map<String, (String, bool)>> categorias() async => {
    for (final c in await base.select(base.categorias).get())
      c.id: (c.nombre, c.activa),
  };

  test(
    'Renombra las que cambiaron y agrega las nuevas, una sola vez',
    () async {
      await ponerAlDiaCategorias(base, id);
      final despues = await categorias();
      // Los ids no cambian: lo anotado sigue en su categoría.
      expect(despues['personal'], ('Sueldos del personal', true));
      expect(despues['transporte'], ('Movilidad del negocio', true));
      expect(despues['mercaderia'], ('Mercadería', true));
      final nombres = {for (final c in despues.values) c.$1};
      expect(nombres, containsAll(categoriasComunesIngreso));
      expect(nombres, containsAll(categoriasComunesEgreso));
      expect(nombres, isNot(contains('Personal')));

      await ponerAlDiaCategorias(base, id);
      expect(await categorias(), despues);
    },
  );

  test('Si ya estaba la nueva, lo anotado pasa a ella y la vieja queda '
      'inactiva', () async {
    await base
        .into(base.categorias)
        .insert(
          CategoriasCompanion.insert(
            id: 'sueldos',
            empresaId: 'e',
            nombre: 'Sueldos del personal',
            tipoMovimiento: TipoMovimiento.egreso,
            orden: 9,
          ),
        );
    await base.customStatement(
      "INSERT INTO usuarios (id, creado_en) VALUES ('u', 0)",
    );
    await base.customStatement(
      "INSERT INTO cuentas (id, empresa_id, tipo, nombre, orden) "
      "VALUES ('c', 'e', 'efectivo', 'Efectivo', 0)",
    );
    await base
        .into(base.movimientos)
        .insert(
          MovimientosCompanion.insert(
            id: 'm',
            empresaId: 'e',
            tipo: TipoMovimiento.egreso,
            cuentaId: 'c',
            montoCentimos: 30000,
            fechaMovimiento: DateTime(2026, 10, 3),
            estadoPago: EstadoPago.pagado,
            montoPagadoCentimos: 30000,
            categoriaId: const Value('personal'),
            nivelConfianza: NivelConfianza.d,
            fuente: Fuente.texto,
            autorId: 'u',
            estado: EstadoRegistro.vigente,
            estadoSincronizacion: EstadoSincronizacion.porSubir,
            creadoEn: DateTime(2026, 10, 3),
          ),
        );

    await ponerAlDiaCategorias(base, id);
    final despues = await categorias();
    expect(despues['personal'], ('Personal', false));
    expect(despues['sueldos'], ('Sueldos del personal', true));
    final m = await base.select(base.movimientos).getSingle();
    expect(m.categoriaId, 'sueldos');
  });
}
