import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/opciones.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/cuentas.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
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
                Container(
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
            ],
          ),
        ),
        if (billeteras.isNotEmpty || bancos.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            Textos.billeteraEmpiezaEnCero,
            style: Tipografia.secundario,
          ),
        ],
        for (final (titulo, opciones) in [
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
                key: Key(
                  _elegida == TipoCuenta.otra
                      ? 'nombre-otra-billetera'
                      : 'nombre-otro-banco',
                ),
                controller: _nombreOtra,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                style: Tipografia.textoFuerte.copyWith(fontSize: 16),
                decoration: InputDecoration(
                  hintText: _elegida == TipoCuenta.otra
                      ? Textos.nombreDeLaBilletera
                      : Textos.nombreDelBanco,
                ),
              ),
            ],
          ],
      ],
      acciones: [
        if (billeteras.isNotEmpty || bancos.isNotEmpty)
          FilledButton(
            onPressed: _sePuedeAgregar ? _agregar : null,
            child: const Text(Textos.agregar),
          ),
      ],
    );
  }
}
