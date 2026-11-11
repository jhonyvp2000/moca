import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dominio/modelos.dart';
import '../pais/peru/formato.dart';
import 'iconos.dart';
import '../tema/colores.dart';
import '../tema/medidas.dart';
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
    this.cuenta,
  });

  /// La cuenta de este monto: su icono a la izquierda, como en el Inicio
  /// (mejora 01).
  final TipoCuenta? cuenta;

  final String etiqueta;
  final String? detalle;
  final TextEditingController controlador;
  final ValueChanged<String>? alCambiar;
  final bool autofocus;
  final TextInputAction accionTeclado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Medidas.e4,
        vertical: Medidas.e3,
      ),
      child: Row(
        children: [
          if (cuenta case final c?) ...[
            _IconoCuenta(c),
            const SizedBox(width: Medidas.e3),
          ],
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
          Text(
            'S/',
            style: Tipografia.texto.copyWith(color: Colores.textoSecundario),
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
              style: Tipografia.cifra(Tipografia.tituloTarjeta),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: Tipografia.cifra(Tipografia.secundario),
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
      // Como las tarjetas: sombra azul, sin borde gris (mejora 01).
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Medidas.radioGrande),
        boxShadow: Sombras.nivel1,
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

/// El icono de una cuenta en su cuadro de color (mejora 01).
class _IconoCuenta extends StatelessWidget {
  const _IconoCuenta(this.cuenta);

  final TipoCuenta cuenta;

  @override
  Widget build(BuildContext context) {
    final (color, fondo) = Iconos.coloresDeCuenta(cuenta);
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(Medidas.e2 + 2),
        ),
        child: Icon(Iconos.deCuenta(cuenta), size: 20, color: color),
      ),
    );
  }
}
