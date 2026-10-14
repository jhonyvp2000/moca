import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../comun/icono_trazo.dart';
import '../../inyeccion.dart';
import '../../pais/peru/qr_sunat.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// Leer el QR del comprobante (estado no dibujado, aprobado el 13-10-2026):
/// cámara a pantalla completa con un recuadro, linterna y «Cerrar».
class PantallaEscanerQr extends ConsumerStatefulWidget {
  const PantallaEscanerQr({super.key});

  @override
  ConsumerState<PantallaEscanerQr> createState() => _EstadoEscanerQr();
}

class _EstadoEscanerQr extends ConsumerState<PantallaEscanerQr> {
  final _camara = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _procesando = false;

  /// Mensaje cuando el código no sirve; nulo mientras se busca.
  String? _problema;

  @override
  void dispose() {
    _camara.dispose();
    super.dispose();
  }

  Future<void> _alDetectar(BarcodeCapture captura) async {
    if (_procesando || _problema != null) return;
    final contenido = captura.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (contenido == null) return;
    _procesando = true;
    await HapticFeedback.mediumImpact();
    final lectura = leerQrSunat(contenido);
    if (lectura == null) {
      setState(() => _problema = Textos.qrNoEsComprobante);
    } else if (await ref
        .read(repositorioComprobantesProvider)
        .yaAnotado(lectura)) {
      setState(() => _problema = Textos.comprobanteYaAnotado);
    } else if (mounted) {
      context.pushReplacement(Rutas.confirmarLectura, extra: lectura);
      return;
    }
    _procesando = false;
  }

  @override
  Widget build(BuildContext context) {
    final problema = _problema;
    return Scaffold(
      backgroundColor: Colores.textoPrincipal,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _camara,
            onDetect: _alDetectar,
            errorBuilder: (context, error) => _SinCamara(
              alEscribir: () => context.pushReplacement(Rutas.escribir),
            ),
          ),
          // Recuadro donde va el QR.
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colores.sobreMarca, width: 3),
                borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Medidas.margenLateral),
              child: Column(
                children: [
                  Row(
                    children: [
                      _BotonRedondo(
                        icono: Icono.cerrar,
                        etiqueta: Textos.cerrar,
                        alTocar: () => context.pop(),
                      ),
                      const Spacer(),
                      _BotonRedondo(
                        icono: Icono.linterna,
                        etiqueta: Textos.linterna,
                        alTocar: _camara.toggleTorch,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Medidas.rellenoTarjeta),
                    decoration: BoxDecoration(
                      color: Colores.superficie,
                      borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
                    ),
                    child: problema == null
                        ? const Text(
                            Textos.apuntaAlQr,
                            textAlign: TextAlign.center,
                            style: Tipografia.textoFuerte,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(problema, style: Tipografia.textoFuerte),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => setState(() {
                                  _problema = null;
                                  _procesando = false;
                                }),
                                child: const Text(Textos.intentarOtraVez),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          context.pushReplacement(Rutas.foto),
                                      child: const Text(Textos.tomarFoto),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => context.pushReplacement(
                                        Rutas.escribir,
                                      ),
                                      child: const Text(Textos.escribirlo),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({
    required this.icono,
    required this.etiqueta,
    required this.alTocar,
  });

  final Icono icono;
  final String etiqueta;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: etiqueta,
      child: Material(
        color: Colores.superficie,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: alTocar,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: IconoTrazo(icono, color: Colores.textoPrincipal),
            ),
          ),
        ),
      ),
    );
  }
}

class _SinCamara extends StatelessWidget {
  const _SinCamara({required this.alEscribir});

  final VoidCallback alEscribir;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colores.fondo,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Medidas.margenLateral),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(Textos.sinPermisoCamara, style: Tipografia.texto),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: alEscribir,
                child: const Text(Textos.escribirlo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
