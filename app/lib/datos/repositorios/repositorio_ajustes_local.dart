import '../../dominio/ajustes.dart';
import '../local/base_local.dart';
import 'acceso_local.dart';

class RepositorioAjustesLocal implements RepositorioAjustes {
  RepositorioAjustesLocal(BaseLocal base)
    : _a = AccesoLocal(base, DateTime.now);

  final AccesoLocal _a;
  static const _claveMicrofono = 'microfono_explicado';

  @override
  Future<bool> microfonoExplicado() async =>
      await _a.leerAjuste(_claveMicrofono) != null;

  @override
  Future<void> marcarMicrofonoExplicado() =>
      _a.guardarAjuste(_claveMicrofono, 'si');

  @override
  Future<bool> seccionAbierta(String clave) async =>
      await _a.leerAjuste('seccion_$clave') == 'abierta';

  @override
  Future<void> guardarSeccion(String clave, {required bool abierta}) =>
      _a.guardarAjuste('seccion_$clave', abierta ? 'abierta' : 'cerrada');
}
