import 'package:drift/drift.dart';

import '../../dominio/cifras.dart';
import '../../dominio/informe.dart';
import '../../dominio/modelos.dart';
import '../../pais/peru/categorias.dart';
import '../calculos/saldos.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

class RepositorioInformeLocal implements RepositorioInforme {
  RepositorioInformeLocal(BaseLocal base, {DateTime Function()? ahora})
    : _a = AccesoLocal(base, ahora ?? DateTime.now);

  final AccesoLocal _a;
  BaseLocal get _base => _a.base;

  /// Cambio mínimo de una categoría para mencionarlo: S/ 100 y 20 %.
  static const _cambioMinimoCentimos = 10000;
  static const _cambioMinimoProporcion = 0.2;

  /// La mercadería del mes avisa desde 30 % sobre el promedio de hasta tres
  /// meses anteriores.
  static const _umbralMercaderia = 1.3;
  static const _mesesParaPromedio = 3;
  static const _filasDeGastos = 5;

  @override
  Stream<InformeMes> observarMes(DateTime? mes) =>
      _a.cambios().asyncMap((_) => _calcular(mes));

  /// El informe es el flujo de caja del mes (entrega 14.9): un movimiento
  /// cuenta el día en que la plata se movió, igual que en el saldo.
  static DateTime _fecha(Movimiento m) => m.fechaPago ?? m.fechaMovimiento;

  Future<InformeMes> _calcular(DateTime? pedido) async {
    // Los del servidor, si valen (entrega 13): el mes pedido, sin salirse
    // del primero ni del actual.
    if (await _a.cifrasDelServidor() case Cifras(:final informes)
        when informes.isNotEmpty) {
      if (pedido == null) return informes.last;
      final mes = DateTime(pedido.year, pedido.month);
      if (mes.isBefore(informes.first.mes)) return informes.first;
      return informes.firstWhere(
        (i) => i.mes == mes,
        orElse: () => informes.last,
      );
    }
    return calcularMes(pedido);
  }

  /// El informe de un mes calculado en el teléfono.
  Future<InformeMes> calcularMes(DateTime? pedido) async {
    final ahora = _a.ahora();
    final actual = DateTime(ahora.year, ahora.month);
    final empresa = await _a.empresa();
    final vigentes = empresa == null
        ? const <Movimiento>[]
        : (await _a.movimientos(empresa.id))
              .where((m) => m.estado == EstadoRegistro.vigente)
              .toList();
    final categorias = empresa == null
        ? const <String, String>{}
        : {
            for (final c in await (_base.select(
              _base.categorias,
            )..where((c) => c.empresaId.equals(empresa.id))).get())
              c.id: c.nombre,
          };

    final cuentas = empresa == null
        ? const <Cuenta>[]
        : await (_base.select(
            _base.cuentas,
          )..where((c) => c.empresaId.equals(empresa.id))).get();
    final desdeDe = {for (final c in cuentas) c.id: c.fechaSaldoInicial};
    // Las mismas reglas que el saldo: solo lo pagado, y desde el saldo
    // inicial de su cuenta. Así el informe cuadra con «Tienes hoy».
    bool cuentaParaSaldo(String cuentaId, DateTime fecha) {
      final desde = desdeDe[cuentaId];
      return desde == null || !fecha.isBefore(desde);
    }

    final pagados = [
      for (final m in vigentes)
        if (m.estadoPago == EstadoPago.pagado &&
            cuentaParaSaldo(m.cuentaId, _fecha(m)))
          m,
    ];
    final ajustes = empresa == null
        ? const <AjusteArqueo>[]
        : [
            for (final a in await _a.ajustes(empresa.id))
              if (cuentaParaSaldo(a.cuentaId, a.fecha)) a,
          ];

    final fechas = [
      for (final m in pagados) _fecha(m),
      for (final a in ajustes) a.fecha,
      for (final c in cuentas) ?c.fechaSaldoInicial,
    ];
    final inicio = fechas.isEmpty
        ? ahora
        : fechas.reduce((a, b) => a.isBefore(b) ? a : b);
    final primerMes = DateTime(inicio.year, inicio.month);

    var mes = pedido == null ? actual : DateTime(pedido.year, pedido.month);
    if (mes.isAfter(actual)) mes = actual;
    if (mes.isBefore(primerMes)) mes = primerMes;
    final enCurso = mes == actual;
    final finMes = DateTime(mes.year, mes.month + 1);
    final hasta = enCurso
        ? inicioDelDia(ahora).add(const Duration(days: 1))
        : finMes;

    List<Movimiento> periodo(DateTime desde, DateTime hasta) => [
      for (final m in pagados)
        if (!_fecha(m).isBefore(desde) && _fecha(m).isBefore(hasta)) m,
    ];
    int ajustado(DateTime desde, DateTime hasta) => ajustes
        .where((a) => !a.fecha.isBefore(desde) && a.fecha.isBefore(hasta))
        .fold(0, (s, a) => s + a.centimos);
    int suma(Iterable<Movimiento> ms, TipoMovimiento tipo) =>
        ms.where((m) => m.tipo == tipo).fold(0, (s, m) => s + m.montoCentimos);
    // Cuánto creció la plata en el periodo.
    int crecio(DateTime desde, DateTime hasta) {
      final ms = periodo(desde, hasta);
      return suma(ms, TipoMovimiento.ingreso) +
          suma(ms, TipoMovimiento.aporte) -
          suma(ms, TipoMovimiento.egreso) -
          suma(ms, TipoMovimiento.retiro) +
          ajustado(desde, hasta);
    }

    // La plata al empezar [mes]: cada cuenta con su saldo de ese momento, o
    // con su saldo inicial si empezó después.
    int plataAl(DateTime momento) {
      var total = 0;
      for (final c in cuentas) {
        total += c.saldoInicialCentimos ?? 0;
        final desde = c.fechaSaldoInicial;
        if (desde != null && !desde.isBefore(momento)) continue;
        for (final m in pagados) {
          if (m.cuentaId != c.id || !_fecha(m).isBefore(momento)) continue;
          total += m.tipo.entraPlata ? m.montoCentimos : -m.montoCentimos;
        }
        for (final a in ajustes) {
          if (a.cuentaId == c.id && a.fecha.isBefore(momento)) {
            total += a.centimos;
          }
        }
      }
      return total;
    }

    Map<String, int> porCategoria(Iterable<Movimiento> ms) {
      final total = <String, int>{};
      for (final m in ms.where((m) => m.tipo == TipoMovimiento.egreso)) {
        final nombre = categorias[m.categoriaId] ?? 'Otros';
        total[nombre] = (total[nombre] ?? 0) + m.montoCentimos;
      }
      return total;
    }

    final delMes = periodo(mes, hasta);
    final esPrimero = mes == primerMes;

    // Mes anterior: hasta el mismo día si el mes está en curso.
    DateTime? mesAnterior;
    int? diferencia;
    CambioDeCategoria? cambio;
    if (!esPrimero) {
      mesAnterior = DateTime(mes.year, mes.month - 1);
      var hastaAnterior = mes;
      if (enCurso) {
        final mismoDia = DateTime(
          mesAnterior.year,
          mesAnterior.month,
          ahora.day + 1,
        );
        if (mismoDia.isBefore(mes)) hastaAnterior = mismoDia;
      }
      final anterior = periodo(mesAnterior, hastaAnterior);
      diferencia = crecio(mes, hasta) - crecio(mesAnterior, hastaAnterior);

      final ahoraPorCategoria = porCategoria(delMes);
      final antesPorCategoria = porCategoria(anterior);
      String? mayor;
      var mayorCambio = 0;
      for (final nombre in {
        ...ahoraPorCategoria.keys,
        ...antesPorCategoria.keys,
      }) {
        final c =
            (ahoraPorCategoria[nombre] ?? 0) - (antesPorCategoria[nombre] ?? 0);
        if (c.abs() > mayorCambio.abs() ||
            (c != 0 &&
                c.abs() == mayorCambio.abs() &&
                nombre.compareTo(mayor!) < 0)) {
          mayor = nombre;
          mayorCambio = c;
        }
      }
      if (mayor != null) {
        final antes = antesPorCategoria[mayor] ?? 0;
        if (mayorCambio.abs() >= _cambioMinimoCentimos &&
            (antes == 0 ||
                mayorCambio.abs() >= antes * _cambioMinimoProporcion)) {
          cambio = CambioDeCategoria(nombre: mayor, centimos: mayorCambio);
        }
      }
    }

    // En qué se fue la plata: a lo más cinco filas.
    // Empates: por nombre, igual que en el servidor.
    final ordenadas = porCategoria(delMes).entries.toList()
      ..sort(
        (a, b) => switch (b.value.compareTo(a.value)) {
          0 => a.key.compareTo(b.key),
          final c => c,
        },
      );
    final gastos = ordenadas.length <= _filasDeGastos
        ? [
            for (final e in ordenadas)
              GastoPorCategoria(nombre: e.key, centimos: e.value),
          ]
        : [
            for (final e in ordenadas.take(_filasDeGastos - 1))
              GastoPorCategoria(nombre: e.key, centimos: e.value),
            GastoPorCategoria(
              nombre: null,
              centimos: ordenadas
                  .skip(_filasDeGastos - 1)
                  .fold(0, (s, e) => s + e.value),
            ),
          ];

    // Mercadería frente al promedio de hasta tres meses anteriores.
    int mercaderia(Iterable<Movimiento> ms) => ms
        .where(
          (m) =>
              m.tipo == TipoMovimiento.egreso &&
              categoriasDeMercaderia.contains(categorias[m.categoriaId]),
        )
        .fold(0, (s, m) => s + m.montoCentimos);
    final anteriores = [
      for (var i = 1; i <= _mesesParaPromedio; i++)
        if (!DateTime(mes.year, mes.month - i).isBefore(primerMes))
          mercaderia(
            periodo(
              DateTime(mes.year, mes.month - i),
              DateTime(mes.year, mes.month - i + 1),
            ),
          ),
    ];
    final promedio = anteriores.isEmpty
        ? 0
        : anteriores.reduce((a, b) => a + b) / anteriores.length;
    final advertencia =
        promedio > 0 && mercaderia(delMes) >= promedio * _umbralMercaderia;

    return InformeMes(
      mes: mes,
      enCurso: enCurso,
      sinRegistros: delMes.isEmpty && ajustado(mes, hasta) == 0,
      desdeDia: esPrimero && inicio.day > 1 ? inicio.day : null,
      mesAnterior: mesAnterior,
      diferenciaConAnteriorCentimos: diferencia,
      inicioCentimos: plataAl(mes),
      entroCentimos: suma(delMes, TipoMovimiento.ingreso),
      salioCentimos: suma(delMes, TipoMovimiento.egreso),
      retirosCentimos: suma(delMes, TipoMovimiento.retiro),
      aportesCentimos: suma(delMes, TipoMovimiento.aporte),
      ajustesCentimos: ajustado(mes, hasta),
      gastos: gastos,
      cambio: cambio,
      loQueDebesCentimos: vigentes
          .where(
            (m) =>
                m.tipo == TipoMovimiento.egreso &&
                m.estadoPago != EstadoPago.pagado,
          )
          .fold(0, (s, m) => s + m.montoCentimos - m.montoPagadoCentimos),
      confianza: _confianza(delMes),
      advertenciaMercaderia: advertencia,
      mesPrevio: esPrimero ? null : DateTime(mes.year, mes.month - 1),
      mesSiguiente: enCurso ? null : DateTime(mes.year, mes.month + 1),
    );
  }

  @override
  Future<DetalleParaPdf> detalleParaPdf(InformeMes informe) async {
    final ahora = _a.ahora();
    final mes = informe.mes;
    final finMes = DateTime(mes.year, mes.month + 1);
    final desde = DateTime(mes.year, mes.month, informe.desdeDia ?? 1);
    final hasta = informe.enCurso
        ? inicioDelDia(ahora)
        : finMes.subtract(const Duration(days: 1));

    // Hasta seis meses, del más antiguo al del informe.
    final meses = <InformeMes>[informe];
    while (meses.length < 6 && meses.first.mesPrevio != null) {
      meses.insert(0, await calcularMes(meses.first.mesPrevio));
    }

    final empresa = await _a.empresa();
    if (empresa == null) {
      return DetalleParaPdf(
        desde: desde,
        hasta: hasta,
        saldosAlCierre: const {},
        ingresos: const [],
        deudas: const [],
        comprobantes: const [],
        meses: meses,
      );
    }
    final cuentas = await _a.cuentas(empresa.id);
    final vigentes = (await _a.movimientos(empresa.id))
        .where((m) => m.estado == EstadoRegistro.vigente)
        .toList();
    final ajustes = await _a.ajustes(empresa.id);
    final categorias = {
      for (final c in await (_base.select(
        _base.categorias,
      )..where((c) => c.empresaId.equals(empresa.id))).get())
        c.id: c.nombre,
    };
    final proveedores = {
      for (final c in await (_base.select(
        _base.contrapartes,
      )..where((c) => c.empresaId.equals(empresa.id))).get())
        c.id: c.nombre,
    };

    // Cuánto había en cada cuenta al cerrar el periodo, con las reglas del
    // saldo. En el mes en curso, lo de hoy.
    final cierre = informe.enCurso ? null : finMes;
    final saldos = <TipoCuenta, int>{};
    for (final c in TipoCuenta.enOrden) {
      for (final cuenta in cuentas.where((x) => x.tipo == c)) {
        final inicio = cuenta.fechaSaldoInicial;
        if (cierre != null && inicio != null && !inicio.isBefore(cierre)) {
          continue;
        }
        saldos[c] = saldoDeCuenta(
          saldoInicialCentimos: cuenta.saldoInicialCentimos,
          fechaSaldoInicial: inicio,
          movimientos: [
            for (final m in vigentes)
              if (m.cuentaId == cuenta.id &&
                  (cierre == null || _fecha(m).isBefore(cierre)))
                AccesoLocal.paraSaldo(m),
            for (final a in ajustes)
              if (a.cuentaId == cuenta.id &&
                  (cierre == null || a.fecha.isBefore(cierre)))
                a.paraSaldo,
          ],
        );
      }
    }

    // De dónde vino la plata: lo que entró en el periodo, por categoría.
    final ingresosPorCategoria = <String, int>{};
    final hastaFlujo = informe.enCurso
        ? hasta.add(const Duration(days: 1))
        : finMes;
    for (final m in vigentes) {
      if (m.tipo != TipoMovimiento.ingreso ||
          m.estadoPago != EstadoPago.pagado) {
        continue;
      }
      final f = _fecha(m);
      if (f.isBefore(mes) || !f.isBefore(hastaFlujo)) continue;
      final nombre = categorias[m.categoriaId] ?? 'Otros';
      ingresosPorCategoria[nombre] =
          (ingresosPorCategoria[nombre] ?? 0) + m.montoCentimos;
    }
    final ingresos = [
      for (final e in ingresosPorCategoria.entries)
        GastoPorCategoria(nombre: e.key, centimos: e.value),
    ]..sort((a, b) => b.centimos.compareTo(a.centimos));

    // Lo que se debe hoy.
    final deudas = [
      for (final m in vigentes)
        if (m.tipo == TipoMovimiento.egreso &&
            m.estadoPago != EstadoPago.pagado)
          DeudaPendiente(
            fecha: m.fechaComprobante ?? m.fechaMovimiento,
            centimos: m.montoCentimos - m.montoPagadoCentimos,
            proveedor: proveedores[m.contraparteId],
            categoria: categorias[m.categoriaId],
          ),
    ]..sort((a, b) => a.fecha.compareTo(b.fecha));

    // Los comprobantes emitidos en el mes, con su movimiento vigente.
    final porComprobante = {
      for (final m in vigentes)
        if (m.comprobanteId != null) m.comprobanteId!: m,
    };
    final comprobantes = <ComprobanteDelMes>[];
    for (final c in await (_base.select(
      _base.comprobantes,
    )..where((c) => c.empresaId.equals(empresa.id))).get()) {
      final m = porComprobante[c.id];
      final fecha = c.fechaEmision ?? m?.fechaComprobante;
      if (m == null || fecha == null) continue;
      if (fecha.isBefore(mes) || !fecha.isBefore(finMes)) continue;
      comprobantes.add(
        ComprobanteDelMes(
          fecha: fecha,
          totalCentimos: m.montoCentimos,
          pagado: m.estadoPago == EstadoPago.pagado,
          tipo: c.tipo,
          serie: c.serie,
          numero: c.numero,
          ruc: c.emisorIdentificacion,
          proveedor: c.emisorNombre ?? proveedores[m.contraparteId],
          igvCentimos: c.impuestoCentimos,
        ),
      );
    }
    comprobantes.sort((a, b) => a.fecha.compareTo(b.fecha));

    // Lo anotado en el periodo, con su comprobante si tiene.
    final datosComprobante = {
      for (final c in await (_base.select(
        _base.comprobantes,
      )..where((c) => c.empresaId.equals(empresa.id))).get())
        c.id: c,
    };
    final rucs = {
      for (final c in await (_base.select(
        _base.contrapartes,
      )..where((c) => c.empresaId.equals(empresa.id))).get())
        c.id: c.identificacionFiscal,
    };
    final tipoDeCuenta = {for (final c in cuentas) c.id: c.tipo};
    final operaciones = [
      for (final m in vigentes)
        if (!m.fechaMovimiento.isBefore(desde) &&
            m.fechaMovimiento.isBefore(finMes))
          _operacion(
            m,
            tipoDeCuenta[m.cuentaId] ?? TipoCuenta.efectivo,
            datosComprobante[m.comprobanteId],
            categoria: categorias[m.categoriaId],
            proveedor: proveedores[m.contraparteId],
            ruc: rucs[m.contraparteId],
          ),
    ]..sort((a, b) => a.fecha.compareTo(b.fecha));

    return DetalleParaPdf(
      desde: desde,
      hasta: hasta,
      saldosAlCierre: saldos,
      ingresos: ingresos,
      deudas: deudas,
      comprobantes: comprobantes,
      meses: meses,
      operaciones: operaciones,
    );
  }

  @override
  Future<FlujoParaCredito> flujoParaCredito() async {
    final ahora = _a.ahora();
    final actual = DateTime(ahora.year, ahora.month);
    final meses = [
      for (var i = 6; i >= 1; i--) DateTime(actual.year, actual.month - i),
    ];
    final empresa = await _a.empresa();
    if (empresa == null) {
      return FlujoParaCredito(
        meses: [
          for (final m in meses)
            MesDelFlujo(mes: m, estado: EstadoMesFlujo.antesDeMoca),
        ],
      );
    }

    // Las mismas reglas que el informe y el saldo: solo lo pagado, el día
    // que se pagó y desde el saldo inicial de su cuenta.
    final cuentas = await _a.cuentas(empresa.id);
    final desdeDe = {for (final c in cuentas) c.id: c.fechaSaldoInicial};
    bool cuenta(String cuentaId, DateTime fecha) {
      final desde = desdeDe[cuentaId];
      return desde == null || !fecha.isBefore(desde);
    }

    final pagados = [
      for (final m in await _a.movimientos(empresa.id))
        if (m.estado == EstadoRegistro.vigente &&
            m.estadoPago == EstadoPago.pagado &&
            cuenta(m.cuentaId, _fecha(m)))
          m,
    ];
    final fechas = [
      for (final m in pagados) _fecha(m),
      for (final c in cuentas) ?c.fechaSaldoInicial,
    ];
    final inicio = fechas.isEmpty
        ? null
        : fechas.reduce((a, b) => a.isBefore(b) ? a : b);

    final categorias = {
      for (final c in await (_base.select(
        _base.categorias,
      )..where((c) => c.empresaId.equals(empresa.id))).get())
        c.id: c.nombre,
    };
    final proveedores = {
      for (final c in await (_base.select(
        _base.contrapartes,
      )..where((c) => c.empresaId.equals(empresa.id))).get())
        c.id: c.nombre,
    };

    // A quién se pagan cuotas: el proveedor, o la nota si no hay.
    String entidad(Movimiento m) {
      final nombre = proveedores[m.contraparteId] ?? m.nota?.trim();
      return nombre == null || nombre.isEmpty ? 'Sin nombre' : nombre;
    }

    bool esCuota(Movimiento m) =>
        m.tipo == TipoMovimiento.egreso &&
        categorias[m.categoriaId] == categoriaCuotaDePrestamo;
    final desde6 = meses.first;
    final hasta6 = actual;
    final enPeriodo = [
      for (final m in pagados)
        if (!_fecha(m).isBefore(desde6) && _fecha(m).isBefore(hasta6)) m,
    ];
    final porEntidad = <String, int>{};
    for (final m in enPeriodo.where(esCuota)) {
      porEntidad[entidad(m)] = (porEntidad[entidad(m)] ?? 0) + m.montoCentimos;
    }
    final ordenadas = porEntidad.keys.toList()
      ..sort((a, b) => porEntidad[b]!.compareTo(porEntidad[a]!));
    final entidades = ordenadas.length <= 3
        ? ordenadas
        : [...ordenadas.take(2), 'Otras ${ordenadas.length - 2} entidades'];
    int filaDeCuota(String nombre) {
      final i = ordenadas.indexOf(nombre);
      return i < 2 ? i : 2;
    }

    final resultado = <MesDelFlujo>[];
    for (final mes in meses) {
      final fin = DateTime(mes.year, mes.month + 1);
      if (inicio == null || !inicio.isBefore(fin)) {
        resultado.add(
          MesDelFlujo(mes: mes, estado: EstadoMesFlujo.antesDeMoca),
        );
        continue;
      }
      final filas = <FilaFlujo, int>{};
      final cuotas = [0, 0, 0];
      var retiros = 0;
      for (final m in enPeriodo) {
        final f = _fecha(m);
        if (f.isBefore(mes) || !f.isBefore(fin)) continue;
        if (m.tipo == TipoMovimiento.retiro) {
          retiros += m.montoCentimos;
          continue;
        }
        // Lo que puso el dueño no es ingreso del negocio.
        if (m.tipo == TipoMovimiento.aporte) continue;
        if (esCuota(m)) {
          cuotas[filaDeCuota(entidad(m))] += m.montoCentimos;
          continue;
        }
        final fila =
            filaDelFlujo[categorias[m.categoriaId]] ??
            (m.tipo == TipoMovimiento.ingreso
                ? FilaFlujo.otrosIngresos
                : FilaFlujo.otrosGastosFijos);
        filas[fila] = (filas[fila] ?? 0) + m.montoCentimos;
      }
      resultado.add(
        MesDelFlujo(
          mes: mes,
          estado: inicio.isAfter(mes)
              ? EstadoMesFlujo.incompleto
              : EstadoMesFlujo.completo,
          centimos: filas,
          cuotas: cuotas,
          retirosCentimos: retiros,
        ),
      );
    }

    final porFila = <FilaFlujo, List<String>>{};
    for (final c
        in await (_base.select(_base.categorias)
              ..where(
                (c) => c.empresaId.equals(empresa.id) & c.activa.equals(true),
              )
              ..orderBy([(c) => OrderingTerm(expression: c.orden)]))
            .get()) {
      if (c.nombre == categoriaCuotaDePrestamo) continue;
      final fila =
          filaDelFlujo[c.nombre] ??
          (c.tipoMovimiento == TipoMovimiento.ingreso
              ? FilaFlujo.otrosIngresos
              : FilaFlujo.otrosGastosFijos);
      (porFila[fila] ??= []).add(c.nombre);
    }

    final usuario = await (_base.select(
      _base.usuarios,
    )..limit(1)).getSingleOrNull();
    return FlujoParaCredito(
      categoriasPorFila: porFila,
      meses: resultado,
      entidades: entidades,
      propietario: usuario?.nombre,
      identificacionFiscal: empresa.identificacionFiscal,
      inicioMoca: inicio,
    );
  }

  static OperacionDelMes _operacion(
    Movimiento m,
    TipoCuenta cuenta,
    Comprobante? c, {
    String? categoria,
    String? proveedor,
    String? ruc,
  }) {
    final numero = [
      ?c?.tipo,
      if (c != null && (c.serie != null || c.numero != null))
        '${c.serie ?? ''}-${c.numero ?? ''}',
    ].join(' ');
    return OperacionDelMes(
      fecha: m.fechaMovimiento,
      tipo: m.tipo,
      cuenta: cuenta,
      centimos: m.montoCentimos,
      estadoPago: m.estadoPago,
      pagadoCentimos: m.montoPagadoCentimos,
      fechaPago: m.estadoPago == EstadoPago.pagado
          ? m.fechaPago ?? m.fechaMovimiento
          : m.fechaPago,
      fuente: m.fuente,
      confianza: m.nivelConfianza,
      categoria: categoria,
      nota: m.nota,
      proveedor: c?.emisorNombre ?? proveedor,
      ruc: c?.emisorIdentificacion ?? ruc,
      comprobante: numero.isEmpty ? null : numero,
      igvCentimos: c?.impuestoCentimos,
    );
  }

  /// Porcentajes del monto por sustento, que suman 100 (resto mayor).
  static ConfianzaDelMes? _confianza(List<Movimiento> ms) {
    final montos = [0, 0, 0];
    for (final m in ms) {
      final i = switch (m.nivelConfianza) {
        NivelConfianza.a || NivelConfianza.b => 0,
        NivelConfianza.c => 1,
        NivelConfianza.d => 2,
      };
      montos[i] += m.montoCentimos;
    }
    final total = montos.fold(0, (s, x) => s + x);
    if (total == 0) return null;
    final exactos = [for (final x in montos) x * 100 / total];
    final enteros = [for (final x in exactos) x.floor()];
    var falta = 100 - enteros.fold(0, (s, x) => s + x);
    final porResto = [0, 1, 2]
      ..sort(
        (a, b) => (exactos[b] - enteros[b]).compareTo(exactos[a] - enteros[a]),
      );
    for (final i in porResto) {
      if (falta == 0) break;
      enteros[i]++;
      falta--;
    }
    return ConfianzaDelMes(
      conComprobante: enteros[0],
      conFoto: enteros[1],
      sinPapel: enteros[2],
    );
  }
}
