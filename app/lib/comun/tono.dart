import 'package:flutter/widgets.dart';

import '../tema/colores.dart';
import '../tema/tema.dart';

/// El significado de un color en Moca. El color nunca va solo: lo acompaña
/// un signo, una flecha o una palabra, para quien no distinga colores.
enum Tono {
  /// La marca: neutro con peso (selección, enlaces).
  marca,

  /// Entró plata.
  ingreso,

  /// Salió plata.
  egreso,

  /// Te deben, lo debes, la prueba gratis.
  pendiente,

  /// Cero, por subir.
  neutro;

  /// El color del texto o del icono.
  Color color(BuildContext context) {
    final c = ColoresMoca.de(context);
    return switch (this) {
      Tono.marca => Colores.marca,
      Tono.ingreso => c.ingreso,
      Tono.egreso => c.egreso,
      Tono.pendiente => c.pendienteTexto,
      Tono.neutro => c.neutro,
    };
  }

  /// El fondo suave para chips, etiquetas e iconos.
  Color fondo(BuildContext context) {
    final c = ColoresMoca.de(context);
    return switch (this) {
      Tono.marca => Colores.azul100,
      Tono.ingreso => c.ingresoFondo,
      Tono.egreso => c.egresoFondo,
      Tono.pendiente => c.pendienteFondo,
      Tono.neutro => c.neutroFondo,
    };
  }
}
