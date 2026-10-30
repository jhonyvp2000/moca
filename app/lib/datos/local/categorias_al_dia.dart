import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../dominio/modelos.dart';
import '../../pais/peru/categorias.dart';
import 'base_local.dart';

/// Pone al día las categorías de un teléfono que ya tenía datos (entrega
/// 14.14): renombra las que cambiaron de nombre y agrega las nuevas al
/// final. Se puede llamar las veces que sea: si ya está al día, no cambia
/// nada.
Future<void> ponerAlDiaCategorias(BaseLocal base) async {
  for (final empresa in await base.select(base.empresas).get()) {
    final categorias = await (base.select(
      base.categorias,
    )..where((c) => c.empresaId.equals(empresa.id))).get();

    for (final MapEntry(key: viejo, value: nuevo)
        in categoriasRenombradas.entries) {
      final anterior = categorias
          .where(
            (c) =>
                c.nombre == viejo &&
                c.tipoMovimiento == TipoMovimiento.egreso &&
                c.activa,
          )
          .firstOrNull;
      if (anterior == null) continue;
      final yaEsta = categorias
          .where(
            (c) =>
                c.nombre == nuevo && c.tipoMovimiento == TipoMovimiento.egreso,
          )
          .firstOrNull;
      if (yaEsta == null) {
        await (base.update(base.categorias)
              ..where((c) => c.id.equals(anterior.id)))
            .write(CategoriasCompanion(nombre: Value(nuevo)));
      } else {
        // Las dos existen (llegaron de otro teléfono): lo anotado pasa a la
        // nueva y la vieja queda inactiva, con su nombre, para no chocar.
        await (base.update(base.movimientos)
              ..where((m) => m.categoriaId.equals(anterior.id)))
            .write(MovimientosCompanion(categoriaId: Value(yaEsta.id)));
        await (base.update(base.categorias)
              ..where((c) => c.id.equals(anterior.id)))
            .write(const CategoriasCompanion(activa: Value(false)));
      }
    }

    final nombres = {
      for (final c in await (base.select(
        base.categorias,
      )..where((c) => c.empresaId.equals(empresa.id))).get())
        (c.nombre, c.tipoMovimiento),
    };
    var orden = nombres.length;
    for (final (tipo, lista) in [
      (TipoMovimiento.ingreso, categoriasComunesIngreso),
      (TipoMovimiento.egreso, categoriasComunesEgreso),
    ]) {
      for (final nombre in lista) {
        if (nombres.contains((nombre, tipo))) continue;
        await base
            .into(base.categorias)
            .insert(
              CategoriasCompanion.insert(
                id: idDeCategoriaNueva(empresa.id, tipo, nombre),
                empresaId: empresa.id,
                nombre: nombre,
                tipoMovimiento: tipo,
                orden: orden++,
              ),
            );
      }
    }
  }
}

/// El mismo id en todos los teléfonos del negocio (entrega 14.14.1): si dos
/// teléfonos agregan la misma categoría nueva antes de sincronizar, al
/// juntarse es una sola y no aparece dos veces.
String idDeCategoriaNueva(
  String empresaId,
  TipoMovimiento tipo,
  String nombre,
) => const Uuid().v5(
  Namespace.url.value,
  'moca:$empresaId:${tipo.name}:$nombre',
);
