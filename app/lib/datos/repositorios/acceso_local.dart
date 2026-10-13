import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../dominio/arqueo.dart';
import '../../dominio/modelos.dart';
import '../calculos/saldos.dart';
import '../calculos/semana.dart';
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

  /// Saldo de cada cuenta, calculado aquí y no en las pantallas. Los
  /// [ajustes] del arqueo cambian el saldo sin ser gasto ni ingreso.
  static Map<TipoCuenta, int> saldosPorCuenta(
    List<Cuenta> cuentas,
    List<Movimiento> movimientos, {
    List<AjusteArqueo> ajustes = const [],
  }) => {
    for (final cuenta in cuentas)
      cuenta.tipo: saldoDeCuenta(
        saldoInicialCentimos: cuenta.saldoInicialCentimos,
        fechaSaldoInicial: cuenta.fechaSaldoInicial,
        movimientos: [
          ...movimientos.where((m) => m.cuentaId == cuenta.id).map(paraSaldo),
          for (final a in ajustes)
            if (a.cuentaId == cuenta.id) a.paraSaldo,
        ],
      ),
  };

  /// Si la app está en la Demo (los datos son de ejemplo).
  static const claveModo = 'modo';
  static const modoDemo = 'demo';

  Future<bool> enDemo() async => await leerAjuste(claveModo) == modoDemo;

  /// Ajuste del operador: mostrar la tarjeta del arqueo sin esperar al
  /// domingo. Se borra al guardar un arqueo.
  static const claveArqueoPedido = 'arqueo_pedido';

  /// Hecho si hay arqueo esta semana; falta desde el lunes a las 8:00 a. m.
  /// si la semana anterior quedó sin arqueo; toca el domingo o si el
  /// operador lo pidió.
  Future<EstadoArqueo> estadoArqueo(
    String empresaId,
    List<Movimiento> movimientos,
  ) async {
    final ahora = this.ahora();
    final lunes = inicioDeSemana(ahora);
    final arqueos = await (base.select(
      base.arqueos,
    )..where((a) => a.empresaId.equals(empresaId))).get();
    if (arqueos.any((a) => !a.fecha.isBefore(lunes))) {
      return EstadoArqueo.hecho;
    }
    final lunesPasado = lunes.subtract(const Duration(days: 7));
    final empezoAntes = movimientos.any(
      (m) => m.fechaMovimiento.isBefore(lunes),
    );
    final semanaPasadaSinArqueo = !arqueos.any(
      (a) => !a.fecha.isBefore(lunesPasado),
    );
    if (empezoAntes &&
        semanaPasadaSinArqueo &&
        !ahora.isBefore(lunes.add(const Duration(hours: 8)))) {
      return EstadoArqueo.falta;
    }
    if (ahora.weekday == DateTime.sunday ||
        await leerAjuste(claveArqueoPedido) != null) {
      return EstadoArqueo.toca;
    }
    return EstadoArqueo.nada;
  }

  /// Saldo de cada cuenta de la empresa, con los ajustes del arqueo.
  Future<Map<TipoCuenta, int>> saldos(String empresaId) async =>
      saldosPorCuenta(
        await cuentas(empresaId),
        await movimientos(empresaId),
        ajustes: await ajustes(empresaId),
      );

  /// Cuánto tiene el dueño en total.
  Future<int> tienesHoy(String empresaId) async =>
      (await saldos(empresaId)).values.fold<int>(0, (s, v) => s + v);

  /// Las diferencias del arqueo que ajustan el saldo: error de vuelto, «no
  /// lo sé» y las menores a S/ 1. Las que generaron un movimiento ya están
  /// en el saldo por ese movimiento.
  Future<List<AjusteArqueo>> ajustes(String empresaId) async {
    final filas =
        await (base.select(base.arqueoCuentas).join([
                innerJoin(
                  base.arqueos,
                  base.arqueos.id.equalsExp(base.arqueoCuentas.arqueoId),
                ),
              ])
              ..where(base.arqueos.empresaId.equals(empresaId))
              ..orderBy([OrderingTerm.asc(base.arqueos.fecha)]))
            .get();
    return [
      for (final fila in filas)
        if (fila.readTable(base.arqueoCuentas) case final c
            when c.diferenciaCentimos != 0 && c.movimientoId == null)
          AjusteArqueo(
            id: c.id,
            cuentaId: c.cuentaId,
            fecha: fila.readTable(base.arqueos).fecha,
            centimos: c.diferenciaCentimos,
            motivo: c.motivo,
            calculadoCentimos: c.saldoCalculadoCentimos,
            contadoCentimos: c.saldoRealCentimos,
          ),
    ];
  }

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
          base.arqueoCuentas,
          base.alertas,
          base.diasCerrados,
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

/// Una diferencia del arqueo que ajusta el saldo de una cuenta.
class AjusteArqueo {
  const AjusteArqueo({
    required this.id,
    required this.cuentaId,
    required this.fecha,
    required this.centimos,
    required this.motivo,
    required this.calculadoCentimos,
    required this.contadoCentimos,
  });

  final String id;
  final String cuentaId;
  final DateTime fecha;

  /// Positivo si sobró plata; negativo si faltó.
  final int centimos;
  final MotivoArqueo? motivo;
  final int calculadoCentimos;
  final int contadoCentimos;

  MovimientoParaSaldo get paraSaldo => MovimientoParaSaldo(
    tipo: centimos > 0 ? TipoMovimiento.ingreso : TipoMovimiento.egreso,
    montoCentimos: centimos.abs(),
    estado: EstadoRegistro.vigente,
    estadoPago: EstadoPago.pagado,
    fecha: fecha,
  );
}
