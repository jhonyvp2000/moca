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

/// «Tus cuentas»: una fila por cuenta, con su icono, el nombre y el saldo a
/// la derecha, una debajo de otra (entrega 60; antes eran tarjetas que se
/// deslizaban de lado). Igual en el Inicio y en el de la primera semana.
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Medidas.margenLateral),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SeccionTitulo(
            Textos.tusCuentas,
            accion: conVerTodas ? Textos.verTodas : null,
            alTocar: () => context.push(Rutas.cuentas),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colores.superficie,
              borderRadius: BorderRadius.circular(Medidas.radioGrande),
              boxShadow: Sombras.nivel1,
            ),
            child: Column(
              children: [
                for (final (i, cuenta) in cuentas.indexed)
                  _FilaCuenta(
                    cuenta: cuenta,
                    centimos: saldos[cuenta] ?? 0,
                    ocultar: ocultar,
                    conSeparador: i < cuentas.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCuenta extends StatelessWidget {
  const _FilaCuenta({
    required this.cuenta,
    required this.centimos,
    required this.ocultar,
    required this.conSeparador,
  });

  final TipoCuenta cuenta;
  final int centimos;
  final bool ocultar;
  final bool conSeparador;

  @override
  Widget build(BuildContext context) {
    final (color, fondo) = Iconos.coloresDeCuenta(cuenta);
    return Container(
      constraints: const BoxConstraints(
        minHeight: Medidas.objetivoTactilMinimo,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Medidas.e4,
        vertical: Medidas.e3,
      ),
      decoration: conSeparador
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colores.separador)),
            )
          : null,
      child: Row(
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
          const SizedBox(width: Medidas.e3),
          Expanded(
            child: Text(
              Textos.nombreCuenta(cuenta),
              style: Tipografia.textoFuerte,
            ),
          ),
          const SizedBox(width: Medidas.e2),
          ocultar
              ? const Text(Textos.montoOculto, style: Tipografia.tituloTarjeta)
              : MontoText(centimos, estilo: Tipografia.tituloTarjeta),
        ],
      ),
    );
  }
}
