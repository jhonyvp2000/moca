import 'dart:convert';

import 'package:drift/drift.dart';

import '../../dominio/historial.dart';
import '../../dominio/modelos.dart';
import '../../dominio/movimientos.dart';
import '../calculos/saldos.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

class RepositorioHistorialLocal implements RepositorioHistorial {
  RepositorioHistorialLocal(
    BaseLocal base, {
    DateTime Function()? ahora,
    Future<bool> Function()? hayConexion,
  }) : _a = AccesoLocal(base, ahora ?? DateTime.now, hayConexion: hayConexion);

  final AccesoLocal _a;
  BaseLocal get _base => _a.base;

  static const _entidad = 'movimiento';

  // --- Lectura -----------------------------------------------------------------

  /// Todo lo que hace falta para armar filas y detalles, leído de una vez.
  Future<_Datos?> _leer() async {
    final empresa = await _a.empresa();
    if (empresa == null) return null;
    final cuentas = await _a.cuentas(empresa.id);
    final categorias = await (_base.select(
      _base.categorias,
    )..where((c) => c.empresaId.equals(empresa.id))).get();
    final contrapartes = await (_base.select(
      _base.contrapartes,
    )..where((c) => c.empresaId.equals(empresa.id))).get();
    final comprobantes = await (_base.select(
      _base.comprobantes,
    )..where((c) => c.empresaId.equals(empresa.id))).get();
    return _Datos(
      empresa: empresa,
      cuentas: cuentas,
      movimientos: await _a.movimientos(empresa.id),
      categorias: {for (final c in categorias) c.id: c.nombre},
      contrapartes: {for (final c in contrapartes) c.id: c.nombre},
      comprobantes: {for (final c in comprobantes) c.id: c},
    );
  }

  FilaHistorial _fila(_Datos d, Movimiento m) {
    final comprobante = d.comprobantes[m.comprobanteId];
    return FilaHistorial(
      id: m.id,
      tipo: m.tipo,
      montoCentimos: m.montoCentimos,
      fecha: m.fechaMovimiento,
      cuenta: d.tipoDeCuenta(m.cuentaId),
      loDebes: m.estadoPago != EstadoPago.pagado,
      porSubir: m.estadoSincronizacion == EstadoSincronizacion.porSubir,
      categoria: d.categorias[m.categoriaId],
      nota: m.nota,
      proveedor: d.contrapartes[m.contraparteId] ?? comprobante?.emisorNombre,
    );
  }

  @override
  Stream<ResumenHistorial> observarHistorial() => _a.cambios().asyncMap((
    _,
  ) async {
    final d = await _leer();
    if (d == null) return const ResumenHistorial(filas: []);
    final vigentes =
        d.movimientos.where((m) => m.estado == EstadoRegistro.vigente).toList()
          ..sort((a, b) {
            final porFecha = b.fechaMovimiento.compareTo(a.fechaMovimiento);
            return porFecha != 0 ? porFecha : b.creadoEn.compareTo(a.creadoEn);
          });
    return ResumenHistorial(filas: [for (final m in vigentes) _fila(d, m)]);
  });

  @override
  Stream<DetalleMovimiento?> observarDetalle(
    String id,
  ) => _a.cambios().asyncMap((_) async {
    final d = await _leer();
    final m = d?.movimiento(id);
    if (d == null || m == null) return null;
    final comprobante = d.comprobantes[m.comprobanteId];
    final pagado = m.estadoPago == EstadoPago.pagado;
    return DetalleMovimiento(
      fila: _fila(d, m),
      vigente: m.estado == EstadoRegistro.vigente,
      fuente: m.fuente,
      categoriaId: m.categoriaId,
      fechaPago: pagado ? m.fechaPago : null,
      primerDiaDePago: pagado ? null : _primerDiaDePago(d, m),
      comprobante: comprobante == null
          ? null
          : ComprobanteVista(
              totalCentimos: comprobante.totalCentimos,
              origen: comprobante.origenLectura,
              emisorNombre:
                  d.contrapartes[m.contraparteId] ?? comprobante.emisorNombre,
              emisorIdentificacion: comprobante.emisorIdentificacion,
              tipo: comprobante.tipo,
              serie: comprobante.serie,
              numero: comprobante.numero,
              fechaEmision: comprobante.fechaEmision,
              rutaImagen: comprobante.rutaImagen,
            ),
      cambios: await _cambios(d, m),
      saldoSiSeDeshaceCentimos: pagado && m.estado == EstadoRegistro.vigente
          ? d.saldoCon(m.cuentaId, m.copyWith(estado: EstadoRegistro.anulado))
          : null,
    );
  });

  /// Una compra no se paga antes de su comprobante ni antes de que Moca
  /// empezara a llevar las cuentas.
  DateTime _primerDiaDePago(_Datos d, Movimiento m) {
    var primero = inicioDelDia(m.fechaComprobante ?? m.fechaMovimiento);
    for (final c in d.cuentas) {
      final desde = c.fechaSaldoInicial;
      if (desde != null && desde.isAfter(primero)) {
        primero = inicioDelDia(desde);
      }
    }
    final hoy = inicioDelDia(_a.ahora());
    return primero.isAfter(hoy) ? hoy : primero;
  }

  /// La bitácora del movimiento y de los que reemplazó, en orden.
  Future<List<Cambio>> _cambios(_Datos d, Movimiento m) async {
    final ids = <String>[m.id];
    var anterior = m.reemplazaA;
    while (anterior != null && !ids.contains(anterior)) {
      final previo = d.movimiento(anterior);
      if (previo == null) break;
      ids.add(previo.id);
      anterior = previo.reemplazaA;
    }
    final filas =
        await (_base.select(_base.bitacora)
              ..where((b) => b.entidad.equals(_entidad) & b.entidadId.isIn(ids))
              ..orderBy([(b) => OrderingTerm.asc(b.fecha)]))
            .get();
    return [for (final fila in filas) ?_cambio(d, fila)];
  }

  Cambio? _cambio(_Datos d, BitacoraData fila) {
    Map<String, Object?> leer(String? json) => json == null
        ? const {}
        : (jsonDecode(json) as Map).cast<String, Object?>();
    final anterior = leer(fila.valorAnterior);
    final nuevo = leer(fila.valorNuevo);
    switch (fila.accion) {
      case AccionBitacora.crear:
        final fuente = Fuente.values.asNameMap()[nuevo['fuente']];
        return CambioCreado(fila.fecha, fuente ?? Fuente.texto);
      case AccionBitacora.editar:
        final campos = <CampoCambiado>[];
        void comparar(
          CampoMovimiento campo,
          Object? Function(Object?) valor,
          String clave,
        ) {
          final antes = valor(anterior[clave]);
          final despues = valor(nuevo[clave]);
          if (antes != despues) {
            campos.add(CampoCambiado(campo, antes, despues));
          }
        }

        comparar(
          CampoMovimiento.tipo,
          (v) => TipoMovimiento.values.asNameMap()[v],
          'tipo',
        );
        comparar(CampoMovimiento.monto, (v) => v, 'montoCentimos');
        comparar(
          CampoMovimiento.cuenta,
          (v) => TipoCuenta.values.asNameMap()[v],
          'cuenta',
        );
        comparar(
          CampoMovimiento.categoria,
          (v) => d.categorias[v],
          'categoriaId',
        );
        comparar(CampoMovimiento.nota, (v) => v, 'nota');
        return CambioCorregido(fila.fecha, campos);
      case AccionBitacora.pagar:
        final cuenta = TipoCuenta.values.asNameMap()[nuevo['cuenta']];
        final fecha = DateTime.tryParse('${nuevo['fechaPago']}');
        if (cuenta == null || fecha == null) return null;
        return CambioPagado(fila.fecha, cuenta, fecha);
      case AccionBitacora.anular:
        return CambioDeshecho(fila.fecha);
      case AccionBitacora.arquear:
        return null;
    }
  }

  // --- Corregir ----------------------------------------------------------------

  /// Lo que se puede corregir: en una compra con comprobante, el monto y el
  /// tipo son los del comprobante y no cambian.
  Movimiento _corregido(_Datos d, Movimiento m, NuevoMovimiento c) {
    final conComprobante = m.comprobanteId != null;
    final tipo = conComprobante ? m.tipo : c.tipo;
    final monto = conComprobante ? m.montoCentimos : c.montoCentimos;
    final nota = c.nota?.trim();
    return m.copyWith(
      tipo: tipo,
      montoCentimos: monto,
      montoPagadoCentimos: m.estadoPago == EstadoPago.pagado
          ? monto
          : m.montoPagadoCentimos,
      cuentaId: d.idDeCuenta(c.cuenta),
      // Un retiro para el dueño no lleva categoría.
      categoriaId: Value(tipo == TipoMovimiento.retiro ? null : c.categoriaId),
      nota: Value(nota == null || nota.isEmpty ? null : nota),
    );
  }

  Future<Movimiento> _vigente(_Datos d, String id) async {
    final m = d.movimiento(id);
    if (m == null || m.estado != EstadoRegistro.vigente) {
      throw StateError('Ese registro ya no está vigente.');
    }
    return m;
  }

  @override
  Future<int?> saldoSiSeCorrige(String id, NuevoMovimiento correccion) async {
    final d = (await _leer())!;
    final m = await _vigente(d, id);
    if (m.estadoPago != EstadoPago.pagado) return null;
    final nuevo = _corregido(d, m, correccion);
    return d.saldoCon(
      nuevo.cuentaId,
      m.copyWith(estado: EstadoRegistro.anulado),
      extra: nuevo,
    );
  }

  Map<String, Object?> _valores(_Datos d, Movimiento m) => {
    'tipo': m.tipo.name,
    'montoCentimos': m.montoCentimos,
    'cuenta': d.tipoDeCuenta(m.cuentaId).name,
    'categoriaId': m.categoriaId,
    'nota': m.nota,
  };

  @override
  Future<Guardado> corregir(String id, NuevoMovimiento correccion) {
    if (correccion.montoCentimos <= 0) {
      throw ArgumentError('El monto tiene que ser mayor que cero.');
    }
    return _base.transaction(() async {
      final d = (await _leer())!;
      final m = await _vigente(d, id);
      final corregido = _corregido(d, m, correccion);
      if (corregido.tipo != TipoMovimiento.retiro &&
          corregido.categoriaId == null) {
        throw ArgumentError('Entró y salió llevan categoría.');
      }
      final usuario = await _a.usuario();
      final ahora = _a.ahora();
      final nuevoId = _a.nuevoId();
      // El nuevo conserva la fecha del original y lo reemplaza.
      await _base
          .into(_base.movimientos)
          .insert(
            corregido.copyWith(
              id: nuevoId,
              autorId: usuario.id,
              estado: EstadoRegistro.vigente,
              reemplazaA: Value(m.id),
              estadoSincronizacion: await _a.estadoAlGuardar(),
              creadoEn: ahora,
            ),
          );
      await (_base.update(
        _base.movimientos,
      )..where((x) => x.id.equals(m.id))).write(
        const MovimientosCompanion(estado: Value(EstadoRegistro.anulado)),
      );
      await _a.anotarEnBitacora(
        empresaId: d.empresa.id,
        autorId: usuario.id,
        entidad: _entidad,
        entidadId: m.id,
        accion: AccionBitacora.editar,
        anterior: _valores(d, m),
        nuevo: {..._valores(d, corregido), 'reemplazadoPor': nuevoId},
      );
      return Guardado(ids: [nuevoId], tienesHoyCentimos: await _tienesHoy());
    });
  }

  // --- Pagar -------------------------------------------------------------------

  Future<Movimiento> _porPagar(_Datos d, String id) async {
    final m = await _vigente(d, id);
    if (m.estadoPago == EstadoPago.pagado) {
      throw StateError('Esa compra ya está pagada.');
    }
    return m;
  }

  Movimiento _pagado(
    _Datos d,
    Movimiento m,
    TipoCuenta cuenta,
    DateTime fecha,
  ) => m.copyWith(
    cuentaId: d.idDeCuenta(cuenta),
    estadoPago: EstadoPago.pagado,
    montoPagadoCentimos: m.montoCentimos,
    fechaPago: Value(fecha),
  );

  @override
  Future<int> saldoSiSePaga(String id, TipoCuenta cuenta) async {
    final d = (await _leer())!;
    final m = await _porPagar(d, id);
    final pagado = _pagado(d, m, cuenta, _a.ahora());
    return d.saldoCon(pagado.cuentaId, pagado);
  }

  @override
  Future<int> pagar(
    String id, {
    required TipoCuenta cuenta,
    required DateTime dia,
  }) => _base.transaction(() async {
    final d = (await _leer())!;
    final m = await _porPagar(d, id);
    final ahora = _a.ahora();
    final hoy = inicioDelDia(ahora);
    final elegido = inicioDelDia(dia);
    if (elegido.isAfter(hoy) || elegido.isBefore(_primerDiaDePago(d, m))) {
      throw ArgumentError('La fecha de pago no es válida.');
    }
    // Hoy, a esta hora; otro día, a mediodía.
    final fecha = elegido == hoy
        ? ahora
        : DateTime(elegido.year, elegido.month, elegido.day, 12);
    final pagado = _pagado(d, m, cuenta, fecha);
    final estado = await _a.estadoAlGuardar();
    await (_base.update(
      _base.movimientos,
    )..where((x) => x.id.equals(m.id))).write(
      MovimientosCompanion(
        cuentaId: Value(pagado.cuentaId),
        estadoPago: const Value(EstadoPago.pagado),
        montoPagadoCentimos: Value(pagado.montoPagadoCentimos),
        fechaPago: Value(fecha),
        // El pago sin señal también queda por subir.
        estadoSincronizacion: estado == EstadoSincronizacion.porSubir
            ? const Value(EstadoSincronizacion.porSubir)
            : const Value.absent(),
      ),
    );
    final usuario = await _a.usuario();
    await _a.anotarEnBitacora(
      empresaId: d.empresa.id,
      autorId: usuario.id,
      entidad: _entidad,
      entidadId: m.id,
      accion: AccionBitacora.pagar,
      anterior: {
        'estadoPago': m.estadoPago.name,
        'cuenta': d.tipoDeCuenta(m.cuentaId).name,
      },
      nuevo: {
        'estadoPago': EstadoPago.pagado.name,
        'cuenta': cuenta.name,
        'fechaPago': fecha.toIso8601String(),
      },
    );
    return d.saldoCon(pagado.cuentaId, pagado);
  });

  // --- Deshacer ----------------------------------------------------------------

  @override
  Future<void> deshacer(String id) => _base.transaction(() async {
    final empresa = (await _a.empresa())!;
    final actualizados =
        await (_base.update(_base.movimientos)..where(
              (m) =>
                  m.id.equals(id) &
                  m.estado.equalsValue(EstadoRegistro.vigente),
            ))
            .write(
              const MovimientosCompanion(estado: Value(EstadoRegistro.anulado)),
            );
    if (actualizados == 0) return;
    final usuario = await _a.usuario();
    await _a.anotarEnBitacora(
      empresaId: empresa.id,
      autorId: usuario.id,
      entidad: _entidad,
      entidadId: id,
      accion: AccionBitacora.anular,
      anterior: {'estado': EstadoRegistro.vigente.name},
      nuevo: {'estado': EstadoRegistro.anulado.name},
    );
  });

  Future<int> _tienesHoy() async {
    final empresa = (await _a.empresa())!;
    return AccesoLocal.saldosPorCuenta(
      await _a.cuentas(empresa.id),
      await _a.movimientos(empresa.id),
    ).values.fold<int>(0, (suma, saldo) => suma + saldo);
  }
}

class _Datos {
  _Datos({
    required this.empresa,
    required this.cuentas,
    required this.movimientos,
    required this.categorias,
    required this.contrapartes,
    required this.comprobantes,
  });

  final Empresa empresa;
  final List<Cuenta> cuentas;
  final List<Movimiento> movimientos;
  final Map<String, String> categorias;
  final Map<String, String> contrapartes;
  final Map<String, Comprobante> comprobantes;

  Movimiento? movimiento(String id) =>
      movimientos.where((m) => m.id == id).firstOrNull;

  TipoCuenta tipoDeCuenta(String cuentaId) =>
      cuentas.firstWhere((c) => c.id == cuentaId).tipo;

  String idDeCuenta(TipoCuenta tipo) =>
      cuentas.firstWhere((c) => c.tipo == tipo).id;

  /// El saldo de una cuenta si [cambiado] reemplaza al movimiento con su
  /// mismo id, más [extra] si se agrega uno nuevo.
  int saldoCon(String cuentaId, Movimiento cambiado, {Movimiento? extra}) {
    final lista = [
      for (final m in movimientos) m.id == cambiado.id ? cambiado : m,
      ?extra,
    ];
    final cuenta = cuentas.firstWhere((c) => c.id == cuentaId);
    return AccesoLocal.saldosPorCuenta([cuenta], lista)[cuenta.tipo]!;
  }
}
