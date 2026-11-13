import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import '../textos/textos.dart';

/// Barra inferior de S04: cuatro pestañas y el botón central para registrar.
class BarraInferior extends StatelessWidget {
  const BarraInferior({
    super.key,
    required this.pestanaActual,
    required this.alElegirPestana,
    required this.alRegistrar,
    this.conInformes = true,
    this.conRegistrar = true,
  });

  /// 0 Inicio, 1 Historial, 2 Informes, 3 Moca.
  final int pestanaActual;
  final ValueChanged<int> alElegirPestana;
  final VoidCallback alRegistrar;

  /// Según el rol (entrega 20): el encargado y el ayudante no ven los
  /// informes; el contador no anota.
  final bool conInformes;
  final bool conRegistrar;

  @override
  Widget build(BuildContext context) {
    Widget pestana(int indice, IconData icono, String etiqueta) => Expanded(
      child: _Pestana(
        icono: icono,
        etiqueta: etiqueta,
        activa: pestanaActual == indice,
        alTocar: () => alElegirPestana(indice),
      ),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colores.superficie,
        boxShadow: Sombras.nivel2,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Medidas.e2,
            Medidas.e2,
            Medidas.e2,
            Medidas.e3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              pestana(0, Icons.home_rounded, Textos.pestanaInicio),
              pestana(
                1,
                Icons.format_list_bulleted_rounded,
                Textos.pestanaHistorial,
              ),
              if (conRegistrar)
                Expanded(child: _BotonRegistrar(alTocar: alRegistrar)),
              if (conInformes)
                pestana(2, Icons.bar_chart_rounded, Textos.pestanaInformes),
              pestana(3, Icons.auto_awesome_rounded, Textos.pestanaMoca),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pestana extends StatelessWidget {
  const _Pestana({
    required this.icono,
    required this.etiqueta,
    required this.activa,
    required this.alTocar,
  });

  final IconData icono;
  final String etiqueta;
  final bool activa;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final color = activa ? Colores.marca : Colores.textoSecundario;
    return Semantics(
      selected: activa,
      button: true,
      child: InkResponse(
        onTap: alTocar,
        radius: 36,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Medidas.altoItemBarra),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // La pestaña activa, con su píldora azul suave.
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: Medidas.e4,
                  vertical: Medidas.e1,
                ),
                decoration: BoxDecoration(
                  color: activa ? Colores.azul100 : Colores.superficie,
                  borderRadius: BorderRadius.circular(Medidas.radioPildora),
                ),
                child: Icon(icono, size: 24, color: color),
              ),
              const SizedBox(height: Medidas.e1),
              Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: Tipografia.etiquetaBarra.copyWith(
                  color: color,
                  fontWeight: activa ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El + del centro: un círculo azul que sobresale un poco de la barra,
/// con un aro blanco y sombra azul.
class _BotonRegistrar extends StatelessWidget {
  const _BotonRegistrar({required this.alTocar});

  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: Transform.translate(
        offset: const Offset(0, -Medidas.e3),
        child: Semantics(
          button: true,
          label: Textos.registrar,
          child: Container(
            padding: const EdgeInsets.all(Medidas.e1),
            decoration: const BoxDecoration(
              color: Colores.superficie,
              shape: BoxShape.circle,
              boxShadow: Sombras.nivel2,
            ),
            child: Material(
              color: Colores.marca,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: alTocar,
                child: const SizedBox.square(
                  dimension: Medidas.botonCentral - 8,
                  child: Icon(
                    Icons.add_rounded,
                    size: 32,
                    color: Colores.sobreMarca,
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
