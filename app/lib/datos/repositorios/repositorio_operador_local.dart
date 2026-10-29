import 'package:drift/drift.dart';

import '../../dominio/modelos.dart';
import '../../dominio/repositorio_operador.dart';
import '../local/base_local.dart';
import '../simulados/demo.dart' as demo;
import 'acceso_local.dart';
import 'repositorio_arqueo_local.dart';
import 'repositorio_movimientos_local.dart';

class RepositorioOperadorLocal implements RepositorioOperador {
  RepositorioOperadorLocal(this._base, {DateTime Function()? ahora})
    : _ahora = ahora ?? DateTime.now;

  final BaseLocal _base;
  final DateTime Function() _ahora;

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

  @override
  Future<void> cargarDemo() async {
    await borrarTodo();
    await demo.cargarDemo(_base, _ahora());
  }

  @override
  Stream<bool> observarDemo() {
    final a = AccesoLocal(_base, _ahora);
    return a.cambios().asyncMap((_) => a.enDemo());
  }

  // --- Simular otra persona (entrega 20.1) ---------------------------------

  AccesoLocal get _a => AccesoLocal(_base, _ahora);

  @override
  Future<void> verComo(Rol? rol) async {
    if (rol == null) {
      await (_base.delete(
        _base.ajustes,
      )..where((a) => a.clave.equals(AccesoLocal.claveVerComo))).go();
    } else {
      await _a.guardarAjuste(AccesoLocal.claveVerComo, rol.name);
    }
  }

  @override
  Stream<Rol?> observarVerComo() => _a.cambios().asyncMap(
    (_) async =>
        Rol.values.asNameMap()[await _a.leerAjuste(AccesoLocal.claveVerComo)],
  );

  @override
  Future<void> simularVentaDeOtro() async {
    final empresa = await _a.empresa();
    if (empresa == null) return;
    final efectivo = (await _a.cuentas(empresa.id))
        .where((c) => c.tipo == TipoCuenta.efectivo)
        .firstOrNull;
    if (efectivo == null) return;
    final venta =
        await (_base.select(_base.categorias)..where(
              (c) =>
                  c.empresaId.equals(empresa.id) &
                  c.tipoMovimiento.equalsValue(TipoMovimiento.ingreso),
            ))
            .get();
    final ahora = _ahora();
    await _base.transaction(() async {
      await _base
          .into(_base.usuarios)
          .insert(
            UsuariosCompanion.insert(
              id: AccesoLocal.usuarioSimulado,
              nombre: const Value(AccesoLocal.nombreSimulado),
              creadoEn: ahora,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await _base
          .into(_base.movimientos)
          .insert(
            MovimientosCompanion.insert(
              id: _a.nuevoId(),
              empresaId: empresa.id,
              tipo: TipoMovimiento.ingreso,
              cuentaId: efectivo.id,
              montoCentimos: 2500,
              fechaMovimiento: ahora,
              estadoPago: EstadoPago.pagado,
              montoPagadoCentimos: 2500,
              fechaPago: Value(ahora),
              categoriaId: Value(venta.firstOrNull?.id),
              nivelConfianza: NivelConfianza.d,
              fuente: Fuente.voz,
              autorId: AccesoLocal.usuarioSimulado,
              estado: EstadoRegistro.vigente,
              // Ya «está» en el servidor: no se sube.
              estadoSincronizacion: EstadoSincronizacion.subido,
              creadoEn: ahora,
            ),
          );
    });
  }

  @override
  Future<void> salirDeLaSimulacion() async {
    await _base.transaction(() async {
      await (_base.delete(
        _base.movimientos,
      )..where((m) => m.autorId.equals(AccesoLocal.usuarioSimulado))).go();
      await (_base.delete(
        _base.usuarios,
      )..where((u) => u.id.equals(AccesoLocal.usuarioSimulado))).go();
      await verComo(null);
    });
  }
}
