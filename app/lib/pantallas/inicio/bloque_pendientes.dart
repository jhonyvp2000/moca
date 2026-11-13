import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/monto_text.dart';
import '../../comun/tono.dart';
import '../../dominio/historial.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// Lo pendiente en dos fichas (entrega 59): «Te deben S/ 30 ›» en ámbar y
/// «Debes S/ 742 ›» en coral; cada una abre su lista. La que está en cero
/// no aparece; sin nada pendiente, nada. En el Inicio y en los Informes.
class BloquePendientes extends ConsumerWidget {
  const BloquePendientes({
    super.key,
    this.ocultar = false,
    this.margen = const EdgeInsets.fromLTRB(
      Medidas.margenLateral,
      Medidas.separacionTarjetas,
      Medidas.margenLateral,
      0,
    ),
  });

  final bool ocultar;
  final EdgeInsets margen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int total(List<FilaHistorial> filas) =>
        filas.fold(0, (s, f) => s + f.montoCentimos);
    final teDeben = total(ref.watch(loQueTeDebenProvider).value ?? const []);
    final debes = total(ref.watch(loQueDebesProvider).value ?? const []);
    if (teDeben == 0 && debes == 0) return const SizedBox.shrink();
    final fichas = [
      if (teDeben > 0)
        _Ficha(
          etiqueta: Textos.fichaTeDeben,
          centimos: teDeben,
          tono: Tono.pendiente,
          ocultar: ocultar,
          alTocar: () => context.push(Rutas.loQueTeDeben),
        ),
      if (debes > 0)
        _Ficha(
          etiqueta: Textos.fichaDebes,
          centimos: debes,
          tono: Tono.egreso,
          ocultar: ocultar,
          alTocar: () => context.push(Rutas.loQueDebes),
        ),
    ];
    return Padding(
      padding: margen,
      child: Row(
        children: [
          for (final (i, f) in fichas.indexed) ...[
            if (i > 0) const SizedBox(width: Medidas.e3),
            Expanded(child: f),
          ],
          // Una sola ficha no ocupa todo el ancho.
          if (fichas.length == 1) ...[
            const SizedBox(width: Medidas.e3),
            const Expanded(child: SizedBox.shrink()),
          ],
        ],
      ),
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({
    required this.etiqueta,
    required this.centimos,
    required this.tono,
    required this.ocultar,
    required this.alTocar,
  });

  final String etiqueta;
  final int centimos;
  final Tono tono;
  final bool ocultar;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final color = tono.color(context);
    return Material(
      color: tono.fondo(context),
      borderRadius: BorderRadius.circular(Medidas.radioMedio),
      child: InkWell(
        borderRadius: BorderRadius.circular(Medidas.radioMedio),
        onTap: alTocar,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: Medidas.altoBotonPrincipal,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Medidas.e4,
              vertical: Medidas.e3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: Tipografia.apoyo.copyWith(color: color)),
                Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: ocultar
                            ? Text(
                                Textos.montoOculto,
                                style: Tipografia.montoMediano.copyWith(
                                  color: color,
                                ),
                              )
                            : MontoText(
                                centimos,
                                estilo: Tipografia.montoMediano,
                                tono: tono,
                              ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
