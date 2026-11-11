import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/monto_text.dart';
import '../../dominio/medicion.dart';
import '../../inyeccion.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Tienes hoy» (mejora 01): la tarjeta azul del Inicio, con el monto grande
/// en blanco, de qué periodo es (entrega 36), una píldora con lo de hoy y la
/// explicación detrás del ⓘ.
class TarjetaTienesHoy extends StatelessWidget {
  const TarjetaTienesHoy({
    super.key,
    required this.etiqueta,
    required this.centimos,
    required this.explicacion,
    this.ocultar = false,
    this.pildora,
  });

  final String etiqueta;
  final int centimos;

  /// Lo que dice el ⓘ: cómo se llega a esta cifra.
  final String explicacion;
  final bool ocultar;

  /// «Vendiste hoy S/ 100».
  final String? pildora;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Medidas.radioMayor),
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Colores.marca, Colores.azul400],
        ),
        boxShadow: Sombras.nivel2,
      ),
      child: Stack(
        children: [
          // El círculo claro de fondo, solo adorno.
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colores.sobreMarca.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.e6,
              Medidas.e5,
              Medidas.e3,
              Medidas.e6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            etiqueta,
                            style: Tipografia.tituloFila.copyWith(
                              color: Colores.sobreMarca,
                            ),
                          ),
                          // De qué periodo es (entrega 36): no se reinicia.
                          Text(
                            Textos.desdeQueEmpezaste,
                            style: Tipografia.secundario.copyWith(
                              color: Colores.sobreMarcaSuave,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: Textos.queEsEstaCifra,
                      onPressed: () => _explicar(context),
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        color: Colores.sobreMarca,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Medidas.e2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ocultar
                      ? Text(
                          Textos.montoOculto,
                          style: Tipografia.montoPrincipal.copyWith(
                            color: Colores.sobreMarca,
                          ),
                        )
                      : MontoAnimado(centimos, color: Colores.sobreMarca),
                ),
                if (pildora case final texto?) ...[
                  const SizedBox(height: Medidas.e3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Medidas.e3,
                      vertical: Medidas.e2,
                    ),
                    decoration: BoxDecoration(
                      color: Colores.superficie,
                      borderRadius: BorderRadius.circular(Medidas.radioPildora),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          size: 18,
                          color: Colores.marca,
                        ),
                        const SizedBox(width: Medidas.e2),
                        Flexible(
                          child: Text(
                            texto,
                            style: Tipografia.cifra(
                              Tipografia.textoFuerte.copyWith(
                                color: Colores.marca,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _explicar(BuildContext context) {
    // Se mide cuánto se abre la explicación (entrega 59).
    ProviderScope.containerOf(context, listen: false)
        .read(medicionProvider)
        .anotar(EventoMedicion.seccionAbierta, {'seccion': 'tienes_hoy_info'});
    _mostrarExplicacion(context);
  }

  void _mostrarExplicacion(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (hoja) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          0,
          Medidas.margenLateral,
          Medidas.e6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(etiqueta, style: Tipografia.tituloPantalla),
            const SizedBox(height: Medidas.e1),
            const Text(Textos.desdeQueEmpezaste, style: Tipografia.secundario),
            const SizedBox(height: Medidas.e4),
            Text(explicacion, style: Tipografia.texto),
            const SizedBox(height: Medidas.e5),
            FilledButton(
              onPressed: () => Navigator.of(hoja).pop(),
              child: const Text(Textos.entendido),
            ),
          ],
        ),
      ),
    ),
  );
}
