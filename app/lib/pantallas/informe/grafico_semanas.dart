import 'package:flutter/material.dart';

import '../../comun/monto_text.dart';
import '../../dominio/informe.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Por semana» en Informes (mejora 01): lo que entró y salió en cada
/// semana del mes, en barras. Las semanas que faltan van punteadas; la de
/// más movimiento lleva su monto encima. Sin dependencias: son Containers.
class GraficoSemanas extends StatelessWidget {
  const GraficoSemanas({super.key, required this.semanas});

  final List<SemanaDelMes> semanas;

  static const _alto = 120.0;

  @override
  Widget build(BuildContext context) {
    final mayor = semanas.fold(
      0,
      (m, s) =>
          [m, s.entroCentimos, s.salioCentimos].reduce((a, b) => a > b ? a : b),
    );
    final destacada = mayor == 0
        ? null
        : semanas.indexWhere(
            (s) => s.entroCentimos == mayor || s.salioCentimos == mayor,
          );
    double alto(int centimos) =>
        mayor == 0 ? 0 : (centimos / mayor * _alto).clamp(3, _alto);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(Textos.porSemana, style: Tipografia.tituloSeccion),
            ),
            const _Leyenda(color: Colores.ingreso, texto: Textos.entro),
            const SizedBox(width: Medidas.e3),
            _Leyenda(
              color: Colores.egreso.withValues(alpha: 0.7),
              texto: Textos.salio,
            ),
          ],
        ),
        const SizedBox(height: Medidas.e4),
        Semantics(
          label: [
            for (final s in semanas)
              if (!s.futura)
                '${s.desde}–${s.hasta}: ${Textos.entro} '
                    '${s.entroCentimos ~/ 100}, ${Textos.salio} '
                    '${s.salioCentimos ~/ 100}',
          ].join('. '),
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (n, s) in semanas.indexed)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // El monto de la semana con más movimiento.
                        SizedBox(
                          height: 24,
                          child: n == destacada
                              ? FittedBox(
                                  child: MontoText(
                                    s.entroCentimos >= s.salioCentimos
                                        ? s.entroCentimos
                                        : s.salioCentimos,
                                    estilo: Tipografia.apoyo.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: s.entroCentimos >= s.salioCentimos
                                          ? Colores.marca
                                          : Colores.egreso,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(
                          height: _alto,
                          child: s.futura
                              ? Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: 44,
                                    height: _alto * 0.75,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colores.grisAzulado,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        Medidas.radioChico / 2,
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _Barra(
                                      alto: alto(s.entroCentimos),
                                      color: Colores.ingreso,
                                    ),
                                    const SizedBox(width: Medidas.e1),
                                    _Barra(
                                      alto: alto(s.salioCentimos),
                                      color: Colores.egreso.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const Divider(height: 1),
                        const SizedBox(height: Medidas.e2),
                        Text(
                          '${s.desde}–${s.hasta}',
                          style: Tipografia.apoyo.copyWith(
                            color: n == destacada
                                ? Colores.textoPrincipal
                                : Colores.textoSecundario,
                            fontWeight: n == destacada
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({required this.alto, required this.color});

  final double alto;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: alto == 0 ? 3 : alto,
    decoration: BoxDecoration(
      color: alto == 0 ? Colores.separador : color,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(Medidas.radioMini),
      ),
    ),
  );
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(Medidas.radioMini),
        ),
      ),
      const SizedBox(width: Medidas.e1),
      Text(texto, style: Tipografia.apoyo),
    ],
  );
}
