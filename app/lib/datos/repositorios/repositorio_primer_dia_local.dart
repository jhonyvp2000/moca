import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../dominio/modelos.dart';
import '../../dominio/primer_dia.dart';
import '../../pais/peru/categorias.dart';
import '../calculos/saldos.dart';
import '../local/base_local.dart';

class RepositorioPrimerDiaLocal implements RepositorioPrimerDia {
  RepositorioPrimerDiaLocal(this._base, {DateTime Function()? ahora})
    : _ahora = ahora ?? DateTime.now;

  final BaseLocal _base;
  final DateTime Function() _ahora;
  static const _uuid = Uuid();

  static const _claveEtapa = 'etapa';
  static const _claveSinCuentaDesde = 'sin_cuenta_desde';

  static const _nombresCuenta = {
    TipoCuenta.efectivo: 'Efectivo',
    TipoCuenta.yape: 'Yape',
    TipoCuenta.banco: 'Banco',
  };

  String _nuevoId() => _uuid.v4();

  // --- Etapa ---------------------------------------------------------------

  @override
  Stream<EtapaInicio> observarEtapa() {
    final consulta = _base.select(_base.ajustes)
      ..where((a) => a.clave.equals(_claveEtapa));
    return consulta.watchSingleOrNull().map(
      (fila) => fila == null
          ? EtapaInicio.bienvenida
          : EtapaInicio.values.byName(fila.valor),
    );
  }

  Future<EtapaInicio> _etapaActual() => observarEtapa().first;

  Future<void> _guardarAjuste(String clave, String valor) => _base
      .into(_base.ajustes)
      .insertOnConflictUpdate(
        AjustesCompanion.insert(clave: clave, valor: valor),
      );

  Future<void> _pasarA(EtapaInicio etapa) =>
      _guardarAjuste(_claveEtapa, etapa.name);

  // --- Lecturas de apoyo -----------------------------------------------------

  Future<Empresa?> _empresa() =>
      (_base.select(_base.empresas)..limit(1)).getSingleOrNull();

  Future<Usuario> _usuario() =>
      (_base.select(_base.usuarios)..limit(1)).getSingle();

  Future<void> _anotarEnBitacora({
    required String empresaId,
    required String autorId,
    required String entidad,
    required String entidadId,
    required AccionBitacora accion,
    Map<String, Object?>? anterior,
    Map<String, Object?>? nuevo,
  }) => _base
      .into(_base.bitacora)
      .insert(
        BitacoraCompanion.insert(
          id: _nuevoId(),
          empresaId: empresaId,
          autorId: autorId,
          entidad: entidad,
          entidadId: entidadId,
          accion: accion,
          valorAnterior: Value(anterior == null ? null : jsonEncode(anterior)),
          valorNuevo: Value(nuevo == null ? null : jsonEncode(nuevo)),
          fecha: _ahora(),
        ),
      );

  Future<void> _agregarCategorias(
    String empresaId,
    TipoMovimiento tipo,
    List<String> nombres,
  ) async {
    final existentes = await (_base.select(
      _base.categorias,
    )..where((c) => c.empresaId.equals(empresaId))).get();
    var orden = existentes.length;
    for (final nombre in nombres) {
      if (existentes.any((c) => c.nombre == nombre)) continue;
      await _base
          .into(_base.categorias)
          .insert(
            CategoriasCompanion.insert(
              id: _nuevoId(),
              empresaId: empresaId,
              nombre: nombre,
              tipoMovimiento: tipo,
              orden: orden++,
            ),
          );
    }
  }

  // --- Camino del primer día -------------------------------------------------

  @override
  Future<void> anotarPrimeraVenta(Map<TipoCuenta, int> ventaPorCuenta) async {
    if (!ventaPorCuenta.values.any((monto) => monto > 0)) {
      throw ArgumentError('La venta necesita al menos un monto.');
    }
    await _base.transaction(() async {
      // Un doble toque en «Guardar» no debe duplicar la venta.
      if (await _etapaActual() != EtapaInicio.bienvenida) return;

      final ahora = _ahora();
      final usuarioId = _nuevoId();
      final empresaId = _nuevoId();

      await _base
          .into(_base.usuarios)
          .insert(UsuariosCompanion.insert(id: usuarioId, creadoEn: ahora));
      // El negocio se completa en el alta (S02).
      await _base
          .into(_base.empresas)
          .insert(
            EmpresasCompanion.insert(
              id: empresaId,
              nombre: '',
              tipoNegocio: TipoNegocio.otro,
              modo: ModoEmpresa.simple,
              pais: 'PE',
              moneda: 'PEN',
              horaCierreMinutos: 21 * 60,
              creadoEn: ahora,
            ),
          );
      await _base
          .into(_base.membresias)
          .insert(
            MembresiasCompanion.insert(
              id: _nuevoId(),
              usuarioId: usuarioId,
              empresaId: empresaId,
              rol: Rol.dueno,
            ),
          );

      // Las tres cuentas existen desde la primera venta, con el saldo
      // inicial pendiente (decisiones.md, 12-10-2026).
      final cuentaIds = <TipoCuenta, String>{};
      for (final (orden, tipo) in TipoCuenta.values.indexed) {
        final id = _nuevoId();
        cuentaIds[tipo] = id;
        await _base
            .into(_base.cuentas)
            .insert(
              CuentasCompanion.insert(
                id: id,
                empresaId: empresaId,
                tipo: tipo,
                nombre: _nombresCuenta[tipo]!,
                orden: orden,
              ),
            );
      }

      await _agregarCategorias(
        empresaId,
        TipoMovimiento.ingreso,
        categoriasComunesIngreso,
      );
      await _agregarCategorias(
        empresaId,
        TipoMovimiento.egreso,
        categoriasComunesEgreso,
      );
      final ventaDelDia =
          await (_base.select(_base.categorias)..where(
                (c) =>
                    c.empresaId.equals(empresaId) &
                    c.nombre.equals(categoriaVentaDelDia),
              ))
              .getSingle();

      for (final MapEntry(key: tipo, value: monto) in ventaPorCuenta.entries) {
        if (monto <= 0) continue;
        final id = _nuevoId();
        await _base
            .into(_base.movimientos)
            .insert(
              MovimientosCompanion.insert(
                id: id,
                empresaId: empresaId,
                tipo: TipoMovimiento.ingreso,
                cuentaId: cuentaIds[tipo]!,
                montoCentimos: monto,
                fechaMovimiento: ahora,
                estadoPago: EstadoPago.pagado,
                montoPagadoCentimos: monto,
                fechaPago: Value(ahora),
                categoriaId: Value(ventaDelDia.id),
                // Venta del día sin comprobante: nivel D (modelo-datos.md).
                nivelConfianza: NivelConfianza.d,
                fuente: Fuente.texto,
                autorId: usuarioId,
                estado: EstadoRegistro.vigente,
                estadoSincronizacion: EstadoSincronizacion.subido,
                creadoEn: ahora,
              ),
            );
        await _anotarEnBitacora(
          empresaId: empresaId,
          autorId: usuarioId,
          entidad: 'movimiento',
          entidadId: id,
          accion: AccionBitacora.crear,
          nuevo: {
            'tipo': TipoMovimiento.ingreso.name,
            'cuenta': tipo.name,
            'montoCentimos': monto,
            'categoria': categoriaVentaDelDia,
          },
        );
      }

      await _pasarA(EtapaInicio.guardarAvance);
    });
  }

  @override
  Future<void> guardarCelular(String celular) async {
    await _base.transaction(() async {
      final usuario = await _usuario();
      final empresa = (await _empresa())!;
      await (_base.update(_base.usuarios)
            ..where((u) => u.id.equals(usuario.id)))
          .write(UsuariosCompanion(celular: Value(celular)));
      await _anotarEnBitacora(
        empresaId: empresa.id,
        autorId: usuario.id,
        entidad: 'usuario',
        entidadId: usuario.id,
        accion: AccionBitacora.editar,
        anterior: {'celular': usuario.celular},
        nuevo: {'celular': celular},
      );
      await _pasarA(EtapaInicio.alta);
    });
  }

  @override
  Future<void> seguirSinCuenta() async {
    await _base.transaction(() async {
      await _guardarAjuste(_claveSinCuentaDesde, _ahora().toIso8601String());
      await _pasarA(EtapaInicio.alta);
    });
  }

  @override
  Future<void> completarAlta(DatosAlta datos) async {
    await _base.transaction(() async {
      final usuario = await _usuario();
      final empresa = (await _empresa())!;
      await (_base.update(
        _base.empresas,
      )..where((e) => e.id.equals(empresa.id))).write(
        EmpresasCompanion(
          nombre: Value(datos.nombre.trim()),
          tipoNegocio: Value(datos.tipoNegocio),
          horaCierreMinutos: Value(datos.horaCierreMinutos),
        ),
      );
      await _anotarEnBitacora(
        empresaId: empresa.id,
        autorId: usuario.id,
        entidad: 'empresa',
        entidadId: empresa.id,
        accion: AccionBitacora.editar,
        anterior: {
          'nombre': empresa.nombre,
          'tipoNegocio': empresa.tipoNegocio.name,
          'horaCierreMinutos': empresa.horaCierreMinutos,
        },
        nuevo: {
          'nombre': datos.nombre.trim(),
          'tipoNegocio': datos.tipoNegocio.name,
          'horaCierreMinutos': datos.horaCierreMinutos,
        },
      );
      await _agregarCategorias(
        empresa.id,
        TipoMovimiento.egreso,
        categoriasEgresoPorNegocio[datos.tipoNegocio]!,
      );
      if (datos.saldos != null) {
        await _fijarSaldos(empresa.id, usuario.id, datos.saldos!);
      }
      await _pasarA(EtapaInicio.listo);
    });
  }

  @override
  Future<void> declararSaldo(Map<TipoCuenta, int> saldos) async {
    await _base.transaction(() async {
      final usuario = await _usuario();
      final empresa = (await _empresa())!;
      await _fijarSaldos(empresa.id, usuario.id, saldos);
    });
  }

  /// El saldo inicial es el de antes de la primera venta: rige desde el
  /// inicio del primer día. Una cuenta sin monto queda en cero.
  Future<void> _fijarSaldos(
    String empresaId,
    String autorId,
    Map<TipoCuenta, int> saldos,
  ) async {
    final primerMovimiento =
        await (_base.select(_base.movimientos)
              ..where((m) => m.empresaId.equals(empresaId))
              ..orderBy([(m) => OrderingTerm.asc(m.fechaMovimiento)])
              ..limit(1))
            .getSingleOrNull();
    final desde = inicioDelDia(primerMovimiento?.fechaMovimiento ?? _ahora());

    final cuentas = await (_base.select(
      _base.cuentas,
    )..where((c) => c.empresaId.equals(empresaId))).get();
    for (final cuenta in cuentas) {
      final saldo = saldos[cuenta.tipo] ?? 0;
      await (_base.update(
        _base.cuentas,
      )..where((c) => c.id.equals(cuenta.id))).write(
        CuentasCompanion(
          saldoInicialCentimos: Value(saldo),
          fechaSaldoInicial: Value(desde),
        ),
      );
      await _anotarEnBitacora(
        empresaId: empresaId,
        autorId: autorId,
        entidad: 'cuenta',
        entidadId: cuenta.id,
        accion: AccionBitacora.editar,
        anterior: {'saldoInicialCentimos': cuenta.saldoInicialCentimos},
        nuevo: {'saldoInicialCentimos': saldo},
      );
    }
  }

  // --- Resumen -----------------------------------------------------------------

  @override
  Stream<ResumenPrimerDia> observarResumen() {
    final cambios = _base.tableUpdates(
      TableUpdateQuery.onAllTables([
        _base.empresas,
        _base.cuentas,
        _base.movimientos,
        _base.categorias,
      ]),
    );
    return cambios
        .map((_) => null)
        .startWith(null)
        .asyncMap((_) => _calcularResumen());
  }

  Future<ResumenPrimerDia> _calcularResumen() async {
    final empresa = await _empresa();
    if (empresa == null) {
      return const ResumenPrimerDia(
        nombreNegocio: '',
        tienesHoyCentimos: 0,
        saldoPendiente: true,
        ventaDeHoyCentimos: 0,
        diasConVenta: 0,
      );
    }
    final cuentas = await (_base.select(
      _base.cuentas,
    )..where((c) => c.empresaId.equals(empresa.id))).get();
    final movimientos = await (_base.select(
      _base.movimientos,
    )..where((m) => m.empresaId.equals(empresa.id))).get();
    final ventaDelDia =
        await (_base.select(_base.categorias)..where(
              (c) =>
                  c.empresaId.equals(empresa.id) &
                  c.nombre.equals(categoriaVentaDelDia),
            ))
            .getSingleOrNull();

    var tienesHoy = 0;
    for (final cuenta in cuentas) {
      tienesHoy += saldoDeCuenta(
        saldoInicialCentimos: cuenta.saldoInicialCentimos,
        fechaSaldoInicial: cuenta.fechaSaldoInicial,
        movimientos: movimientos
            .where((m) => m.cuentaId == cuenta.id)
            .map(
              (m) => MovimientoParaSaldo(
                tipo: m.tipo,
                montoCentimos: m.montoCentimos,
                estado: m.estado,
                estadoPago: m.estadoPago,
                fecha: m.fechaPago ?? m.fechaMovimiento,
              ),
            ),
      );
    }

    final hoy = inicioDelDia(_ahora());
    final ventas = movimientos.where(
      (m) =>
          m.estado == EstadoRegistro.vigente &&
          m.tipo == TipoMovimiento.ingreso &&
          ventaDelDia != null &&
          m.categoriaId == ventaDelDia.id,
    );
    final ventaDeHoy = ventas
        .where((m) => inicioDelDia(m.fechaMovimiento) == hoy)
        .fold(0, (suma, m) => suma + m.montoCentimos);
    final dias = ventas.map((m) => inicioDelDia(m.fechaMovimiento)).toSet();

    return ResumenPrimerDia(
      nombreNegocio: empresa.nombre,
      tienesHoyCentimos: tienesHoy,
      saldoPendiente: cuentas.any((c) => c.saldoInicialCentimos == null),
      ventaDeHoyCentimos: ventaDeHoy,
      diasConVenta: dias.length,
    );
  }
}

extension _ConInicio<T> on Stream<T> {
  Stream<T> startWith(T valor) async* {
    yield valor;
    yield* this;
  }
}
