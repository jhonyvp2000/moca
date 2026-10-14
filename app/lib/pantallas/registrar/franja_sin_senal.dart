import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/icono_trazo.dart';
import '../../inyeccion.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Sin señal. Se guarda en tu teléfono y sube cuando vuelva.» Solo aparece
/// cuando el teléfono no tiene señal (mockup de S07).
class FranjaSinSenal extends ConsumerWidget {
  const FranjaSinSenal({super.key, this.separacion = 14});

  /// Espacio debajo de la franja, cuando se muestra.
  final double separacion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(hayConexionProvider).value != false) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(bottom: separacion),
      child: Semantics(
        liveRegion: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colores.superficie,
            borderRadius: BorderRadius.circular(Medidas.radioBoton),
            border: Border.all(color: Colores.bordeTarjeta),
          ),
          child: Row(
            children: [
              const IconoTrazo(
                Icono.sinSenal,
                color: Colores.textoSecundario,
                tamano: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(Textos.sinSenal, style: Tipografia.secundario),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
