import 'package:flutter/material.dart';

import '../../comun/pantalla_pendiente.dart';
import '../../textos/textos.dart';

/// S04 · Inicio. Llega en la entrega 3.
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaPendiente(titulo: Textos.tituloInicio, entrega: 3);
  }
}
