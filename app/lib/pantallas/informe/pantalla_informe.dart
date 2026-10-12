import 'package:flutter/material.dart';

import '../../comun/pantalla_pendiente.dart';
import '../../textos/textos.dart';

/// S14 · Informe del mes. Llega en la entrega 8.
class PantallaInforme extends StatelessWidget {
  const PantallaInforme({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaPendiente(titulo: Textos.tituloInforme, entrega: 8);
  }
}
