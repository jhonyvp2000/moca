import 'package:flutter/material.dart';

import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import '../textos/textos.dart';
import 'tarjeta.dart';

/// Pestaña que todavía no se construye: su título y una tarjeta que dice en
/// qué entrega llega (estado aprobado por Jhony el 12-10-2026).
class PantallaPendiente extends StatelessWidget {
  const PantallaPendiente({
    super.key,
    required this.entrega,
    this.titulo,
    this.cabecera,
  });

  final int entrega;
  final String? titulo;

  /// Cabecera propia; si no hay, se usa el título.
  final Widget? cabecera;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          16,
          Medidas.margenLateral,
          16,
        ),
        children: [
          cabecera ??
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(titulo ?? '', style: Tipografia.tituloPantalla),
              ),
          const SizedBox(height: 12),
          Tarjeta(
            child: Text(
              Textos.llegaEnEntrega(entrega),
              style: Tipografia.texto,
            ),
          ),
        ],
      ),
    );
  }
}
