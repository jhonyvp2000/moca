import 'package:drift/drift.dart' show Value;

import '../../dominio/cuentas.dart';
import '../../dominio/modelos.dart';
import '../calculos/saldos.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

class RepositorioCuentasLocal implements RepositorioCuentas {
  RepositorioCuentasLocal(BaseLocal base, {DateTime Function()? ahora})
    : _a = AccesoLocal(base, ahora ?? DateTime.now);

  final AccesoLocal _a;

  @override
  Stream<List<CuentaVista>> observar() =>
      _a.cambios().asyncMap((_) => _calcular());

  Future<List<CuentaVista>> _calcular() async {
    final empresa = await _a.empresa();
    if (empresa == null) return const [];
    final cuentas = await _a.cuentas(empresa.id);
    final saldos = await _a.saldos(empresa.id);
    final arqueadas = await _arqueadas();
    return [
      for (final c in cuentas)
        CuentaVista(
          id: c.id,
          tipo: c.tipo,
          // El BCP se guardaba como «Banco» antes de la entrega 14.1.
          nombre: c.tipo.conNombrePropio
              ? c.nombre
              : AccesoLocal.nombresCuenta[c.tipo]!,
          saldoCentimos: c.saldoInicialCentimos == null ? null : saldos[c.tipo],
          inicialCentimos: c.saldoInicialCentimos,
          desde: c.fechaSaldoInicial,
          arqueada: arqueadas.contains(c.id),
          enUso: c.enUso,
        ),
    ];
  }

  @override
  Future<void> agregarBilletera(TipoCuenta tipo, {String? nombre}) async {
    assert(TipoCuenta.agregables.contains(tipo));
    final empresa = (await _a.empresa())!;
    final usuario = await _a.usuario();
    await _a.base.transaction(() async {
      final cuentas = await _a.cuentas(empresa.id);
      // La que se dejó de usar vuelve, con su historial (entrega 58).
      if (cuentas.where((c) => c.tipo == tipo).firstOrNull case final c?) {
        if (!c.enUso) await _ponerEnUso(c.id, true, empresa.id, usuario.id);
        return;
      }
      final pendiente = cuentas.any((c) => c.saldoInicialCentimos == null);
      final limpio = nombre?.trim() ?? '';
      await _a.crearCuenta(
        empresaId: empresa.id,
        autorId: usuario.id,
        tipo: tipo,
        nombre: switch (tipo) {
          _ when tipo.conNombrePropio && limpio.isNotEmpty => limpio,
          _ => AccesoLocal.nombresCuenta[tipo]!,
        },
        orden: cuentas.length,
        saldoInicialCentimos: pendiente ? null : 0,
        fechaSaldoInicial: pendiente ? null : inicioDelDia(_a.ahora()),
      );
    });
  }

  /// Las cuentas que ya entraron en algún arqueo.
  Future<Set<String>> _arqueadas() async => {
    for (final a in await _a.base.select(_a.base.arqueoCuentas).get())
      a.cuentaId,
  };

  @override
  Future<bool> corregirSaldoInicial(String cuentaId, int centimos) async {
    final empresa = (await _a.empresa())!;
    final usuario = await _a.usuario();
    return _a.base.transaction(() async {
      final cuenta = await (_a.base.select(
        _a.base.cuentas,
      )..where((c) => c.id.equals(cuentaId))).getSingleOrNull();
      if (cuenta == null ||
          cuenta.empresaId != empresa.id ||
          cuenta.saldoInicialCentimos == null ||
          (await _arqueadas()).contains(cuentaId)) {
        return false;
      }
      if (cuenta.saldoInicialCentimos == centimos) return true;
      await (_a.base.update(_a.base.cuentas)
            ..where((c) => c.id.equals(cuentaId)))
          .write(CuentasCompanion(saldoInicialCentimos: Value(centimos)));
      await _a.anotarEnBitacora(
        empresaId: empresa.id,
        autorId: usuario.id,
        entidad: 'cuenta',
        entidadId: cuentaId,
        accion: AccionBitacora.editar,
        anterior: {'saldoInicialCentimos': cuenta.saldoInicialCentimos},
        nuevo: {'saldoInicialCentimos': centimos, 'origen': 'correccion'},
      );
      return true;
    });
  }

  @override
  Future<ResultadoDejarDeUsar> dejarDeUsar(String cuentaId) async {
    final empresa = (await _a.empresa())!;
    final usuario = await _a.usuario();
    return _a.base.transaction(() async {
      final cuenta = await (_a.base.select(
        _a.base.cuentas,
      )..where((c) => c.id.equals(cuentaId))).getSingle();
      if (cuenta.tipo == TipoCuenta.efectivo) {
        return ResultadoDejarDeUsar.esEfectivo;
      }
      final saldo = (await _a.saldos(empresa.id))[cuenta.tipo] ?? 0;
      if (cuenta.saldoInicialCentimos != null && saldo != 0) {
        return ResultadoDejarDeUsar.conSaldo;
      }
      if (cuenta.enUso) {
        await _ponerEnUso(cuentaId, false, empresa.id, usuario.id);
      }
      return ResultadoDejarDeUsar.listo;
    });
  }

  @override
  Future<void> volverAUsar(String cuentaId) async {
    final empresa = (await _a.empresa())!;
    final usuario = await _a.usuario();
    await _ponerEnUso(cuentaId, true, empresa.id, usuario.id);
  }

  Future<void> _ponerEnUso(
    String cuentaId,
    bool enUso,
    String empresaId,
    String autorId,
  ) async {
    await (_a.base.update(_a.base.cuentas)..where((c) => c.id.equals(cuentaId)))
        .write(CuentasCompanion(enUso: Value(enUso)));
    await _a.anotarEnBitacora(
      empresaId: empresaId,
      autorId: autorId,
      entidad: 'cuenta',
      entidadId: cuentaId,
      accion: AccionBitacora.editar,
      anterior: {'enUso': !enUso},
      nuevo: {'enUso': enUso},
    );
  }
}
