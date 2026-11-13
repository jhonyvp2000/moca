import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import 'tarjeta.dart';

/// Una opción de Ajustes (mejora 01): el icono en su cuadro azul suave, el
/// título, una línea y, a la derecha, la flecha o lo que haga falta (un
/// interruptor).
class FilaAjuste extends StatelessWidget {
  const FilaAjuste({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.alTocar,
    this.derecha,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback? alTocar;

  /// Nulo: la flecha.
  final Widget? derecha;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Medidas.e4,
            vertical: Medidas.e3,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colores.azul100,
                  borderRadius: BorderRadius.circular(Medidas.radioChico),
                ),
                child: Icon(icono, size: 22, color: Colores.marca),
              ),
              const SizedBox(width: Medidas.e3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: Tipografia.tituloFila),
                    Text(detalle, style: Tipografia.secundario),
                  ],
                ),
              ),
              derecha ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colores.textoSecundario,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una opción de Ajustes que lleva a otra pantalla.
class TarjetaEnlace extends StatelessWidget {
  const TarjetaEnlace({
    super.key,
    required this.titulo,
    required this.detalle,
    required this.ruta,
    this.icono = Icons.tune_rounded,
  });

  final String titulo;
  final String detalle;
  final String ruta;
  final IconData icono;

  @override
  Widget build(BuildContext context) => FilaAjuste(
    icono: icono,
    titulo: titulo,
    detalle: detalle,
    alTocar: () => context.push(ruta),
  );
}

/// Las opciones de una sección de Ajustes en una sola tarjeta, separadas
/// por líneas (mejora 01), con el título de la sección en mayúsculas.
class GrupoDeAjustes extends StatelessWidget {
  const GrupoDeAjustes({super.key, required this.titulo, required this.filas});

  final String titulo;
  final List<Widget> filas;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Medidas.e5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Medidas.e1, bottom: Medidas.e2),
          child: Semantics(
            header: true,
            child: Text(
              titulo.toUpperCase(),
              style: Tipografia.apoyo.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        Tarjeta(
          relleno: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
            child: Material(
              color: Colores.superficie,
              child: Column(
                children: [
                  for (final (i, f) in filas.indexed) ...[
                    if (i > 0) const Divider(indent: 72, height: 1),
                    f,
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
