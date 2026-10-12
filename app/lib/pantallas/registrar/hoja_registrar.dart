import 'package:flutter/material.dart';

import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// Lo que abre el botón central. S06 llega en la entrega 3.
Future<void> mostrarHojaRegistrar(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          0,
          Medidas.margenLateral,
          16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(Textos.registrar, style: Tipografia.tituloPantalla),
            const SizedBox(height: 8),
            Text(Textos.registrarLlegaEnEntrega(3), style: Tipografia.texto),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(Textos.entendido),
            ),
          ],
        ),
      ),
    ),
  );
}
