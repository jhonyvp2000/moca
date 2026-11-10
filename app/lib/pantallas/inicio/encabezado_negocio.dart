import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/boton_redondo.dart';
import '../../dominio/equipo.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// El encabezado del Inicio (mejora 01): la inicial y el nombre del negocio,
/// una línea debajo y, a la derecha, Avisos y Ajustes. Ajustes está en todas
/// las versiones del Inicio: desde ahí se vuelve a la cuenta (entrega 45.1).
class EncabezadoNegocio extends ConsumerWidget {
  const EncabezadoNegocio({
    super.key,
    required this.nombre,
    this.detalle,
    this.extra,
    this.conMargen = true,
  });

  /// Sin margen lateral cuando la lista ya lo pone.
  final bool conMargen;

  final String nombre;
  final String? detalle;

  /// Otro botón antes de Avisos (el ojo para ocultar los montos).
  final Widget? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permisos = ref.watch(permisosProvider).value ?? Permisos.delDueno;
    final inicial = nombre.trim().isEmpty
        ? 'M'
        : nombre.trim().characters.first.toUpperCase();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        conMargen ? Medidas.margenLateral : 0,
        Medidas.e4,
        conMargen ? Medidas.margenLateral : 0,
        Medidas.e2,
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: Medidas.objetivoTactilMinimo,
              height: Medidas.objetivoTactilMinimo,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colores.marca,
                borderRadius: BorderRadius.circular(Medidas.radioChico),
              ),
              child: Text(
                inicial,
                style: Tipografia.tituloSeccion.copyWith(
                  fontSize: 20,
                  color: Colores.sobreMarca,
                ),
              ),
            ),
          ),
          const SizedBox(width: Medidas.e3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Tipografia.tituloSeccion.copyWith(fontSize: 19),
                ),
                if (detalle case final d?)
                  Text(d, style: Tipografia.secundario),
              ],
            ),
          ),
          if (extra case final e?) ...[const SizedBox(width: Medidas.e2), e],
          // Los avisos están en el Asistente, para quien los ve.
          if (permisos.veAvisos) ...[
            const SizedBox(width: Medidas.e2),
            BotonRedondo(
              icono: Icons.notifications_none_rounded,
              nombre: Textos.avisos,
              alTocar: () =>
                  StatefulNavigationShell.maybeOf(context)?.goBranch(3),
            ),
          ],
          const SizedBox(width: Medidas.e2),
          BotonRedondo(
            icono: Icons.settings_outlined,
            nombre: Textos.ajustes,
            alTocar: () => context.push(Rutas.ajustes),
          ),
        ],
      ),
    );
  }
}
