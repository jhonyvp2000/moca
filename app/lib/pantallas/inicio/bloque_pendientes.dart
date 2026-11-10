import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/tarjeta.dart';
import '../../comun/tarjeta_resumen.dart';
import '../../comun/tono.dart';
import '../../dominio/historial.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/medidas.dart';
import '../../textos/textos.dart';

/// Lo pendiente en el Inicio (mejora 01): «Te deben» en ámbar y «Debes» en
/// coral, con el total y los nombres. Lo ve quien ve los informes; sin nada
/// pendiente no aparece.
class BloquePendientes extends ConsumerWidget {
  const BloquePendientes({super.key, this.ocultar = false});

  final bool ocultar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teDeben = ref.watch(loQueTeDebenProvider).value ?? const [];
    final debes = ref.watch(loQueDebesProvider).value ?? const [];
    if (teDeben.isEmpty && debes.isEmpty) return const SizedBox.shrink();
    final tarjetas = [
      if (teDeben.isNotEmpty)
        _resumen(
          context,
          teDeben,
          Textos.teDebenCuantos,
          Tono.pendiente,
          Rutas.loQueTeDeben,
        ),
      if (debes.isNotEmpty)
        _resumen(
          context,
          debes,
          Textos.debesCuantos,
          Tono.egreso,
          Rutas.loQueDebes,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Medidas.margenLateral,
        Medidas.separacionTarjetas,
        Medidas.margenLateral,
        0,
      ),
      child: Tarjeta(
        relleno: const EdgeInsets.all(Medidas.e3),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, t) in tarjetas.indexed) ...[
                if (i > 0) const SizedBox(width: Medidas.e3),
                Expanded(child: t),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _resumen(
    BuildContext context,
    List<FilaHistorial> filas,
    String Function(int) etiqueta,
    Tono tono,
    String ruta,
  ) {
    // Una persona por nombre; lo que no tiene nombre no se nombra.
    final nombres = <String>[];
    for (final f in filas) {
      final n = f.proveedor?.trim();
      if (n != null && n.isNotEmpty && !nombres.contains(n)) nombres.add(n);
    }
    final sinNombre = filas.any((f) => (f.proveedor?.trim() ?? '').isEmpty);
    final personas = nombres.length + (sinNombre ? 1 : 0);
    final total = filas.fold(0, (s, f) => s + f.montoCentimos);
    return TarjetaResumen(
      etiqueta: etiqueta(personas),
      centimos: total,
      ocultar: ocultar,
      detalle: nombres.isEmpty ? null : Textos.nombresPendientes(nombres),
      tono: tono,
      alTocar: () => context.push(ruta),
    );
  }
}
