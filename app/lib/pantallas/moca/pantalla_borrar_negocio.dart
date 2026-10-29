import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../dominio/cuenta_real.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Borrar mi negocio y mis datos» (entrega 16.1): el derecho del dueño a
/// borrar sus datos (Ley 29733), a la vista y no solo en el ajuste oculto.
/// Solo el titular llega aquí. Primero borra el servidor; el teléfono se
/// borra solo si el servidor ya borró. El número se guarda, sin datos.
class PantallaBorrarNegocio extends ConsumerStatefulWidget {
  const PantallaBorrarNegocio({super.key});

  @override
  ConsumerState<PantallaBorrarNegocio> createState() => _EstadoBorrar();
}

class _EstadoBorrar extends ConsumerState<PantallaBorrarNegocio> {
  final _texto = TextEditingController();
  bool _borrando = false;
  String? _error;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  bool get _escrito => _texto.text.trim().toUpperCase() == 'BORRAR';

  Future<void> _borrar() async {
    setState(() {
      _borrando = true;
      _error = null;
    });
    final mensajes = ScaffoldMessenger.of(context);
    final resultado = await ref
        .read(servicioCuentaProvider)
        .borrarEnElServidor();
    if (!mounted) return;
    if (resultado != ResultadoBorrado.listo) {
      setState(() {
        _borrando = false;
        _error = resultado == ResultadoBorrado.sinSenal
            ? Textos.borrarSinSenal
            : Textos.borrarFallo;
      });
      return;
    }
    await ref.read(repositorioOperadorProvider).borrarTodo();
    if (!mounted) return;
    // Sin datos no hay negocio: la app vuelve a la Bienvenida.
    context.go(Rutas.bienvenida);
    mensajes.showSnackBar(
      const SnackBar(content: Text(Textos.seBorroTodoEnServidor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.borrarMiNegocio,
        alVolver: _borrando ? null : () => context.pop(),
      ),
      contenido: [
        const Text(Textos.queSeBorra, style: Tipografia.textoFuerte),
        const SizedBox(height: 8),
        for (final texto in const [
          Textos.seBorraLoAnotado,
          Textos.seBorranLasFotos,
          Textos.seBorraElEquipo,
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('•  $texto', style: Tipografia.texto),
          ),
        const SizedBox(height: 8),
        const Text(Textos.seGuardaElNumero, style: Tipografia.secundario),
        const SizedBox(height: 16),
        const Aviso(texto: Textos.antesDeBorrar),
        const SizedBox(height: 16),
        TextField(
          controller: _texto,
          enabled: !_borrando,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: Textos.escribeBorrar),
        ),
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Aviso(texto: error),
        ],
      ],
      acciones: [
        FilledButton(
          onPressed: _escrito && !_borrando ? _borrar : null,
          child: Text(_borrando ? Textos.borrando : Textos.borrarParaSiempre),
        ),
      ],
    );
  }
}
