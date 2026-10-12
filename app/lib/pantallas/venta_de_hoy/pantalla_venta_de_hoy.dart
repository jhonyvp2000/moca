import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/campo_monto.dart';
import '../../comun/estructura.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// S07 · Venta de hoy, en su versión escrita. La voz llega en la entrega 4
/// y llenará esta misma pantalla.
class PantallaVentaDeHoy extends ConsumerStatefulWidget {
  const PantallaVentaDeHoy({super.key});

  @override
  ConsumerState<PantallaVentaDeHoy> createState() => _EstadoVentaDeHoy();
}

class _EstadoVentaDeHoy extends ConsumerState<PantallaVentaDeHoy> {
  final _efectivo = TextEditingController();
  final _yape = TextEditingController();
  final _banco = TextEditingController();
  bool _conBanco = false;
  bool _guardando = false;

  @override
  void dispose() {
    _efectivo.dispose();
    _yape.dispose();
    _banco.dispose();
    super.dispose();
  }

  Map<TipoCuenta, int> get _ventaPorCuenta => {
    TipoCuenta.efectivo: leerSolesEnCentimos(_efectivo.text) ?? 0,
    TipoCuenta.yape: leerSolesEnCentimos(_yape.text) ?? 0,
    if (_conBanco) TipoCuenta.banco: leerSolesEnCentimos(_banco.text) ?? 0,
  };

  int get _total => _ventaPorCuenta.values.fold(0, (a, b) => a + b);

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await ref
          .read(repositorioPrimerDiaProvider)
          .anotarPrimeraVenta(_ventaPorCuenta);
      // Al guardar, la app pasa sola a «Guarda tu avance».
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void actualizar(String _) => setState(() {});
    final total = _total;

    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.ventaDeHoy,
        alVolver: () => context.go(Rutas.bienvenida),
      ),
      contenido: [
        const Text(Textos.cuantoVendisteHoy, style: Tipografia.tituloPantalla),
        const SizedBox(height: 6),
        const Text(Textos.ventaPorCuentaDetalle, style: Tipografia.secundario),
        const SizedBox(height: 16),
        GrupoMontos(
          filas: [
            FilaMonto(
              etiqueta: Textos.efectivo,
              controlador: _efectivo,
              alCambiar: actualizar,
              autofocus: true,
            ),
            FilaMonto(
              etiqueta: Textos.yape,
              controlador: _yape,
              alCambiar: actualizar,
              accionTeclado: _conBanco
                  ? TextInputAction.next
                  : TextInputAction.done,
            ),
            if (_conBanco)
              FilaMonto(
                etiqueta: Textos.banco,
                controlador: _banco,
                alCambiar: actualizar,
                autofocus: true,
                accionTeclado: TextInputAction.done,
              ),
          ],
        ),
        if (!_conBanco)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _conBanco = true),
              child: const Text(Textos.agregarBanco),
            ),
          ),
        const SizedBox(height: 8),
        Tarjeta(
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  Textos.totalQueEntroHoy,
                  style: Tipografia.secundario,
                ),
              ),
              Text(
                formatearSoles(total),
                style: Tipografia.cifra(
                  Tipografia.tituloTarjeta.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ],
      acciones: [
        FilledButton(
          onPressed: total > 0 && !_guardando ? _guardar : null,
          child: const Text(Textos.guardar),
        ),
        BotonTexto(
          texto: Textos.volver,
          alTocar: () => context.go(Rutas.bienvenida),
        ),
      ],
    );
  }
}
