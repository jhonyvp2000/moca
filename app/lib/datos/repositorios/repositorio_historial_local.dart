import 'dart:convert';

import 'package:drift/drift.dart';

import '../../pais/peru/documentos.dart';
import '../../dominio/arqueo.dart';
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
      yo: (await _a.usuarioONulo())?.id,
      equipo: await _a.equipo(),
      empresa: empresa,
      cuentas: cuentas,
      movimientos: await _a.movimientos(empresa.id),
      categorias: {for (final c in categorias) c.id: c.nombre},
      contrapartes: {for (final c in contrapartes) c.id: c.nombre},
      clientes: {for (final c in contrapartes) c.id: c},
      comprobantes: {for (final c in comprobantes) c.id: c},
      ajustes: await _a.ajustes(empresa.id),
    );
  }

  FilaHistorial _filaDeAjuste(_Datos d, AjusteArqueo a) => FilaHistorial(
    id: a.id,
    tipo: a.centimos > 0 ? TipoMovimiento.ingreso : TipoMovimiento.egreso,
    montoCentimos: a.centimos.abs(),
    fecha: a.fecha,
    cuenta: d.tipoDeCuenta(a.cuentaId),
    loDebes: false,
    porSubir: false,
    ajusteArqueo: true,
  );

  /// Los ajustes que se muestran: los menores a S/ 1 no dicen nada al dueño.
  Iterable<AjusteArqueo> _ajustesVisibles(_Datos d) =>
      d.ajustes.where((a) => a.centimos.abs() >= toleranciaArqueoCentimos);

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
      // El anotado manda; si no hay, el del comprobante leído (entrega 66).
      documentoTipo: m.documentoTipo ?? comprobante?.tipo,
      documentoNumero:
          m.documentoNumero ??
          (comprobante == null
              ? null
              : [
                  comprobante.serie,
                  comprobante.numero,
                ].whereType<String>().join('-').nullSiVacio),
      cuentaDestino: m.cuentaDestinoId == null
          ? null
          : d.tipoDeCuenta(m.cuentaDestinoId!),
      deOtro: d.yo != null && m.autorId != d.yo,
      autorNombre: d.equipo[m.autorId]?.$1,
      autorRol: d.equipo[m.autorId]?.$2,
      anotadoEn: m.creadoEn,
      vence: m.fechaVencimiento,
      parteDe: m.abonaA,
      pagadoEnPartesCentimos: d
          .partesDe(m.id)
          .fold(0, (s, p) => s + p.montoCentimos),
      contraparteId: m.contraparteId,
      celular: d.clientes[m.contraparteId]?.celular,
      recordadoEn: d.clientes[m.contraparteId]?.recordadoEn,
      fechaPago: m.estadoPago == EstadoPago.pagado ? m.fechaPago : null,
    );
  }

  @override
  Stream<List<FilaHistorial>> observarLoQueDebes() =>
      _pendientes(TipoMovimiento.egreso);

  @override
  Stream<List<FilaHistorial>> observarLoQueTeDeben() =>
      _pendientes(TipoMovimiento.ingreso);

  Stream<List<FilaHistorial>> _pendientes(TipoMovimiento tipo) =>
      _a.cambios().asyncMap((_) async {
        final d = await _leer();
        if (d == null) return const <FilaHistorial>[];
        final deudas =
            [
              for (final m in d.movimientos)
                if (m.estado == EstadoRegistro.vigente &&
                    m.tipo == tipo &&
                    m.estadoPago != EstadoPago.pagado)
                  m,
            ]..sort(
              (a, b) => (a.fechaVencimiento ?? a.fechaMovimiento).compareTo(
                b.fechaVencimiento ?? b.fechaMovimiento,
              ),
            );
        return [
          for (final m in deudas)
            // Lo que falta pagar, como en el total del informe.
            _fila(d, m).conMonto(m.montoCentimos - m.montoPagadoCentimos),
        ];
      });

  @override
  Stream<List<FilaHistorial>> observarDeCategoria(ConsultaDeCategoria c) =>
      _a.cambios().asyncMap((_) async {
        final d = await _leer();
        if (d == null) return const <FilaHistorial>[];
        // La misma regla del informe (RepositorioInformeLocal): lo pagado,
        // desde el saldo inicial de su cuenta, el día en que se movió.
        final desdeDe = {for (final k in d.cuentas) k.id: k.fechaSaldoInicial};
        final ahora = _a.ahora();
        final actual = DateTime(ahora.year, ahora.month);
        final enCurso = c.anual ? c.mes.year == ahora.year : c.mes == actual;
        final hasta = enCurso
            ? inicioDelDia(ahora).add(const Duration(days: 1))
            : c.anual
            ? DateTime(c.mes.year + 1)
            : DateTime(c.mes.year, c.mes.month + 1);
        DateTime fecha(Movimiento m) => m.fechaPago ?? m.fechaMovimiento;
        bool entra(Movimiento m) {
          if (m.estado != EstadoRegistro.vigente ||
              m.tipo != c.tipo ||
              m.estadoPago != EstadoPago.pagado) {
            return false;
          }
          final f = fecha(m);
          final desde = desdeDe[m.cuentaId];
          if (desde != null && f.isBefore(desde)) return false;
          if (f.isBefore(c.mes) || !f.isBefore(hasta)) return false;
          final nombre = d.categorias[m.categoriaId] ?? 'Otros';
          final nombres = c.nombres;
          return nombres == null
              ? !c.salvo.contains(nombre)
              : nombres.contains(nombre);
        }

        final elegidos = d.movimientos.where(entra).toList()
          ..sort((a, b) => fecha(b).compareTo(fecha(a)));
        return [for (final m in elegidos) _fila(d, m)];
      });

  @override
  Stream<ResumenHistorial> observarHistorial() => _a.cambios().asyncMap((
    _,
  ) async {
    final d = await _leer();
    if (d == null) return const ResumenHistorial(filas: []);
    final vigentes = d.movimientos.where(
      (m) => m.estado == EstadoRegistro.vigente,
    );
    final filas =
        [
          for (final m in vigentes) (m.creadoEn, _fila(d, m)),
          // Lo cobrado o pagado otro día sale también el día del pago
          // (entrega 55).
          for (final m in vigentes)
            if (_fila(d, m) case final f when f.pagadoOtroDia)
              (f.fechaPago!, f.comoPago()),
          for (final a in _ajustesVisibles(d)) (a.fecha, _filaDeAjuste(d, a)),
        ]..sort((a, b) {
          final porFecha = b.$2.fecha.compareTo(a.$2.fecha);
          return porFecha != 0 ? porFecha : b.$1.compareTo(a.$1);
        });
    return ResumenHistorial(filas: [for (final (_, f) in filas) f]);
  });

  @override
  Stream<DetalleMovimiento?> observarDetalle(
    String id,
  ) => _a.cambios().asyncMap((_) async {
    final d = await _leer();
    if (d == null) return null;
    final m = d.movimiento(id);
    if (m == null) {
      final a = d.ajustes.where((a) => a.id == id).firstOrNull;
      if (a == null) return null;
      return DetalleMovimiento(
        fila: _filaDeAjuste(d, a),
        vigente: true,
        fuente: Fuente.arqueo,
        cambios: [CambioCreado(a.fecha, Fuente.arqueo)],
        saldoSiSeDeshaceCentimos: null,
        ajuste: AjusteVista(
          calculadoCentimos: a.calculadoCentimos,
          contadoCentimos: a.contadoCentimos,
          motivo: a.motivo,
        ),
      );
    }
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
      // Pagos en partes (entrega 44).
      partes: [
        for (final p in d.partesDe(m.id))
          ParteDePago(
            id: p.id,
            fechaPago: p.fechaPago ?? p.fechaMovimiento,
            cuenta: d.tipoDeCuenta(p.cuentaId),
            montoCentimos: p.montoCentimos,
          ),
      ],
      deuda: switch (m.abonaA) {
        final id? => switch (d.movimiento(id)) {
          final deuda? => DeudaDeLaParte(
            id: deuda.id,
            tipo: deuda.tipo,
            faltaCentimos:
                deuda.estado == EstadoRegistro.vigente &&
                    deuda.estadoPago != EstadoPago.pagado
                ? deuda.montoCentimos - deuda.montoPagadoCentimos
                : 0,
            abierta:
                deuda.estado == EstadoRegistro.vigente &&
                deuda.estadoPago != EstadoPago.pagado,
          ),
          null => null,
        },
        null => null,
      },
      trabaAlCorregir: _trabaAlCorregir(d, m),
      trabaAlDeshacer: _trabaAlDeshacer(d, m),
      sePuedeDeshacerElPago: await _fuePagadaComoDeuda(m),
      saldoSiSeDeshaceElPagoCentimos: await _fuePagadaComoDeuda(m)
          ? d.saldoCon(m.cuentaId, _otraVezDeuda(m))
          : null,
    );
  });

  /// Fue una deuda y se pagó completa con «Ya lo pagué» o «Ya me pagó»
  /// (entrega 44.2): lo dice su bitácora.
  Future<bool> _fuePagadaComoDeuda(Movimiento m) async {
    if (m.estado != EstadoRegistro.vigente ||
        m.estadoPago != EstadoPago.pagado ||
        m.abonaA != null) {
      return false;
    }
    final pagos =
        await (_base.select(_base.bitacora)..where(
              (b) =>
                  b.entidad.equals(_entidad) &
                  b.entidadId.equals(m.id) &
                  b.accion.equalsValue(AccionBitacora.pagar),
            ))
            .get();
    return pagos.any(
      (p) => !_leerJson(p.valorNuevo).containsKey('parteCentimos'),
    );
  }

  /// El registro otra vez como deuda: no ha movido ninguna cuenta.
  static Movimiento _otraVezDeuda(Movimiento m) => m.copyWith(
    estadoPago: EstadoPago.pendiente,
    montoPagadoCentimos: 0,
    fechaPago: const Value(null),
  );

  @override
  Future<void> guardarCelular(String contraparteId, String? celular) =>
      (_base.update(_base.contrapartes)
            ..where((c) => c.id.equals(contraparteId)))
          .write(ContrapartesCompanion(celular: Value(celular)));

  @override
  Future<void> marcarRecordado(String contraparteId) =>
      (_base.update(_base.contrapartes)
            ..where((c) => c.id.equals(contraparteId)))
          .write(ContrapartesCompanion(recordadoEn: Value(_a.ahora())));

  @override
  Future<int> deshacerPago(String id) => _base.transaction(() async {
    final d = (await _leer())!;
    final m = await _vigente(d, id);
    if (!await _fuePagadaComoDeuda(m)) {
      throw StateError('No fue una deuda pagada.');
    }
    final deuda = _otraVezDeuda(m);
    final estado = await _a.estadoAlGuardar();
    await (_base.update(
      _base.movimientos,
    )..where((x) => x.id.equals(m.id))).write(
      MovimientosCompanion(
        estadoPago: const Value(EstadoPago.pendiente),
        montoPagadoCentimos: const Value(0),
        fechaPago: const Value(null),
        estadoSincronizacion: estado == EstadoSincronizacion.porSubir
            ? const Value(EstadoSincronizacion.porSubir)
            : const Value.absent(),
      ),
    );
    await _a.anotarEnBitacora(
      empresaId: d.empresa.id,
      autorId: (await _a.usuario()).id,
      entidad: _entidad,
      entidadId: m.id,
      accion: AccionBitacora.editar,
      anterior: {
        'estadoPago': m.estadoPago.name,
        'cuenta': d.tipoDeCuenta(m.cuentaId).name,
        'fechaPago': m.fechaPago?.toIso8601String(),
      },
      nuevo: {'estadoPago': EstadoPago.pendiente.name, 'deshacerPago': true},
    );
    return d.saldoCon(m.cuentaId, deuda);
  });

  /// Una deuda con partes, o una parte, no se corrige (entrega 44).
  static TrabaDelRegistro? _trabaAlCorregir(_Datos d, Movimiento m) {
    if (m.abonaA != null) return TrabaDelRegistro.esParte;
    if (d.partesDe(m.id).isNotEmpty) return TrabaDelRegistro.tienePartes;
    return null;
  }

  /// Una deuda con partes no se deshace; una parte, solo la más reciente
  /// y con la deuda abierta (entrega 44).
  static TrabaDelRegistro? _trabaAlDeshacer(_Datos d, Movimiento m) {
    if (d.partesDe(m.id).isNotEmpty) return TrabaDelRegistro.tienePartes;
    final deudaId = m.abonaA;
    if (deudaId == null) return null;
    final deuda = d.movimiento(deudaId);
    final abierta =
        deuda != null &&
        deuda.estado == EstadoRegistro.vigente &&
        deuda.estadoPago != EstadoPago.pagado;
    final ultima = d.partesDe(deudaId).lastOrNull;
    return abierta && ultima?.id == m.id
        ? null
        : TrabaDelRegistro.noEsLaUltimaParte;
  }

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

  static Map<String, Object?> _leerJson(String? json) => json == null
      ? const {}
      : (jsonDecode(json) as Map).cast<String, Object?>();

  Cambio? _cambio(_Datos d, BitacoraData fila) {
    final anterior = _leerJson(fila.valorAnterior);
    final nuevo = _leerJson(fila.valorNuevo);
    // Se deshizo un cobro o un pago (entrega 44.2).
    if (fila.accion == AccionBitacora.editar && nuevo['deshacerPago'] == true) {
      return CambioPagoDeshecho(
        fila.fecha,
        cobro: d.movimiento(fila.entidadId)?.tipo == TipoMovimiento.ingreso,
      );
    }
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
        // Entrega 66: una corrección de antes no los trae, y no cuenta.
        if (anterior.containsKey('documento')) {
          comparar(CampoMovimiento.documento, (v) => v, 'documento');
          comparar(CampoMovimiento.institucion, (v) => v, 'contraparte');
        }
        return CambioCorregido(fila.fecha, campos);
      case AccionBitacora.pagar:
        final cuenta = TipoCuenta.values.asNameMap()[nuevo['cuenta']];
        final fecha = DateTime.tryParse('${nuevo['fechaPago']}');
        if (cuenta == null || fecha == null) return null;
        return CambioPagado(
          fila.fecha,
          cuenta,
          fecha,
          parteCentimos: nuevo['parteCentimos'] as int?,
          cobro: d.movimiento(fila.entidadId)?.tipo == TipoMovimiento.ingreso,
        );
      case AccionBitacora.anular:
        return CambioDeshecho(fila.fecha);
      case AccionBitacora.arquear:
        return null;
    }
  }

  // --- Corregir ----------------------------------------------------------------

  /// Lo que se puede corregir: en una compra con comprobante, el monto y el
  /// tipo son los del comprobante y no cambian.
  ///
  /// Una compra escrita puede pasar a deberse o a estar pagada (entrega 41);
  /// la de un comprobante sigue como estaba.
  Movimiento _corregido(
    _Datos d,
    Movimiento m,
    NuevoMovimiento c, {
    String? contraparteId,
  }) {
    final conComprobante = m.comprobanteId != null;
    final tipo = conComprobante ? m.tipo : c.tipo;
    final monto = conComprobante ? m.montoCentimos : c.montoCentimos;
    final nota = c.nota?.trim();
    final debia = m.estadoPago != EstadoPago.pagado;
    final debe = conComprobante ? debia : c.pendiente;
    return m.copyWith(
      tipo: tipo,
      montoCentimos: monto,
      estadoPago: debe ? EstadoPago.pendiente : EstadoPago.pagado,
      montoPagadoCentimos: debe ? (debia ? m.montoPagadoCentimos : 0) : monto,
      // Al dejar de deberse, la plata sale hoy; al pasar a deberse, todavía
      // no ha salido.
      fechaPago: Value(
        debe
            ? (debia ? m.fechaPago : null)
            : (debia ? _a.ahora() : m.fechaPago),
      ),
      // La institución se puede cambiar aun con comprobante (entrega 66);
      // si se deja vacía, el comprobante conserva su emisor.
      contraparteId: Value(
        tipo.sinCategoria
            ? null
            : conComprobante
            ? (contraparteId ?? m.contraparteId)
            : contraparteId,
      ),
      cuentaId: d.idDeCuenta(c.cuenta),
      // Un pase lleva su destino (entrega 21.1).
      cuentaDestinoId: Value(
        tipo.esPase && c.cuentaDestino != null
            ? d.idDeCuenta(c.cuentaDestino!)
            : null,
      ),
      // Un retiro para el dueño y un pase no llevan categoría.
      categoriaId: Value(tipo.sinCategoria ? null : c.categoriaId),
      nota: Value(nota == null || nota.isEmpty ? null : nota),
      // El documento, editable siempre (entrega 66).
      documentoTipo: Value(tipo.sinCategoria ? null : _limpio(c.documentoTipo)),
      documentoNumero: Value(
        tipo.sinCategoria ? null : _limpio(c.documentoNumero),
      ),
    );
  }

  static String? _limpio(String? texto) {
    final t = texto?.trim();
    return t == null || t.isEmpty ? null : t;
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
    final nuevo = _corregido(d, m, correccion);
    if (nuevo.estadoPago != EstadoPago.pagado) return null;
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
    'pagado': m.estadoPago == EstadoPago.pagado,
    // Entrega 66: el documento y con quién.
    'documento': textoDelDocumento(m.documentoTipo, m.documentoNumero),
    'contraparte': d.contrapartes[m.contraparteId],
  };

  @override
  Future<Guardado> corregir(String id, NuevoMovimiento correccion) {
    if (correccion.montoCentimos <= 0) {
      throw ArgumentError('El monto tiene que ser mayor que cero.');
    }
    return _base.transaction(() async {
      final d = (await _leer())!;
      final m = await _vigente(d, id);
      if (_trabaAlCorregir(d, m) case final traba?) {
        throw StateError(traba.name);
      }
      if (m.comprobanteId == null && correccion.faltaQuienDebe) {
        throw ArgumentError('Una venta a crédito lleva quién la debe.');
      }
      // Con comprobante, el tipo y si se debe no cambian: el nombre que
      // cuenta es la institución (entrega 66).
      final tipo = m.comprobanteId != null ? m.tipo : correccion.tipo;
      final nombre = m.comprobanteId != null
          ? _limpio(correccion.institucion)
          : correccion.nombreContraparte;
      final corregido = _corregido(
        d,
        m,
        correccion,
        contraparteId: nombre == null || tipo.sinCategoria
            ? null
            : await _a.contraparte(
                d.empresa.id,
                tipo: tipo == TipoMovimiento.ingreso
                    ? TipoContraparte.cliente
                    : TipoContraparte.proveedor,
                nombre: nombre,
              ),
      );
      if (!corregido.tipo.sinCategoria && corregido.categoriaId == null) {
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
        nuevo: {
          ..._valores(d, corregido),
          // Un nombre nuevo todavía no está en lo leído.
          if (corregido.contraparteId != null &&
              !d.contrapartes.containsKey(corregido.contraparteId))
            'contraparte': nombre,
          'reemplazadoPor': nuevoId,
        },
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

  /// Un pago en parte (entrega 44): un registro pagado de la misma deuda,
  /// con su cuenta y su día, que dice de qué deuda es.
  Movimiento _parte(
    _Datos d,
    Movimiento m, {
    required String id,
    required TipoCuenta cuenta,
    required DateTime fecha,
    required int centimos,
    required String autorId,
    required EstadoSincronizacion estado,
    required DateTime creadoEn,
  }) => m.copyWith(
    id: id,
    cuentaId: d.idDeCuenta(cuenta),
    montoCentimos: centimos,
    estadoPago: EstadoPago.pagado,
    montoPagadoCentimos: centimos,
    fechaMovimiento: fecha,
    fechaPago: Value(fecha),
    fechaComprobante: const Value(null),
    fechaVencimiento: const Value(null),
    comprobanteId: const Value(null),
    reemplazaA: const Value(null),
    abonaA: Value(m.id),
    autorId: autorId,
    estado: EstadoRegistro.vigente,
    estadoSincronizacion: estado,
    creadoEn: creadoEn,
  );

  /// Una parte vale si es más que cero y menos de lo que falta.
  static void _validarParte(Movimiento m, int parte) {
    if (parte <= 0 || parte >= m.montoCentimos - m.montoPagadoCentimos) {
      throw ArgumentError('La parte tiene que ser menos de lo que falta.');
    }
  }

  @override
  Future<int> saldoSiSePaga(
    String id,
    TipoCuenta cuenta, {
    int? parteCentimos,
  }) async {
    final d = (await _leer())!;
    final m = await _porPagar(d, id);
    if (parteCentimos == null) {
      final pagado = _pagado(d, m, cuenta, _a.ahora());
      return d.saldoCon(pagado.cuentaId, pagado);
    }
    _validarParte(m, parteCentimos);
    final parte = _parte(
      d,
      m,
      id: '_parte',
      cuenta: cuenta,
      fecha: _a.ahora(),
      centimos: parteCentimos,
      autorId: m.autorId,
      estado: m.estadoSincronizacion,
      creadoEn: _a.ahora(),
    );
    return d.saldoCon(
      parte.cuentaId,
      m.copyWith(montoCentimos: m.montoCentimos - parteCentimos),
      extra: parte,
    );
  }

  @override
  Future<int> pagar(
    String id, {
    required TipoCuenta cuenta,
    required DateTime dia,
    int? parteCentimos,
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
    final estado = await _a.estadoAlGuardar();
    if (parteCentimos != null) {
      return _pagarParte(d, m, cuenta, fecha, parteCentimos, estado);
    }
    final pagado = _pagado(d, m, cuenta, fecha);
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

  /// Paga una parte (entrega 44): un registro pagado nuevo, y la deuda se
  /// queda con lo que falta.
  Future<int> _pagarParte(
    _Datos d,
    Movimiento m,
    TipoCuenta cuenta,
    DateTime fecha,
    int centimos,
    EstadoSincronizacion estado,
  ) async {
    _validarParte(m, centimos);
    final usuario = await _a.usuario();
    final parte = _parte(
      d,
      m,
      id: _a.nuevoId(),
      cuenta: cuenta,
      fecha: fecha,
      centimos: centimos,
      autorId: usuario.id,
      estado: estado,
      creadoEn: _a.ahora(),
    );
    await _base.into(_base.movimientos).insert(parte);
    final queda = m.copyWith(montoCentimos: m.montoCentimos - centimos);
    await (_base.update(
      _base.movimientos,
    )..where((x) => x.id.equals(m.id))).write(
      MovimientosCompanion(
        montoCentimos: Value(queda.montoCentimos),
        estadoSincronizacion: estado == EstadoSincronizacion.porSubir
            ? const Value(EstadoSincronizacion.porSubir)
            : const Value.absent(),
      ),
    );
    await _a.anotarEnBitacora(
      empresaId: d.empresa.id,
      autorId: usuario.id,
      entidad: _entidad,
      entidadId: parte.id,
      accion: AccionBitacora.crear,
      nuevo: {
        'tipo': parte.tipo.name,
        'cuenta': cuenta.name,
        'montoCentimos': centimos,
        'categoriaId': parte.categoriaId,
        'abonaA': m.id,
        'fuente': parte.fuente.name,
      },
    );
    await _a.anotarEnBitacora(
      empresaId: d.empresa.id,
      autorId: usuario.id,
      entidad: _entidad,
      entidadId: m.id,
      accion: AccionBitacora.pagar,
      anterior: {'montoCentimos': m.montoCentimos},
      nuevo: {
        'cuenta': cuenta.name,
        'fechaPago': fecha.toIso8601String(),
        'parteCentimos': centimos,
        'parte': parte.id,
        'montoCentimos': queda.montoCentimos,
      },
    );
    return d.saldoCon(parte.cuentaId, queda, extra: parte);
  }

  // --- Deshacer ----------------------------------------------------------------

  @override
  Future<void> deshacer(String id) => _base.transaction(() async {
    final d = await _leer();
    final m = d?.movimiento(id);
    if (d != null && m != null && m.estado == EstadoRegistro.vigente) {
      if (_trabaAlDeshacer(d, m) case final traba?) {
        throw StateError(traba.name);
      }
      // Deshacer una parte devuelve lo pagado a la deuda (entrega 44).
      if (m.abonaA case final deudaId?) {
        final deuda = d.movimiento(deudaId)!;
        final vuelve = deuda.copyWith(
          montoCentimos: deuda.montoCentimos + m.montoCentimos,
        );
        await (_base.update(
          _base.movimientos,
        )..where((x) => x.id.equals(deuda.id))).write(
          MovimientosCompanion(
            montoCentimos: Value(vuelve.montoCentimos),
            estadoSincronizacion:
                await _a.estadoAlGuardar() == EstadoSincronizacion.porSubir
                ? const Value(EstadoSincronizacion.porSubir)
                : const Value.absent(),
          ),
        );
        await _a.anotarEnBitacora(
          empresaId: d.empresa.id,
          autorId: (await _a.usuario()).id,
          entidad: _entidad,
          entidadId: deuda.id,
          accion: AccionBitacora.editar,
          anterior: _valores(d, deuda),
          nuevo: _valores(d, vuelve),
        );
      }
    }
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
    return _a.tienesHoy(empresa.id);
  }
}

class _Datos {
  _Datos({
    required this.yo,
    required this.equipo,
    required this.empresa,
    required this.cuentas,
    required this.movimientos,
    required this.categorias,
    required this.contrapartes,
    required this.clientes,
    required this.comprobantes,
    required this.ajustes,
  });

  /// Quien usa el teléfono y los nombres del equipo (entrega 20).
  final String? yo;
  final Map<String, (String?, Rol?)> equipo;
  final Empresa empresa;
  final List<Cuenta> cuentas;
  final List<Movimiento> movimientos;
  final Map<String, String> categorias;
  final Map<String, String> contrapartes;

  /// Las filas completas, con el celular y el último recordatorio (53).
  final Map<String, Contraparte> clientes;
  final Map<String, Comprobante> comprobantes;
  final List<AjusteArqueo> ajustes;

  Movimiento? movimiento(String id) =>
      movimientos.where((m) => m.id == id).firstOrNull;

  /// Los pagos en partes vigentes de una deuda, del más viejo al más nuevo
  /// (entrega 44).
  List<Movimiento> partesDe(String deudaId) =>
      movimientos
          .where(
            (m) => m.abonaA == deudaId && m.estado == EstadoRegistro.vigente,
          )
          .toList()
        ..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));

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
    return AccesoLocal.saldosPorCuenta(
      [cuenta],
      lista,
      ajustes: ajustes,
    )[cuenta.tipo]!;
  }
}

extension on String {
  String? get nullSiVacio => isEmpty ? null : this;
}
