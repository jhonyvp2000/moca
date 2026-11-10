import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/icono_trazo.dart';
import '../../comun/videos.dart';
import '../../dominio/modelos.dart';
import '../../dominio/tutoria.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import 'franja_sin_senal.dart';

/// El + de la barra (mejora 01): las formas de anotar en una hoja inferior.
/// Elegir una cierra la hoja y abre esa pantalla.
Future<void> mostrarHojaRegistrar(BuildContext context) async {
  final ruta = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (hoja) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (hoja, desplazamiento) => ContenidoRegistrar(
        controlador: desplazamiento,
        alElegir: (ruta) => Navigator.of(hoja).pop(ruta),
        alCancelar: () => Navigator.of(hoja).pop(),
      ),
    ),
  );
  if (ruta != null && context.mounted) await context.push(ruta);
}

/// S06 · Registrar, como pantalla: la abren los avisos, el Historial vacío
/// y el acceso directo del teléfono. Muestra lo mismo que la hoja del +.
class PantallaRegistrar extends StatelessWidget {
  const PantallaRegistrar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                Medidas.e4,
                Medidas.margenLateral,
                0,
              ),
              child: Row(
                children: [
                  Semantics(
                    label: Textos.cerrar,
                    child: BotonVolver(
                      icono: Icono.cerrar,
                      alTocar: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: Medidas.e2),
                  Text(Textos.registrar, style: Tipografia.tituloTarjeta),
                ],
              ),
            ),
            Expanded(
              child: ContenidoRegistrar(
                alElegir: (ruta) => context.pushReplacement(ruta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Las formas de anotar: voz, foto, QR y escribirlo, más dos atajos. Sin el
/// ejemplo de fiado ni la ayuda de Yape compartido (ajustes respecto al
/// mockup).
class ContenidoRegistrar extends ConsumerWidget {
  const ContenidoRegistrar({
    super.key,
    required this.alElegir,
    this.alCancelar,
    this.controlador,
  });

  final ValueChanged<String> alElegir;

  /// En la hoja, «Cancelar» al pie.
  final VoidCallback? alCancelar;
  final ScrollController? controlador;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sin cuenta, cuántas fotos de prueba quedan (entrega 14.2).
    final pruebas = ref.watch(fotosDePruebaProvider).value;
    // Todo armado de una vez (no es una lista larga): con letra grande,
    // «Escribirlo» existe aunque haya que desplazarse para verlo.
    return SingleChildScrollView(
      controller: controlador,
      padding: const EdgeInsets.fromLTRB(
        Medidas.margenLateral,
        Medidas.e2,
        Medidas.margenLateral,
        Medidas.e6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: const Text(
              Textos.diloOMuestralo,
              style: Tipografia.tituloPantalla,
            ),
          ),
          const SizedBox(height: Medidas.e1),
          const Text(Textos.mocaReconoceSola, style: Tipografia.secundario),
          const SizedBox(height: Medidas.e4),
          const FranjaSinSenal(separacion: Medidas.e3),
          const TarjetaPrimeraVez(
            video: VideoTutoria.gastoConFoto,
            margen: EdgeInsets.only(bottom: Medidas.e3),
          ),
          _Entrada(
            icono: Icons.mic_rounded,
            titulo: Textos.decirloConVoz,
            detalle: Textos.ejemplosVoz,
            principal: true,
            alTocar: () => alElegir(Rutas.voz),
          ),
          const SizedBox(height: Medidas.e3),
          _Entrada(
            icono: Icons.photo_camera_rounded,
            titulo: Textos.tomarFoto,
            detalle: switch (pruebas) {
              null => Textos.tomarFotoDetalle,
              0 => Textos.guardaTuAvanceParaFotos,
              final n => Textos.fotosDePruebaQuedan(n),
            },
            alTocar: () => alElegir(Rutas.foto),
          ),
          const SizedBox(height: Medidas.e3),
          _Entrada(
            icono: Icons.qr_code_scanner_rounded,
            titulo: Textos.leerQr,
            detalle: Textos.leerQrDetalle,
            alTocar: () => alElegir(Rutas.qr),
          ),
          const SizedBox(height: Medidas.e3),
          _Entrada(
            icono: Icons.edit_rounded,
            titulo: Textos.escribirlo,
            detalle: Textos.escribirloDetalle,
            alTocar: () => alElegir(Rutas.escribir),
          ),
          const SizedBox(height: Medidas.e5),
          const Text(Textos.atajos, style: Tipografia.apoyo),
          const SizedBox(height: Medidas.e2),
          Wrap(
            spacing: Medidas.e2,
            runSpacing: Medidas.e2,
            children: [
              _Atajo(
                icono: Icons.south_west_rounded,
                texto: Textos.atajoVentaDelDia,
                color: Colores.ingreso,
                fondo: Colores.ingresoFondo,
                alTocar: () => alElegir(Rutas.ventaDelDia),
              ),
              _Atajo(
                icono: Icons.north_east_rounded,
                texto: Textos.atajoUnGasto,
                color: Colores.egreso,
                fondo: Colores.egresoFondo,
                alTocar: () => alElegir(
                  Uri(
                    path: Rutas.escribir,
                    queryParameters: {'tipo': TipoMovimiento.egreso.name},
                  ).toString(),
                ),
              ),
            ],
          ),
          if (alCancelar != null) ...[
            const SizedBox(height: Medidas.e4),
            TextButton(
              onPressed: alCancelar,
              style: TextButton.styleFrom(
                foregroundColor: Colores.textoSecundario,
              ),
              child: const Text(Textos.cancelar),
            ),
          ],
        ],
      ),
    );
  }
}

class _Entrada extends StatelessWidget {
  const _Entrada({
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.principal = false,
    this.alTocar,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final bool principal;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final activa = alTocar != null;
    final texto = principal ? Colores.sobreMarca : Colores.textoPrincipal;
    final textoSuave = principal
        ? Colores.sobreMarcaSuave
        : Colores.textoSecundario;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medidas.radioGrande),
      side: principal
          ? BorderSide.none
          : const BorderSide(color: Colores.bordeTarjeta),
    );

    return Opacity(
      opacity: activa ? 1 : 0.6,
      child: Semantics(
        button: true,
        enabled: activa,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Medidas.radioGrande),
            boxShadow: principal ? Sombras.nivel2 : null,
          ),
          child: Material(
            color: principal ? Colores.marca : Colores.azul50,
            shape: forma,
            child: InkWell(
              customBorder: forma,
              onTap: alTocar,
              child: Padding(
                padding: const EdgeInsets.all(Medidas.e4),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: principal ? Colores.azul400 : Colores.azul100,
                        borderRadius: BorderRadius.circular(Medidas.radioMedio),
                      ),
                      child: Icon(
                        icono,
                        size: 26,
                        color: principal ? Colores.sobreMarca : Colores.marca,
                      ),
                    ),
                    const SizedBox(width: Medidas.e4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: Tipografia.tituloSeccion.copyWith(
                              fontSize: 17,
                              color: texto,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            detalle,
                            style: Tipografia.secundario.copyWith(
                              color: textoSuave,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: principal ? Colores.sobreMarca : Colores.neutro,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un atajo de la hoja: la venta del día o un gasto, con su flecha.
class _Atajo extends StatelessWidget {
  const _Atajo({
    required this.icono,
    required this.texto,
    required this.color,
    required this.fondo,
    required this.alTocar,
  });

  final IconData icono;
  final String texto;
  final Color color;
  final Color fondo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Material(
    color: fondo,
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: Medidas.objetivoTactilMinimo,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Medidas.e4,
            vertical: Medidas.e2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 20, color: color),
              const SizedBox(width: Medidas.e2),
              Flexible(
                child: Text(
                  texto,
                  style: Tipografia.textoFuerte.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
