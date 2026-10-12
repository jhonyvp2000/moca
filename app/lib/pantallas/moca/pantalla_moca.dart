import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../comun/isotipo.dart';
import '../../comun/pantalla_pendiente.dart';
import '../../rutas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// S16 · Moca. El contenido llega en la entrega 8; la cabecera ya es la del
/// mockup y su isotipo abre el ajuste oculto del operador.
class PantallaMoca extends StatelessWidget {
  const PantallaMoca({super.key});

  /// Tiempo que hay que mantener presionado el isotipo (decisiones.md).
  static const esperaAjusteOculto = Duration(seconds: 3);

  @override
  Widget build(BuildContext context) {
    return PantallaPendiente(
      entrega: 8,
      cabecera: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            RawGestureDetector(
              gestures: {
                LongPressGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      LongPressGestureRecognizer
                    >(
                      () => LongPressGestureRecognizer(
                        duration: esperaAjusteOculto,
                      ),
                      (reconocedor) =>
                          reconocedor.onLongPress = () =>
                              context.push(Rutas.operador),
                    ),
              },
              child: const Isotipo(key: claveIsotipo, tamano: 40),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Textos.pestanaMoca, style: Tipografia.tituloPantalla),
                  Text(Textos.subtituloMoca, style: Tipografia.secundario),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const claveIsotipo = Key('isotipo-moca');
}
