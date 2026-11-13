import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// La entrada a «Pregúntale a Moca» en el Inicio (entrega 74), debajo de
/// «Tienes hoy».
class BarraPreguntale extends StatelessWidget {
  const BarraPreguntale({super.key});

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medidas.radioMedio),
      side: const BorderSide(color: Colores.azulMedio, width: 1.5),
    );
    return Semantics(
      button: true,
      label: Textos.preguntaleAMoca,
      child: Material(
        color: Colores.superficie,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: () => context.push(Rutas.preguntale),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.e4,
              Medidas.e2,
              Medidas.e2,
              Medidas.e2,
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_outlined, color: Colores.marca),
                const SizedBox(width: Medidas.e3),
                const Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Textos.preguntaleAMoca,
                          style: Tipografia.textoFuerte,
                        ),
                        Text(
                          Textos.preguntaleEjemplo,
                          style: Tipografia.secundario,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: Medidas.e2),
                Container(
                  width: Medidas.objetivoTactilMinimo,
                  height: Medidas.objetivoTactilMinimo,
                  decoration: BoxDecoration(
                    color: Colores.marca,
                    borderRadius: BorderRadius.circular(Medidas.radioChico),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colores.sobreMarca,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
