import 'package:flutter/material.dart';

import '../../comun/monto_text.dart';
import '../../comun/seccion_titulo.dart';
import '../../comun/tarjeta.dart';
import '../../comun/tono.dart';
import '../../dominio/movimientos.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Esta semana» en el Inicio (mejora 01): lo que te quedó, la comparación
/// con la semana pasada y lo que entró y salió, cada monto con su signo.
/// Es de todo el negocio: la ven el dueño y el contador.
class TarjetaSemana extends StatelessWidget {
  const TarjetaSemana({super.key, required this.resumen, this.ocultar = false});

  final ResumenInicio resumen;
  final bool ocultar;

  String _soles(int centimos) =>
      ocultar ? Textos.montoOculto : formatearSoles(centimos);

  @override
  Widget build(BuildContext context) {
    final r = resumen;
    final diferencia = r.diferenciaConSemanaAnteriorCentimos;
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SeccionTitulo(Textos.estaSemana),
          // De qué periodo es (entrega 36).
          const Text(Textos.deLunesAHoy, style: Tipografia.secundario),
          const SizedBox(height: Medidas.e3),
          if (!r.semanaConMovimientos)
            const Text(Textos.semanaSinMovimientos, style: Tipografia.texto)
          else ...[
            Text.rich(
              TextSpan(
                style: Tipografia.texto,
                children: [
                  const TextSpan(text: Textos.estaSemanaTeQuedo),
                  TextSpan(
                    text: _soles(r.semanaQuedoCentimos),
                    style: Tipografia.cifra(
                      const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            if (diferencia != null) ...[
              const SizedBox(height: Medidas.e1),
              // Subió o bajó: flecha y signo; azul si subió, gris si bajó
              // (decisiones.md, 10-11-2026).
              Row(
                children: [
                  if (diferencia != 0) ...[
                    Icon(
                      diferencia > 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 18,
                      color: diferencia > 0 ? Colores.marca : Colores.neutro,
                    ),
                    const SizedBox(width: Medidas.e2),
                  ],
                  Expanded(
                    child: Text(
                      diferencia > 0
                          ? Textos.masQueLaSemanaPasada(_soles(diferencia))
                          : diferencia < 0
                          ? Textos.menosQueLaSemanaPasada(_soles(-diferencia))
                          : Textos.igualQueLaSemanaPasada,
                      style: Tipografia.cifra(
                        Tipografia.apoyo.copyWith(
                          color: diferencia > 0
                              ? Colores.azul900
                              : Colores.neutro,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Medidas.e3),
            Wrap(
              spacing: Medidas.e5,
              runSpacing: Medidas.e2,
              children: [
                _Linea(
                  etiqueta: Textos.entro,
                  centimos: r.semanaEntroCentimos,
                  tono: Tono.ingreso,
                  ocultar: ocultar,
                ),
                _Linea(
                  etiqueta: Textos.salio,
                  centimos: r.semanaSalioCentimos,
                  tono: Tono.egreso,
                  ocultar: ocultar,
                ),
                if (r.semanaAportesCentimos > 0)
                  _Linea(
                    etiqueta: Textos.puseDeMiBolsillo,
                    centimos: r.semanaAportesCentimos,
                    tono: Tono.ingreso,
                    ocultar: ocultar,
                  ),
                // Con retiros, también lo que sacaste: así cuadra con la
                // plata (entrega 14.9).
                if (r.semanaRetirosCentimos > 0)
                  _Linea(
                    etiqueta: Textos.retiroParaMi,
                    centimos: r.semanaRetirosCentimos,
                    tono: Tono.egreso,
                    ocultar: ocultar,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({
    required this.etiqueta,
    required this.centimos,
    required this.tono,
    required this.ocultar,
  });

  final String etiqueta;
  final int centimos;
  final Tono tono;
  final bool ocultar;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(etiqueta, style: Tipografia.apoyo),
      ocultar
          ? const Text(Textos.montoOculto, style: Tipografia.textoFuerte)
          : MontoText(
              centimos,
              estilo: Tipografia.textoFuerte.copyWith(fontSize: 17),
              tono: tono,
              conSigno: true,
            ),
    ],
  );
}
