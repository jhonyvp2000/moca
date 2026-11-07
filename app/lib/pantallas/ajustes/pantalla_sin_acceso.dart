import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/isotipo.dart';
import '../../dominio/cuenta_real.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// Este teléfono perdió el acceso al negocio (entrega 37): se borró, lo
/// quitaron, salió o la cuenta se abrió en otro teléfono. Su copia ya se
/// borró: no queda nada del negocio detrás, solo qué pasó y qué hacer.
class PantallaSinAcceso extends ConsumerWidget {
  const PantallaSinAcceso({super.key});

  /// Todo lo de Moca en este teléfono, para empezar de cero.
  Future<void> _deCero(WidgetRef ref) =>
      ref.read(repositorioOperadorProvider).borrarTodo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sinAcceso =
        ref.watch(sinAccesoProvider).value ??
        const SinAcceso(motivo: MotivoSinAcceso.sinNegocio, negocio: '');
    final otroTelefono = sinAcceso.motivo == MotivoSinAcceso.otroTelefono;
    return Scaffold(
      backgroundColor: Colores.fondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Medidas.margenLateral),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: Isotipo(tamano: 64)),
              const SizedBox(height: 20),
              Text(
                Textos.sinAccesoTitulo(sinAcceso),
                style: Tipografia.tituloPantalla,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                Textos.sinAccesoDetalle(sinAcceso.motivo),
                style: Tipografia.secundario,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (otroTelefono) ...[
                FilledButton(
                  onPressed: () async {
                    await _deCero(ref);
                    if (context.mounted) context.go(Rutas.entrar);
                  },
                  child: const Text(Textos.volverAEntrarConMiNumero),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _deCero(ref),
                  child: const Text(Textos.empezarDeCeroAqui),
                ),
              ] else ...[
                FilledButton(
                  onPressed: () => _deCero(ref),
                  child: const Text(Textos.empezarMiNegocio),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push(Rutas.negocios),
                  child: const Text(Textos.verMisNegociosEInvitaciones),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
