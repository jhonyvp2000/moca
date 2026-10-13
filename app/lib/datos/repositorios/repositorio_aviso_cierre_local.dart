import 'package:drift/drift.dart';

import '../../dominio/aviso_cierre.dart';
import '../../dominio/modelos.dart';
import '../../pais/peru/categorias.dart';
import '../../pais/peru/formato.dart';
import '../calculos/saldos.dart';
import '../calculos/semana.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';
import 'repositorio_movimientos_local.dart';

class RepositorioAvisoCierreLocal implements RepositorioAvisoCierre {
  RepositorioAvisoCierreLocal(
    BaseLocal base, {
    DateTime Function()? ahora,
    Future<bool> Function()? hayConexion,
  }) : _a = AccesoLocal(base, ahora ?? DateTime.now, hayConexion: hayConexion),
       _movimientos = RepositorioMovimientosLocal(
         base,
         ahora: ahora,
         hayConexion: hayConexion,
       );

  final AccesoLocal _a;
  final RepositorioMovimientosLocal _movimientos;
  BaseLocal get _base => _a.base;

  static const _clavePermiso = 'permiso_avisos';
  static const _diasDePlan = 7;

  /// Los avisos del día salen a las 8:00 a. m.
  static const _horaAvisos = 8;

  /// Banco se pregunta solo si hubo ventas al banco en los últimos 30 días.
  static const _diasConBanco = 30;

  static int _idCierre(int dia) => 100 + dia;
  static int _idManana(int dia) => 200 + dia;

  Future<Set<DateTime>> _diasConVenta(String empresaId) async {
    final venta = await _categoriaVenta(empresaId);
    return {
      for (final m in await _a.movimientos(empresaId))
        if (m.estado == EstadoRegistro.vigente && m.categoriaId == venta)
          inicioDelDia(m.fechaMovimiento),
    };
  }

  Future<String?> _categoriaVenta(String empresaId) async =>
      (await (_base.select(_base.categorias)..where(
                (c) =>
                    c.empresaId.equals(empresaId) &
                    c.nombre.equals(categoriaVentaDelDia),
              ))
              .getSingleOrNull())
          ?.id;

  Future<Set<DateTime>> _diasCerrados(String empresaId) async => {
    for (final d in await (_base.select(
      _base.diasCerrados,
    )..where((d) => d.empresaId.equals(empresaId))).get())
      inicioDelDia(d.dia),
  };

  @override
  Stream<List<NotificacionProgramada>> observarPlan() =>
      _a.cambios().asyncMap((_) => plan());

  @override
  Future<List<NotificacionProgramada>> plan() async {
    final empresa = await _a.empresa();
    if (empresa == null || await _a.enDemo()) return const [];
    final ahora = _a.ahora();
    final hoy = inicioDelDia(ahora);
    final movimientos = (await _a.movimientos(empresa.id))
        .where((m) => m.estado == EstadoRegistro.vigente)
        .toList();
    if (movimientos.isEmpty) return const [];
    final conVenta = await _diasConVenta(empresa.id);
    final cerrados = await _diasCerrados(empresa.id);
    final arqueos = await (_base.select(
      _base.arqueos,
    )..where((a) => a.empresaId.equals(empresa.id))).get();
    final primerDia = movimientos
        .map((m) => inicioDelDia(m.fechaMovimiento))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final ultimoConActividad = {
      for (final m in movimientos) inicioDelDia(m.fechaMovimiento),
      ...cerrados,
    }.reduce((a, b) => a.isAfter(b) ? a : b);

    final plan = <NotificacionProgramada>[];
    for (var i = 0; i < _diasDePlan; i++) {
      final dia = DateTime(hoy.year, hoy.month, hoy.day + i);

      // El aviso de cierre, si ese día todavía no hay venta.
      final cierre = dia.add(Duration(minutes: empresa.horaCierreMinutos));
      if (cierre.isAfter(ahora) &&
          !conVenta.contains(dia) &&
          !cerrados.contains(dia)) {
        plan.add(
          NotificacionProgramada(
            id: _idCierre(i),
            cuando: cierre,
            tipo: TipoNotificacion.cierre,
          ),
        );
      }

      // Un aviso a las 8:00 a. m., el más importante.
      final manana = dia.add(const Duration(hours: _horaAvisos));
      if (!manana.isAfter(ahora)) continue;
      final lunes = dia.weekday == DateTime.monday;
      final semanaPasada = dia.subtract(const Duration(days: 7));
      final arqueoSemanaPasada = arqueos.any(
        (a) => !a.fecha.isBefore(semanaPasada) && a.fecha.isBefore(dia),
      );
      // Días sin anotar contados hasta la víspera, si nada cambia.
      final sinAnotar = dia.difference(ultimoConActividad).inDays - 1;
      final TipoNotificacion? tipo;
      if (lunes && primerDia.isBefore(semanaPasada) && !arqueoSemanaPasada) {
        tipo = TipoNotificacion.faltaArqueo;
      } else if (sinAnotar >= 2) {
        tipo = TipoNotificacion.diasSinAnotar;
      } else if (lunes && primerDia.isBefore(semanaPasada)) {
        tipo = TipoNotificacion.resumenSemanal;
      } else {
        tipo = null;
      }
      if (tipo != null) {
        plan.add(
          NotificacionProgramada(
            id: _idManana(i),
            cuando: manana,
            tipo: tipo,
            dias: tipo == TipoNotificacion.diasSinAnotar ? sinAnotar : null,
          ),
        );
      }
    }
    return plan;
  }

  @override
  Future<SiguientePaso> responderVenta(TipoCuenta cuenta, String? texto) async {
    if (texto != null) {
      final limpio = texto.replaceAll(RegExp(r'[sS]/'), '').trim();
      final centimos =
          leerSolesConCentimos(limpio) ?? leerSolesEnCentimos(limpio);
      if (centimos == null) return MontoNoEntendido(cuenta);
      if (centimos > 0) {
        await _movimientos.anotarVentaDelDia({cuenta: centimos});
      }
    }
    final empresa = (await _a.empresa())!;
    switch (cuenta) {
      case TipoCuenta.efectivo:
        return const PreguntarCuenta(TipoCuenta.yape);
      case TipoCuenta.yape:
        if (await _vendioPorBanco(empresa.id)) {
          return const PreguntarCuenta(TipoCuenta.banco);
        }
      case TipoCuenta.banco:
        break;
    }
    final inicio = await _movimientos.observarInicio().first;
    final ahora = _a.ahora();
    final arqueoHecho =
        (await (_base.select(
          _base.arqueos,
        )..where((a) => a.empresaId.equals(empresa.id))).get()).any(
          (a) => !a.fecha.isBefore(inicioDeSemana(ahora)),
        );
    return VentaLista(
      ventaDeHoyCentimos: inicio.ventaDeHoyCentimos,
      tocaArqueo: ahora.weekday == DateTime.sunday && !arqueoHecho,
    );
  }

  Future<bool> _vendioPorBanco(String empresaId) async {
    final venta = await _categoriaVenta(empresaId);
    final banco = (await _a.cuentas(empresaId))
        .firstWhere((c) => c.tipo == TipoCuenta.banco)
        .id;
    final desde = _a.ahora().subtract(const Duration(days: _diasConBanco));
    return (await _a.movimientos(empresaId)).any(
      (m) =>
          m.estado == EstadoRegistro.vigente &&
          m.categoriaId == venta &&
          m.cuentaId == banco &&
          m.fechaMovimiento.isAfter(desde),
    );
  }

  @override
  Future<void> hoyNoAbri() async {
    final empresa = (await _a.empresa())!;
    final hoy = inicioDelDia(_a.ahora());
    if ((await _diasCerrados(empresa.id)).contains(hoy)) return;
    await _base
        .into(_base.diasCerrados)
        .insert(
          DiasCerradosCompanion.insert(
            id: _a.nuevoId(),
            empresaId: empresa.id,
            dia: hoy,
          ),
        );
  }

  @override
  Future<bool> permisoPreguntado() async =>
      await _a.leerAjuste(_clavePermiso) != null;

  @override
  Future<void> marcarPermisoPreguntado() =>
      _a.guardarAjuste(_clavePermiso, 'si');
}
