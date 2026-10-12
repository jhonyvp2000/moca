import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comun/icono_trazo.dart';
import '../comun/tarjeta.dart';
import '../inyeccion.dart';
import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import '../textos/textos.dart';

final conteoRegistrosProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(repositorioOperadorProvider).contarRegistros(),
);

/// Ajuste oculto para quien organiza la prueba. Se abre manteniendo
/// presionado 3 segundos el isotipo de la pestaña Moca.
class PantallaOperador extends ConsumerWidget {
  const PantallaOperador({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conteo = ref.watch(conteoRegistrosProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const IconoTrazo(
            Icono.volver,
            color: Colores.textoPrincipal,
            tamano: 24,
          ),
        ),
        title: const Text(Textos.tituloOperador),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          0,
          Medidas.margenLateral,
          24,
        ),
        children: [
          const Text(Textos.subtituloOperador, style: Tipografia.secundario),
          const SizedBox(height: 16),
          Tarjeta(
            child: Text(switch (conteo) {
              AsyncData(:final value) => Textos.registrosGuardados(value),
              _ => Textos.contandoRegistros,
            }, style: Tipografia.texto),
          ),
          const SizedBox(height: Medidas.separacionTarjetas),
          Tarjeta(
            relleno: EdgeInsets.zero,
            child: Column(
              children: [
                _Opcion(
                  titulo: Textos.borrarTodo,
                  detalle: Textos.borrarTodoDetalle,
                  alTocar: () => _borrarTodo(context, ref),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.empezarPrimerDia,
                  detalle: Textos.opcionLlegaEnEntrega(2),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.empezarDemo,
                  detalle: Textos.opcionLlegaEnEntrega(9),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.forzarFotoIlegible,
                  detalle: Textos.opcionLlegaEnEntrega(5),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.elegirFrase,
                  detalle: Textos.opcionLlegaEnEntrega(4),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.exportarMedicion,
                  detalle: Textos.opcionLlegaEnEntrega(9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _borrarTodo(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Textos.confirmarBorrarTitulo),
        content: const Text(Textos.confirmarBorrarTexto),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Textos.borrarTodoBoton),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    await ref.read(repositorioOperadorProvider).borrarTodo();
    ref.invalidate(conteoRegistrosProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(Textos.seBorroTodo)));
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({required this.titulo, required this.detalle, this.alTocar});

  final String titulo;
  final String detalle;

  /// Nulo mientras la opción no está disponible.
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final activa = alTocar != null;
    return InkWell(
      onTap: alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Tipografia.textoFuerte.copyWith(
                        color: activa
                            ? Colores.textoPrincipal
                            : Colores.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(detalle, style: Tipografia.secundario),
                  ],
                ),
              ),
              if (activa) const IconoTrazo(Icono.borrar, color: Colores.marca),
            ],
          ),
        ),
      ),
    );
  }
}
