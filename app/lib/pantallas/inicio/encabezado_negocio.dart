import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// El encabezado del Inicio (mejora 01): la inicial y el nombre del negocio,
/// con una línea debajo. Desde la entrega 61 no lleva botones: todo el
/// encabezado se toca y abre Ajustes (desde ahí se vuelve a la cuenta,
/// entrega 45.1). Los avisos están en el Asistente, y el ojo, en «Tienes hoy».
class EncabezadoNegocio extends StatelessWidget {
  const EncabezadoNegocio({
    super.key,
    required this.nombre,
    this.detalle,
    this.conMargen = true,
  });

  /// Sin margen lateral cuando la lista ya lo pone.
  final bool conMargen;

  final String nombre;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.trim().isEmpty
        ? 'M'
        : nombre.trim().characters.first.toUpperCase();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        conMargen ? Medidas.margenLateral : 0,
        Medidas.e4,
        conMargen ? Medidas.margenLateral : 0,
        Medidas.e2,
      ),
      child: Tooltip(
        message: Textos.ajustes,
        child: Semantics(
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(Medidas.radioChico),
            onTap: () => context.push(Rutas.ajustes),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: Medidas.objetivoTactilMinimo,
              ),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: Medidas.objetivoTactilMinimo,
                      height: Medidas.objetivoTactilMinimo,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colores.marca,
                        borderRadius: BorderRadius.circular(Medidas.radioChico),
                      ),
                      child: Text(
                        inicial,
                        style: Tipografia.tituloDestacado.copyWith(
                          color: Colores.sobreMarca,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Medidas.e3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Tipografia.tituloDestacado,
                        ),
                        if (detalle case final d?)
                          Text(d, style: Tipografia.secundario),
                      ],
                    ),
                  ),
                  const SizedBox(width: Medidas.e2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 28,
                    color: Colores.textoSecundario,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
