import 'package:flutter/painting.dart';

import 'colores.dart';

/// Tipografía del sistema de diseño: Plus Jakarta Sans, 14 px como mínimo en
/// todo texto y cifras tabulares en todos los montos.
abstract final class Tipografia {
  static const familia = 'PlusJakartaSans';
  static const _numerosTabulares = [FontFeature.tabularFigures()];

  /// El monto principal («Tienes hoy»): 52/800. El «S/» va aparte, al 45 % y
  /// más liviano (ver MontoText).
  static const montoPrincipal = TextStyle(
    fontFamily: familia,
    fontSize: 52,
    height: 1.1,
    fontWeight: FontWeight.w800,
    color: Colores.textoPrincipal,
    fontFeatures: _numerosTabulares,
  );

  /// Montos destacados de una tarjeta (cuentas, pendientes): 24/800.
  static const montoTarjeta = TextStyle(
    fontFamily: familia,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: Colores.textoPrincipal,
    fontFeatures: _numerosTabulares,
  );

  /// Título de pantalla: 26/800.
  static const tituloPantalla = TextStyle(
    fontFamily: familia,
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: Colores.textoPrincipal,
  );

  /// Título de sección: 16/800.
  static const tituloSeccion = TextStyle(
    fontFamily: familia,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w800,
    color: Colores.textoPrincipal,
  );

  /// Los tamaños intermedios con nombre (mejora 01): ninguna pantalla los
  /// escribe a mano.
  static final montoGrande = montoPrincipal.copyWith(fontSize: 44);
  static final montoMediano = montoTarjeta.copyWith(fontSize: 20);
  static final encabezado = tituloPantalla.copyWith(fontSize: 24);
  static final tituloDestacado = tituloSeccion.copyWith(fontSize: 19);
  static final tituloFila = tituloSeccion.copyWith(fontSize: 17);

  static const tituloTarjeta = TextStyle(
    fontFamily: familia,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: Colores.textoPrincipal,
  );

  /// Texto normal para leer con calma: 15/500, interlineado 1.4.
  static const texto = TextStyle(
    fontFamily: familia,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: Colores.textoPrincipal,
  );

  static const textoFuerte = TextStyle(
    fontFamily: familia,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: Colores.textoPrincipal,
  );

  static const secundario = TextStyle(
    fontFamily: familia,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: Colores.textoSecundario,
  );

  /// Texto de apoyo y etiquetas: 14/600 (el mínimo de la app es 14 px).
  static const apoyo = TextStyle(
    fontFamily: familia,
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
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
