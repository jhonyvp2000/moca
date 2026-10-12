import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import 'icono_trazo.dart';

/// Pantalla con contenido que se desplaza y botones fijos abajo. Con el
/// teclado abierto, los botones quedan justo encima del teclado.
class PantallaConAcciones extends StatelessWidget {
  const PantallaConAcciones({
    super.key,
    required this.contenido,
    required this.acciones,
    this.encabezado,
    this.rellenoSuperior = 4,
  });

  final Widget? encabezado;
  final List<Widget> contenido;
  final List<Widget> acciones;
  final double rellenoSuperior;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ?encabezado,
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  Medidas.margenLateral,
                  rellenoSuperior,
                  Medidas.margenLateral,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: contenido,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                12,
                Medidas.margenLateral,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, accion) in acciones.indexed) ...[
                    if (i > 0) const SizedBox(height: 8),
                    accion,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de S02 y S07: botón «volver» cuadrado y título.
class EncabezadoConVolver extends StatelessWidget {
  const EncabezadoConVolver({super.key, required this.titulo, this.alVolver});

  final String titulo;

  /// Nulo: sin botón «volver».
  final VoidCallback? alVolver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Medidas.margenLateral, 16, 20, 12),
      child: Row(
        children: [
          if (alVolver != null) ...[
            BotonVolver(alTocar: alVolver!),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              titulo,
              style: Tipografia.tituloTarjeta.copyWith(fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}

class BotonVolver extends StatelessWidget {
  const BotonVolver({super.key, required this.alTocar});

  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: Material(
        color: Colores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Medidas.radioBoton),
          side: const BorderSide(color: Colores.bordeTarjeta),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Medidas.radioBoton),
          ),
          onTap: alTocar,
          child: const SizedBox.square(
            dimension: Medidas.objetivoTactilMinimo,
            child: Center(
              child: IconoTrazo(Icono.volver, color: Colores.textoPrincipal),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso en ámbar (diseno/estilo.md: el ámbar es solo para avisos).
class Aviso extends StatelessWidget {
  const Aviso({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colores.avisoFondo,
        borderRadius: BorderRadius.circular(Medidas.radioBoton),
        border: const Border(
          left: BorderSide(color: Colores.avisoMarca, width: 4),
        ),
      ),
      child: Text(
        texto,
        style: Tipografia.secundario.copyWith(color: Colores.avisoTexto),
      ),
    );
  }
}

/// Error de un campo, en ámbar.
class TextoError extends StatelessWidget {
  const TextoError(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        texto,
        style: Tipografia.secundario.copyWith(
          color: Colores.avisoTexto,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Botón de texto secundario de los mockups («Ahora no, seguir probando»).
class BotonTexto extends StatelessWidget {
  const BotonTexto({super.key, required this.texto, required this.alTocar});

  final String texto;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: alTocar,
      style: TextButton.styleFrom(
        foregroundColor: Colores.textoPrincipal,
        minimumSize: const Size.fromHeight(Medidas.altoBotonSecundario),
        textStyle: Tipografia.textoFuerte,
      ),
      child: Text(texto, textAlign: TextAlign.center),
    );
  }
}
