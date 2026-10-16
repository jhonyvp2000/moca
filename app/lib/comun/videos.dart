import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/tutoria.dart';
import '../inyeccion.dart';
import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import '../textos/textos.dart';
import 'icono_trazo.dart';
import 'tarjeta.dart';

/// Abre el video y lo marca como visto (entrega 14.6).
Future<void> verVideo(
  BuildContext context,
  WidgetRef ref,
  VideoTutoria video,
  DesdeVideo desde,
) async {
  final mensajes = ScaffoldMessenger.of(context);
  final enlace = ref.read(estadoTutoriaProvider)?.enlaces[video];
  final abierto =
      enlace != null && await ref.read(abridorProvider).abrir(enlace);
  if (enlace == null || abierto) {
    await ref.read(repositorioTutoriaProvider).marcarVisto(video, desde);
  }
  if (!abierto) {
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            enlace == null ? Textos.videoSinEnlace : Textos.videoNoSeAbrio,
          ),
        ),
      );
  }
}

/// «▶ Ver cómo · 20 s». No aparece si el video aún no tiene enlace.
class EnlaceVerComo extends ConsumerWidget {
  const EnlaceVerComo({super.key, required this.video, required this.desde});

  final VideoTutoria video;
  final DesdeVideo desde;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoTutoriaProvider);
    if (estado == null || !estado.disponible(video)) {
      return const SizedBox.shrink();
    }
    return Semantics(
      button: true,
      label: '${Textos.verComo(video.segundos)}: ${Textos.tituloVideo(video)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => verVideo(context, ref, video, desde),
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconoTrazo(
                Icono.reproducir,
                color: Colores.marca,
                tamano: 18,
              ),
              const SizedBox(width: 6),
              Text(
                Textos.verComo(video.segundos),
                style: Tipografia.textoFuerte.copyWith(color: Colores.marca),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «¿Primera vez? Mira cómo se hace»: una sola vez, la primera que se abre
/// la pantalla. «Ver video» y «Ahora no» la cierran para siempre.
class TarjetaPrimeraVez extends ConsumerWidget {
  const TarjetaPrimeraVez({
    super.key,
    required this.video,
    this.margen = EdgeInsets.zero,
  });

  final VideoTutoria video;
  final EdgeInsets margen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoTutoriaProvider);
    if (estado == null ||
        !estado.disponible(video) ||
        estado.vistos.contains(video) ||
        estado.tarjetasCerradas.contains(video)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: margen,
      child: TarjetaMoca(
        texto: Textos.primeraVez(video.segundos),
        accion: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () =>
                    verVideo(context, ref, video, DesdeVideo.primeraVez),
                child: const Text(Textos.verVideo),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    ref.read(repositorioTutoriaProvider).cerrarTarjeta(video),
                child: const Text(Textos.ahoraNoCorto),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Aprende en 3 minutos», en la pestaña Moca: los videos con su duración y
/// un ✓ en los que ya vio.
class SeccionAprende extends ConsumerWidget {
  const SeccionAprende({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoTutoriaProvider);
    if (estado == null || !estado.algunoDisponible) {
      return const SizedBox.shrink();
    }
    final videos = [
      for (final v in VideoTutoria.values)
        if (estado.disponible(v)) v,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Semantics(
          header: true,
          child: Text(
            Textos.aprendeEnTresMinutos,
            style: Tipografia.secundario.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 2),
        const Text(Textos.aprendeDetalle, style: Tipografia.secundario),
        const SizedBox(height: 8),
        Tarjeta(
          relleno: EdgeInsets.zero,
          child: Material(
            color: Colores.superficie,
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, v) in videos.indexed)
                  _FilaVideo(
                    video: v,
                    visto: estado.vistos.contains(v),
                    conSeparador: i < videos.length - 1,
                    alTocar: () =>
                        verVideo(context, ref, v, DesdeVideo.aprende),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilaVideo extends StatelessWidget {
  const _FilaVideo({
    required this.video,
    required this.visto,
    required this.conSeparador,
    required this.alTocar,
  });

  final VideoTutoria video;
  final bool visto;
  final bool conSeparador;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: visto,
      child: InkWell(
        onTap: alTocar,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: conSeparador
              ? const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colores.separador)),
                )
              : null,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: visto ? Colores.marca : Colores.tinteAzul,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: IconoTrazo(
                    visto ? Icono.check : Icono.reproducir,
                    color: visto ? Colores.sobreMarca : Colores.azulOscuro,
                    tamano: 16,
                    grosor: visto ? 2.6 : 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Textos.tituloVideo(video),
                  style: visto
                      ? Tipografia.texto.copyWith(
                          color: Colores.textoSecundario,
                        )
                      : Tipografia.textoFuerte,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Textos.duracionVideo(video.segundos),
                style: Tipografia.secundario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
