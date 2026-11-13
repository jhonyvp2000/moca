import 'package:flutter/material.dart';

import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import '../textos/textos.dart';
import 'monto_text.dart';
import 'tono.dart';

/// Un resumen chico con fondo suave: «Te deben · 2 / S/ 130 / Marcos y
/// Rosa».
class TarjetaResumen extends StatelessWidget {
  const TarjetaResumen({
    super.key,
    required this.etiqueta,
    required this.centimos,
    this.detalle,
    this.tono = Tono.marca,
    this.alTocar,
    this.ocultar = false,
  });

  /// Con los montos ocultos (el ojo del Inicio).
  final bool ocultar;

  final String etiqueta;
  final int centimos;
  final String? detalle;
  final Tono tono;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final color = tono.color(context);
    return Material(
      color: tono.fondo(context),
      borderRadius: BorderRadius.circular(Medidas.radioMedio),
      child: InkWell(
        borderRadius: BorderRadius.circular(Medidas.radioMedio),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(Medidas.e4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: Tipografia.apoyo.copyWith(color: color)),
              const SizedBox(height: Medidas.e1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: ocultar
                    ? const Text(
                        Textos.montoOculto,
                        style: Tipografia.montoTarjeta,
                      )
                    : MontoText(centimos),
              ),
              if (detalle != null) ...[
                const SizedBox(height: Medidas.e1),
                Text(
                  detalle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Tipografia.secundario.copyWith(color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
