import 'package:drift/drift.dart';

import '../../dominio/comprobantes.dart';
import '../../dominio/modelos.dart';
import '../../dominio/movimientos.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

class RepositorioComprobantesLocal implements RepositorioComprobantes {
  RepositorioComprobantesLocal(BaseLocal base, {DateTime Function()? ahora})
    : _a = AccesoLocal(base, ahora ?? DateTime.now);

  final AccesoLocal _a;
  BaseLocal get _base => _a.base;

  /// El comprobante con la misma llave (emisor + tipo + serie + número).
  Future<Comprobante?> _mismoComprobante(
    String empresaId,
    LecturaComprobante l,
  ) async {
    if (!l.identificable) return null;
    return (_base.select(_base.comprobantes)..where(
          (c) =>
              c.empresaId.equals(empresaId) &
              c.emisorIdentificacion.equals(l.emisorIdentificacion!) &
              c.tipo.equals(l.tipo!) &
              c.serie.equals(l.serie!) &
              c.numero.equals(l.numero!),
        ))
        .getSingleOrNull();
  }

  @override
  Future<bool> yaAnotado(LecturaComprobante lectura) async {
    final empresa = await _a.empresa();
    if (empresa == null) return false;
    final comprobante = await _mismoComprobante(empresa.id, lectura);
    if (comprobante == null) return false;
    // Si se deshizo, se puede volver a anotar.
    final vigentes =
        await (_base.select(_base.movimientos)..where(
              (m) =>
                  m.comprobanteId.equals(comprobante.id) &
                  m.estado.equalsValue(EstadoRegistro.vigente),
            ))
            .get();
    return vigentes.isNotEmpty;
  }

  @override
  Future<Guardado> guardarCompra(CompraConfirmada compra) {
    if (compra.totalCentimos <= 0) {
      throw ArgumentError('El total tiene que ser mayor que cero.');
    }
    final l = compra.lectura;
    return _base.transaction(() async {
      if (await yaAnotado(l)) {
        throw StateError('Ese comprobante ya está anotado.');
      }
      final empresa = (await _a.empresa())!;
      final usuario = await _a.usuario();
      final ahora = _a.ahora();
      final nombre = (compra.emisorNombre ?? l.emisorNombre)?.trim();

      // El proveedor, si se sabe quién es. Si ya existe (mismo RUC o mismo
      // nombre), se reutiliza.
      String? contraparteId;
      final ruc = l.emisorIdentificacion;
      final conNombre = nombre != null && nombre.isNotEmpty;
      if (conNombre || ruc != null) {
        final proveedores = await (_base.select(
          _base.contrapartes,
        )..where((c) => c.empresaId.equals(empresa.id))).get();
        final mismo = proveedores.where(
          (c) =>
              (ruc != null && c.identificacionFiscal == ruc) ||
              (conNombre && c.nombre.toLowerCase() == nombre.toLowerCase()),
        );
        if (mismo.isNotEmpty) {
          contraparteId = mismo.first.id;
        } else {
          contraparteId = _a.nuevoId();
          await _base
              .into(_base.contrapartes)
              .insert(
                ContrapartesCompanion.insert(
                  id: contraparteId,
                  empresaId: empresa.id,
                  nombre: conNombre ? nombre : 'RUC $ruc',
                  identificacionFiscal: Value(ruc),
                  tipo: TipoContraparte.proveedor,
                ),
              );
        }
      }

      // El comprobante: si ya existía (se deshizo antes), se reutiliza.
      final existente = await _mismoComprobante(empresa.id, l);
      final comprobanteId = existente?.id ?? _a.nuevoId();
      if (existente == null) {
        await _base
            .into(_base.comprobantes)
            .insert(
              ComprobantesCompanion.insert(
                id: comprobanteId,
                empresaId: empresa.id,
                emisorIdentificacion: Value(l.emisorIdentificacion),
                emisorNombre: Value(nombre),
                tipo: Value(l.tipo),
                serie: Value(l.serie),
                numero: Value(l.numero),
                fechaEmision: Value(compra.fecha ?? l.fechaEmision),
                impuestoCentimos: Value(l.impuestoCentimos),
                totalCentimos: compra.totalCentimos,
                rutaImagen: Value(l.rutaImagen),
                origenLectura: l.origen,
                creadoEn: ahora,
              ),
            );
      }

      final cuentaId = (await _a.cuentas(empresa.id))
          .firstWhere((c) => c.tipo == compra.cuenta)
          .id;
      final id = _a.nuevoId();
      await _base
          .into(_base.movimientos)
          .insert(
            MovimientosCompanion.insert(
              id: id,
              empresaId: empresa.id,
              tipo: TipoMovimiento.egreso,
              cuentaId: cuentaId,
              montoCentimos: compra.totalCentimos,
              fechaMovimiento: ahora,
              fechaComprobante: Value(compra.fecha ?? l.fechaEmision ?? ahora),
              estadoPago: compra.pagado
                  ? EstadoPago.pagado
                  : EstadoPago.pendiente,
              montoPagadoCentimos: compra.pagado ? compra.totalCentimos : 0,
              // Lo que se debe no ha salido de ninguna cuenta todavía.
              fechaPago: Value(compra.pagado ? ahora : null),
              categoriaId: Value(compra.categoriaId),
              contraparteId: Value(contraparteId),
              comprobanteId: Value(comprobanteId),
              // QR o foto legible: B. Foto ilegible completada a mano: C.
              nivelConfianza: l.legible ? NivelConfianza.b : NivelConfianza.c,
              fuente: l.origen == OrigenLectura.qr ? Fuente.qr : Fuente.foto,
              autorId: usuario.id,
              estado: EstadoRegistro.vigente,
              estadoSincronizacion: EstadoSincronizacion.subido,
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
          'tipo': TipoMovimiento.egreso.name,
          'cuenta': compra.cuenta.name,
          'montoCentimos': compra.totalCentimos,
          'categoriaId': compra.categoriaId,
          'pagado': compra.pagado,
          'comprobanteId': comprobanteId,
          'fuente': l.origen.name,
        },
      );

      final tienesHoy = AccesoLocal.saldosPorCuenta(
        await _a.cuentas(empresa.id),
        await _a.movimientos(empresa.id),
      ).values.fold<int>(0, (s, v) => s + v);
      return Guardado(ids: [id], tienesHoyCentimos: tienesHoy);
    });
  }
}
