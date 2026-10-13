import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../dominio/modelos.dart';
import '../calculos/saldos.dart';
import '../local/base_local.dart';

/// Lo que comparten los repositorios locales: identificadores, la empresa y
/// el usuario del teléfono, la bitácora, los ajustes y los saldos.
class AccesoLocal {
  AccesoLocal(this.base, this.ahora, {Future<bool> Function()? hayConexion})
    : _hayConexion = hayConexion ?? _siempreConectado;

  final BaseLocal base;
  final DateTime Function() ahora;
  final Future<bool> Function() _hayConexion;
  static Future<bool> _siempreConectado() async => true;
  static const _uuid = Uuid();

  String nuevoId() => _uuid.v4();

  /// Lo guardado sin conexión queda «por subir» y la marca no cambia: en el
  /// prototipo no hay servidor.
  Future<EstadoSincronizacion> estadoAlGuardar() async => await _hayConexion()
      ? EstadoSincronizacion.subido
      : EstadoSincronizacion.porSubir;

  Future<Empresa?> empresa() =>
      (base.select(base.empresas)..limit(1)).getSingleOrNull();

  Future<Usuario> usuario() =>
      (base.select(base.usuarios)..limit(1)).getSingle();

  Future<String?> leerAjuste(String clave) async {
    final fila = await (base.select(
      base.ajustes,
    )..where((a) => a.clave.equals(clave))).getSingleOrNull();
    return fila?.valor;
  }

  Future<void> guardarAjuste(String clave, String valor) => base
      .into(base.ajustes)
      .insertOnConflictUpdate(
        AjustesCompanion.insert(clave: clave, valor: valor),
      );

  Future<void> anotarEnBitacora({
    required String empresaId,
    required String autorId,
    required String entidad,
    required String entidadId,
    required AccionBitacora accion,
    Map<String, Object?>? anterior,
    Map<String, Object?>? nuevo,
  }) => base
      .into(base.bitacora)
      .insert(
        BitacoraCompanion.insert(
          id: nuevoId(),
          empresaId: empresaId,
          autorId: autorId,
          entidad: entidad,
          entidadId: entidadId,
          accion: accion,
          valorAnterior: Value(anterior == null ? null : jsonEncode(anterior)),
          valorNuevo: Value(nuevo == null ? null : jsonEncode(nuevo)),
          fecha: ahora(),
        ),
      );

  Future<List<Cuenta>> cuentas(String empresaId) =>
      (base.select(base.cuentas)
            ..where((c) => c.empresaId.equals(empresaId))
            ..orderBy([(c) => OrderingTerm.asc(c.orden)]))
          .get();

  Future<List<Movimiento>> movimientos(String empresaId) => (base.select(
    base.movimientos,
  )..where((m) => m.empresaId.equals(empresaId))).get();

  /// Para los cálculos, la fecha de un movimiento es la del pago: lo que
  /// todavía se debe no ha salido de ninguna cuenta.
  static MovimientoParaSaldo paraSaldo(Movimiento m) => MovimientoParaSaldo(
    tipo: m.tipo,
    montoCentimos: m.montoCentimos,
    estado: m.estado,
    estadoPago: m.estadoPago,
    fecha: m.fechaPago ?? m.fechaMovimiento,
  );

  /// Saldo de cada cuenta, calculado aquí y no en las pantallas.
  static Map<TipoCuenta, int> saldosPorCuenta(
    List<Cuenta> cuentas,
    List<Movimiento> movimientos,
  ) => {
    for (final cuenta in cuentas)
      cuenta.tipo: saldoDeCuenta(
        saldoInicialCentimos: cuenta.saldoInicialCentimos,
        fechaSaldoInicial: cuenta.fechaSaldoInicial,
        movimientos: movimientos
            .where((m) => m.cuentaId == cuenta.id)
            .map(paraSaldo),
      ),
  };

  /// Se emite al empezar y cada vez que cambian los datos que importan.
  Stream<void> cambios() => base
      .tableUpdates(
        TableUpdateQuery.onAllTables([
          base.empresas,
          base.cuentas,
          base.movimientos,
          base.categorias,
          base.arqueos,
          base.ajustes,
          base.bitacora,
        ]),
      )
      .map((_) {})
      ._conInicio();
}

extension _ConInicio on Stream<void> {
  Stream<void> _conInicio() async* {
    yield null;
    yield* this;
  }
}
