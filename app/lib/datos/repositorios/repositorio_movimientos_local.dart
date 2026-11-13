import 'package:drift/drift.dart';

import '../../dominio/modelos.dart';
import '../../dominio/movimientos.dart';
import '../../pais/peru/categorias.dart';
import '../calculos/saldos.dart';
import '../calculos/semana.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

class RepositorioMovimientosLocal implements RepositorioMovimientos {
  RepositorioMovimientosLocal(
    BaseLocal base, {
    DateTime Function()? ahora,
    Future<bool> Function()? hayConexion,
  }) : _a = AccesoLocal(base, ahora ?? DateTime.now, hayConexion: hayConexion);

  final AccesoLocal _a;
  BaseLocal get _base => _a.base;

  /// Ajuste del operador: mostrar S04 sin esperar la primera semana.
  static const claveSaltarPrimeraSemana = 'primera_semana_saltada';
  static const _duracionPrimeraSemana = Duration(days: 7);

  // --- Inicio ----------------------------------------------------------------

  @override
  Stream<ResumenInicio> observarInicio() =>
      _a.cambios().asyncMap((_) => _calcularInicio());

  Future<ResumenInicio> _calcularInicio() async {
    final empresa = await _a.empresa();
    if (empresa == null) {
      return const ResumenInicio(
        nombreNegocio: '',
        saldosPorCuenta: {},
        semanaEntroCentimos: 0,
        semanaSalioCentimos: 0,
        semanaConMovimientos: false,
        diferenciaConSemanaAnteriorCentimos: null,
        ventaDeHoyCentimos: 0,
        mostrarPrimerDia: true,
      );
    }
    final ahora = _a.ahora();
    final cuentas = await _a.cuentas(empresa.id);
    final movimientos = await _a.movimientos(empresa.id);

    // Las cifras del servidor, si valen (entrega 13).
    if (await _a.cifrasDelServidor() case final cifras?) {
      final i = cifras.inicio;
      return ResumenInicio(
        nombreNegocio: empresa.nombre,
        saldosPorCuenta: cifras.saldos,
        semanaEntroCentimos: i.semanaEntroCentimos,
        semanaSalioCentimos: i.semanaSalioCentimos,
        semanaRetirosCentimos: i.semanaRetirosCentimos,
        semanaAportesCentimos: i.semanaAportesCentimos,
        semanaConMovimientos: i.semanaConMovimientos,
        diferenciaConSemanaAnteriorCentimos:
            i.diferenciaConSemanaAnteriorCentimos,
        ventaDeHoyCentimos: i.ventaDeHoyCentimos,
        // Lo fiado de hoy sale de lo que tiene el teléfono (entrega 51).
        fiadoDeHoyCentimos: await _fiadoDeHoy(empresa.id, movimientos),
        mostrarPrimerDia: await _esPrimeraSemana(empresa.id, movimientos),
        estadoArqueo: await _a.estadoArqueo(empresa.id, movimientos),
      );
    }

    final paraCalculo = movimientos.map(AccesoLocal.paraSaldo).toList();

    final lunes = inicioDeSemana(ahora);
    // Hasta el final de hoy: incluye lo que se acaba de anotar.
    final manana = inicioDelDia(ahora).add(const Duration(days: 1));
    final semana = resumirPeriodo(paraCalculo, desde: lunes, hasta: manana);
    final lunesPasado = lunes.subtract(const Duration(days: 7));
    final semanaPasadaCompleta = resumirPeriodo(
      paraCalculo,
      desde: lunesPasado,
      hasta: lunes,
    );
    // Se compara con la semana pasada hasta el mismo día.
    final semanaPasadaHastaHoy = resumirPeriodo(
      paraCalculo,
      desde: lunesPasado,
      hasta: manana.subtract(const Duration(days: 7)),
    );

    return ResumenInicio(
      nombreNegocio: empresa.nombre,
      saldosPorCuenta: AccesoLocal.saldosPorCuenta(
        cuentas,
        movimientos,
        ajustes: await _a.ajustes(empresa.id),
      ),
      semanaEntroCentimos: semana.entroCentimos,
      semanaSalioCentimos: semana.salioCentimos,
      semanaRetirosCentimos: semana.retirosCentimos,
      semanaAportesCentimos: semana.aportesCentimos,
      semanaConMovimientos: semana.cantidad > 0,
      diferenciaConSemanaAnteriorCentimos: semanaPasadaCompleta.cantidad > 0
          ? semana.quedoCentimos - semanaPasadaHastaHoy.quedoCentimos
          : null,
      ventaDeHoyCentimos: await _ventaDeHoy(empresa.id, movimientos),
      fiadoDeHoyCentimos: await _fiadoDeHoy(empresa.id, movimientos),
      mostrarPrimerDia: await _esPrimeraSemana(empresa.id, movimientos),
      estadoArqueo: await _a.estadoArqueo(empresa.id, movimientos),
    );
  }

  /// De la venta de hoy, lo que se fió y falta cobrar (entrega 51): lo
  /// mismo que cuenta «Lo que te deben».
  Future<int> _fiadoDeHoy(String empresaId, List<Movimiento> movs) async {
    final venta = await _categoriaVentaDelDia(empresaId);
    final hoy = inicioDelDia(_a.ahora());
    return movs
        .where(
          (m) =>
              m.estado == EstadoRegistro.vigente &&
              m.categoriaId == venta.id &&
              m.estadoPago != EstadoPago.pagado &&
              inicioDelDia(m.fechaMovimiento) == hoy,
        )
        .fold<int>(
          0,
          (suma, m) => suma + m.montoCentimos - m.montoPagadoCentimos,
        );
  }

  Future<int> _ventaDeHoy(String empresaId, List<Movimiento> movs) async {
    final venta = await _categoriaVentaDelDia(empresaId);
    final hoy = inicioDelDia(_a.ahora());
    return movs
        .where(
          (m) =>
              m.estado == EstadoRegistro.vigente &&
              m.categoriaId == venta.id &&
              inicioDelDia(m.fechaMovimiento) == hoy,
        )
        .fold<int>(0, (suma, m) => suma + m.montoCentimos);
  }

  Future<bool> _esPrimeraSemana(
    String empresaId,
    List<Movimiento> movimientos,
  ) async {
    if (await _a.leerAjuste(claveSaltarPrimeraSemana) != null) return false;
    final arqueos = await (_base.select(
      _base.arqueos,
    )..where((a) => a.empresaId.equals(empresaId))).get();
    if (arqueos.isNotEmpty) return false;
    if (movimientos.isEmpty) return true;
    final primero = movimientos
        .map((m) => m.fechaMovimiento)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return _a.ahora().isBefore(primero.add(_duracionPrimeraSemana));
  }

  // --- Categorías --------------------------------------------------------------

  @override
  Future<List<CategoriaVista>> categorias(TipoMovimiento tipo) async {
    final empresa = await _a.empresa();
    if (empresa == null || tipo.delDueno) return const [];
    final filas =
        await (_base.select(_base.categorias)
              ..where(
                (c) =>
                    c.empresaId.equals(empresa.id) &
                    c.tipoMovimiento.equalsValue(tipo) &
                    c.activa.equals(true),
              )
              ..orderBy([(c) => OrderingTerm.asc(c.orden)]))
            .get();
    return [for (final c in filas) CategoriaVista(id: c.id, nombre: c.nombre)];
  }

  Future<Categoria> _categoriaVentaDelDia(String empresaId) =>
      (_base.select(_base.categorias)..where(
            (c) =>
                c.empresaId.equals(empresaId) &
                c.nombre.equals(categoriaVentaDelDia),
          ))
          .getSingle();

  // --- Guardar -----------------------------------------------------------------

  @override
  Future<int> saldoSiSeGuarda(NuevoMovimiento m) async {
    final empresa = (await _a.empresa())!;
    final saldos = await _a.saldos(empresa.id);
    final actual = saldos[m.cuenta] ?? 0;
    return switch (m.tipo) {
      TipoMovimiento.ingreso ||
      TipoMovimiento.aporte => actual + m.montoCentimos,
      TipoMovimiento.egreso ||
      TipoMovimiento.retiro ||
      TipoMovimiento.transferencia => actual - m.montoCentimos,
    };
  }

  @override
  Future<Guardado> registrar(NuevoMovimiento m) async {
    if (m.montoCentimos <= 0) {
      throw ArgumentError('El monto tiene que ser mayor que cero.');
    }
    if (!m.tipo.sinCategoria && m.categoriaId == null) {
      throw ArgumentError('Entró y salió llevan categoría.');
    }
    if (m.tipo.esPase &&
        (m.cuentaDestino == null || m.cuentaDestino == m.cuenta)) {
      throw ArgumentError('Un pase va de una cuenta a otra distinta.');
    }
    if (m.faltaQuienDebe) {
      throw ArgumentError('Una venta a crédito lleva quién la debe.');
    }
    return _base.transaction(() async {
      final id = await _insertar(
        tipo: m.tipo,
        cuenta: m.cuenta,
        montoCentimos: m.montoCentimos,
        cuentaDestino: m.tipo.esPase ? m.cuentaDestino : null,
        // La plata entre el dueño y el negocio y los pases no llevan
        // categoría.
        categoriaId: m.tipo.sinCategoria ? null : m.categoriaId,
        nota: m.nota?.trim().isEmpty ?? true ? null : m.nota!.trim(),
        fuente: m.fuente,
        pendiente: m.pendiente,
        // Con quién y con qué documento, solo en Entró y Salió (entrega 66).
        contraparte: m.tipo.sinCategoria ? null : m.nombreContraparte,
        celular: m.pendiente ? m.celularContraparte : null,
        documentoTipo: m.tipo.sinCategoria ? null : _limpio(m.documentoTipo),
        documentoNumero: m.tipo.sinCategoria
            ? null
            : _limpio(m.documentoNumero),
      );
      return Guardado(ids: [id], tienesHoyCentimos: await _tienesHoy());
    });
  }

  @override
  Future<Guardado> anotarVentaDelDia(
    Map<TipoCuenta, int> ventaPorCuenta, {
    Fuente fuente = Fuente.texto,
    FiadoDelDia? fiado,
  }) {
    final conFiado = fiado != null && fiado.montoCentimos > 0;
    if (!ventaPorCuenta.values.any((monto) => monto > 0) && !conFiado) {
      throw ArgumentError('La venta necesita al menos un monto.');
    }
    if (conFiado && fiado.quien.trim().isEmpty) {
      throw ArgumentError('Lo fiado necesita a quién.');
    }
    return _base.transaction(() async {
      final empresa = (await _a.empresa())!;
      final venta = await _categoriaVentaDelDia(empresa.id);
      final ids = <String>[];
      for (final MapEntry(key: cuenta, value: monto)
          in ventaPorCuenta.entries) {
        if (monto <= 0) continue;
        ids.add(
          await _insertar(
            tipo: TipoMovimiento.ingreso,
            cuenta: cuenta,
            montoCentimos: monto,
            categoriaId: venta.id,
            fuente: fuente,
          ),
        );
      }
      // Lo fiado (entrega 52): una venta que todavía te deben.
      if (conFiado) {
        ids.add(
          await _insertar(
            tipo: TipoMovimiento.ingreso,
            cuenta: fiado.cuenta,
            montoCentimos: fiado.montoCentimos,
            categoriaId: venta.id,
            fuente: fuente,
            pendiente: true,
            contraparte: fiado.quien.trim(),
            celular: fiado.celular,
          ),
        );
      }
      return Guardado(ids: ids, tienesHoyCentimos: await _tienesHoy());
    });
  }

  Future<String> _insertar({
    required TipoMovimiento tipo,
    required TipoCuenta cuenta,
    required int montoCentimos,
    TipoCuenta? cuentaDestino,
    String? categoriaId,
    String? nota,
    Fuente fuente = Fuente.texto,
    bool pendiente = false,
    String? contraparte,
    String? celular,
    String? documentoTipo,
    String? documentoNumero,
  }) async {
    final empresa = (await _a.empresa())!;
    final usuario = await _a.usuario();
    final cuentas = await _a.cuentas(empresa.id);
    final cuentaId = cuentas.firstWhere((c) => c.tipo == cuenta).id;
    final destinoId = cuentaDestino == null
        ? null
        : cuentas.firstWhere((c) => c.tipo == cuentaDestino).id;
    final ahora = _a.ahora();
    final id = _a.nuevoId();
    final contraparteId = contraparte != null
        ? await _a.contraparte(
            empresa.id,
            tipo: tipo == TipoMovimiento.ingreso
                ? TipoContraparte.cliente
                : TipoContraparte.proveedor,
            nombre: contraparte,
            celular: celular,
          )
        : null;
    await _base
        .into(_base.movimientos)
        .insert(
          MovimientosCompanion.insert(
            id: id,
            empresaId: empresa.id,
            tipo: tipo,
            cuentaId: cuentaId,
            cuentaDestinoId: Value(destinoId),
            montoCentimos: montoCentimos,
            fechaMovimiento: ahora,
            // Lo que se debe (entrega 41) o te deben (entrega 42) no ha
            // movido ninguna cuenta todavía: la cuenta se elige al pagarlo.
            estadoPago: pendiente ? EstadoPago.pendiente : EstadoPago.pagado,
            montoPagadoCentimos: pendiente ? 0 : montoCentimos,
            fechaPago: Value(pendiente ? null : ahora),
            contraparteId: Value(contraparteId),
            categoriaId: Value(categoriaId),
            nota: Value(nota),
            documentoTipo: Value(documentoTipo),
            documentoNumero: Value(documentoNumero),
            // Escrito o dicho por el dueño, sin comprobante: nivel D.
            nivelConfianza: NivelConfianza.d,
            fuente: fuente,
            autorId: usuario.id,
            estado: EstadoRegistro.vigente,
            estadoSincronizacion: await _a.estadoAlGuardar(),
            creadoEn: ahora,
          ),
        );
    await _a.anotarEnBitacora(
      empresaId: empresa.id,
      autorId: usuario.id,
      entidad: 'movimiento',
      entidadId: id,
      accion: AccionBitacora.crear,
      nuevo: {
        'tipo': tipo.name,
        'cuenta': cuenta.name,
        'cuentaDestino': ?cuentaDestino?.name,
        'montoCentimos': montoCentimos,
        'categoriaId': categoriaId,
        'nota': nota,
        'fuente': fuente.name,
        if (pendiente) 'pagado': false,
        'documentoTipo': ?documentoTipo,
        'documentoNumero': ?documentoNumero,
        'contraparte': ?contraparte,
      },
    );
    return id;
  }

  Future<int> _tienesHoy() async {
    final empresa = (await _a.empresa())!;
    return _a.tienesHoy(empresa.id);
  }

  @override
  Future<void> deshacer(Guardado guardado) => _base.transaction(() async {
    final empresa = (await _a.empresa())!;
    final usuario = await _a.usuario();
    for (final id in guardado.ids) {
      final actualizados =
          await (_base.update(_base.movimientos)..where(
                (m) =>
                    m.id.equals(id) &
                    m.estado.equalsValue(EstadoRegistro.vigente),
              ))
              .write(
                const MovimientosCompanion(
                  estado: Value(EstadoRegistro.anulado),
                ),
              );
      if (actualizados == 0) continue;
      await _a.anotarEnBitacora(
        empresaId: empresa.id,
        autorId: usuario.id,
        entidad: 'movimiento',
        entidadId: id,
        accion: AccionBitacora.anular,
        anterior: {'estado': EstadoRegistro.vigente.name},
        nuevo: {'estado': EstadoRegistro.anulado.name},
      );
    }
  });

  static String? _limpio(String? texto) {
    final t = texto?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  @override
  Future<List<String>> nombresDeContrapartes() async {
    final empresa = await _a.empresa();
    if (empresa == null) return const [];
    final enUso = {
      for (final m
          in await (_base.select(_base.movimientos)..where(
                (m) =>
                    m.empresaId.equals(empresa.id) &
                    m.estado.equalsValue(EstadoRegistro.vigente) &
                    m.contraparteId.isNotNull(),
              ))
              .get())
        m.contraparteId!,
    };
    final filas = await (_base.select(
      _base.contrapartes,
    )..where((c) => c.empresaId.equals(empresa.id))).get();
    final nombres = {
      for (final c in filas)
        if (enUso.contains(c.id)) c.nombre,
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return nombres;
  }
}
