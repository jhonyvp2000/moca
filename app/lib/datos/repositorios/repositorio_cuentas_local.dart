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
    return [
      for (final c in cuentas)
        CuentaVista(
          tipo: c.tipo,
          // El BCP se guardaba como «Banco» antes de la entrega 14.1.
          nombre: c.tipo.conNombrePropio
              ? c.nombre
              : AccesoLocal.nombresCuenta[c.tipo]!,
          saldoCentimos: c.saldoInicialCentimos == null ? null : saldos[c.tipo],
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
      if (cuentas.any((c) => c.tipo == tipo)) return;
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
}
