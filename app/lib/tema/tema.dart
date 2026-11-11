import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colores.dart';
import 'medidas.dart';
import 'tipografia.dart';

OutlineInputBorder _bordeCampo(Color color, double grosor) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(Medidas.radioCampo),
      borderSide: BorderSide(color: color, width: grosor),
    );

/// Los colores con significado, en el tema: así una pantalla los pide al
/// contexto y el modo oscuro solo tiene que dar otra instancia.
@immutable
class ColoresMoca extends ThemeExtension<ColoresMoca> {
  const ColoresMoca({
    required this.ingreso,
    required this.ingresoFondo,
    required this.egreso,
    required this.egresoFondo,
    required this.pendiente,
    required this.pendienteTexto,
    required this.pendienteFondo,
    required this.neutro,
    required this.neutroFondo,
  });

  /// Modo claro: el principal.
  static const claro = ColoresMoca(
    ingreso: Colores.ingreso,
    ingresoFondo: Colores.ingresoFondo,
    egreso: Colores.egreso,
    egresoFondo: Colores.egresoFondo,
    pendiente: Colores.pendiente,
    pendienteTexto: Colores.pendienteTexto,
    pendienteFondo: Colores.pendienteFondo,
    neutro: Colores.neutro,
    neutroFondo: Colores.neutroFondo,
  );

  final Color ingreso;
  final Color ingresoFondo;
  final Color egreso;
  final Color egresoFondo;
  final Color pendiente;
  final Color pendienteTexto;
  final Color pendienteFondo;
  final Color neutro;
  final Color neutroFondo;

  static ColoresMoca de(BuildContext context) =>
      Theme.of(context).extension<ColoresMoca>() ?? claro;

  @override
  ColoresMoca copyWith({
    Color? ingreso,
    Color? ingresoFondo,
    Color? egreso,
    Color? egresoFondo,
    Color? pendiente,
    Color? pendienteTexto,
    Color? pendienteFondo,
    Color? neutro,
    Color? neutroFondo,
  }) => ColoresMoca(
    ingreso: ingreso ?? this.ingreso,
    ingresoFondo: ingresoFondo ?? this.ingresoFondo,
    egreso: egreso ?? this.egreso,
    egresoFondo: egresoFondo ?? this.egresoFondo,
    pendiente: pendiente ?? this.pendiente,
    pendienteTexto: pendienteTexto ?? this.pendienteTexto,
    pendienteFondo: pendienteFondo ?? this.pendienteFondo,
    neutro: neutro ?? this.neutro,
    neutroFondo: neutroFondo ?? this.neutroFondo,
  );

  @override
  ColoresMoca lerp(ColoresMoca? otro, double t) {
    if (otro == null) return this;
    return ColoresMoca(
      ingreso: Color.lerp(ingreso, otro.ingreso, t)!,
      ingresoFondo: Color.lerp(ingresoFondo, otro.ingresoFondo, t)!,
      egreso: Color.lerp(egreso, otro.egreso, t)!,
      egresoFondo: Color.lerp(egresoFondo, otro.egresoFondo, t)!,
      pendiente: Color.lerp(pendiente, otro.pendiente, t)!,
      pendienteTexto: Color.lerp(pendienteTexto, otro.pendienteTexto, t)!,
      pendienteFondo: Color.lerp(pendienteFondo, otro.pendienteFondo, t)!,
      neutro: Color.lerp(neutro, otro.neutro, t)!,
      neutroFondo: Color.lerp(neutroFondo, otro.neutroFondo, t)!,
    );
  }
}

/// El único tema de la app. Las pantallas no definen colores ni tamaños sueltos.
ThemeData temaMoca() {
  const esquema = ColorScheme.light(
    primary: Colores.marca,
    onPrimary: Colores.sobreMarca,
    primaryContainer: Colores.azul100,
    onPrimaryContainer: Colores.azul900,
    secondary: Colores.azulOscuro,
    onSecondary: Colores.sobreMarca,
    secondaryContainer: Colores.azul100,
    onSecondaryContainer: Colores.azul900,
    surfaceContainerLowest: Colores.superficie,
    surfaceContainerLow: Colores.azul50,
    surfaceContainer: Colores.fondo,
    shadow: Colores.sombra,
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
    extensions: const [ColoresMoca.claro],
    // Transiciones suaves entre pantallas, iguales en todo Android.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
    fontFamily: Tipografia.familia,
    scaffoldBackgroundColor: Colores.fondo,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textTheme: const TextTheme(
      displayLarge: Tipografia.montoPrincipal,
      headlineSmall: Tipografia.tituloPantalla,
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
    // El secundario, como en el sistema de diseño: azul suave sin borde.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colores.azul100,
        foregroundColor: Colores.marca,
        minimumSize: const Size.fromHeight(Medidas.altoBotonSecundario),
        side: BorderSide.none,
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
      dragHandleColor: Colores.grisAzulado,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Medidas.radioMayor),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colores.superficie,
      selectedColor: Colores.azul100,
      side: const BorderSide(color: Colores.bordeTarjeta),
      labelStyle: Tipografia.textoFuerte,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioPildora),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      thumbColor: WidgetStateProperty.all(Colores.superficie),
      trackColor: WidgetStateProperty.resolveWith(
        (estado) => estado.contains(WidgetState.selected)
            ? Colores.marca
            : Colores.grisAzulado,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colores.marca,
      linearTrackColor: Colores.azul100,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colores.azulOscuro,
      contentTextStyle: Tipografia.texto.copyWith(color: Colores.sobreMarca),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioBoton),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colores.superficie,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: Tipografia.secundario,
      border: _bordeCampo(Colores.bordeCampo, 1),
      enabledBorder: _bordeCampo(Colores.bordeCampo, 1),
      focusedBorder: _bordeCampo(Colores.marca, 2),
      errorBorder: _bordeCampo(Colores.avisoMarca, 1),
      focusedErrorBorder: _bordeCampo(Colores.avisoMarca, 2),
    ),
    timePickerTheme: const TimePickerThemeData(
      backgroundColor: Colores.superficie,
    ),
    dividerTheme: const DividerThemeData(
      color: Colores.separador,
      thickness: 1,
      space: 1,
    ),
  );
}
