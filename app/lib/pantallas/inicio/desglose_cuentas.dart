import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../comun/iconos.dart';
import '../../comun/monto_text.dart';
import '../../comun/seccion_titulo.dart';
import '../../dominio/modelos.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Tus cuentas» (mejora 01): una tarjeta por cuenta, con su icono, que se
/// desliza de lado. Igual en el Inicio y en el de la primera semana.
class DesgloseDeCuentas extends StatelessWidget {
  const DesgloseDeCuentas({
    super.key,
    required this.saldos,
    this.ocultar = false,
    this.conVerTodas = false,
  });

  final Map<TipoCuenta, int> saldos;

  /// En el Inicio se pueden ocultar los montos.
  final bool ocultar;

  /// «Ver todas» lleva a Mis cuentas: solo para quien las cambia.
  final bool conVerTodas;

  @override
  Widget build(BuildContext context) {
    final cuentas = saldos.isEmpty ? TipoCuenta.basicas : saldos.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Medidas.margenLateral,
          ),
          child: SeccionTitulo(
            Textos.tusCuentas,
            accion: conVerTodas ? Textos.verTodas : null,
            alTocar: () => context.push(Rutas.cuentas),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            Medidas.margenLateral,
            0,
            Medidas.margenLateral,
            Medidas.e2,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, cuenta) in cuentas.indexed) ...[
                  if (i > 0) const SizedBox(width: Medidas.e3),
                  _TarjetaCuenta(
                    cuenta: cuenta,
                    centimos: saldos[cuenta] ?? 0,
                    ocultar: ocultar,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaCuenta extends StatelessWidget {
  const _TarjetaCuenta({
    required this.cuenta,
    required this.centimos,
    required this.ocultar,
  });

  final TipoCuenta cuenta;
  final int centimos;
  final bool ocultar;

  @override
  Widget build(BuildContext context) {
    final (color, fondo) = Iconos.coloresDeCuenta(cuenta);
    return Container(
      width: 148,
      padding: const EdgeInsets.all(Medidas.e4),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Medidas.radioGrande),
        boxShadow: Sombras.nivel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(Medidas.radioChico),
            ),
            child: Icon(Iconos.deCuenta(cuenta), size: 22, color: color),
          ),
          const SizedBox(height: Medidas.e3),
          Text(
            Textos.nombreCuenta(cuenta),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Tipografia.secundario,
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ocultar
                ? const Text(Textos.montoOculto, style: Tipografia.montoTarjeta)
                : MontoText(centimos, estilo: Tipografia.montoMediano),
          ),
        ],
      ),
    );
  }
}
