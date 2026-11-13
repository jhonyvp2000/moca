import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import 'tono.dart';

/// Una opción para elegir, con icono y color según su significado: «Entró»
/// en azul, «Salió» en coral, lo interno en neutro. Elegida, lleva borde,
/// fondo suave y un check.
class ChipSeleccion extends StatelessWidget {
  const ChipSeleccion({
    super.key,
    required this.etiqueta,
    required this.elegida,
    required this.alTocar,
    this.icono,
    this.tono = Tono.marca,
    this.detalle,
    this.grande = false,
  });

  /// Al lado del nombre, en su propio texto («S/ 200»).
  final String? detalle;

  /// «Entró» y «Salió» en Escribirlo: el icono en su cuadro de color.
  final bool grande;

  final String etiqueta;
  final bool elegida;
  final VoidCallback? alTocar;
  final IconData? icono;
  final Tono tono;

  @override
  Widget build(BuildContext context) {
    final color = tono.color(context);
    return Semantics(
      button: true,
      selected: elegida,
      child: Material(
        color: elegida ? tono.fondo(context) : Colores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Medidas.radioMedio),
          side: BorderSide(
            color: elegida ? color : Colores.bordeTarjeta,
            width: elegida ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Medidas.radioMedio),
          onTap: alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: Medidas.objetivoTactilMinimo,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Medidas.e4,
                vertical: Medidas.e2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icono != null && grande) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: elegida ? color : tono.fondo(context),
                        borderRadius: BorderRadius.circular(Medidas.e2 + 2),
                      ),
                      child: Icon(
                        icono,
                        size: 20,
                        color: elegida ? Colores.sobreMarca : color,
                      ),
                    ),
                    const SizedBox(width: Medidas.e3),
                  ] else if (icono != null) ...[
                    Icon(icono, size: 20, color: color),
                    const SizedBox(width: Medidas.e2),
                  ],
                  Flexible(
                    child: Text(
                      etiqueta,
                      style: Tipografia.textoFuerte.copyWith(
                        fontSize: grande ? 17 : null,
                        color: elegida ? color : Colores.textoPrincipal,
                      ),
                    ),
                  ),
                  if (detalle case final d?)
                    Text(
                      ' · $d',
                      style: Tipografia.cifra(
                        Tipografia.textoFuerte.copyWith(
                          color: elegida ? color : Colores.textoSecundario,
                        ),
                      ),
                    ),
                  if (elegida && !grande) ...[
                    const SizedBox(width: Medidas.e2),
                    Icon(Icons.check_rounded, size: 20, color: color),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
