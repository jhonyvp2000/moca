import 'package:flutter/painting.dart';

import 'colores.dart';

/// Medidas del sistema de diseño, en píxeles lógicos: espaciado en
/// múltiplos de 4 y 8, radios de 12, 16, 20 y 24, y 48 dp como mínimo para
/// todo lo que se toca.
abstract final class Medidas {
  // --- Espaciado ----------------------------------------------------------------
  static const e1 = 4.0;
  static const e2 = 8.0;
  static const e3 = 12.0;
  static const e4 = 16.0;
  static const e5 = 20.0;
  static const e6 = 24.0;
  static const e8 = 32.0;

  // --- Radios -------------------------------------------------------------------
  static const radioChico = 12.0;
  static const radioMedio = 16.0;
  static const radioGrande = 20.0;
  static const radioMayor = 24.0;

  /// Para chips y etiquetas en forma de píldora.
  static const radioPildora = 999.0;

  // --- Nombres de uso -----------------------------------------------------------
  static const margenLateral = e5;
  static const separacionTarjetas = e3;
  static const rellenoTarjeta = e4;
  static const radioTarjeta = radioGrande;
  static const radioBoton = radioMedio;
  static const radioCampo = radioChico;
  static const altoBotonPrincipal = 52.0;
  static const altoBotonSecundario = 48.0;
  static const altoCampo = 48.0;
  static const objetivoTactilMinimo = 48.0;
  static const altoItemBarra = 56.0;
  static const botonCentral = 64.0;

  /// Lo que la barra inferior le quita al contenido, para que nada quede
  /// tapado.
  static const altoBarraInferior = 88.0;
}

/// Superficies con elevación: sombra azul suave en dos niveles, sin bordes
/// grises.
abstract final class Sombras {
  /// Tarjetas y filas: 0 1 2.
  static const nivel1 = [
    BoxShadow(color: Colores.sombra, offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Lo que destaca (la tarjeta azul, el botón +, las hojas): 0 1 2 y 0 4 14.
  static const nivel2 = [
    BoxShadow(color: Colores.sombra, offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Colores.sombra, offset: Offset(0, 4), blurRadius: 14),
  ];
}
