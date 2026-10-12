import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colores.dart';
import 'medidas.dart';
import 'tipografia.dart';

/// El único tema de la app. Las pantallas no definen colores ni tamaños sueltos.
ThemeData temaMoca() {
  const esquema = ColorScheme.light(
    primary: Colores.marca,
    onPrimary: Colores.sobreMarca,
    secondary: Colores.azulOscuro,
    onSecondary: Colores.sobreMarca,
    surface: Colores.superficie,
    onSurface: Colores.textoPrincipal,
    onSurfaceVariant: Colores.textoSecundario,
    outline: Colores.bordeTarjeta,
    outlineVariant: Colores.separador,
    // Sin rojo ni negro: los errores usan el ámbar de los avisos.
    error: Colores.avisoMarca,
    onError: Colores.sobreMarca,
  );

  final formaBoton = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Medidas.radioBoton),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    fontFamily: Tipografia.familia,
    scaffoldBackgroundColor: Colores.fondo,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textTheme: const TextTheme(
      titleLarge: Tipografia.tituloPantalla,
      titleMedium: Tipografia.tituloTarjeta,
      bodyLarge: Tipografia.texto,
      bodyMedium: Tipografia.texto,
      bodySmall: Tipografia.secundario,
      labelLarge: Tipografia.boton,
      labelMedium: Tipografia.etiquetaBarra,
      labelSmall: Tipografia.secundario,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colores.fondo,
      foregroundColor: Colores.textoPrincipal,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: Tipografia.tituloPantalla,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colores.fondo,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colores.superficie,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colores.marca,
        foregroundColor: Colores.sobreMarca,
        minimumSize: const Size.fromHeight(Medidas.altoBotonPrincipal),
        shape: formaBoton,
        textStyle: Tipografia.boton,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colores.superficie,
        foregroundColor: Colores.textoPrincipal,
        minimumSize: const Size.fromHeight(Medidas.altoBotonSecundario),
        side: const BorderSide(color: Colores.bordeBotonSecundario),
        shape: formaBoton,
        textStyle: Tipografia.boton,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colores.marca,
        minimumSize: const Size(
          Medidas.objetivoTactilMinimo,
          Medidas.objetivoTactilMinimo,
        ),
        textStyle: Tipografia.boton,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colores.superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      ),
      titleTextStyle: Tipografia.tituloTarjeta.copyWith(fontSize: 18),
      contentTextStyle: Tipografia.texto,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colores.superficie,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Colores.bordeBotonSecundario,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Medidas.radioTarjeta),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colores.azulOscuro,
      contentTextStyle: Tipografia.texto.copyWith(color: Colores.sobreMarca),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioBoton),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Colores.separador,
      thickness: 1,
      space: 1,
    ),
  );
}
