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
import '../registrar/confirmacion.dart';

/// S07 · Venta de hoy, en su versión escrita. La voz llega en la entrega 4
/// y llenará esta misma pantalla. Sirve para la primera venta (antes del
/// alta) y para la venta de los días siguientes, que se suma a la de hoy.
class PantallaVentaDeHoy extends ConsumerStatefulWidget {
  const PantallaVentaDeHoy({
    super.key,
    this.primeraVenta = true,
    this.montosIniciales,
  });

  final bool primeraVenta;

  /// Montos ya puestos, por ejemplo al corregir lo que se dijo por voz.
  final Map<TipoCuenta, int>? montosIniciales;

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
  void initState() {
    super.initState();
    final montos = widget.montosIniciales ?? const {};
    String soles(TipoCuenta c) =>
        (montos[c] ?? 0) > 0 ? separarMiles(montos[c]! ~/ 100) : '';
    _efectivo.text = soles(TipoCuenta.efectivo);
    _yape.text = soles(TipoCuenta.yape);
    _banco.text = soles(TipoCuenta.banco);
    _conBanco = _banco.text.isNotEmpty;
  }

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
      if (widget.primeraVenta) {
        await ref
            .read(repositorioPrimerDiaProvider)
            .anotarPrimeraVenta(_ventaPorCuenta);
        // Al guardar, la app pasa sola a «Guarda tu avance».
        return;
      }
      final repo = ref.read(repositorioMovimientosProvider);
      final guardado = await repo.anotarVentaDelDia(_ventaPorCuenta);
      if (!mounted) return;
      final mensajes = ScaffoldMessenger.of(context);
      context.pop();
      mostrarGuardado(mensajes, guardado, repo.deshacer);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _volver() =>
      widget.primeraVenta ? context.go(Rutas.bienvenida) : context.pop();

  @override
  Widget build(BuildContext context) {
    void actualizar(String _) => setState(() {});
    final total = _total;
    final ventaYaAnotada = widget.primeraVenta
        ? 0
        : ref.watch(resumenInicioProvider).value?.ventaDeHoyCentimos ?? 0;

    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.ventaDeHoy,
        alVolver: _volver,
      ),
      contenido: [
        const Text(Textos.cuantoVendisteHoy, style: Tipografia.tituloPantalla),
        const SizedBox(height: 6),
        const Text(Textos.ventaPorCuentaDetalle, style: Tipografia.secundario),
        if (ventaYaAnotada > 0) ...[
          const SizedBox(height: 12),
          TarjetaMoca(
            texto: Textos.hoyYaAnotaste(formatearSoles(ventaYaAnotada)),
          ),
        ],
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
        BotonTexto(texto: Textos.volver, alTocar: _volver),
      ],
    );
  }
}
