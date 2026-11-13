import 'package:flutter/material.dart';

import '../tema/medidas.dart';
import '../tema/tipografia.dart';

/// El título de una sección, con una acción a la derecha si hace falta
/// («Ver todas»).
class SeccionTitulo extends StatelessWidget {
  const SeccionTitulo(this.texto, {super.key, this.accion, this.alTocar});

  final String texto;
  final String? accion;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Medidas.e2),
    child: Row(
      children: [
        Expanded(child: Text(texto, style: Tipografia.tituloSeccion)),
        if (accion != null)
          TextButton(onPressed: alTocar, child: Text(accion!)),
      ],
    ),
  );
}
