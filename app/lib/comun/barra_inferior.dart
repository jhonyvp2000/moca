import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import '../textos/textos.dart';
import 'icono_trazo.dart';

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
    Widget pestana(int indice, Icono icono, String etiqueta) => Expanded(
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
        border: Border(top: BorderSide(color: Colores.bordeTarjeta)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Row(
            children: [
              pestana(0, Icono.inicio, Textos.pestanaInicio),
              pestana(1, Icono.historial, Textos.pestanaHistorial),
              if (conRegistrar)
                Expanded(child: _BotonRegistrar(alTocar: alRegistrar)),
              if (conInformes)
                pestana(2, Icono.informes, Textos.pestanaInformes),
              pestana(3, Icono.moca, Textos.pestanaMoca),
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

  final Icono icono;
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
              IconoTrazo(icono, color: color),
              const SizedBox(height: 4),
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

class _BotonRegistrar extends StatelessWidget {
  const _BotonRegistrar({required this.alTocar});

  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: Semantics(
        button: true,
        label: Textos.registrar,
        child: Material(
          color: Colores.marca,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: alTocar,
            child: const SizedBox.square(
              dimension: Medidas.botonCentral,
              child: Center(
                child: IconoTrazo(
                  Icono.mas,
                  color: Colores.sobreMarca,
                  tamano: 28,
                  grosor: 2.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
