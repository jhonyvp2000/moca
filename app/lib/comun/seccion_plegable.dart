import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/medicion.dart';
import '../inyeccion.dart';
import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import '../textos/textos.dart';

/// Lo que se ve a un toque (entrega 59): una fila con su título y «▾»; al
/// tocarla se despliega [hijo]. Cada teléfono recuerda si quedó abierta, y
/// abrirla queda en la medición, sin montos.
class SeccionPlegable extends ConsumerStatefulWidget {
  const SeccionPlegable({
    super.key,
    required this.clave,
    required this.titulo,
    required this.hijo,
    this.resumen,
    this.margenEncabezado = EdgeInsets.zero,
  });

  /// El margen de la fila que se toca, si [hijo] trae el suyo (las cuentas
  /// del Inicio se deslizan hasta el borde).
  final EdgeInsets margenEncabezado;

  /// Con qué nombre se recuerda y se mide: «inicio_cuentas».
  final String clave;
  final String titulo;

  /// Lo que se ve al lado del título, plegada: «Efectivo, Yape y BCP».
  final String? resumen;
  final Widget hijo;

  @override
  ConsumerState<SeccionPlegable> createState() => _EstadoSeccionPlegable();
}

class _EstadoSeccionPlegable extends ConsumerState<SeccionPlegable> {
  bool _abierta = false;

  @override
  void initState() {
    super.initState();
    ref.read(repositorioAjustesProvider).seccionAbierta(widget.clave).then((
      abierta,
    ) {
      if (mounted && abierta != _abierta) setState(() => _abierta = abierta);
    });
  }

  Future<void> _alternar() async {
    final abierta = !_abierta;
    setState(() => _abierta = abierta);
    await ref
        .read(repositorioAjustesProvider)
        .guardarSeccion(widget.clave, abierta: abierta);
    if (abierta) {
      await ref.read(medicionProvider).anotar(EventoMedicion.seccionAbierta, {
        'seccion': widget.clave,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: widget.margenEncabezado,
          child: Material(
            color: Colores.superficie,
            borderRadius: BorderRadius.circular(Medidas.radioMedio),
            child: InkWell(
              borderRadius: BorderRadius.circular(Medidas.radioMedio),
              onTap: _alternar,
              child: Semantics(
                button: true,
                expanded: _abierta,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: Medidas.altoBotonPrincipal,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Medidas.e4,
                      vertical: Medidas.e3,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.resumen ?? widget.titulo,
                            style: widget.resumen == null
                                ? Tipografia.textoFuerte
                                : Tipografia.apoyo,
                          ),
                        ),
                        const SizedBox(width: Medidas.e2),
                        // Lo justo para su texto, hasta la mitad: con letra
                        // grande baja de línea antes que desbordarse.
                        if (_abierta || widget.resumen != null)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                            ),
                            child: Text(
                              _abierta ? Textos.ocultarSeccion : widget.titulo,
                              textAlign: TextAlign.end,
                              style: Tipografia.textoFuerte.copyWith(
                                color: Colores.marca,
                              ),
                            ),
                          ),
                        Icon(
                          _abierta
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: Colores.marca,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_abierta) ...[
          const SizedBox(height: Medidas.separacionTarjetas),
          widget.hijo,
        ],
      ],
    );
  }
}
