import 'package:flutter/material.dart';

import '../../dominio/movimientos.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../textos/textos.dart';

/// Aviso después de guardar (mockup de S10): «Guardado. Ahora tienes …» con
/// «Deshacer» durante unos segundos. Deshacer anula; no borra.
void mostrarGuardado(
  ScaffoldMessengerState mensajes,
  Guardado guardado,
  Future<void> Function(Guardado) deshacer,
) {
  mensajes
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        persist: false,
        content: Text(
          Textos.guardadoAhoraTienes(
            formatearSoles(guardado.tienesHoyCentimos),
          ),
        ),
        action: SnackBarAction(
          label: Textos.deshacer,
          textColor: Colores.sobreMarca,
          onPressed: () async {
            await deshacer(guardado);
            mensajes.showSnackBar(
              const SnackBar(content: Text(Textos.seDeshizo)),
            );
          },
        ),
      ),
    );
}
