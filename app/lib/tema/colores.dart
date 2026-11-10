import 'package:flutter/painting.dart';

/// Colores del sistema de diseño (diseno/estilo.md y
/// docs/mejora-01/moca-08-sistema-de-diseno.png). Las pantallas usan solo
/// estos. Azul de marca; ámbar para avisos y para lo pendiente; rojo coral
/// para las salidas (el monto y fondos suaves, siempre con su signo o
/// flecha); sin verde y sin negro (decisiones.md, 10-11-2026).
abstract final class Colores {
  // --- Escala azul de marca ----------------------------------------------------
  static const azul50 = Color(0xFFEEF3FF);
  static const azul100 = Color(0xFFE3EDFF);
  static const azul400 = Color(0xFF3B6BEB);
  static const marca = Color(0xFF1D4ED8);
  static const azul900 = Color(0xFF1E3A8A);

  // --- Texto y superficies -----------------------------------------------------
  static const textoPrincipal = Color(0xFF13213F);
  static const textoSecundario = Color(0xFF52607A);
  static const fondo = Color(0xFFF4F7FC);
  static const superficie = Color(0xFFFFFFFF);
  static const sobreMarca = Color(0xFFFFFFFF);

  /// Texto secundario sobre fondo azul (S00 y «Tienes hoy»).
  static const sobreMarcaSuave = Color(0xFFDCE7FB);

  // --- Semánticos: cada uno con su fondo suave para chips y etiquetas ----------
  /// Lo que entró: con «+» y flecha, nunca solo el color.
  static const ingreso = marca;
  static const ingresoFondo = azul100;

  /// Lo que salió: con «–» y flecha, nunca solo el color.
  static const egreso = Color(0xFFC42B3C);
  static const egresoFondo = Color(0xFFFDE8EB);

  /// Lo pendiente («Te debe», «Lo debes», la prueba gratis). El tono fuerte
  /// solo en barras y puntos: como texto no alcanza el contraste.
  static const pendiente = Color(0xFFD97706);
  static const pendienteTexto = Color(0xFF8A4500);
  static const pendienteFondo = Color(0xFFFFF1D6);

  /// Cero y lo que todavía no sube («Por subir»).
  static const neutro = Color(0xFF5F6B84);
  static const neutroFondo = Color(0xFFF4F6FA);

  // --- Identidad de cuentas (solo en su icono) ---------------------------------
  static const yape = Color(0xFF6D28D9);
  static const yapeFondo = Color(0xFFF1EAFE);
  static const plin = Color(0xFF0E7490);
  static const plinFondo = Color(0xFFE0F5FA);

  // --- Bordes y separadores (campos y chips; las tarjetas van con sombra) ------
  static const bordeTarjeta = Color(0xFFDDE5F0);
  static const bordeBotonSecundario = Color(0xFFB5C2D6);
  static const bordeCampo = Color(0xFF8696B0);
  static const separador = Color(0xFFE4EAF3);

  /// Sombra azul al 6 %, en lugar de bordes grises.
  static const sombra = Color(0x0F1E3A8A);

  // --- Nombres de antes (siguen en uso) ----------------------------------------
  static const azulOscuro = azul900;
  static const tinteAzul = azul100;
  static const avisoMarca = Color(0xFF9A4A06);
  static const avisoTexto = pendienteTexto;
  static const avisoTextoFuerte = Color(0xFF5C2C04);
  static const avisoFondo = pendienteFondo;

  /// El monto de una salida.
  static const salida = egreso;

  /// Barra de «qué tan seguras son estas cuentas» (S14): foto y sin papel.
  static const azulMedio = Color(0xFF7FA3E8);
  static const grisAzulado = Color(0xFFC5D0E0);
}
