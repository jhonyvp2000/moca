import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import 'isotipo.dart';

/// Tarjeta blanca con borde (diseno/estilo.md).
class Tarjeta extends StatelessWidget {
  const Tarjeta({super.key, required this.child, this.relleno});

  final Widget child;
  final EdgeInsetsGeometry? relleno;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: relleno ?? const EdgeInsets.all(Medidas.rellenoTarjeta),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        border: Border.all(color: Colores.bordeTarjeta),
      ),
      child: child,
    );
  }
}

/// Lo que dice Moca va en su propia tarjeta: tinte azul con el isotipo,
/// para que el dueño lo distinga de los datos.
class TarjetaMoca extends StatelessWidget {
  const TarjetaMoca({super.key, required this.texto, this.accion});

  final String texto;

  /// Un botón debajo del texto, por ejemplo «Hacer arqueo».
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colores.tinteAzul,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Isotipo(tamano: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Moca', style: Tipografia.etiquetaMoca),
                const SizedBox(height: 4),
                Text(texto, style: Tipografia.texto),
                if (accion != null) ...[const SizedBox(height: 12), accion!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
