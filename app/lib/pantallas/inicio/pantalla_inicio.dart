import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import 'hoja_saldo.dart';
import 'pantalla_inicio_completa.dart';
import 'pantalla_primer_dia.dart';

/// Inicio: S03 durante la primera semana, hasta el primer arqueo; después,
/// S04. La regla vive en la capa de datos.
class PantallaInicio extends ConsumerWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inicio = ref.watch(resumenInicioProvider).value;
    if (inicio == null) return const SizedBox.shrink();

    void anotarVenta() => context.push(Rutas.ventaDelDia);

    if (!inicio.mostrarPrimerDia) {
      return PantallaInicioCompleta(
        resumen: inicio,
        alAnotarVenta: anotarVenta,
      );
    }

    final primerDia = ref.watch(resumenPrimerDiaProvider).value;
    if (primerDia == null) return const SizedBox.shrink();
    return PantallaPrimerDia(
      resumen: primerDia,
      alAnotarVenta: anotarVenta,
      alAnotarGasto: () => context.push(
        Uri(
          path: Rutas.escribir,
          queryParameters: {'tipo': TipoMovimiento.egreso.name},
        ).toString(),
      ),
      alDeclararSaldo: () => mostrarHojaSaldo(context),
    );
  }
}
