import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/errores.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// Lo que falló en los teléfonos (entrega 27), solo para Jhony. Al tocar un
/// error se copia su detalle, para pasárselo a Claude Code.
class PantallaErrores extends ConsumerStatefulWidget {
  const PantallaErrores({super.key});

  @override
  ConsumerState<PantallaErrores> createState() => _EstadoErrores();
}

class _EstadoErrores extends ConsumerState<PantallaErrores> {
  List<ErrorAgrupado>? _errores;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final errores = await ref.read(servicioErroresProvider).errores();
    if (!mounted) return;
    setState(() {
      _errores = errores;
      _cargando = false;
    });
  }

  static String _detalle(ErrorAgrupado e) => [
    e.mensaje,
    'Pantalla: ${e.pantalla ?? '—'} · ${e.entrega ?? '—'} (${e.armado ?? '—'})',
    if (e.pila != null) e.pila!,
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    final errores = _errores;
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.errores,
        alVolver: () => context.pop(),
      ),
      contenido: [
        if (_cargando)
          const Center(child: CircularProgressIndicator())
        else if (errores == null)
          const Aviso(texto: Textos.necesitasSenalParaErrores)
        else if (errores.isEmpty)
          const Text(Textos.sinErrores, style: Tipografia.secundario)
        else
          for (final e in errores)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(e.mensaje, style: Tipografia.textoFuerte),
                    const SizedBox(height: 4),
                    Text(
                      [
                        Textos.erroresVeces(e.veces, e.negocios),
                        '${formatearDiaYMes(e.ultima)} ${formatearHora(e.ultima.hour * 60 + e.ultima.minute)}',
                        if (e.pantalla != null) e.pantalla!,
                        if (e.entrega != null) '${e.entrega} (${e.armado})',
                      ].join(' · '),
                      style: Tipografia.secundario,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _detalle(e)));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(Textos.detalleCopiado),
                            ),
                          );
                        },
                        child: const Text(Textos.copiarDetalle),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
      acciones: const [],
    );
  }
}
