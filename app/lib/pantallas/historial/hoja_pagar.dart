import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/campo_monto.dart';
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
  const ResultadoPago({
    required this.cuenta,
    required this.saldoCentimos,
    this.parteCentimos,
    this.faltaCentimos = 0,
  });

  final TipoCuenta cuenta;

  /// Cómo quedó la cuenta.
  final int saldoCentimos;

  /// Un pago en parte (entrega 44): cuánto, y lo que falta.
  final int? parteCentimos;
  final int faltaCentimos;
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

  /// Todo o una parte (entrega 44).
  bool _parte = false;
  final _monto = TextEditingController();
  String? _errorMonto;

  int get _falta => widget.detalle.fila.montoCentimos;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

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
    final parte = _parte ? leerSolesEnCentimos(_monto.text) : null;
    if (_parte && (parte == null || parte <= 0 || parte >= _falta)) {
      setState(
        () => _errorMonto = Textos.parteMenorQue(
          formatearSolesComprobante(_falta),
        ),
      );
      return;
    }
    setState(() {
      _guardando = true;
      _errorMonto = null;
    });
    try {
      final quedaria = await repo.saldoSiSePaga(
        id,
        _cuenta,
        parteCentimos: parte,
      );
      if (quedaria < 0 && mounted && !await _preguntarNegativo(quedaria)) {
        return;
      }
      final saldo = await repo.pagar(
        id,
        cuenta: _cuenta,
        dia: _dia,
        parteCentimos: parte,
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        ResultadoPago(
          cuenta: _cuenta,
          saldoCentimos: saldo,
          parteCentimos: parte,
          faltaCentimos: parte == null ? 0 : _falta - parte,
        ),
      );
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
    // Una venta a crédito se cobra (entrega 42): la plata entra.
    final cobro = widget.detalle.fila.teDeben;
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
            Text(
              cobro ? Textos.yaMePago : Textos.yaLoPague,
              style: Tipografia.tituloPantalla,
            ),
            const SizedBox(height: 16),
            // Todo o una parte (entrega 44).
            const Text(Textos.cuanto, style: etiqueta),
            const SizedBox(height: 8),
            Opciones<bool>(
              opciones: {
                false: Textos.todoElMonto(formatearSolesComprobante(_falta)),
                true: Textos.unaParte,
              },
              elegida: _parte,
              alElegir: (p) => setState(() {
                _parte = p;
                _errorMonto = null;
              }),
            ),
            if (_parte) ...[
              const SizedBox(height: 8),
              GrupoMontos(
                filas: [
                  FilaMonto(
                    etiqueta: Textos.montoDeLaParte,
                    controlador: _monto,
                    autofocus: true,
                    accionTeclado: TextInputAction.done,
                  ),
                ],
              ),
              if (_errorMonto case final error?) ...[
                const SizedBox(height: 6),
                Text(
                  error,
                  style: Tipografia.secundario.copyWith(
                    color: Colores.avisoTexto,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 18),
            Text(
              cobro ? Textos.aDondeEntro : Textos.conQuePagaste,
              style: etiqueta,
            ),
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
            Text(
              cobro ? Textos.cuandoTePago : Textos.cuandoPagaste,
              style: etiqueta,
            ),
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
              child: Text(cobro ? Textos.yaMePago : Textos.yaLoPague),
            ),
          ],
        ),
      ),
    );
  }
}
