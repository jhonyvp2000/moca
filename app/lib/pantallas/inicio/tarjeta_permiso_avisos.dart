import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/tarjeta.dart';
import '../../comun/videos.dart';
import '../../dominio/tutoria.dart';
import '../../inyeccion.dart';
import '../../tema/medidas.dart';
import '../../textos/textos.dart';

/// Pide el permiso de avisos la primera vez que se llega al Inicio
/// (estado aprobado el 13-10-2026). No aparece en la Demo.
class TarjetaPermisoAvisos extends ConsumerStatefulWidget {
  const TarjetaPermisoAvisos({super.key});

  @override
  ConsumerState<TarjetaPermisoAvisos> createState() => _EstadoTarjetaPermiso();
}

class _EstadoTarjetaPermiso extends ConsumerState<TarjetaPermisoAvisos> {
  bool _negado = false;

  Future<void> _cerrar() async {
    await ref.read(repositorioAvisoCierreProvider).marcarPermisoPreguntado();
    ref.invalidate(permisoAvisosPreguntadoProvider);
  }

  Future<void> _pedir() async {
    final permitido = await ref.read(notificadorProvider).pedirPermiso();
    if (permitido) {
      await _cerrar();
    } else if (mounted) {
      setState(() => _negado = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preguntado = ref.watch(permisoAvisosPreguntadoProvider).value;
    final demo = ref.watch(enDemoProvider).value;
    if (preguntado != false || demo != false) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Medidas.margenLateral,
        0,
        Medidas.margenLateral,
        Medidas.separacionTarjetas,
      ),
      child: TarjetaMoca(
        texto: _negado ? Textos.sinPermisoAvisos : Textos.permisoAvisos,
        accion: _negado
            ? OutlinedButton(
                onPressed: _cerrar,
                child: const Text(Textos.entendido),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _pedir,
                    child: const Text(Textos.permitirAvisos),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _cerrar,
                    child: const Text(Textos.ahoraNoCorto),
                  ),
                  // Qué es el aviso de la noche (entrega 14.6).
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: EnlaceVerComo(
                      video: VideoTutoria.avisoDeLaNoche,
                      desde: DesdeVideo.permisoAvisos,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
