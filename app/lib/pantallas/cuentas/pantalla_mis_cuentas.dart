import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/campo_monto.dart';
import '../../comun/estructura.dart';
import '../../comun/opciones.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/cuentas.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Mis cuentas» (estado no dibujado, aprobado el 13-10-2026): las cuentas
/// del negocio con su saldo y agregar una billetera o un banco (entrega
/// 14.1). Nada se borra.
class PantallaMisCuentas extends ConsumerStatefulWidget {
  const PantallaMisCuentas({super.key});

  @override
  ConsumerState<PantallaMisCuentas> createState() => _EstadoMisCuentas();
}

class _EstadoMisCuentas extends ConsumerState<PantallaMisCuentas> {
  final _nombreOtra = TextEditingController();
  TipoCuenta? _elegida;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreOtra.dispose();
    super.dispose();
  }

  bool get _sePuedeAgregar =>
      _elegida != null &&
      !_guardando &&
      (!_elegida!.conNombrePropio || _nombreOtra.text.trim().isNotEmpty);

  Future<void> _agregar() async {
    final tipo = _elegida!;
    setState(() => _guardando = true);
    try {
      final nombre = tipo.conNombrePropio
          ? _nombreOtra.text.trim()
          : Textos.nombreCuenta(tipo);
      await ref
          .read(repositorioCuentasProvider)
          .agregarBilletera(tipo, nombre: nombre);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(Textos.billeteraAgregada(nombre))));
      _nombreOtra.clear();
      setState(() => _elegida = null);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Corregir el saldo con el que empezó, o por qué ya no (entrega 16.2).
  Future<void> _abrirCuenta(CuentaVista cuenta) async {
    final corregida = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HojaSaldoInicial(cuenta: cuenta),
    );
    if (corregida == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Textos.saldoInicialCorregido(cuenta.nombre))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentas = ref.watch(cuentasProvider).value ?? const <CuentaVista>[];
    Map<TipoCuenta, String> faltan(List<TipoCuenta> tipos) => {
      for (final t in tipos)
        if (!cuentas.any((c) => c.tipo == t))
          t: switch (t) {
            TipoCuenta.otra => Textos.otra,
            TipoCuenta.otroBanco => Textos.otroBanco,
            _ => Textos.nombreCuenta(t),
          },
    };
    final billeteras = faltan(TipoCuenta.billeteras);
    final bancos = faltan(TipoCuenta.otrosBancos);
    // Hasta dos cajas más, de a una (entrega 21).
    final siguienteCaja = [
      TipoCuenta.caja2,
      TipoCuenta.caja3,
    ].where((t) => !cuentas.any((c) => c.tipo == t)).firstOrNull;
    final cajas = {?siguienteCaja: Textos.otraCaja};
    final hayQueAgregar =
        billeteras.isNotEmpty || bancos.isNotEmpty || cajas.isNotEmpty;
    const etiqueta = TextStyle(
      fontFamily: Tipografia.familia,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Colores.textoPrincipal,
    );

    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.misCuentas,
        alVolver: () => context.pop(),
      ),
      contenido: [
        Tarjeta(
          relleno: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, c) in cuentas.indexed)
                InkWell(
                  // El saldo pendiente se pone como siempre, en el Inicio.
                  onTap: c.inicialCentimos == null
                      ? null
                      : () => _abrirCuenta(c),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: Medidas.objetivoTactilMinimo,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: i < cuentas.length - 1
                        ? const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colores.separador),
                            ),
                          )
                        : null,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(c.nombre, style: Tipografia.textoFuerte),
                        ),
                        Text(
                          c.saldoCentimos == null
                              ? Textos.saldoPorPoner
                              : formatearSoles(c.saldoCentimos!),
                          style: c.saldoCentimos == null
                              ? Tipografia.secundario
                              : Tipografia.cifra(Tipografia.textoFuerte),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hayQueAgregar) ...[
          const SizedBox(height: 8),
          const Text(
            Textos.billeteraEmpiezaEnCero,
            style: Tipografia.secundario,
          ),
        ],
        for (final (titulo, opciones) in [
          (Textos.agregarUnaCaja, cajas),
          (Textos.agregarBilletera, billeteras),
          (Textos.agregarUnBanco, bancos),
        ])
          if (opciones.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(titulo, style: etiqueta),
            const SizedBox(height: 10),
            Opciones<TipoCuenta>(
              opciones: opciones,
              elegida: opciones.containsKey(_elegida) ? _elegida : null,
              alElegir: (t) => setState(() {
                if (_elegida != t) _nombreOtra.clear();
                _elegida = t;
              }),
            ),
            if (opciones.containsKey(_elegida) &&
                _elegida!.conNombrePropio) ...[
              const SizedBox(height: 10),
              TextField(
                key: Key(switch (_elegida) {
                  TipoCuenta.otra => 'nombre-otra-billetera',
                  TipoCuenta.otroBanco => 'nombre-otro-banco',
                  _ => 'nombre-caja',
                }),
                controller: _nombreOtra,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                style: Tipografia.textoFuerte.copyWith(fontSize: 16),
                decoration: InputDecoration(
                  hintText: switch (_elegida) {
                    TipoCuenta.otra => Textos.nombreDeLaBilletera,
                    TipoCuenta.otroBanco => Textos.nombreDelBanco,
                    _ => Textos.nombreDeLaCaja,
                  },
                ),
              ),
            ],
          ],
      ],
      acciones: [
        if (hayQueAgregar)
          FilledButton(
            onPressed: _sePuedeAgregar ? _agregar : null,
            child: const Text(Textos.agregar),
          ),
      ],
    );
  }
}

class _HojaSaldoInicial extends ConsumerStatefulWidget {
  const _HojaSaldoInicial({required this.cuenta});

  final CuentaVista cuenta;

  @override
  ConsumerState<_HojaSaldoInicial> createState() => _EstadoHojaSaldo();
}

class _EstadoHojaSaldo extends ConsumerState<_HojaSaldoInicial> {
  late final _monto = TextEditingController(
    text: separarMiles((widget.cuenta.inicialCentimos ?? 0) ~/ 100),
  );
  bool _guardando = false;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _guardar(int centimos) async {
    setState(() => _guardando = true);
    final listo = await ref
        .read(repositorioCuentasProvider)
        .corregirSaldoInicial(widget.cuenta.id, centimos);
    if (mounted) Navigator.of(context).pop(listo);
  }

  @override
  Widget build(BuildContext context) {
    final cuenta = widget.cuenta;
    // Vacío no es cero: se guarda solo un monto escrito.
    final escrito = leerSolesEnCentimos(_monto.text);
    final nuevo = escrito ?? 0;
    final cambio = escrito != null && escrito != cuenta.inicialCentimos;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          Medidas.margenLateral,
          Medidas.margenLateral,
          Medidas.margenLateral + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(cuenta.nombre, style: Tipografia.tituloPantalla),
            const SizedBox(height: 12),
            if (cuenta.seCorrigeElInicial) ...[
              const Text(
                Textos.corregirSaldoInicial,
                style: Tipografia.textoFuerte,
              ),
              const SizedBox(height: 8),
              GrupoMontos(
                filas: [
                  FilaMonto(
                    etiqueta: Textos.conCuantoEmpezaste(cuenta.nombre),
                    detalle: cuenta.desde == null
                        ? null
                        : Textos.saldoInicialDesde(
                            formatearDiaYMes(cuenta.desde!),
                          ),
                    controlador: _monto,
                    autofocus: true,
                    accionTeclado: TextInputAction.done,
                    alCambiar: (_) => setState(() {}),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                Textos.conEsteCambioTienes(
                  formatearSoles(cuenta.saldoConInicial(nuevo)),
                  cuenta.nombre,
                ),
                style: Tipografia.secundario,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: cambio && !_guardando ? () => _guardar(nuevo) : null,
                child: const Text(Textos.guardar),
              ),
            ] else ...[
              const Text(
                Textos.yaHuboArqueoDeLaCuenta,
                style: Tipografia.secundario,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(Rutas.arqueo);
                },
                child: const Text(Textos.hacerArqueo),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
