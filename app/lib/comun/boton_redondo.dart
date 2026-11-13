import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';

/// Un botón de icono redondo y blanco, con sombra azul, para el encabezado
/// (Ajustes, Avisos). 48 dp, con su nombre para el lector de pantalla.
class BotonRedondo extends StatelessWidget {
  const BotonRedondo({
    super.key,
    required this.icono,
    required this.nombre,
    required this.alTocar,
  });

  final IconData icono;
  final String nombre;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: nombre,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: Sombras.nivel1,
      ),
      child: Material(
        color: Colores.superficie,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: alTocar,
          child: SizedBox.square(
            dimension: Medidas.objetivoTactilMinimo,
            child: Icon(icono, size: 24, color: Colores.textoPrincipal),
          ),
        ),
      ),
    ),
  );
}
