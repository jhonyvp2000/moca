import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/enlace.dart';
import '../../inyeccion.dart';
import '../../textos/textos.dart';

/// La sección «Moca» de Ajustes (entrega 95): recomendarla a otro dueño por
/// WhatsApp, la página web y la política de privacidad. Para todos los roles
/// y en la Demo: no muestra nada del negocio.
class MocaEnLaWeb extends ConsumerWidget {
  const MocaEnLaWeb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> abrir(String enlace, String siFalla) async {
      final mensajes = ScaffoldMessenger.of(context);
      if (!await ref.read(abridorProvider).abrir(enlace)) {
        mensajes.showSnackBar(SnackBar(content: Text(siFalla)));
      }
    }

    return GrupoDeAjustes(
      titulo: Textos.seccionMoca,
      filas: [
        FilaAjuste(
          icono: Icons.share_rounded,
          titulo: Textos.recomendarMoca,
          detalle: Textos.recomendarMocaDetalle,
          // Sin número: WhatsApp deja elegir a quién mandarlo.
          alTocar: () => abrir(
            'https://wa.me/?text='
            '${Uri.encodeComponent(Textos.mensajeRecomendarMoca(paginaDeMoca))}',
            Textos.noSeAbrioWhatsApp,
          ),
        ),
        FilaAjuste(
          icono: Icons.language_rounded,
          titulo: Textos.mocaEnLaWeb,
          detalle: Textos.mocaEnLaWebDetalle,
          alTocar: () => abrir(paginaDeMoca, Textos.noSeAbrioLaPagina),
        ),
        FilaAjuste(
          icono: Icons.privacy_tip_outlined,
          titulo: Textos.politicaDePrivacidad,
          detalle: Textos.politicaDePrivacidadDetalle,
          alTocar: () => abrir(
            ref.read(enlacePrivacidadProvider),
            Textos.noSeAbrioLaPagina,
          ),
        ),
      ],
    );
  }
}
