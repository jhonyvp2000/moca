import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import '../textos/textos.dart';

/// Lo que se ve cuando una pantalla falla, en vez del recuadro de Flutter
/// (entrega 27). El error ya quedó anotado para Jhony.
class PantallaConError extends StatelessWidget {
  const PantallaConError({super.key});

  @override
  Widget build(BuildContext context) {
    final navegador = Navigator.maybeOf(context);
    return Material(
      color: Colores.fondo,
      child: Padding(
        padding: const EdgeInsets.all(Medidas.margenLateral),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              Textos.algoSalioMal,
              style: Tipografia.tituloTarjeta,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Medidas.e2),
            const Text(
              Textos.algoSalioMalDetalle,
              style: Tipografia.secundario,
              textAlign: TextAlign.center,
            ),
            if (navegador != null && navegador.canPop()) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => navegador.maybePop(),
                child: const Text(Textos.volver),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
