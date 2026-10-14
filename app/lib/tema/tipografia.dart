import 'package:flutter/painting.dart';

import 'colores.dart';

/// Tipografía de diseno/estilo.md: Plus Jakarta Sans, 14 px como mínimo en
/// todo texto (también en la barra inferior) y números tabulares en las cifras.
abstract final class Tipografia {
  static const familia = 'PlusJakartaSans';
  static const _numerosTabulares = [FontFeature.tabularFigures()];

  static const tituloPantalla = TextStyle(
    fontFamily: familia,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colores.textoPrincipal,
  );

  static const tituloTarjeta = TextStyle(
    fontFamily: familia,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colores.textoPrincipal,
  );

  static const texto = TextStyle(
    fontFamily: familia,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: Colores.textoPrincipal,
  );

  static const textoFuerte = TextStyle(
    fontFamily: familia,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: Colores.textoPrincipal,
  );

  static const secundario = TextStyle(
    fontFamily: familia,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: Colores.textoSecundario,
  );

  static const etiquetaMoca = TextStyle(
    fontFamily: familia,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colores.azulOscuro,
  );

  static const boton = TextStyle(
    fontFamily: familia,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const etiquetaBarra = TextStyle(
    fontFamily: familia,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Para montos: siempre con números tabulares.
  static TextStyle cifra(TextStyle base) =>
      base.copyWith(fontFeatures: _numerosTabulares);
}
