import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/campo_monto.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// S03, paso 1: declarar el saldo que quedó pendiente en el alta (estado no
/// dibujado, aprobado el 12-10-2026). Usa los mismos campos de S02.
Future<void> mostrarHojaSaldo(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _HojaSaldo(),
  );
}

class _HojaSaldo extends ConsumerStatefulWidget {
  const _HojaSaldo();

  @override
  ConsumerState<_HojaSaldo> createState() => _EstadoHojaSaldo();
}

class _EstadoHojaSaldo extends ConsumerState<_HojaSaldo> {
  final _campos = {
    for (final c in TipoCuenta.values) c: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    await ref.read(repositorioPrimerDiaProvider).declararSaldo({
      for (final cuenta in ref.read(tiposDeCuentaProvider))
        cuenta: leerSolesEnCentimos(_campos[cuenta]!.text) ?? 0,
    });
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cuentas = ref.watch(tiposDeCuentaProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.margenLateral,
            0,
            Medidas.margenLateral,
            16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                Textos.cuantoTeniasAlEmpezar,
                style: Tipografia.tituloPantalla,
              ),
              const SizedBox(height: 4),
              const Text(Textos.saldoHojaDetalle, style: Tipografia.secundario),
              const SizedBox(height: 12),
              GrupoMontos(
                filas: [
                  for (final (i, cuenta) in cuentas.indexed)
                    FilaMonto(
                      etiqueta: Textos.nombreCuenta(cuenta),
                      controlador: _campos[cuenta]!,
                      autofocus: i == 0,
                      accionTeclado: i == cuentas.length - 1
                          ? TextInputAction.done
                          : TextInputAction.next,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _guardar,
                child: const Text(Textos.guardarSaldo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
