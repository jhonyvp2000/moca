import 'package:flutter/material.dart';

import '../../dominio/historial.dart';
import '../../dominio/modelos.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «+ S/ 350» para lo que entró, «− S/ 980» para lo que salió. Los signos y el
/// símbolo no se separan de la cifra.
String montoConSigno(TipoMovimiento tipo, int centimos) =>
    '${tipo == TipoMovimiento.ingreso ? '+' : '−'} '
    '${formatearSoles(centimos.abs())}';

/// Lo que entró va en azul; lo que salió, en el color del texto.
Color colorDelMonto(TipoMovimiento tipo) =>
    tipo == TipoMovimiento.ingreso ? Colores.marca : Colores.textoPrincipal;

/// El título de un movimiento: el proveedor, «Retiro para mí», la nota o la
/// categoría.
String tituloDeFila(FilaHistorial f) {
  if (f.proveedor case final proveedor?) return proveedor;
  if (f.tipo == TipoMovimiento.retiro) return Textos.retiroParaMi;
  return f.nota ?? f.categoria ?? Textos.nombreTipo(f.tipo);
}

/// La línea de abajo: categoría y cuenta, sin repetir lo que ya dice el
/// título. Lo que se debe no ha salido de ninguna cuenta.
List<String> _partes(FilaHistorial f) {
  final cuenta = Textos.nombreCuenta(f.cuenta);
  if (f.tipo == TipoMovimiento.retiro) return [Textos.retiroNoCuenta, cuenta];
  final tituloEsCategoria =
      f.proveedor == null && f.nota == null && f.categoria != null;
  return [
    if (!tituloEsCategoria && f.categoria != null) f.categoria!,
    if (!f.loDebes) cuenta,
    if (f.porSubir) Textos.marcaPorSubir,
  ];
}

class DetalleDeFila extends StatelessWidget {
  const DetalleDeFila({super.key, required this.fila});

  final FilaHistorial fila;

  @override
  Widget build(BuildContext context) {
    final partes = _partes(fila);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: partes.join(' · ')),
          if (fila.loDebes) ...[
            if (partes.isNotEmpty) const TextSpan(text: ' · '),
            TextSpan(
              text: Textos.loDebes,
              style: Tipografia.secundario.copyWith(
                color: Colores.avisoTexto,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
      style: Tipografia.secundario,
    );
  }
}

/// Una fila del Historial (S10).
class FilaMovimiento extends StatelessWidget {
  const FilaMovimiento({
    super.key,
    required this.fila,
    required this.alTocar,
    this.conSeparador = false,
  });

  final FilaHistorial fila;
  final VoidCallback alTocar;
  final bool conSeparador;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alTocar,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: conSeparador
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colores.separador)),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tituloDeFila(fila),
                    style: Tipografia.textoFuerte.copyWith(height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  DetalleDeFila(fila: fila),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              montoConSigno(fila.tipo, fila.montoCentimos),
              style: Tipografia.cifra(
                Tipografia.tituloTarjeta.copyWith(
                  color: colorDelMonto(fila.tipo),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
