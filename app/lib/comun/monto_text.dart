import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../pais/peru/formato.dart';
import '../tema/tipografia.dart';
import 'tono.dart';

/// Un monto con el «S/» más pequeño y liviano que la cifra, cifras
/// tabulares y, si se pide, signo y color con significado: «+ S/ 80»,
/// «− S/ 100». El cero va siempre en gris neutro, nunca en rojo.
class MontoText extends StatelessWidget {
  const MontoText(
    this.centimos, {
    super.key,
    this.estilo = Tipografia.montoTarjeta,
    this.tono,
    this.conSigno = false,
    this.conCentimos = false,
    this.color,
    this.escalaSimbolo = 0.45,
  });

  final int centimos;
  final TextStyle estilo;

  /// Ingreso o egreso le dan color (y signo, con [conSigno]); nulo, el color
  /// del estilo.
  final Tono? tono;
  final bool conSigno;

  /// Cada registro lleva sus céntimos; saldos, totales e informes no.
  final bool conCentimos;

  /// Para montos sobre la tarjeta azul.
  final Color? color;

  /// El tamaño del «S/» respecto de la cifra.
  final double escalaSimbolo;

  @override
  Widget build(BuildContext context) {
    final texto = conCentimos
        ? formatearSolesComprobante(centimos.abs())
        : formatearSoles(centimos.abs());
    // «S/ 1,250» → «S/» y «1,250», con el espacio fijo en medio.
    final corte = texto.indexOf('/') + 1;
    final simbolo = texto.substring(0, corte);
    final cifra = texto.substring(corte);
    final esCero = conCentimos ? centimos == 0 : (centimos / 100).round() == 0;
    final tonoFinal = esCero ? Tono.neutro : tono;
    final colorFinal =
        color ??
        (tonoFinal == null || tonoFinal == Tono.marca
            ? estilo.color
            : tonoFinal.color(context));
    final base = Tipografia.cifra(estilo).copyWith(color: colorFinal);
    final signo = !conSigno || esCero
        ? ''
        : switch (tono) {
            // Como en el Historial: «+ S/ 80», «− S/ 100» (mejora 01).
            Tono.ingreso => '+\u00A0',
            Tono.egreso => '−\u00A0',
            _ => centimos < 0 ? '−\u00A0' : '',
          };
    final tamano = base.fontSize ?? 15;
    return Text.rich(
      TextSpan(
        children: [
          if (signo.isNotEmpty) TextSpan(text: signo),
          TextSpan(
            text: simbolo,
            style: base.copyWith(
              // Nunca menos de 14 px ni más grande que la cifra.
              fontSize: math.min(tamano, math.max(14, tamano * escalaSimbolo)),
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: cifra),
        ],
      ),
      style: base,
      maxLines: 1,
      softWrap: false,
    );
  }
}

/// Un monto que cambia con una animación corta, contando desde el valor
/// anterior (el «Tienes hoy», por ejemplo).
class MontoAnimado extends StatelessWidget {
  const MontoAnimado(
    this.centimos, {
    super.key,
    this.estilo = Tipografia.montoPrincipal,
    this.color,
  });

  final int centimos;
  final TextStyle estilo;
  final Color? color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: centimos.toDouble()),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
    builder: (context, valor, _) =>
        MontoText(valor.round(), estilo: estilo, color: color),
  );
}
