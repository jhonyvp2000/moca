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
import '../registrar/franja_sin_senal.dart';
import '../registrar/confirmacion.dart';
import '../../dominio/medicion.dart';

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
  final _campos = {
    for (final c in TipoCuenta.values) c: TextEditingController(),
  };
  bool _conBanco = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final montos = widget.montosIniciales ?? const {};
    String soles(TipoCuenta c) =>
        (montos[c] ?? 0) > 0 ? separarMiles(montos[c]! ~/ 100) : '';
    for (final MapEntry(key: cuenta, value: campo) in _campos.entries) {
      campo.text = soles(cuenta);
    }
    _conBanco = _campos[TipoCuenta.banco]!.text.isNotEmpty;
    ref.read(medicionProvider).anotar(EventoMedicion.ventaAbierta, {
      'modo': 'escrita',
    });
  }

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Efectivo, Yape y las billeteras que usa; el banco, si lo agregó.
  List<TipoCuenta> get _cuentasVisibles => [
    for (final c in ref.read(tiposDeCuentaProvider))
      if (c != TipoCuenta.banco || _conBanco) c,
  ];

  Map<TipoCuenta, int> get _ventaPorCuenta => {
    for (final c in _cuentasVisibles)
      c: leerSolesEnCentimos(_campos[c]!.text) ?? 0,
  };

  int get _total => _ventaPorCuenta.values.fold(0, (a, b) => a + b);

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      if (widget.primeraVenta) {
        await ref
            .read(repositorioPrimerDiaProvider)
            .anotarPrimeraVenta(_ventaPorCuenta);
        await ref.read(medicionProvider).anotar(EventoMedicion.ventaGuardada, {
          'modo': 'escrita',
        });
        // Al guardar, la app pasa sola a «Guarda tu avance».
        return;
      }
      final repo = ref.read(repositorioMovimientosProvider);
      final guardado = await repo.anotarVentaDelDia(_ventaPorCuenta);
      await ref.read(medicionProvider).anotar(EventoMedicion.ventaGuardada, {
        'modo': 'escrita',
      });
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
    ref.watch(tiposDeCuentaProvider);
    final cuentas = _cuentasVisibles;
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
        const FranjaSinSenal(),
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
            for (final (i, cuenta) in cuentas.indexed)
              FilaMonto(
                etiqueta: Textos.nombreCuenta(cuenta),
                controlador: _campos[cuenta]!,
                alCambiar: actualizar,
                // El banco recién agregado toma el foco.
                autofocus: i == 0 || cuenta == TipoCuenta.banco,
                accionTeclado: i == cuentas.length - 1
                    ? TextInputAction.done
                    : TextInputAction.next,
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
