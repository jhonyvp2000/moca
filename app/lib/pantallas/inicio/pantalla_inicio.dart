import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dominio/cuenta_real.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../textos/textos.dart';
import 'hoja_saldo.dart';
import 'pantalla_inicio_completa.dart';
import 'pantalla_primer_dia.dart';
import 'tarjeta_permiso_avisos.dart';

/// Inicio: S03 durante la primera semana, hasta el primer arqueo; después,
/// S04. La regla vive en la capa de datos.
class PantallaInicio extends ConsumerWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inicio = ref.watch(resumenInicioProvider).value;
    if (inicio == null) return const SizedBox.shrink();

    void anotarVenta() => context.push(Rutas.vozVenta);

    // Con varias personas en el negocio, cuándo bajó lo de los demás
    // (entrega 18).
    final cuenta = ref.watch(situacionCuentaProvider).value;
    final actualizado =
        cuenta != null &&
            cuenta.estado == EstadoCuenta.guardada &&
            cuenta.variasPersonas &&
            cuenta.actualizadoEn != null
        ? Textos.actualizadoHace(
            cuenta.actualizadoEn!,
            ref.read(relojProvider)(),
          )
        : null;

    if (!inicio.mostrarPrimerDia) {
      return PantallaInicioCompleta(
        resumen: inicio,
        actualizado: actualizado,
        alAnotarVenta: anotarVenta,
        alHacerArqueo: () => context.push(Rutas.arqueo),
        aviso: ref.watch(avisosProvider).value?.firstOrNull,
        tarjetaAvisos: const TarjetaPermisoAvisos(),
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
      alHacerArqueo: () => context.push(Rutas.arqueo),
      tarjetaAvisos: const TarjetaPermisoAvisos(),
    );
  }
}
