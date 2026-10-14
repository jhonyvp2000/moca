import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/tarjeta.dart';
import '../../dominio/cuenta_real.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// Pestaña Moca: pide guardar el avance a los tres días de «Ahora no», o
/// confirmar el número a quien pasó por el código de prueba del prototipo
/// (estados de la entrega 11, aprobados el 14-10-2026). Desde la entrega
/// 12, avisa si la cuenta se abrió en otro teléfono.
class TarjetaGuardarAvance extends ConsumerWidget {
  const TarjetaGuardarAvance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final situacion = ref.watch(situacionCuentaProvider).value;
    if (situacion == null || !situacion.mostrarTarjeta) {
      return const SizedBox.shrink();
    }
    if (situacion.estado == EstadoCuenta.cerradaEnOtro) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 18),
        child: Tarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(Textos.cuentaAbiertaEnOtro, style: Tipografia.tituloTarjeta),
              SizedBox(height: 4),
              Text(
                Textos.cuentaAbiertaEnOtroDetalle,
                style: Tipografia.secundario,
              ),
            ],
          ),
        ),
      );
    }
    final confirmar = situacion.estado == EstadoCuenta.porConfirmar;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              confirmar ? Textos.confirmaTuNumero : Textos.guardaTuAvance,
              style: Tipografia.tituloTarjeta,
            ),
            const SizedBox(height: 4),
            Text(
              confirmar
                  ? Textos.confirmaTuNumeroDetalle
                  : Textos.guardaTuAvanceDetalle,
              style: Tipografia.secundario,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  context.push(Rutas.cuenta, extra: situacion.celular),
              child: Text(
                confirmar ? Textos.confirmarMiNumero : Textos.guardarMiAvance,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
