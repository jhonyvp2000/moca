import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import 'icono_trazo.dart';
import 'tarjeta.dart';

/// Una tarjeta que lleva a otra pantalla: «Mis cuentas», «Ajustes».
class TarjetaEnlace extends StatelessWidget {
  const TarjetaEnlace({
    super.key,
    required this.titulo,
    required this.detalle,
    required this.ruta,
  });

  final String titulo;
  final String detalle;
  final String ruta;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      relleno: EdgeInsets.zero,
      child: Material(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        child: InkWell(
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          onTap: () => context.push(ruta),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: Tipografia.textoFuerte),
                      Text(detalle, style: Tipografia.secundario),
                    ],
                  ),
                ),
                const IconoTrazo(
                  Icono.derecha,
                  color: Colores.textoSecundario,
                  tamano: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
