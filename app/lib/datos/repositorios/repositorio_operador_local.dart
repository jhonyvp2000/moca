import '../../dominio/repositorio_operador.dart';
import '../local/base_local.dart';
import 'repositorio_arqueo_local.dart';
import 'repositorio_movimientos_local.dart';

class RepositorioOperadorLocal implements RepositorioOperador {
  RepositorioOperadorLocal(this._base);

  final BaseLocal _base;

  @override
  Future<int> contarRegistros() async {
    var total = 0;
    for (final tabla in _base.allTables) {
      final fila = await _base
          .customSelect('SELECT COUNT(*) AS n FROM ${tabla.actualTableName}')
          .getSingle();
      total += fila.read<int>('n');
    }
    return total;
  }

  @override
  Future<void> borrarTodo() async {
    await _base.transaction(() async {
      await _base.customStatement('PRAGMA defer_foreign_keys = ON');
      for (final tabla in _base.allTables) {
        await _base.delete(tabla).go();
      }
    });
  }

  @override
  Future<void> saltarPrimeraSemana() => _base
      .into(_base.ajustes)
      .insertOnConflictUpdate(
        AjustesCompanion.insert(
          clave: RepositorioMovimientosLocal.claveSaltarPrimeraSemana,
          valor: 'si',
        ),
      );

  @override
  Future<void> pedirArqueo() => _base
      .into(_base.ajustes)
      .insertOnConflictUpdate(
        AjustesCompanion.insert(
          clave: RepositorioArqueoLocal.claveArqueoPedido,
          valor: 'si',
        ),
      );
}
