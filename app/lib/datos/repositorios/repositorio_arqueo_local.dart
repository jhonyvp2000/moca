import 'package:drift/drift.dart';

import '../../dominio/arqueo.dart';
import '../../dominio/modelos.dart';
import '../../pais/peru/categorias.dart';
import '../calculos/saldos.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

class RepositorioArqueoLocal implements RepositorioArqueo {
  RepositorioArqueoLocal(
    BaseLocal base, {
    DateTime Function()? ahora,
    Future<bool> Function()? hayConexion,
  }) : _a = AccesoLocal(base, ahora ?? DateTime.now, hayConexion: hayConexion);

  final AccesoLocal _a;
  BaseLocal get _base => _a.base;

  /// Ajuste del operador: mostrar la tarjeta del arqueo sin esperar al
  /// domingo. Se borra al guardar un arqueo.
  static const claveArqueoPedido = AccesoLocal.claveArqueoPedido;

  @override
  Future<List<CuentaArqueo>> preparar() async {
    final empresa = (await _a.empresa())!;
    final saldos = await _a.saldos(empresa.id);
    return [
      for (final c in await _a.cuentas(empresa.id))
        CuentaArqueo(
          cuenta: c.tipo,
          calculadoCentimos: saldos[c.tipo] ?? 0,
          puntoDePartida: c.saldoInicialCentimos == null,
        ),
    ];
  }

  @override
  Future<int> guardar(List<ConteoCuenta> conteos) =>
      _base.transaction(() async {
        final empresa = (await _a.empresa())!;
        final usuario = await _a.usuario();
        final ahora = _a.ahora();
        final cuentas = await _a.cuentas(empresa.id);
        final movimientos = await _a.movimientos(empresa.id);
        final ajustes = await _a.ajustes(empresa.id);
        final saldos = AccesoLocal.saldosPorCuenta(
          cuentas,
          movimientos,
          ajustes: ajustes,
        );
        final estado = await _a.estadoAlGuardar();

        final arqueoId = _a.nuevoId();
        await _base
            .into(_base.arqueos)
            .insert(
              ArqueosCompanion.insert(
                id: arqueoId,
                empresaId: empresa.id,
                fecha: ahora,
                autorId: usuario.id,
                creadoEn: ahora,
              ),
            );

        final resumen = <Map<String, Object?>>[];
        for (final conteo in conteos) {
          final cuenta = cuentas.firstWhere((c) => c.tipo == conteo.cuenta);
          final contado = conteo.contadoCentimos;
          var calculado = saldos[cuenta.tipo] ?? 0;
          var diferencia = 0;
          MotivoArqueo? motivo;
          String? movimientoId;

          if (cuenta.saldoInicialCentimos == null) {
            // Punto de partida: el saldo inicial es lo contado menos lo que se
            // movió desde el primer día.
            final primero = movimientos.isEmpty
                ? ahora
                : movimientos
                      .map((m) => m.fechaMovimiento)
                      .reduce((a, b) => a.isBefore(b) ? a : b);
            final desde = inicioDelDia(primero);
            calculado = saldoDeCuenta(
              saldoInicialCentimos: 0,
              fechaSaldoInicial: desde,
              movimientos: [
                ...movimientos
                    .where((m) => m.cuentaId == cuenta.id)
                    .map(AccesoLocal.paraSaldo),
                ...movimientos
                    .where((m) => m.cuentaDestinoId == cuenta.id)
                    .map(AccesoLocal.paraSaldoDestino),
                for (final a in ajustes)
                  if (a.cuentaId == cuenta.id) a.paraSaldo,
              ],
            );
            final inicial = contado - calculado;
            await (_base.update(
              _base.cuentas,
            )..where((c) => c.id.equals(cuenta.id))).write(
              CuentasCompanion(
                saldoInicialCentimos: Value(inicial),
                fechaSaldoInicial: Value(desde),
              ),
            );
            await _a.anotarEnBitacora(
              empresaId: empresa.id,
              autorId: usuario.id,
              entidad: 'cuenta',
              entidadId: cuenta.id,
              accion: AccionBitacora.editar,
              anterior: {'saldoInicialCentimos': null},
              nuevo: {'saldoInicialCentimos': inicial, 'origen': 'arqueo'},
            );
          } else {
            diferencia = contado - calculado;
            if (diferencia.abs() >= toleranciaArqueoCentimos) {
              motivo = conteo.motivo;
              if (motivo == null || !motivosPara(diferencia).contains(motivo)) {
                throw ArgumentError(
                  'Falta explicar la diferencia en ${cuenta.tipo.name}.',
                );
              }
              final tipo = switch (motivo) {
                MotivoArqueo.retiroParaMi => TipoMovimiento.retiro,
                MotivoArqueo.puseYo => TipoMovimiento.aporte,
                MotivoArqueo.gastoOlvidado => TipoMovimiento.egreso,
                MotivoArqueo.ventaNoAnotada => TipoMovimiento.ingreso,
                MotivoArqueo.errorDeVuelto || MotivoArqueo.noLoSe => null,
              };
              if (tipo != null) {
                final categoriaId = switch (motivo) {
                  MotivoArqueo.gastoOlvidado => conteo.categoriaId,
                  MotivoArqueo.ventaNoAnotada => await _categoriaVentaDelDia(
                    empresa.id,
                  ),
                  _ => null,
                };
                if (tipo == TipoMovimiento.egreso && categoriaId == null) {
                  throw ArgumentError('El gasto olvidado lleva categoría.');
                }
                movimientoId = await _insertarMovimiento(
                  empresaId: empresa.id,
                  autorId: usuario.id,
                  cuentaId: cuenta.id,
                  cuenta: cuenta.tipo,
                  tipo: tipo,
                  montoCentimos: diferencia.abs(),
                  categoriaId: categoriaId,
                  estado: estado,
                );
              }
            }
          }

          await _base
              .into(_base.arqueoCuentas)
              .insert(
                ArqueoCuentasCompanion.insert(
                  id: _a.nuevoId(),
                  arqueoId: arqueoId,
                  cuentaId: cuenta.id,
                  saldoCalculadoCentimos: calculado,
                  saldoRealCentimos: contado,
                  diferenciaCentimos: diferencia,
                  motivo: Value(motivo),
                  movimientoId: Value(movimientoId),
                ),
              );
          resumen.add({
            'cuenta': cuenta.tipo.name,
            'calculadoCentimos': calculado,
            'contadoCentimos': contado,
            'diferenciaCentimos': diferencia,
            'motivo': motivo?.name,
            'movimientoId': movimientoId,
          });
        }

        await _a.anotarEnBitacora(
          empresaId: empresa.id,
          autorId: usuario.id,
          entidad: 'arqueo',
          entidadId: arqueoId,
          accion: AccionBitacora.arquear,
          nuevo: {'cuentas': resumen},
        );
        await (_base.delete(
          _base.ajustes,
        )..where((x) => x.clave.equals(claveArqueoPedido))).go();
        return _a.tienesHoy(empresa.id);
      });

  Future<String> _categoriaVentaDelDia(String empresaId) async =>
      (await (_base.select(_base.categorias)..where(
                (c) =>
                    c.empresaId.equals(empresaId) &
                    c.nombre.equals(categoriaVentaDelDia),
              ))
              .getSingle())
          .id;

  Future<String> _insertarMovimiento({
    required String empresaId,
    required String autorId,
    required String cuentaId,
    required TipoCuenta cuenta,
    required TipoMovimiento tipo,
    required int montoCentimos,
    required String? categoriaId,
    required EstadoSincronizacion estado,
  }) async {
    final ahora = _a.ahora();
    final id = _a.nuevoId();
    await _base
        .into(_base.movimientos)
        .insert(
          MovimientosCompanion.insert(
            id: id,
            empresaId: empresaId,
            tipo: tipo,
            cuentaId: cuentaId,
            montoCentimos: montoCentimos,
            fechaMovimiento: ahora,
            estadoPago: EstadoPago.pagado,
            montoPagadoCentimos: montoCentimos,
            fechaPago: Value(ahora),
            categoriaId: Value(categoriaId),
            // Declarado en el arqueo, sin comprobante: nivel D.
            nivelConfianza: NivelConfianza.d,
            fuente: Fuente.arqueo,
            autorId: autorId,
            estado: EstadoRegistro.vigente,
            estadoSincronizacion: estado,
            creadoEn: ahora,
          ),
        );
    await _a.anotarEnBitacora(
      empresaId: empresaId,
      autorId: autorId,
      entidad: 'movimiento',
      entidadId: id,
      accion: AccionBitacora.crear,
      nuevo: {
        'tipo': tipo.name,
        'cuenta': cuenta.name,
        'montoCentimos': montoCentimos,
        'categoriaId': categoriaId,
        'fuente': Fuente.arqueo.name,
      },
    );
    return id;
  }
}
