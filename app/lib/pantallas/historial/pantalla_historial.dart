import 'package:flutter/material.dart';

import '../../comun/pantalla_pendiente.dart';
import '../../textos/textos.dart';

/// S10 · Historial. Llega en la entrega 6.
class PantallaHistorial extends StatelessWidget {
  const PantallaHistorial({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaPendiente(titulo: Textos.tituloHistorial, entrega: 6);
  }
}
