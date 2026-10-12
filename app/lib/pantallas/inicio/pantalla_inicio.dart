import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inyeccion.dart';
import '../registrar/hoja_registrar.dart';
import 'hoja_saldo.dart';
import 'pantalla_primer_dia.dart';

/// Inicio. Durante la primera semana, hasta el primer arqueo, es S03; S04
/// llega en la entrega 3.
class PantallaInicio extends ConsumerWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen = ref.watch(resumenPrimerDiaProvider).value;
    if (resumen == null) return const SizedBox.shrink();

    return PantallaPrimerDia(
      resumen: resumen,
      // Anotar ventas y gastos desde aquí llega con Registrar (entrega 3).
      alAnotarVenta: () => mostrarHojaRegistrar(context),
      alAnotarGasto: () => mostrarHojaRegistrar(context),
      alDeclararSaldo: () => mostrarHojaSaldo(context),
    );
  }
}
