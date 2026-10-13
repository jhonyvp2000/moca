import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../comun/icono_trazo.dart';
import '../comun/tarjeta.dart';
import '../dominio/voz.dart';
import '../inyeccion.dart';
import '../rutas.dart';
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
    final sinSenal = ref.watch(simularSinSenalProvider);

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
            // Mientras se vuelve a contar, se mantiene la cifra anterior.
            child: Text(switch (conteo.value) {
              final int registros => Textos.registrosGuardados(registros),
              null => Textos.contandoRegistros,
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
                  detalle: Textos.empezarPrimerDiaDetalle,
                  alTocar: () => _empezarPrimerDia(context, ref),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.saltarPrimeraSemana,
                  detalle: Textos.saltarPrimeraSemanaDetalle,
                  alTocar: () => _saltarPrimeraSemana(context, ref),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.empezarDemo,
                  detalle: Textos.opcionLlegaEnEntrega(9),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.forzarFotoIlegible,
                  detalle: Textos.forzarFotoIlegibleDetalle,
                  alTocar: () {
                    ref.read(forzarIlegibleProvider.notifier).forzar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(Textos.fotoIlegibleForzada)),
                    );
                  },
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.elegirFrase,
                  detalle: Textos.elegirFraseDetalle,
                  alTocar: () => _elegirFrase(context, ref),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.simularSinSenal,
                  detalle: sinSenal
                      ? Textos.simularSinSenalActivo
                      : Textos.simularSinSenalDetalle,
                  alTocar: () {
                    ref.read(simularSinSenalProvider.notifier).cambiar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          sinSenal
                              ? Textos.senalDelTelefono
                              : Textos.sinSenalSimulada,
                        ),
                      ),
                    );
                  },
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

  Future<void> _elegirFrase(BuildContext context, WidgetRef ref) async {
    final frases = ref.read(frasesDeEjemploProvider);
    final mensajes = ScaffoldMessenger.of(context);
    final elegida = await showModalBottomSheet<FraseEjemplo>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                0,
                Medidas.margenLateral,
                8,
              ),
              child: Text(Textos.elegirFrase, style: Tipografia.tituloPantalla),
            ),
            for (final frase in frases)
              ListTile(
                minTileHeight: Medidas.objetivoTactilMinimo + 12,
                title: Text('«${frase.texto}»', style: Tipografia.texto),
                onTap: () => Navigator.of(context).pop(frase),
              ),
          ],
        ),
      ),
    );
    if (elegida == null) return;
    ref.read(fraseElegidaProvider.notifier).elegir(elegida);
    mensajes.showSnackBar(
      SnackBar(content: Text(Textos.fraseElegida(elegida.texto))),
    );
  }

  Future<void> _saltarPrimeraSemana(BuildContext context, WidgetRef ref) async {
    final mensajes = ScaffoldMessenger.of(context);
    await ref.read(repositorioOperadorProvider).saltarPrimeraSemana();
    mensajes.showSnackBar(
      const SnackBar(content: Text(Textos.primeraSemanaSaltada)),
    );
  }

  Future<void> _empezarPrimerDia(BuildContext context, WidgetRef ref) async {
    final confirmado = await _confirmar(
      context,
      titulo: Textos.confirmarPrimerDiaTitulo,
      boton: Textos.empezarPrimerDiaBoton,
    );
    if (!confirmado) return;
    await ref.read(repositorioOperadorProvider).borrarTodo();
    if (context.mounted) context.go(Rutas.bienvenida);
  }

  Future<bool> _confirmar(
    BuildContext context, {
    required String titulo,
    required String boton,
  }) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: const Text(Textos.confirmarBorrarTexto),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(boton),
          ),
        ],
      ),
    );
    return confirmado == true;
  }

  Future<void> _borrarTodo(BuildContext context, WidgetRef ref) async {
    final confirmado = await _confirmar(
      context,
      titulo: Textos.confirmarBorrarTitulo,
      boton: Textos.borrarTodoBoton,
    );
    if (!confirmado || !context.mounted) return;

    final mensajes = ScaffoldMessenger.of(context);
    await ref.read(repositorioOperadorProvider).borrarTodo();
    ref.invalidate(conteoRegistrosProvider);
    // Sin datos no hay negocio: la app vuelve a la Bienvenida.
    if (context.mounted) context.go(Rutas.bienvenida);
    mensajes.showSnackBar(const SnackBar(content: Text(Textos.seBorroTodo)));
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
