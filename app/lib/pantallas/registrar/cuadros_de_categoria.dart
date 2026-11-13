import 'package:flutter/material.dart';

import '../../comun/chip_seleccion.dart';
import '../../comun/tono.dart';
import '../../dominio/movimientos.dart';
import '../../pais/peru/categorias.dart';
import '../../tema/medidas.dart';

/// Las categorías de «Escribirlo»: desde la entrega 67, pastillas solo con
/// el nombre corto, sin íconos, y todas a la vista, sin «Ver más». Primero
/// lo que el negocio compra para vender.
class CuadrosDeCategoria extends StatelessWidget {
  const CuadrosDeCategoria({
    super.key,
    required this.categorias,
    required this.elegida,
    required this.alElegir,
    required this.tono,
  });

  final List<CategoriaVista> categorias;
  final String? elegida;
  final ValueChanged<String> alElegir;
  final Tono tono;

  @override
  Widget build(BuildContext context) {
    final todas = [
      ...categorias.where((c) => categoriasDeMercaderia.contains(c.nombre)),
      ...categorias.where((c) => !categoriasDeMercaderia.contains(c.nombre)),
    ];
    return Wrap(
      spacing: Medidas.e2,
      runSpacing: Medidas.e2,
      children: [
        for (final c in todas)
          ChipSeleccion(
            etiqueta: nombreCortoDeCategoria(c.nombre),
            elegida: c.id == elegida,
            tono: tono,
            alTocar: () => alElegir(c.id),
          ),
      ],
    );
  }
}
