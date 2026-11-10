import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';

/// Cuando no hay nada que mostrar: un icono amable, qué pasa y, si hay,
/// qué hacer.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.texto,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String? texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Medidas.e6),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Colores.azul100,
            shape: BoxShape.circle,
          ),
          child: Icon(icono, size: 30, color: Colores.marca),
        ),
        const SizedBox(height: Medidas.e3),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: Tipografia.tituloSeccion,
        ),
        if (texto != null) ...[
          const SizedBox(height: Medidas.e1),
          Text(
            texto!,
            textAlign: TextAlign.center,
            style: Tipografia.secundario,
          ),
        ],
        if (accion != null) ...[const SizedBox(height: Medidas.e4), accion!],
      ],
    ),
  );
}
