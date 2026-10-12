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
  final _efectivo = TextEditingController();
  final _yape = TextEditingController();
  final _banco = TextEditingController();

  @override
  void dispose() {
    _efectivo.dispose();
    _yape.dispose();
    _banco.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    await ref.read(repositorioPrimerDiaProvider).declararSaldo({
      TipoCuenta.efectivo: leerSolesEnCentimos(_efectivo.text) ?? 0,
      TipoCuenta.yape: leerSolesEnCentimos(_yape.text) ?? 0,
      TipoCuenta.banco: leerSolesEnCentimos(_banco.text) ?? 0,
    });
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                  FilaMonto(
                    etiqueta: Textos.efectivo,
                    controlador: _efectivo,
                    autofocus: true,
                  ),
                  FilaMonto(etiqueta: Textos.yape, controlador: _yape),
                  FilaMonto(
                    etiqueta: Textos.banco,
                    controlador: _banco,
                    accionTeclado: TextInputAction.done,
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
