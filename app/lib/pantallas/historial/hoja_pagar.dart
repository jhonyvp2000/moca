import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/opciones.dart';
import '../../dominio/historial.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

class ResultadoPago {
  const ResultadoPago({required this.cuenta, required this.saldoCentimos});

  final TipoCuenta cuenta;

  /// Cómo quedó la cuenta.
  final int saldoCentimos;
}

/// «Ya lo pagué» (estado no dibujado, aprobado el 13-10-2026): con qué cuenta
/// y qué día. Se paga completo. Devuelve nulo si se cierra sin pagar.
Future<ResultadoPago?> mostrarHojaPagar(
  BuildContext context,
  DetalleMovimiento detalle,
) => showModalBottomSheet<ResultadoPago>(
  context: context,
  isScrollControlled: true,
  builder: (context) => _HojaPagar(detalle: detalle),
);

enum _Cuando { hoy, ayer, otroDia }

class _HojaPagar extends ConsumerStatefulWidget {
  const _HojaPagar({required this.detalle});

  final DetalleMovimiento detalle;

  @override
  ConsumerState<_HojaPagar> createState() => _EstadoHojaPagar();
}

class _EstadoHojaPagar extends ConsumerState<_HojaPagar> {
  late TipoCuenta _cuenta = widget.detalle.fila.cuenta;
  _Cuando _cuando = _Cuando.hoy;
  DateTime? _otroDia;
  bool _guardando = false;

  DateTime get _hoy {
    final ahora = ref.read(relojProvider)();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  DateTime get _ayer => DateTime(_hoy.year, _hoy.month, _hoy.day - 1);

  DateTime get _primerDia => widget.detalle.primerDiaDePago ?? _hoy;

  DateTime get _dia => switch (_cuando) {
    _Cuando.hoy => _hoy,
    _Cuando.ayer => _ayer,
    _Cuando.otroDia => _otroDia ?? _hoy,
  };

  Future<void> _elegirOtroDia() async {
    final elegido = await showDatePicker(
      context: context,
      firstDate: _primerDia,
      lastDate: _hoy,
      initialDate: _otroDia ?? _hoy,
    );
    if (elegido == null) return;
    setState(() {
      _otroDia = elegido;
      _cuando = elegido == _hoy
          ? _Cuando.hoy
          : elegido == _ayer
          ? _Cuando.ayer
          : _Cuando.otroDia;
    });
  }

  Future<void> _pagar() async {
    final repo = ref.read(repositorioHistorialProvider);
    final id = widget.detalle.fila.id;
    setState(() => _guardando = true);
    try {
      final quedaria = await repo.saldoSiSePaga(id, _cuenta);
      if (quedaria < 0 && mounted && !await _preguntarNegativo(quedaria)) {
        return;
      }
      final saldo = await repo.pagar(id, cuenta: _cuenta, dia: _dia);
      if (!mounted) return;
      Navigator.of(context)
          .pop(ResultadoPago(cuenta: _cuenta, saldoCentimos: saldo));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<bool> _preguntarNegativo(int quedaria) async {
    final seguir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Textos.quedariaNegativoTitulo),
        content: Text(
          Textos.quedariaNegativo(
            Textos.nombreCuenta(_cuenta),
            formatearSoles(quedaria),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Textos.revisar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Textos.guardarIgual),
          ),
        ],
      ),
    );
    return seguir == true;
  }

  @override
  Widget build(BuildContext context) {
    const etiqueta = TextStyle(
      fontFamily: Tipografia.familia,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Colores.textoPrincipal,
    );
    final ayerSePuede = !_ayer.isBefore(_primerDia);
    final otroDiaSePuede = _primerDia.isBefore(_ayer);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          0,
          Medidas.margenLateral,
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(Textos.yaLoPague, style: Tipografia.tituloPantalla),
            const SizedBox(height: 16),
            const Text(Textos.conQuePagaste, style: etiqueta),
            const SizedBox(height: 8),
            OpcionesRejilla<TipoCuenta>(
              opciones: {
                for (final c in ref.watch(tiposDeCuentaProvider))
                  c: Textos.nombreCuenta(c),
              },
              elegida: _cuenta,
              alElegir: (c) => setState(() => _cuenta = c),
            ),
            const SizedBox(height: 18),
            const Text(Textos.cuandoPagaste, style: etiqueta),
            const SizedBox(height: 8),
            Opciones<_Cuando>(
              opciones: {
                _Cuando.hoy: Textos.hoy,
                if (ayerSePuede) _Cuando.ayer: Textos.ayer,
                if (otroDiaSePuede)
                  _Cuando.otroDia:
                      _cuando == _Cuando.otroDia && _otroDia != null
                      ? formatearDiaYMes(_otroDia!)
                      : Textos.otroDia,
              },
              elegida: _cuando,
              alElegir: (cuando) {
                if (cuando == _Cuando.otroDia) {
                  _elegirOtroDia();
                } else {
                  setState(() => _cuando = cuando);
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _pagar,
              child: const Text(Textos.yaLoPague),
            ),
          ],
        ),
      ),
    );
  }
}
