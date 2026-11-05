import 'package:drift/drift.dart' show Value;

import '../../dominio/modelos.dart';
import '../../dominio/negocio.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

class RepositorioNegocioLocal implements RepositorioNegocio {
  RepositorioNegocioLocal(this._base, {DateTime Function()? ahora})
    : _a = AccesoLocal(_base, ahora ?? DateTime.now);

  final BaseLocal _base;
  final AccesoLocal _a;

  @override
  Stream<DatosDelNegocio?> observar() => _a.cambios().asyncMap((_) async {
    final empresa = await _a.empresa();
    return empresa == null
        ? null
        : DatosDelNegocio(
            nombre: empresa.nombre,
            horaCierreMinutos: empresa.horaCierreMinutos,
          );
  });

  @override
  Future<void> guardar(DatosDelNegocio datos) => _base.transaction(() async {
    final empresa = (await _a.empresa())!;
    final nombre = datos.nombre.trim();
    if (nombre.isEmpty) throw ArgumentError('El nombre no puede quedar vacío.');
    if (nombre == empresa.nombre &&
        datos.horaCierreMinutos == empresa.horaCierreMinutos) {
      return;
    }
    await (_base.update(
      _base.empresas,
    )..where((e) => e.id.equals(empresa.id))).write(
      EmpresasCompanion(
        nombre: Value(nombre),
        horaCierreMinutos: Value(datos.horaCierreMinutos),
      ),
    );
    await _a.anotarEnBitacora(
      empresaId: empresa.id,
      autorId: (await _a.usuario()).id,
      entidad: 'empresa',
      entidadId: empresa.id,
      accion: AccionBitacora.editar,
      anterior: {
        'nombre': empresa.nombre,
        'horaCierreMinutos': empresa.horaCierreMinutos,
      },
      nuevo: {'nombre': nombre, 'horaCierreMinutos': datos.horaCierreMinutos},
    );
  });
}
