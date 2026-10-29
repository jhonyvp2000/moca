import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../dominio/arqueo.dart';
import '../../dominio/cifras.dart';
import '../../dominio/comprobantes.dart' show fotosDePruebaPorTelefono;
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

  /// Sin cuenta, lo guardado sin conexión queda «por subir» y la marca no
  /// cambia, como en el prototipo.
  Future<EstadoSincronizacion> estadoAlGuardar() async {
    // Con cuenta, todo queda «por subir» hasta que el servidor lo recibe
    // (entrega 11).
    if (await leerAjuste(claveCuentaVerificada) != null) {
      return EstadoSincronizacion.porSubir;
    }
    return await _hayConexion()
        ? EstadoSincronizacion.subido
        : EstadoSincronizacion.porSubir;
  }

  /// El celular verificado de verdad (entrega 11). Sin él, no hay cuenta.
  static const claveCuentaVerificada = 'cuenta_verificada';

  /// Fotos de prueba que le quedan al teléfono sin cuenta (entrega 14.2).
  static const claveFotosDePrueba = 'fotos_de_prueba';
  static const fotosDePruebaIniciales = fotosDePruebaPorTelefono;

  /// Las fotos de prueba que quedan; nulo con cuenta o en la Demo, donde no
  /// hay tope de prueba.
  Future<int?> fotosDePrueba() async {
    if (await leerAjuste(claveCuentaVerificada) != null) return null;
    if (await enDemo()) return null;
    return int.tryParse(await leerAjuste(claveFotosDePrueba) ?? '') ??
        fotosDePruebaIniciales;
  }

  /// Las últimas cifras del servidor, con la huella de lo que tenía el
  /// teléfono cuando llegaron (entrega 13).
  static const claveCifras = 'cifras';

  Future<void> guardarCifras(Map<String, Object?> cifras, String huella) =>
      guardarAjuste(
        claveCifras,
        jsonEncode({'huella': huella, 'cifras': cifras}),
      );

  /// Lo último leído, para no volver a leer el mismo texto en cada cambio.
  static String? _textoLeido;
  static ({String huella, Cifras cifras})? _leidas;

  /// Las cifras del servidor, si valen para lo que hay hoy en el teléfono:
  /// con cuenta, fuera de la Demo, del mismo día y sin nada por subir. Si
  /// no, nulas: el teléfono calcula lo mismo con las mismas reglas.
  Future<Cifras?> cifrasDelServidor() async {
    if (await leerAjuste(claveCuentaVerificada) == null) return null;
    if (await enDemo()) return null;
    final texto = await leerAjuste(claveCifras);
    if (texto == null) return null;
    if (texto != _textoLeido) {
      try {
        final guardado = jsonDecode(texto) as Map<String, Object?>;
        _leidas = (
          huella: guardado['huella']! as String,
          cifras: Cifras.fromJson(guardado['cifras']! as Map<String, Object?>),
        );
      } on Object {
        // Algo que esta versión de la app no entiende: se calcula aquí.
        _leidas = null;
      }
      _textoLeido = texto;
    }
    final leidas = _leidas;
    if (leidas == null) return null;
    if (leidas.cifras.dia != Cifras.textoDia(ahora())) return null;
    if (await hayPorSubir() || leidas.huella != await huella()) return null;
    return leidas.cifras;
  }

  /// Si hay movimientos que el servidor todavía no tiene.
  Future<bool> hayPorSubir() async =>
      (await (base.select(base.movimientos)
                ..where(
                  (m) => m.estadoSincronizacion.equalsValue(
                    EstadoSincronizacion.porSubir,
                  ),
                )
                ..limit(1))
              .get())
          .isNotEmpty;

  /// Cambia con cada cambio de lo que se sube: la bitácora registra cada
  /// cambio; los días cerrados, los avisos vistos y la empresa se suman
  /// aparte.
  Future<String> huella() async {
    Future<int> contar(TableInfo tabla) async {
      final total = countAll();
      final consulta = base.selectOnly(tabla)..addColumns([total]);
      return (await consulta.getSingle()).read(total)!;
    }

    final empresa = await this.empresa();
    // Un cambio de nombre de categoría (entrega 14.14) también se sube.
    final categorias = await base
        .customSelect(
          'SELECT COUNT(*) AS n, COALESCE(SUM(activa), 0) AS activas, '
          'COALESCE(SUM(LENGTH(nombre)), 0) AS largo FROM categorias',
        )
        .getSingle();
    return [
      await contar(base.bitacora),
      await contar(base.movimientos),
      await contar(base.diasCerrados),
      await contar(base.cuentas),
      await contar(base.alertas),
      empresa?.nombre,
      empresa?.tipoNegocio.name,
      empresa?.horaCierreMinutos,
      categorias.data.values.join('-'),
    ].join('|');
  }

  Future<Empresa?> empresa() =>
      (base.select(base.empresas)..limit(1)).getSingleOrNull();

  /// Quien usa este teléfono: el de la membresía. Desde la entrega 18 el
  /// teléfono guarda también a las otras personas del negocio (como autores
  /// de lo que anotaron), sin membresía aquí.
  Future<Usuario> usuario() async => (await usuarioONulo())!;

  Future<Usuario?> usuarioONulo() async {
    final propio = await (base.select(base.usuarios).join([
      innerJoin(
        base.membresias,
        base.membresias.usuarioId.equalsExp(base.usuarios.id),
      ),
    ])..limit(1)).getSingleOrNull();
    if (propio != null) return propio.readTable(base.usuarios);
    // Antes del alta todavía no hay membresía: es el único usuario.
    return (base.select(base.usuarios)..limit(1)).getSingleOrNull();
  }

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

  /// El nombre que se guarda con cada cuenta. La otra billetera lleva el que
  /// le puso el dueño.
  static const nombresCuenta = {
    TipoCuenta.efectivo: 'Efectivo',
    TipoCuenta.yape: 'BCP Yape',
    TipoCuenta.banco: 'BCP',
    TipoCuenta.plin: 'Interbank Plin',
    TipoCuenta.bbvaPlin: 'BBVA Plin',
    TipoCuenta.scotiabankPlin: 'Scotiabank Plin',
    TipoCuenta.sip: 'Sip',
    TipoCuenta.otra: 'Otra',
    TipoCuenta.interbank: 'Interbank',
    TipoCuenta.bbva: 'BBVA',
    TipoCuenta.scotiabank: 'Scotiabank',
    TipoCuenta.otroBanco: 'Otro banco o caja',
  };

  /// Crea una cuenta del negocio y la deja en la bitácora.
  Future<void> crearCuenta({
    required String empresaId,
    required String autorId,
    required TipoCuenta tipo,
    required String nombre,
    required int orden,
    int? saldoInicialCentimos,
    DateTime? fechaSaldoInicial,
  }) async {
    final id = nuevoId();
    await base
        .into(base.cuentas)
        .insert(
          CuentasCompanion.insert(
            id: id,
            empresaId: empresaId,
            tipo: tipo,
            nombre: nombre,
            orden: orden,
            saldoInicialCentimos: Value(saldoInicialCentimos),
            fechaSaldoInicial: Value(fechaSaldoInicial),
          ),
        );
    await anotarEnBitacora(
      empresaId: empresaId,
      autorId: autorId,
      entidad: 'cuenta',
      entidadId: id,
      accion: AccionBitacora.crear,
      nuevo: {'tipo': tipo.name, 'saldoInicialCentimos': saldoInicialCentimos},
    );
  }

  /// En el orden en que se muestran ([TipoCuenta.enOrden]).
  Future<List<Cuenta>> cuentas(String empresaId) async =>
      (await (base.select(
        base.cuentas,
      )..where((c) => c.empresaId.equals(empresaId))).get())..sort(
        (a, b) => TipoCuenta.enOrden
            .indexOf(a.tipo)
            .compareTo(TipoCuenta.enOrden.indexOf(b.tipo)),
      );

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
    if (await cifrasDelServidor() case final cifras?) {
      final estado = cifras.inicio.estadoArqueo;
      if (estado == EstadoArqueo.nada &&
          await leerAjuste(claveArqueoPedido) != null) {
        return EstadoArqueo.toca;
      }
      return estado;
    }
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
      (await cifrasDelServidor())?.saldos ??
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
          base.usuarios,
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
