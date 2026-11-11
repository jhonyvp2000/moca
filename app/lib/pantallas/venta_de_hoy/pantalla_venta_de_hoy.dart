import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/campo_monto.dart';
import '../../comun/estructura.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/equipo.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../dominio/movimientos.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import '../registrar/franja_sin_senal.dart';
import '../registrar/confirmacion.dart';
import '../../dominio/medicion.dart';
import '../../tema/medidas.dart';

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

  /// Lo fiado de hoy, con a quién (entrega 52).
  bool _conFiado = false;
  final _fiado = TextEditingController();
  final _quien = TextEditingController();
  final _celular = TextEditingController();

  @override
  void initState() {
    super.initState();
    final montos = widget.montosIniciales ?? const {};
    String soles(TipoCuenta c) =>
        (montos[c] ?? 0) > 0 ? separarMiles(montos[c]! ~/ 100) : '';
    for (final MapEntry(key: cuenta, value: campo) in _campos.entries) {
      campo.text = soles(cuenta);
    }
    _conBanco = _campos.entries.any(
      (e) => e.key.esBanco && e.value.text.isNotEmpty,
    );
    ref.read(medicionProvider).anotar(EventoMedicion.ventaAbierta, {
      'modo': 'escrita',
    });
  }

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    _fiado.dispose();
    _quien.dispose();
    _celular.dispose();
    super.dispose();
  }

  /// Efectivo, Yape y las billeteras que usa; los bancos, si tocó «+ Banco».
  List<TipoCuenta> get _cuentasVisibles => [
    for (final c in ref.read(tiposDeCuentaProvider))
      if (!c.esBanco || _conBanco) c,
  ];

  Map<TipoCuenta, int> get _ventaPorCuenta => {
    for (final c in _cuentasVisibles)
      c: leerSolesEnCentimos(_campos[c]!.text) ?? 0,
  };

  int get _total => _ventaPorCuenta.values.fold(0, (a, b) => a + b);

  int get _fiadoCentimos =>
      _conFiado ? leerSolesEnCentimos(_fiado.text) ?? 0 : 0;

  /// Lo fiado lleva a quién, como en «Escribirlo» (entrega 42).
  bool get _faltaQuien => _fiadoCentimos > 0 && _quien.text.trim().isEmpty;

  /// El celular del cliente, solo los dueños (entrega 53).
  bool get _pideCelular =>
      (ref.read(permisosProvider).value ?? Permisos.delDueno).rol == Rol.dueno;

  bool get _celularMal =>
      _conFiado &&
      _pideCelular &&
      _celular.text.trim().isNotEmpty &&
      celularDeCliente(_celular.text) == null;

  bool get _sePuedeGuardar =>
      (_total > 0 || _fiadoCentimos > 0) &&
      !_faltaQuien &&
      !_celularMal &&
      !_guardando;

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
      // Lo fiado queda en la caja de quien anota, sin mover su saldo.
      final permisos = ref.read(permisosProvider).value;
      final caja = permisos == null || permisos.puedeUsar(TipoCuenta.efectivo)
          ? TipoCuenta.efectivo
          : permisos.misCajas!.first;
      final guardado = await repo.anotarVentaDelDia(
        _ventaPorCuenta,
        fiado: _fiadoCentimos > 0
            ? FiadoDelDia(
                montoCentimos: _fiadoCentimos,
                quien: _quien.text.trim(),
                cuenta: caja,
                celular: _pideCelular ? celularDeCliente(_celular.text) : null,
              )
            : null,
      );
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
        const SizedBox(height: Medidas.e2),
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
                cuenta: cuenta,
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
        // Lo fiado de hoy, aparte de lo cobrado (entrega 52). La primera
        // venta, antes de la cuenta, no fía.
        if (_conFiado) ...[
          const SizedBox(height: Medidas.e3),
          GrupoMontos(
            filas: [
              FilaMonto(
                etiqueta: Textos.alFiadoEtiqueta,
                controlador: _fiado,
                alCambiar: actualizar,
                autofocus: true,
              ),
            ],
          ),
          const SizedBox(height: Medidas.e3),
          Text(Textos.quienTeDebe, style: Tipografia.tituloSeccion),
          const SizedBox(height: Medidas.e2),
          TextField(
            controller: _quien,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            style: Tipografia.texto,
            onChanged: actualizar,
            decoration: const InputDecoration(
              hintText: Textos.quienTeDebeEjemplo,
              counterText: '',
            ),
          ),
          if (_pideCelular) ...[
            const SizedBox(height: Medidas.e3),
            Text(Textos.suCelularOpcional, style: Tipografia.tituloSeccion),
            const SizedBox(height: Medidas.e2),
            TextField(
              controller: _celular,
              maxLength: 15,
              keyboardType: TextInputType.phone,
              style: Tipografia.texto,
              onChanged: actualizar,
              decoration: InputDecoration(
                hintText: Textos.celularEjemplo,
                helperText: Textos.celularDelClienteAyuda,
                errorText: _celularMal ? Textos.revisaElNumero : null,
                counterText: '',
              ),
            ),
          ],
        ],
        Wrap(
          spacing: Medidas.e2,
          children: [
            if (!_conBanco)
              TextButton(
                onPressed: () => setState(() => _conBanco = true),
                child: const Text(Textos.agregarBanco),
              ),
            if (!_conFiado && !widget.primeraVenta)
              TextButton(
                onPressed: () => setState(() => _conFiado = true),
                child: const Text(Textos.agregarFiado),
              ),
          ],
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
                style: Tipografia.cifra(Tipografia.tituloDestacado),
              ),
            ],
          ),
        ),
        // Lo fiado no entró: va aparte del total (entrega 52).
        if (_fiadoCentimos > 0) ...[
          const SizedBox(height: Medidas.e2),
          Text(
            Textos.alFiadoResumen(formatearSoles(_fiadoCentimos), _quien.text),
            style: Tipografia.cifra(
              Tipografia.textoFuerte.copyWith(color: Colores.pendienteTexto),
            ),
          ),
        ],
      ],
      acciones: [
        if (_faltaQuien || _celularMal)
          Padding(
            padding: const EdgeInsets.only(bottom: Medidas.e2),
            child: Text(
              Textos.falta([
                if (_faltaQuien) Textos.faltaQuienTeDebe,
                if (_celularMal) Textos.faltaRevisarElNumero,
              ]),
              style: Tipografia.apoyo.copyWith(color: Colores.pendienteTexto),
            ),
          ),
        FilledButton(
          onPressed: _sePuedeGuardar ? _guardar : null,
          child: const Text(Textos.guardar),
        ),
        BotonTexto(texto: Textos.volver, alTocar: _volver),
      ],
    );
  }
}
