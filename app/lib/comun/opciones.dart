import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';

/// Botones de una sola elección, como los de tipo de negocio en S02:
/// redondos, borde azul y tinte cuando están elegidos.
class Opciones<T> extends StatelessWidget {
  const Opciones({
    super.key,
    required this.opciones,
    required this.elegida,
    required this.alElegir,
  });

  final Map<T, String> opciones;
  final T? elegida;
  final ValueChanged<T> alElegir;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final MapEntry(key: valor, value: texto) in opciones.entries)
          _Opcion(
            texto: texto,
            elegida: valor == elegida,
            alTocar: () => alElegir(valor),
          ),
      ],
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.texto,
    required this.elegida,
    required this.alTocar,
  });

  final String texto;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: elegida
          ? const BorderSide(color: Colores.marca, width: 2)
          : const BorderSide(color: Colores.bordeBotonSecundario),
    );
    return Semantics(
      selected: elegida,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: elegida ? Colores.tinteAzul : Colores.superficie,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: Medidas.objetivoTactilMinimo,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  texto,
                  style: TextStyle(
                    fontFamily: Tipografia.familia,
                    fontSize: 14,
                    fontWeight: elegida ? FontWeight.w700 : FontWeight.w600,
                    color: elegida
                        ? Colores.azulOscuro
                        : Colores.textoPrincipal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botones de una sola elección en rejilla, todos del mismo ancho (S08:
/// «¿De dónde salió la plata?», «¿Ya lo pagaste?»).
class OpcionesRejilla<T> extends StatelessWidget {
  const OpcionesRejilla({
    super.key,
    required this.opciones,
    required this.elegida,
    required this.alElegir,
  });

  final Map<T, String> opciones;
  final T? elegida;
  final ValueChanged<T> alElegir;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, MapEntry(key: valor, value: texto))
            in opciones.entries.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _BotonRejilla(
              texto: texto,
              elegida: valor == elegida,
              alTocar: () => alElegir(valor),
            ),
          ),
        ],
      ],
    );
  }
}

class _BotonRejilla extends StatelessWidget {
  const _BotonRejilla({
    required this.texto,
    required this.elegida,
    required this.alTocar,
  });

  final String texto;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medidas.radioBoton),
      side: elegida
          ? const BorderSide(color: Colores.marca, width: 2)
          : const BorderSide(color: Colores.bordeBotonSecundario),
    );
    return Semantics(
      selected: elegida,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: elegida ? Colores.tinteAzul : Colores.superficie,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: Medidas.altoBotonSecundario,
            ),
            child: Center(
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Tipografia.familia,
                    fontSize: 15,
                    fontWeight: elegida ? FontWeight.w700 : FontWeight.w600,
                    color: elegida
                        ? Colores.azulOscuro
                        : Colores.textoPrincipal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
