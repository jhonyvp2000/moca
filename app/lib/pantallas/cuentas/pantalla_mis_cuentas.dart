import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/iconos.dart';
import '../../comun/campo_monto.dart';
import '../../comun/estructura.dart';
import '../../comun/opciones.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/cuentas.dart';
import '../../dominio/modelos.dart';
import '../../dominio/movimientos.dart';
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

  /// Volver a usar una cuenta, con su historial (entrega 58).
  Future<void> _volverAUsar(CuentaVista cuenta) async {
    await ref.read(repositorioCuentasProvider).volverAUsar(cuenta.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Textos.volvisteAUsar(cuenta.nombre))),
    );
  }

  /// Dejar de usar una cuenta (entrega 58): nunca Efectivo, solo con S/ 0 y
  /// si no es la caja de nadie del equipo.
  Future<void> _dejarDeUsar(CuentaVista cuenta) async {
    final mensajes = ScaffoldMessenger.of(context);
    if (cuenta.tipo.esCaja) {
      final equipo = await ref.read(servicioEquipoProvider).equipo();
      if (!mounted) return;
      if (equipo == null) {
        await _avisar(Textos.sinSenalParaRevisarCaja);
        return;
      }
      final duena = equipo.personas
          .where((p) => p.cajas.contains(cuenta.id))
          .firstOrNull;
      if (duena != null) {
        await _avisar(Textos.esLaCajaDe(duena.nombre ?? Textos.otraPersona));
        return;
      }
    }
    final saldo = cuenta.saldoCentimos ?? 0;
    if (saldo != 0) {
      await _ofrecerPase(cuenta, saldo);
      return;
    }
    final seguro = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(Textos.preguntaDejarDeUsar(cuenta.nombre)),
        content: const Text(Textos.dejarDeUsarDetalle, style: Tipografia.texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text(Textos.cancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: const Text(Textos.dejarDeUsar),
          ),
        ],
      ),
    );
    if (seguro != true || !mounted) return;
    final resultado = await ref
        .read(repositorioCuentasProvider)
        .dejarDeUsar(cuenta.id);
    if (resultado == ResultadoDejarDeUsar.listo) {
      mensajes.showSnackBar(
        SnackBar(content: Text(Textos.dejasteDeUsar(cuenta.nombre))),
      );
    }
  }

  Future<void> _avisar(String texto) => showDialog<void>(
    context: context,
    builder: (dialogo) => AlertDialog(
      content: Text(texto, style: Tipografia.texto),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogo).pop(),
          child: const Text(Textos.entendido),
        ),
      ],
    ),
  );

  /// Con plata, primero se pasa a otra cuenta: el pase ya armado.
  Future<void> _ofrecerPase(CuentaVista cuenta, int saldo) async {
    final pasar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        content: Text(
          Textos.cuentaConSaldo(
            cuenta.nombre,
            formatearSolesComprobante(saldo),
          ),
          style: Tipografia.texto,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text(Textos.cancelar),
          ),
          if (saldo > 0)
            FilledButton(
              onPressed: () => Navigator.of(dialogo).pop(true),
              child: const Text(Textos.pasarLaPlata),
            ),
        ],
      ),
    );
    if (pasar != true || !mounted) return;
    await context.push(
      Rutas.escribir,
      extra: BorradorMovimiento(
        tipo: TipoMovimiento.transferencia,
        cuenta: cuenta.tipo,
        // Sin céntimos, el monto ya va puesto; con céntimos, se escribe.
        montoCentimos: saldo % 100 == 0 ? saldo : null,
      ),
    );
  }

  /// Corregir el saldo con el que empezó, o por qué ya no (entrega 16.2),
  /// y dejar de usarla (entrega 58).
  Future<void> _abrirCuenta(CuentaVista cuenta) async {
    final corregida = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HojaSaldoInicial(cuenta: cuenta),
    );
    if (corregida == _HojaSaldoInicial.dejarDeUsar && mounted) {
      await _dejarDeUsar(cuenta);
      return;
    }
    if (corregida == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Textos.saldoInicialCorregido(cuenta.nombre))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todas = ref.watch(cuentasProvider).value ?? const <CuentaVista>[];
    // Las que se dejaron de usar van aparte, abajo (entrega 58).
    final cuentas = [
      for (final c in todas)
        if (c.enUso) c,
    ];
    final enDesuso = [
      for (final c in todas)
        if (!c.enUso) c,
    ];
    Map<TipoCuenta, String> faltan(List<TipoCuenta> tipos) => {
      for (final t in tipos)
        if (!todas.any((c) => c.tipo == t))
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
    ].where((t) => !todas.any((c) => c.tipo == t)).firstOrNull;
    final cajas = {?siguienteCaja: Textos.otraCaja};
    final hayQueAgregar =
        billeteras.isNotEmpty || bancos.isNotEmpty || cajas.isNotEmpty;
    const etiqueta = Tipografia.tituloSeccion;

    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.misCuentas,
        alVolver: () => context.pop(),
      ),
      contenido: [
        // De qué periodo es (entrega 36).
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            Textos.saldosDesdeQueEmpezaste,
            style: Tipografia.secundario,
          ),
        ),
        Tarjeta(
          relleno: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, c) in cuentas.indexed)
                InkWell(
                  // El saldo pendiente se pone como siempre, en el Inicio;
                  // la hoja sirve también para dejar de usarla (entrega 58).
                  onTap:
                      c.inicialCentimos == null && c.tipo == TipoCuenta.efectivo
                      ? null
                      : () => _abrirCuenta(c),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: Medidas.objetivoTactilMinimo,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Medidas.e4,
                      vertical: Medidas.e3,
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
                        // El icono de la cuenta, como en el Inicio (mejora 01).
                        ExcludeSemantics(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Iconos.coloresDeCuenta(c.tipo).$2,
                              borderRadius: BorderRadius.circular(
                                Medidas.radioChico,
                              ),
                            ),
                            child: Icon(
                              Iconos.deCuenta(c.tipo),
                              size: 22,
                              color: Iconos.coloresDeCuenta(c.tipo).$1,
                            ),
                          ),
                        ),
                        const SizedBox(width: Medidas.e3),
                        Expanded(
                          child: Text(c.nombre, style: Tipografia.textoFuerte),
                        ),
                        Text(
                          c.saldoCentimos == null
                              ? Textos.saldoPorPoner
                              : formatearSoles(c.saldoCentimos!),
                          style: c.saldoCentimos == null
                              ? Tipografia.secundario
                              : Tipografia.cifra(Tipografia.tituloTarjeta),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // «Ya no usas», con «Volver a usar» (entrega 58).
        if (enDesuso.isNotEmpty) ...[
          const SizedBox(height: Medidas.e5),
          const Text(Textos.yaNoUsas, style: Tipografia.tituloSeccion),
          const SizedBox(height: Medidas.e1),
          const Text(Textos.yaNoUsasDetalle, style: Tipografia.secundario),
          const SizedBox(height: Medidas.e2),
          Tarjeta(
            relleno: EdgeInsets.zero,
            child: Column(
              children: [
                for (final c in enDesuso)
                  ListTile(
                    minTileHeight: Medidas.objetivoTactilMinimo,
                    leading: Icon(
                      Iconos.deCuenta(c.tipo),
                      color: Colores.neutro,
                    ),
                    title: Text(
                      c.nombre,
                      style: Tipografia.textoFuerte.copyWith(
                        color: Colores.textoSecundario,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () => _volverAUsar(c),
                      child: const Text(Textos.volverAUsar),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
            const SizedBox(height: Medidas.e3),
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
              const SizedBox(height: Medidas.e3),
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
                style: Tipografia.tituloTarjeta,
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

  /// Lo que devuelve la hoja al tocar «Dejar de usar esta cuenta».
  static const dejarDeUsar = 'dejar_de_usar';

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
            if (cuenta.inicialCentimos == null)
              const SizedBox.shrink()
            else if (cuenta.seCorrigeElInicial) ...[
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
              const SizedBox(height: Medidas.e3),
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
            // Efectivo no se deja de usar: todo negocio tiene caja.
            if (cuenta.tipo != TipoCuenta.efectivo) ...[
              const SizedBox(height: Medidas.e3),
              const Divider(),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_HojaSaldoInicial.dejarDeUsar),
                style: TextButton.styleFrom(
                  foregroundColor: Colores.textoSecundario,
                ),
                child: const Text(Textos.dejarDeUsarEstaCuenta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
