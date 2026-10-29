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
    '${tipo.entraPlata ? '+' : '−'} '
    // Cada registro con sus céntimos si los tiene (decisiones.md, 16-10-2026).
    '${formatearSolesComprobante(centimos.abs())}';

/// Lo que entró (y lo que puso el dueño) va en azul; lo que salió, en rojo
/// sobrio (entrega 14.9.2).
Color colorDelMonto(TipoMovimiento tipo) =>
    tipo.entraPlata ? Colores.marca : Colores.salida;

/// El título de un movimiento: el proveedor, «Retiro para mí», la nota o la
/// categoría.
String tituloDeFila(FilaHistorial f) {
  if (f.ajusteArqueo) return Textos.ajusteDelArqueo;
  if (f.proveedor case final proveedor?) return proveedor;
  if (f.tipo == TipoMovimiento.retiro) return Textos.retiroParaMi;
  if (f.tipo == TipoMovimiento.aporte) return Textos.puseDeMiBolsillo;
  return f.nota ?? f.categoria ?? Textos.nombreTipo(f.tipo);
}

/// La línea de abajo: categoría y cuenta, sin repetir lo que ya dice el
/// título. Lo que se debe no ha salido de ninguna cuenta.
List<String> _partes(FilaHistorial f) {
  final cuenta = Textos.nombreCuenta(f.cuenta);
  if (f.ajusteArqueo) return [Textos.ajusteNoCuenta, cuenta];
  if (f.tipo == TipoMovimiento.retiro) return [Textos.retiroNoCuenta, cuenta];
  if (f.tipo == TipoMovimiento.aporte) return [Textos.aporteNoCuenta, cuenta];
  final tituloEsCategoria =
      f.proveedor == null && f.nota == null && f.categoria != null;
  return [
    if (!tituloEsCategoria && f.categoria != null) f.categoria!,
    if (!f.loDebes) cuenta,
    if (f.porSubir) Textos.marcaPorSubir,
    // Con varias personas, quién lo anotó (entrega 20).
    if (f.deOtro) Textos.loAnoto(f.autorNombre, f.autorRol),
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
