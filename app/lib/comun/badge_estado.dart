import 'package:flutter/material.dart';

import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import 'tono.dart';

/// Una etiqueta de estado: «Te debe», «Lo debes», «Cobrado», «Por subir».
/// Siempre con texto: el color solo acompaña.
class BadgeEstado extends StatelessWidget {
  const BadgeEstado(this.texto, {super.key, this.tono = Tono.pendiente});

  final String texto;
  final Tono tono;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Medidas.e3,
      vertical: Medidas.e1,
    ),
    decoration: BoxDecoration(
      color: tono.fondo(context),
      borderRadius: BorderRadius.circular(Medidas.radioPildora),
    ),
    child: Text(
      texto,
      style: Tipografia.apoyo.copyWith(
        color: tono.color(context),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
