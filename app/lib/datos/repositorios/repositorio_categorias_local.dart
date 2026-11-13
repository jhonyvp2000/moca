import 'package:drift/drift.dart';

import '../../dominio/categorias.dart';
import '../../dominio/modelos.dart';
import '../../pais/peru/categorias.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

/// «Mis categorías» (entrega 31). Las propias son filas de la misma tabla
/// que las de Moca: se suben, bajan y se ven en el informe igual.
class RepositorioCategoriasLocal implements RepositorioCategorias {
  RepositorioCategoriasLocal(this._base, {DateTime Function()? ahora})
    : _a = AccesoLocal(_base, ahora ?? DateTime.now);

  final BaseLocal _base;
  final AccesoLocal _a;

  /// Las de Moca para este tipo de negocio.
  static Set<(String, TipoMovimiento)> _deMoca(TipoNegocio negocio) => {
    for (final n in categoriasComunesIngreso) (n, TipoMovimiento.ingreso),
    for (final n in categoriasComunesEgreso) (n, TipoMovimiento.egreso),
    for (final n in categoriasEgresoPorNegocio[negocio] ?? const <String>[])
      (n, TipoMovimiento.egreso),
    // Las de nombre viejo (entrega 14.14) tampoco son propias.
    for (final n in categoriasRenombradas.keys) (n, TipoMovimiento.egreso),
  };

  Future<List<Categoria>> _todas(String empresaId) =>
      (_base.select(_base.categorias)
            ..where((c) => c.empresaId.equals(empresaId))
            ..orderBy([(c) => OrderingTerm.asc(c.orden)]))
          .get();

  @override
  Stream<List<CategoriaDelNegocio>> observar() =>
      _a.cambios().asyncMap((_) async {
        final empresa = await _a.empresa();
        if (empresa == null) return const <CategoriaDelNegocio>[];
        final deMoca = _deMoca(empresa.tipoNegocio);
        return [
          for (final c in await _todas(empresa.id))
            if (c.tipoMovimiento == TipoMovimiento.ingreso ||
                c.tipoMovimiento == TipoMovimiento.egreso)
              if (!deMoca.contains((c.nombre, c.tipoMovimiento)) || c.activa)
                CategoriaDelNegocio(
                  id: c.id,
                  nombre: c.nombre,
                  tipo: c.tipoMovimiento,
                  propia: !deMoca.contains((c.nombre, c.tipoMovimiento)),
                  activa: c.activa,
                ),
        ];
      });

  /// El error del nombre, si lo hay: vacío o repetido entre las del negocio
  /// (de entró y de salió, de Moca o propias, en uso o no).
  ErrorCategoria? _errorDelNombre(
    String nombre,
    List<Categoria> todas, {
    String? salvo,
  }) {
    if (nombre.isEmpty) return ErrorCategoria.vacia;
    final comparable = nombreComparable(nombre);
    final repetida = todas.any(
      (c) => c.id != salvo && nombreComparable(c.nombre) == comparable,
    );
    return repetida ? ErrorCategoria.repetida : null;
  }

  static String _limpio(String nombre) {
    final limpio = nombre.trim().replaceAll(RegExp(r'\s+'), ' ');
    return limpio.length > largoNombreCategoria
        ? limpio.substring(0, largoNombreCategoria)
        : limpio;
  }

  @override
  Future<ResultadoCategoria> agregar(String nombre, TipoMovimiento tipo) {
    if (tipo != TipoMovimiento.ingreso && tipo != TipoMovimiento.egreso) {
      throw ArgumentError('Solo entró y salió llevan categoría.');
    }
    return _base.transaction(() async {
      final empresa = (await _a.empresa())!;
      final todas = await _todas(empresa.id);
      final limpio = _limpio(nombre);
      if (_errorDelNombre(limpio, todas) case final error?) {
        return (id: null, error: error);
      }
      final deMoca = _deMoca(empresa.tipoNegocio);
      final propiasEnUso = todas.where(
        (c) =>
            c.tipoMovimiento == tipo &&
            c.activa &&
            !deMoca.contains((c.nombre, c.tipoMovimiento)),
      );
      if (propiasEnUso.length >= maximoPropias(tipo)) {
        return (id: null, error: ErrorCategoria.sinLugar);
      }
      final orden = todas.fold(0, (m, c) => c.orden > m ? c.orden : m) + 1;
      final id = _a.nuevoId();
      await _base
          .into(_base.categorias)
          .insert(
            CategoriasCompanion.insert(
              id: id,
              empresaId: empresa.id,
              nombre: limpio,
              tipoMovimiento: tipo,
              orden: orden,
            ),
          );
      await _a.anotarEnBitacora(
        empresaId: empresa.id,
        autorId: (await _a.usuario()).id,
        entidad: 'categoria',
        entidadId: id,
        accion: AccionBitacora.crear,
        nuevo: {'nombre': limpio, 'tipoMovimiento': tipo.name},
      );
      return (id: id, error: null);
    });
  }

  /// La propia con ese id; las de Moca no se cambian.
  Future<(Empresa, Categoria, List<Categoria>)?> _propia(String id) async {
    final empresa = (await _a.empresa())!;
    final todas = await _todas(empresa.id);
    final categoria = todas.where((c) => c.id == id).firstOrNull;
    if (categoria == null ||
        _deMoca(empresa.tipoNegocio)
            .contains((categoria.nombre, categoria.tipoMovimiento))) {
      return null;
    }
    return (empresa, categoria, todas);
  }

  @override
  Future<ResultadoCategoria> renombrar(String id, String nombre) =>
      _base.transaction(() async {
        final encontrada = await _propia(id);
        if (encontrada == null) {
          return (id: null, error: ErrorCategoria.sinPermiso);
        }
        final (empresa, categoria, todas) = encontrada;
        final limpio = _limpio(nombre);
        if (limpio == categoria.nombre) return (id: id, error: null);
        if (_errorDelNombre(limpio, todas, salvo: id) case final error?) {
          return (id: null, error: error);
        }
        await (_base.update(_base.categorias)..where((c) => c.id.equals(id)))
            .write(CategoriasCompanion(nombre: Value(limpio)));
        await _a.anotarEnBitacora(
          empresaId: empresa.id,
          autorId: (await _a.usuario()).id,
          entidad: 'categoria',
          entidadId: id,
          accion: AccionBitacora.editar,
          anterior: {'nombre': categoria.nombre},
          nuevo: {'nombre': limpio},
        );
        return (id: id, error: null);
      });

  @override
  Future<ResultadoCategoria> usar(String id, {required bool activa}) =>
      _base.transaction(() async {
        final encontrada = await _propia(id);
        if (encontrada == null) {
          return (id: null, error: ErrorCategoria.sinPermiso);
        }
        final (empresa, categoria, todas) = encontrada;
        if (categoria.activa == activa) return (id: id, error: null);
        if (activa) {
          final deMoca = _deMoca(empresa.tipoNegocio);
          final enUso = todas.where(
            (c) =>
                c.tipoMovimiento == categoria.tipoMovimiento &&
                c.activa &&
                !deMoca.contains((c.nombre, c.tipoMovimiento)),
          );
          if (enUso.length >= maximoPropias(categoria.tipoMovimiento)) {
            return (id: null, error: ErrorCategoria.sinLugar);
          }
        }
        await (_base.update(_base.categorias)..where((c) => c.id.equals(id)))
            .write(CategoriasCompanion(activa: Value(activa)));
        await _a.anotarEnBitacora(
          empresaId: empresa.id,
          autorId: (await _a.usuario()).id,
          entidad: 'categoria',
          entidadId: id,
          accion: AccionBitacora.editar,
          anterior: {'activa': categoria.activa},
          nuevo: {'activa': activa},
        );
        return (id: id, error: null);
      });
}
