import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inyeccion.dart';

/// Sube lo propio, baja lo que anotaron los demás y, si hace falta, pide
/// las cifras: lo mismo que cada 30 segundos, pero ya (entrega 18.1).
Future<void> actualizarAhora(WidgetRef ref) async {
  final servicio = ref.read(servicioCuentaProvider);
  if (await servicio.hayCambiosSinSubir()) await servicio.subirTodo();
  await servicio.traerCambios();
  await servicio.actualizarCifras();
}

/// Deslizar hacia abajo para actualizar (entrega 18.1). La lista de
/// adentro necesita `AlwaysScrollableScrollPhysics`, para que el gesto
/// funcione aunque quepa en la pantalla.
class ConActualizar extends ConsumerWidget {
  const ConActualizar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      RefreshIndicator(onRefresh: () => actualizarAhora(ref), child: child);
}
