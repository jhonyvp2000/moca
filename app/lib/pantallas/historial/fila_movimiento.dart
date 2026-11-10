import 'package:flutter/material.dart';

import '../../comun/badge_estado.dart';
import '../../comun/iconos.dart';
import '../../comun/monto_text.dart';
import '../../comun/tono.dart';
import '../../dominio/historial.dart';
import '../../dominio/modelos.dart';
import '../../pais/peru/formato.dart';
import '../../pais/peru/iconos_categorias.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «+ S/ 350» para lo que entró, «− S/ 980» para lo que salió. Los signos y el
/// símbolo no se separan de la cifra.
String montoConSigno(TipoMovimiento tipo, int centimos) =>
    // Un pase no entra ni sale: sin signo (entrega 21.1).
    '${tipo.esPase
        ? ''
        : tipo.entraPlata
        ? '+ '
        : '− '}'
    // Cada registro con sus céntimos si los tiene (decisiones.md, 16-10-2026).
    '${formatearSolesComprobante(centimos.abs())}';

/// Lo que entró (y lo que puso el dueño) va en azul; lo que salió, en rojo
/// sobrio (entrega 14.9.2).
Color colorDelMonto(TipoMovimiento tipo) => tipo.esPase
    ? Colores.textoPrincipal
    : tipo.entraPlata
    ? Colores.marca
    : Colores.salida;

/// El título de un movimiento: el proveedor, «Retiro para mí», la nota o la
/// categoría.
String tituloDeFila(FilaHistorial f) {
  if (f.ajusteArqueo) return Textos.ajusteDelArqueo;
  if (f.proveedor case final proveedor?) return proveedor;
  if (f.tipo == TipoMovimiento.retiro) return Textos.retiroParaMi;
  if (f.tipo == TipoMovimiento.aporte) return Textos.puseDeMiBolsillo;
  if (f.tipo.esPase) return f.nota ?? Textos.pasePlata;
  return f.nota ?? f.categoria ?? Textos.nombreTipo(f.tipo);
}

/// La línea de abajo: categoría y cuenta, sin repetir lo que ya dice el
/// título. Lo que se debe no ha salido de ninguna cuenta.
List<String> _partes(FilaHistorial f, {bool conPorSubir = true}) {
  final cuenta = Textos.nombreCuenta(f.cuenta);
  if (f.ajusteArqueo) return [Textos.ajusteNoCuenta, cuenta];
  if (f.tipo == TipoMovimiento.retiro) return [Textos.retiroNoCuenta, cuenta];
  if (f.tipo == TipoMovimiento.aporte) return [Textos.aporteNoCuenta, cuenta];
  // «Efectivo → BCP» (entrega 21.1).
  if (f.cuentaDestino case final destino? when f.tipo.esPase) {
    return [
      Textos.pase(cuenta, Textos.nombreCuenta(destino)),
      if (conPorSubir && f.porSubir) Textos.marcaPorSubir,
      if (f.deOtro) Textos.loAnoto(f.autorNombre, f.autorRol),
    ];
  }
  final tituloEsCategoria =
      f.proveedor == null && f.nota == null && f.categoria != null;
  return [
    // Un pago en parte, y lo que va pagado de una deuda (entrega 44).
    if (f.parteDe != null) Textos.pagoEnParte,
    if (!tituloEsCategoria && f.categoria != null) f.categoria!,
    if (!f.loDebes) cuenta,
    if (f.loDebes && f.pagadoEnPartesCentimos > 0)
      Textos.pagoDeTotal(
        formatearSolesComprobante(f.pagadoEnPartesCentimos),
        formatearSolesComprobante(f.totalConPartesCentimos),
      ),
    if (f.porSubir) Textos.marcaPorSubir,
    // Con varias personas, quién lo anotó (entrega 20).
    if (f.deOtro) Textos.loAnoto(f.autorNombre, f.autorRol),
  ];
}

class DetalleDeFila extends StatelessWidget {
  const DetalleDeFila({super.key, required this.fila, this.conEstado = true});

  final FilaHistorial fila;

  /// Con «Te debe» y «por subir» en el texto; la fila del Historial los
  /// muestra como etiquetas (mejora 01).
  final bool conEstado;

  @override
  Widget build(BuildContext context) {
    final partes = _partes(fila, conPorSubir: conEstado);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: partes.join(' · ')),
          if (conEstado && fila.loDebes) ...[
            if (partes.isNotEmpty) const TextSpan(text: ' · '),
            TextSpan(
              text: fila.teDeben ? Textos.teDebe : Textos.loDebes,
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

/// Una fila del Historial (S10), rediseñada en la mejora 01: la inicial
/// de la persona o el icono de la categoría, el título, su línea, las
/// etiquetas de estado y el monto con signo y color.
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

  /// Entró, salió o se movió adentro.
  Tono get _tono => fila.tipo.esPase || fila.ajusteArqueo
      ? Tono.neutro
      : fila.tipo.entraPlata
      ? Tono.ingreso
      : Tono.egreso;

  @override
  Widget build(BuildContext context) {
    final quien = fila.proveedor?.trim();
    final conPersona = quien != null && quien.isNotEmpty;
    return InkWell(
      onTap: alTocar,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(
          horizontal: Medidas.e4,
          vertical: Medidas.e3,
        ),
        decoration: conSeparador
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colores.separador)),
              )
            : null,
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: conPersona ? Colores.azul100 : _tono.fondo(context),
                  shape: conPersona ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: conPersona
                      ? null
                      : BorderRadius.circular(Medidas.radioMedio),
                ),
                child: conPersona
                    ? Text(
                        quien.characters.first.toUpperCase(),
                        style: Tipografia.tituloDestacado.copyWith(
                          color: Colores.marca,
                        ),
                      )
                    : Icon(
                        fila.tipo == TipoMovimiento.ingreso ||
                                fila.tipo == TipoMovimiento.egreso
                            ? iconoDeCategoria(fila.categoria)
                            : Iconos.deTipo(fila.tipo),
                        size: 24,
                        color: _tono.color(context),
                      ),
              ),
            ),
            const SizedBox(width: Medidas.e3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tituloDeFila(fila),
                    style: Tipografia.textoFuerte.copyWith(height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  DetalleDeFila(fila: fila, conEstado: false),
                  if (fila.loDebes || fila.porSubir) ...[
                    const SizedBox(height: Medidas.e1),
                    Wrap(
                      spacing: Medidas.e1,
                      runSpacing: Medidas.e1,
                      children: [
                        if (fila.loDebes)
                          BadgeEstado(
                            fila.teDeben ? Textos.teDebe : Textos.loDebes,
                          ),
                        if (fila.porSubir)
                          const BadgeEstado(
                            Textos.porSubirEtiqueta,
                            tono: Tono.neutro,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Medidas.e3),
            MontoText(
              fila.montoCentimos,
              estilo: Tipografia.tituloFila,
              tono: _tono == Tono.neutro ? null : _tono,
              conSigno: true,
              conCentimos: true,
            ),
          ],
        ),
      ),
    );
  }
}
