import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/iconos.dart';
import '../../comun/monto_text.dart';
import '../../comun/tono.dart';
import '../../dominio/historial.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
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
  // El día en que te pagaron o pagaste una deuda (entrega 55).
  if (f.esPago) {
    return f.tipo.entraPlata
        ? Textos.tePago(f.proveedor)
        : Textos.lePagaste(f.proveedor);
  }
  if (f.proveedor case final proveedor?) return proveedor;
  if (f.tipo == TipoMovimiento.retiro) return Textos.retiroParaMi;
  if (f.tipo == TipoMovimiento.aporte) return Textos.puseDeMiBolsillo;
  if (f.tipo.esPase) return f.nota ?? Textos.pasePlata;
  return f.nota ?? f.categoria ?? Textos.nombreTipo(f.tipo);
}

/// Entró, salió o se movió adentro (mejora 01).
Tono tonoDeFila(FilaHistorial f) => f.tipo.esPase || f.ajusteArqueo
    ? Tono.neutro
    : f.tipo.entraPlata
    ? Tono.ingreso
    : Tono.egreso;

/// La inicial de la persona en un círculo o el icono de la categoría en su
/// cuadro de color (mejora 01): en el Historial y en el detalle.
class AvatarDeFila extends StatelessWidget {
  const AvatarDeFila({super.key, required this.fila});

  final FilaHistorial fila;

  @override
  Widget build(BuildContext context) {
    final quien = fila.proveedor?.trim();
    final conPersona = quien != null && quien.isNotEmpty;
    final tono = tonoDeFila(fila);
    return ExcludeSemantics(
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: conPersona ? Colores.azul100 : tono.fondo(context),
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
                color: tono.color(context),
              ),
      ),
    );
  }
}

/// Lo que va en la segunda línea después de la hora (entrega 68): la
/// categoría si el título no la dice, el pase o la cuenta del ajuste.
String? _complemento(FilaHistorial f) {
  if (f.ajusteArqueo) return Textos.nombreCuenta(f.cuenta);
  if (f.cuentaDestino case final destino? when f.tipo.esPase) {
    return Textos.pase(
      Textos.nombreCuenta(f.cuenta),
      Textos.nombreCuenta(destino),
    );
  }
  if (f.tipo == TipoMovimiento.retiro || f.tipo == TipoMovimiento.aporte) {
    return null;
  }
  final categoria = f.categoria;
  return categoria == null || tituloDeFila(f) == categoria ? null : categoria;
}

/// Una fila del Historial (S10). Desde la entrega 68, como en Yape: dos
/// líneas y sin ícono. Arriba, en negrita, la institución (o lo que dice
/// qué fue); abajo, la hora (o la fecha y la hora con [conFecha]), si se
/// debe o falta subir, y la categoría. A la derecha, lo que salió en rojo
/// con «−» y lo que entró en azul, sin signo.
class FilaMovimiento extends ConsumerWidget {
  const FilaMovimiento({
    super.key,
    required this.fila,
    required this.alTocar,
    this.conSeparador = false,
    this.conFecha = false,
  });

  final FilaHistorial fila;
  final VoidCallback alTocar;
  final bool conSeparador;

  /// En una lista sin cabeceras de día («Lo que te deben», una categoría):
  /// la fecha con la hora.
  final bool conFecha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = fila;
    final cuando = conFecha
        ? formatearFechaYHoraDeFila(f.fecha, ref.watch(relojProvider)())
        : formatearHora(f.fecha.hour * 60 + f.fecha.minute);
    final estado = [
      if (f.loDebes) f.teDeben ? Textos.teDebe : Textos.loDebes,
      if (f.porSubir) Textos.porSubirEtiqueta,
    ];
    // Cobrado o pagado otro día: ahí suma (entrega 55).
    final otroDia = f.pagadoOtroDia
        ? (f.tipo.entraPlata ? Textos.cobradoEl : Textos.pagadoEl)(
            formatearDiaYMes(f.fechaPago!),
          )
        : null;
    final complemento = _complemento(f);
    final tono = tonoDeFila(f);
    const separador = TextSpan(text: ' · ');
    return InkWell(
      onTap: alTocar,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: Medidas.objetivoTactilMinimo + Medidas.e4,
        ),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tituloDeFila(f),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tipografia.textoFuerte.copyWith(height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: cuando),
                        // Lo que se debe, antes que la categoría: no se corta.
                        for (final e in estado) ...[
                          separador,
                          TextSpan(
                            text: e,
                            style: TextStyle(
                              color: e == Textos.porSubirEtiqueta
                                  ? Colores.textoSecundario
                                  : Colores.avisoTexto,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (otroDia != null) ...[
                          separador,
                          TextSpan(text: otroDia),
                        ],
                        if (complemento != null) ...[
                          separador,
                          TextSpan(text: complemento),
                        ],
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tipografia.cifra(Tipografia.secundario),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Medidas.e3),
            MontoText(
              f.montoCentimos,
              estilo: Tipografia.textoFuerte,
              tono: tono == Tono.neutro ? null : tono,
              // Solo lo que salió lleva «−» (entrega 68).
              conSigno: tono == Tono.egreso,
              conCentimos: true,
            ),
          ],
        ),
      ),
    );
  }
}
