import 'package:drift/drift.dart';

import '../../dominio/arqueo.dart';
import '../../dominio/modelos.dart';
import '../../dominio/moca.dart';
import '../calculos/saldos.dart';
import '../calculos/semana.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

/// Los avisos los disparan reglas sobre los datos (docs/prototipo-v1.md,
/// «Avisos»); las pantallas solo los redactan con plantillas.
class RepositorioMocaLocal implements RepositorioMoca {
  RepositorioMocaLocal(BaseLocal base, {DateTime Function()? ahora})
    : _a = AccesoLocal(base, ahora ?? DateTime.now);

  final AccesoLocal _a;
  BaseLocal get _base => _a.base;

  /// «Diferencia en el arqueo»: S/ 10 o más marcados «No lo sé».
  static const _diferenciaMinima = 1000;

  /// «Gasto atípico»: S/ 100 o más, el doble del promedio de su categoría
  /// en las 8 semanas anteriores, con al menos 3 gastos previos.
  static const _atipicoMinimo = 10000;
  static const _atipicoVentana = Duration(days: 56);
  static const _atipicoPrevios = 3;

  /// Cuánto tiempo se muestra un gasto atípico.
  static const _atipicoVigencia = Duration(days: 14);

  /// «Días sin registrar»: dos días seguidos.
  static const _diasSinRegistrar = 2;

  @override
  Stream<List<Aviso>> observarAvisos() =>
      _a.cambios().asyncMap((_) => _avisos());

  Future<List<Aviso>> _avisos() async {
    final empresa = await _a.empresa();
    if (empresa == null) return const [];
    final ahora = _a.ahora();
    final hoy = inicioDelDia(ahora);
    final movimientos = await _a.movimientos(empresa.id);
    final vigentes = movimientos
        .where((m) => m.estado == EstadoRegistro.vigente)
        .toList();
    final cuentas = {
      for (final c in await _a.cuentas(empresa.id)) c.id: c.tipo,
    };
    final categorias = {
      for (final c in await (_base.select(
        _base.categorias,
      )..where((c) => c.empresaId.equals(empresa.id))).get())
        c.id: c.nombre,
    };
    final avisos = <Aviso>[];

    // Falta el arqueo.
    if (await _a.estadoArqueo(empresa.id, movimientos) == EstadoArqueo.falta) {
      final lunes = inicioDeSemana(ahora);
      avisos.add(
        Aviso(
          clave: 'falta_arqueo:${lunes.toIso8601String()}',
          tipo: TipoAviso.faltaArqueo,
          prioridad: PrioridadAlerta.importante,
          fecha: lunes.add(const Duration(hours: 8)),
        ),
      );
    }

    // Diferencia en el arqueo marcada «No lo sé».
    for (final a in await _a.ajustes(empresa.id)) {
      if (a.motivo != MotivoArqueo.noLoSe) continue;
      if (a.centimos.abs() < _diferenciaMinima) continue;
      avisos.add(
        Aviso(
          clave: 'diferencia:${a.id}',
          tipo: TipoAviso.diferenciaArqueo,
          prioridad: PrioridadAlerta.importante,
          fecha: a.fecha,
          montoCentimos: a.centimos.abs(),
          cuenta: cuentas[a.cuentaId],
          destinoId: a.id,
        ),
      );
    }

    // Días seguidos sin registrar, contados hasta ayer.
    final dias = {for (final m in vigentes) inicioDelDia(m.fechaMovimiento)};
    if (dias.isNotEmpty && !dias.contains(hoy)) {
      final primero = dias.reduce((a, b) => a.isBefore(b) ? a : b);
      var sinRegistrar = 0;
      var dia = DateTime(hoy.year, hoy.month, hoy.day - 1);
      while (!dia.isBefore(primero) && !dias.contains(dia)) {
        sinRegistrar++;
        dia = DateTime(dia.year, dia.month, dia.day - 1);
      }
      if (sinRegistrar >= _diasSinRegistrar) {
        avisos.add(
          Aviso(
            clave: 'dias:${hoy.toIso8601String()}',
            tipo: TipoAviso.diasSinRegistrar,
            prioridad: PrioridadAlerta.importante,
            fecha: hoy,
            dias: sinRegistrar,
          ),
        );
      }
    }

    // Gastos atípicos de las últimas dos semanas.
    final egresos = vigentes
        .where((m) => m.tipo == TipoMovimiento.egreso)
        .toList();
    for (final m in egresos) {
      if (m.montoCentimos < _atipicoMinimo) continue;
      if (m.fechaMovimiento.isBefore(ahora.subtract(_atipicoVigencia))) {
        continue;
      }
      final desde = m.fechaMovimiento.subtract(_atipicoVentana);
      final previos = [
        for (final p in egresos)
          if (p.id != m.id &&
              p.categoriaId == m.categoriaId &&
              !p.fechaMovimiento.isBefore(desde) &&
              p.fechaMovimiento.isBefore(m.fechaMovimiento))
            p.montoCentimos,
      ];
      if (previos.length < _atipicoPrevios) continue;
      final promedio = previos.reduce((a, b) => a + b) / previos.length;
      if (m.montoCentimos < promedio * 2) continue;
      avisos.add(
        Aviso(
          clave: 'atipico:${m.id}',
          tipo: TipoAviso.gastoAtipico,
          prioridad: PrioridadAlerta.paraTenerEnCuenta,
          fecha: m.fechaMovimiento,
          montoCentimos: m.montoCentimos,
          categoria: categorias[m.categoriaId],
          destinoId: m.id,
        ),
      );
    }

    final vistos = {
      for (final a
          in await (_base.select(_base.alertas)..where(
                (x) =>
                    x.empresaId.equals(empresa.id) &
                    x.estado.equalsValue(EstadoAlerta.vista),
              ))
              .get())
        a.id,
    };
    return avisos.where((a) => !vistos.contains(a.clave)).toList()
      ..sort((a, b) {
        final porPrioridad = a.prioridad.index.compareTo(b.prioridad.index);
        return porPrioridad != 0 ? porPrioridad : b.fecha.compareTo(a.fecha);
      });
  }

  @override
  Future<void> descartar(Aviso aviso) async {
    final empresa = (await _a.empresa())!;
    await _base
        .into(_base.alertas)
        .insertOnConflictUpdate(
          AlertasCompanion.insert(
            id: aviso.clave,
            empresaId: empresa.id,
            tipo: aviso.tipo.name,
            prioridad: aviso.prioridad,
            estado: EstadoAlerta.vista,
            texto: '',
            datos: '{}',
            creadoEn: _a.ahora(),
          ),
        );
  }

  @override
  Stream<ResumenSemana> observarResumen() =>
      _a.cambios().asyncMap((_) => _resumen());

  Future<ResumenSemana> _resumen() async {
    final empresa = await _a.empresa();
    if (empresa == null) {
      return const ResumenSemana(
        semanaPasada: false,
        conMovimientos: false,
        quedoCentimos: 0,
      );
    }
    final ahora = _a.ahora();
    final lunes = inicioDeSemana(ahora);
    final movimientos = await _a.movimientos(empresa.id);
    final paraCalculo = movimientos.map(AccesoLocal.paraSaldo).toList();
    final semanaPasada = movimientos.any(
      (m) =>
          m.estado == EstadoRegistro.vigente &&
          m.fechaMovimiento.isBefore(lunes),
    );
    final desde = semanaPasada
        ? lunes.subtract(const Duration(days: 7))
        : lunes;
    final hasta = semanaPasada
        ? lunes
        : inicioDelDia(ahora).add(const Duration(days: 1));
    final semana = resumirPeriodo(paraCalculo, desde: desde, hasta: hasta);

    int? diferencia;
    if (semanaPasada) {
      final antes = resumirPeriodo(
        paraCalculo,
        desde: desde.subtract(const Duration(days: 7)),
        hasta: desde,
      );
      if (antes.cantidad > 0) {
        diferencia = semana.quedoCentimos - antes.quedoCentimos;
      }
    }

    // Lo que más salió en la semana, por categoría.
    final categorias = {
      for (final c in await (_base.select(
        _base.categorias,
      )..where((c) => c.empresaId.equals(empresa.id))).get())
        c.id: c.nombre,
    };
    final porCategoria = <String, int>{};
    for (final m in movimientos) {
      final p = AccesoLocal.paraSaldo(m);
      if (m.tipo != TipoMovimiento.egreso ||
          m.estado != EstadoRegistro.vigente ||
          m.estadoPago != EstadoPago.pagado ||
          p.fecha.isBefore(desde) ||
          !p.fecha.isBefore(hasta)) {
        continue;
      }
      final nombre = categorias[m.categoriaId];
      if (nombre == null) continue;
      porCategoria[nombre] = (porCategoria[nombre] ?? 0) + m.montoCentimos;
    }
    final top = porCategoria.entries.isEmpty
        ? null
        : porCategoria.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return ResumenSemana(
      semanaPasada: semanaPasada,
      conMovimientos: semana.cantidad > 0,
      quedoCentimos: semana.quedoCentimos,
      diferenciaCentimos: diferencia,
      categoriaTop: top?.key,
      categoriaTopCentimos: top?.value,
    );
  }
}
