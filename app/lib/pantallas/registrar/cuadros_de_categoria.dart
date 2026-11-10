import 'package:flutter/material.dart';

import '../../comun/tono.dart';
import '../../dominio/movimientos.dart';
import '../../pais/peru/categorias.dart';
import '../../pais/peru/iconos_categorias.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// Las categorías de «Escribirlo» en cuadros con icono y nombre corto
/// (mejora 01). Se ven las primeras, «Otros» y la elegida; el resto, con
/// «Ver más».
class CuadrosDeCategoria extends StatefulWidget {
  const CuadrosDeCategoria({
    super.key,
    required this.categorias,
    required this.elegida,
    required this.alElegir,
    required this.tono,
  });

  final List<CategoriaVista> categorias;
  final String? elegida;
  final ValueChanged<String> alElegir;
  final Tono tono;

  @override
  State<CuadrosDeCategoria> createState() => _EstadoCuadros();
}

class _EstadoCuadros extends State<CuadrosDeCategoria> {
  static const _primeras = 5;
  bool _todas = false;

  @override
  Widget build(BuildContext context) {
    // Primero lo que el negocio compra para vender (mercadería, insumos):
    // es lo que más se anota.
    final todas = [
      ...widget.categorias.where(
        (c) => categoriasDeMercaderia.contains(c.nombre),
      ),
      ...widget.categorias.where(
        (c) => !categoriasDeMercaderia.contains(c.nombre),
      ),
    ];
    final visibles = _todas || todas.length <= _primeras + 1
        ? todas
        : [
            for (final (i, c) in todas.indexed)
              if (i < _primeras ||
                  c.nombre == 'Otros' ||
                  c.id == widget.elegida)
                c,
          ];
    final hayMas = visibles.length < todas.length;
    return LayoutBuilder(
      builder: (context, espacio) {
        final columnas = espacio.maxWidth >= 340 ? 4 : 3;
        final ancho =
            (espacio.maxWidth - Medidas.e2 * (columnas - 1)) / columnas;
        return Wrap(
          spacing: Medidas.e2,
          runSpacing: Medidas.e2,
          children: [
            for (final c in visibles)
              SizedBox(
                width: ancho,
                child: _Cuadro(
                  icono: iconoDeCategoria(c.nombre),
                  texto: nombreCortoDeCategoria(c.nombre),
                  elegido: c.id == widget.elegida,
                  tono: widget.tono,
                  alTocar: () => widget.alElegir(c.id),
                ),
              ),
            if (hayMas)
              SizedBox(
                width: ancho,
                child: _Cuadro(
                  icono: Icons.add_rounded,
                  texto: Textos.verMas,
                  elegido: false,
                  tono: Tono.marca,
                  punteado: true,
                  alTocar: () => setState(() => _todas = true),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Cuadro extends StatelessWidget {
  const _Cuadro({
    required this.icono,
    required this.texto,
    required this.elegido,
    required this.tono,
    required this.alTocar,
    this.punteado = false,
  });

  final IconData icono;
  final String texto;
  final bool elegido;
  final Tono tono;
  final VoidCallback alTocar;
  final bool punteado;

  @override
  Widget build(BuildContext context) {
    final color = tono.color(context);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medidas.radioMedio),
      side: BorderSide(
        color: elegido
            ? color
            : punteado
            ? Colores.azulMedio
            : Colores.bordeTarjeta,
        width: elegido ? 2 : 1,
      ),
    );
    return Semantics(
      button: true,
      selected: elegido,
      child: Material(
        color: elegido ? tono.fondo(context) : Colores.superficie,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Medidas.e1,
                vertical: Medidas.e3,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icono,
                    size: 26,
                    color: elegido || punteado ? color : Colores.textoPrincipal,
                  ),
                  const SizedBox(height: Medidas.e1),
                  Text(
                    texto,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Tipografia.apoyo.copyWith(
                      color: elegido || punteado
                          ? color
                          : Colores.textoPrincipal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
