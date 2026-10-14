import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pais/peru/formato.dart';
import '../tema/colores.dart';
import '../tema/tipografia.dart';

/// Soles enteros con separador de miles mientras se escribe («1,200»).
/// Hasta 7 cifras: S/ 9,999,999.
class FormateadorSoles extends TextInputFormatter {
  static const maximoCifras = 7;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    var digitos = nuevo.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.length > maximoCifras) {
      return anterior;
    }
    digitos = digitos.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final texto = digitos.isEmpty ? '' : separarMiles(int.parse(digitos));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Fila de monto de S02: etiqueta a la izquierda, «S/» y el campo alineado a
/// la derecha con números tabulares.
class FilaMonto extends StatelessWidget {
  const FilaMonto({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.detalle,
    this.alCambiar,
    this.autofocus = false,
    this.accionTeclado = TextInputAction.next,
  });

  final String etiqueta;
  final String? detalle;
  final TextEditingController controlador;
  final ValueChanged<String>? alCambiar;
  final bool autofocus;
  final TextInputAction accionTeclado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: Tipografia.textoFuerte),
                if (detalle != null)
                  Text(detalle!, style: Tipografia.secundario),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'S/',
            style: TextStyle(
              fontFamily: Tipografia.familia,
              fontSize: 15,
              color: Colores.textoSecundario,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controlador,
              autofocus: autofocus,
              onChanged: alCambiar,
              keyboardType: TextInputType.number,
              textInputAction: accionTeclado,
              inputFormatters: [FormateadorSoles()],
              textAlign: TextAlign.right,
              style: Tipografia.cifra(
                Tipografia.textoFuerte.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: Tipografia.cifra(
                  Tipografia.secundario.copyWith(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Varios montos dentro de una tarjeta, separados por líneas (S02).
class GrupoMontos extends StatelessWidget {
  const GrupoMontos({super.key, required this.filas});

  final List<Widget> filas;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colores.bordeTarjeta),
      ),
      child: Column(
        children: [
          for (final (i, fila) in filas.indexed) ...[
            if (i > 0) const Divider(),
            fila,
          ],
        ],
      ),
    );
  }
}
