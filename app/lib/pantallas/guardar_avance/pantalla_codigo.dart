import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// Código de acceso (estado no dibujado, aprobado el 12-10-2026). En el
/// prototipo no se envía ningún SMS: cualquier código de 6 dígitos entra.
class PantallaCodigo extends ConsumerStatefulWidget {
  const PantallaCodigo({super.key, required this.celular});

  /// Los 9 dígitos, sin espacios.
  final String celular;

  @override
  ConsumerState<PantallaCodigo> createState() => _EstadoCodigo();
}

class _EstadoCodigo extends ConsumerState<PantallaCodigo> {
  final _codigo = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  bool get _completo => _codigo.text.length == 6;

  Future<void> _confirmar() async {
    if (!_completo || _guardando) return;
    setState(() => _guardando = true);
    try {
      await ref
          .read(repositorioPrimerDiaProvider)
          .guardarCelular(widget.celular);
      // Al guardar, la app pasa sola al alta.
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.guardaTuAvance,
        alVolver: () => context.pop(),
      ),
      contenido: [
        Semantics(
          header: true,
          child: Text(
            Textos.escribeElCodigo,
            style: Tipografia.tituloPantalla.copyWith(fontSize: 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          Textos.codigoEnviadoA(formatearCelular(widget.celular)),
          style: Tipografia.secundario.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 16),
        const Aviso(texto: Textos.codigoEnPrueba),
        const SizedBox(height: 20),
        TextField(
          controller: _codigo,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (_) {
            setState(() {});
            if (_completo) _confirmar();
          },
          style: Tipografia.cifra(
            const TextStyle(
              fontFamily: Tipografia.familia,
              fontSize: 28,
              letterSpacing: 12,
              fontWeight: FontWeight.w700,
              color: Colores.textoPrincipal,
            ),
          ),
          decoration: const InputDecoration(
            hintText: '······',
            labelText: Textos.codigo,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text(Textos.cambiarNumero),
          ),
        ),
      ],
      acciones: [
        FilledButton(
          onPressed: _completo && !_guardando ? _confirmar : null,
          child: const Text(Textos.confirmar),
        ),
      ],
    );
  }
}
