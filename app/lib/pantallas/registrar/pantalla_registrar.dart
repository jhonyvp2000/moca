import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/icono_trazo.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// S06 · Registrar. Sin el ejemplo de fiado ni la ayuda de Yape compartido
/// (ajustes respecto al mockup).
class PantallaRegistrar extends StatelessWidget {
  const PantallaRegistrar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                20,
                Medidas.margenLateral,
                12,
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
                  const SizedBox(width: 8),
                  Text(
                    Textos.registrar,
                    style: Tipografia.tituloTarjeta.copyWith(fontSize: 17),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                8,
                Medidas.margenLateral,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      Textos.diloOMuestralo,
                      style: Tipografia.tituloPantalla.copyWith(
                        fontSize: 26,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Textos.mocaReconoceSola,
                    style: Tipografia.secundario.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  _Entrada(
                    icono: Icono.microfono,
                    titulo: Textos.decirloConVoz,
                    detalle: Textos.ejemplosVoz,
                    principal: true,
                    alTocar: () => context.pushReplacement(Rutas.voz),
                  ),
                  const SizedBox(height: 12),
                  _Entrada(
                    icono: Icono.camara,
                    titulo: Textos.tomarFoto,
                    detalle: Textos.tomarFotoDetalle,
                    alTocar: () => context.pushReplacement(Rutas.foto),
                  ),
                  const SizedBox(height: 12),
                  _Entrada(
                    icono: Icono.qr,
                    titulo: Textos.leerQr,
                    detalle: Textos.leerQrDetalle,
                    alTocar: () => context.pushReplacement(Rutas.qr),
                  ),
                  const SizedBox(height: 12),
                  _Entrada(
                    icono: Icono.lapiz,
                    titulo: Textos.escribirlo,
                    detalle: Textos.escribirloDetalle,
                    alTocar: () => context.pushReplacement(Rutas.escribir),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  final Icono icono;
  final String titulo;
  final String detalle;
  final bool principal;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final activa = alTocar != null;
    final fondo = principal ? Colores.marca : Colores.superficie;
    final texto = principal ? Colores.sobreMarca : Colores.textoPrincipal;
    final textoSuave = principal ? Colores.sobreMarca : Colores.textoSecundario;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      side: principal
          ? BorderSide.none
          : const BorderSide(color: Colores.bordeTarjeta),
    );

    return Opacity(
      opacity: activa ? 1 : 0.6,
      child: Semantics(
        button: true,
        enabled: activa,
        child: Material(
          color: fondo,
          shape: forma,
          child: InkWell(
            customBorder: forma,
            onTap: alTocar,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: principal ? 18 : 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: principal ? Colores.azulOscuro : Colores.tinteAzul,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: IconoTrazo(
                        icono,
                        color: principal
                            ? Colores.sobreMarca
                            : Colores.azulOscuro,
                        tamano: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: Tipografia.tituloTarjeta.copyWith(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
