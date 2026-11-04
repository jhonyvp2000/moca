import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/isotipo.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/version.dart';
import '../../inyeccion.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// Abre el APK que le toca a este teléfono en el navegador.
Future<void> descargarVersion(
  BuildContext context,
  WidgetRef ref,
  EstadoDeVersion estado,
) async {
  final mensajes = ScaffoldMessenger.of(context);
  final enlace = estado.enlace(ref.read(versionInstaladaProvider));
  if (enlace == null || !await ref.read(abridorProvider).abrir(enlace)) {
    mensajes.showSnackBar(
      const SnackBar(content: Text(Textos.noSeAbrioLaDescarga)),
    );
  }
}

/// «Hay una versión nueva de Moca», arriba en el Inicio (entrega 26.3).
class AvisoDeVersion extends ConsumerWidget {
  const AvisoDeVersion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instalada = ref.watch(versionInstaladaProvider);
    final (estado, ahoraNo) =
        ref.watch(versionPublicadaProvider).value ??
        (const EstadoDeVersion(), false);
    if (ahoraNo ||
        !estado.hayNueva(instalada) ||
        estado.enlace(instalada) == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Medidas.separacionTarjetas),
      child: Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(Textos.hayVersionNueva, style: Tipografia.textoFuerte),
            const SizedBox(height: 4),
            const Text(
              Textos.hayVersionNuevaDetalle,
              style: Tipografia.secundario,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => descargarVersion(context, ref, estado),
              child: const Text(Textos.descargar),
            ),
            TextButton(
              onPressed: () => ref.read(guardarAhoraNoVersionProvider)(),
              child: const Text(Textos.ahoraNoVersion),
            ),
          ],
        ),
      ),
    );
  }
}

/// Con `MOCA_APP_MINIMA`, una versión vieja solo puede actualizarse.
class PantallaActualizar extends ConsumerWidget {
  const PantallaActualizar({super.key, required this.estado});

  final EstadoDeVersion estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Medidas.margenLateral),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Center(child: Isotipo(tamano: 64)),
            const SizedBox(height: 20),
            const Text(
              Textos.actualizaMoca,
              style: Tipografia.tituloPantalla,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              Textos.actualizaMocaDetalle,
              style: Tipografia.secundario,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => descargarVersion(context, ref, estado),
              child: const Text(Textos.descargar),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Moca entrega-26.3 (117)», al final de la pestaña Moca.
class VersionDeMoca extends ConsumerWidget {
  const VersionDeMoca({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(versionInstaladaProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Text(
        v.conocida
            ? Textos.versionDeMoca(v.entrega, v.armado)
            : Textos.versionDeDesarrollo,
        style: Tipografia.secundario,
        textAlign: TextAlign.center,
      ),
    );
  }
}
