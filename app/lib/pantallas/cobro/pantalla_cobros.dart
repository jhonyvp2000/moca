import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/opciones.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/cobro.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// La pantalla de cobros de Jhony (entrega 26), desde el ajuste oculto. Solo
/// aparece en su teléfono, y el servidor solo le responde a su número.
class PantallaCobros extends ConsumerStatefulWidget {
  const PantallaCobros({super.key});

  @override
  ConsumerState<PantallaCobros> createState() => _EstadoCobros();
}

class _EstadoCobros extends ConsumerState<PantallaCobros> {
  final _celular = TextEditingController();
  ResumenDeCobros? _resumen;
  FichaDeCobro? _ficha;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  @override
  void dispose() {
    _celular.dispose();
    super.dispose();
  }

  String get _digitos => _celular.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _cargarResumen() async {
    final resumen = await ref.read(servicioPagosProvider).resumen();
    if (!mounted) return;
    setState(() {
      _resumen = resumen;
      if (resumen == null) _error = Textos.necesitasSenalParaCobros;
    });
  }

  static String? _mensaje(ResultadoCobro resultado) => switch (resultado) {
    ResultadoCobro.listo => null,
    ResultadoCobro.sinSenal => Textos.necesitasSenalParaCobros,
    ResultadoCobro.sinPermiso => Textos.sinPermisoCobros,
    ResultadoCobro.noEncontrado => Textos.sinNegocioConEseNumero,
    ResultadoCobro.perdioFundador => Textos.perdioFundador,
    ResultadoCobro.sinCupoFundador => Textos.sinCupoFundador,
    ResultadoCobro.error => Textos.noPudimosComprobar,
  };

  Future<void> _buscar(String celular) async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final (ficha, resultado) = await ref
        .read(servicioPagosProvider)
        .buscar(celular);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _ficha = ficha;
      _error = _mensaje(resultado);
    });
  }

  Future<void> _registrar(FichaDeCobro ficha) async {
    final elegido = await showModalBottomSheet<(PlanCobro, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HojaPago(ficha: ficha),
    );
    if (elegido == null || !mounted) return;
    final (plan, nota) = elegido;
    final si = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(
          Textos.confirmarPago(Textos.nombrePlan(plan), ficha.nombre),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text(Textos.registrarPago),
          ),
        ],
      ),
    );
    if (si != true || !mounted) return;
    final mensajes = ScaffoldMessenger.of(context);
    final (nueva, resultado) = await ref
        .read(servicioPagosProvider)
        .registrarPago(ficha.empresaId, plan, nota: nota);
    if (!mounted) return;
    if (nueva != null) {
      mensajes.showSnackBar(
        SnackBar(
          content: Text(
            Textos.pagoRegistrado(
              nueva.cobro.hasta == null
                  ? ''
                  : formatearDiaYMes(nueva.cobro.hasta!),
            ),
          ),
        ),
      );
      // Con los pagos al día.
      if (nueva.celular case final celular?) await _buscar(celular);
      await _cargarResumen();
      return;
    }
    setState(() => _error = _mensaje(resultado));
  }

  @override
  Widget build(BuildContext context) {
    final resumen = _resumen;
    final ficha = _ficha;
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.cobros,
        alVolver: () => context.pop(),
      ),
      contenido: [
        if (resumen != null)
          Text(
            Textos.fundadoresUsados(
              resumen.fundadores,
              resumen.maximoFundadores,
            ),
            style: Tipografia.secundario,
          ),
        const SizedBox(height: 12),
        const Text(Textos.celularDelDueno, style: Tipografia.textoFuerte),
        const SizedBox(height: 8),
        TextField(
          controller: _celular,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixText: '${Textos.prefijoPeru} ',
            hintText: Textos.celularEjemplo,
          ),
        ),
        const SizedBox(height: 8),
        // Los botones del tema ocupan todo el ancho: va debajo.
        OutlinedButton(
          onPressed: _digitos.length == 9 && !_cargando
              ? () => _buscar(_digitos)
              : null,
          child: const Text(Textos.buscar),
        ),
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Aviso(texto: error),
        ],
        if (ficha != null) ...[
          const SizedBox(height: Medidas.separacionTarjetas),
          _Ficha(ficha: ficha, alRegistrar: () => _registrar(ficha)),
        ],
        if (resumen != null) ...[
          const SizedBox(height: 24),
          const Text(Textos.vencenPronto, style: Tipografia.tituloTarjeta),
          const SizedBox(height: 8),
          if (resumen.negocios.isEmpty)
            const Text(Textos.nadaPorVencer, style: Tipografia.secundario)
          else
            Tarjeta(
              relleno: EdgeInsets.zero,
              child: Material(
                color: Colores.superficie,
                borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final n in resumen.negocios)
                      ListTile(
                        title: Text(n.nombre, style: Tipografia.textoFuerte),
                        subtitle: Text(
                          [
                            Textos.estadoCorto(n.cobro),
                            if (n.celular != null) formatearCelular(n.celular!),
                          ].join(' · '),
                          style: Tipografia.secundario,
                        ),
                        onTap: n.celular == null
                            ? null
                            : () {
                                _celular.text = n.celular!;
                                _buscar(n.celular!);
                              },
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
      acciones: const [],
    );
  }
}

/// Un negocio: su estado, sus pagos y su respuesta del día 10.
class _Ficha extends StatelessWidget {
  const _Ficha({required this.ficha, required this.alRegistrar});

  final FichaDeCobro ficha;
  final VoidCallback alRegistrar;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ficha.nombre, style: Tipografia.tituloTarjeta),
          Text(
            [
              Textos.estadoCorto(ficha.cobro),
              if (ficha.celular != null) formatearCelular(ficha.celular!),
            ].join(' · '),
            style: Tipografia.secundario,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: alRegistrar,
            child: const Text(Textos.registrarPago),
          ),
          if (ficha.pagos.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(Textos.pagosRegistrados, style: Tipografia.textoFuerte),
            for (final p in ficha.pagos)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    Textos.pagoDe(
                      formatearSolesComprobante(p.montoCentimos),
                      formatearDiaYMes(p.desde),
                      formatearDiaYMes(p.hasta),
                    ),
                    if (p.nota != null) p.nota!,
                  ].join(' · '),
                  style: Tipografia.secundario,
                ),
              ),
          ],
          if (ficha.respuestas.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(Textos.respuestaDelDia10, style: Tipografia.textoFuerte),
            for (final r in ficha.respuestas)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    Textos.respondio(switch (r.respuesta) {
                      RespuestaPrecio.si => Textos.respuestaSi,
                      RespuestaPrecio.noSe => Textos.respuestaNoSe,
                      RespuestaPrecio.no => Textos.respuestaNo,
                    }, formatearSolesComprobante(r.precioCentimos)),
                    if (r.motivo != null) '«${r.motivo}»',
                  ].join(' · '),
                  style: Tipografia.secundario,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// El plan y la nota del pago.
class _HojaPago extends StatefulWidget {
  const _HojaPago({required this.ficha});

  final FichaDeCobro ficha;

  @override
  State<_HojaPago> createState() => _EstadoHojaPago();
}

class _EstadoHojaPago extends State<_HojaPago> {
  final _nota = TextEditingController();
  late PlanCobro _plan = widget.ficha.cobro.precioCentimos < 1990
      ? PlanCobro.fundador
      : PlanCobro.normal;

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Text(widget.ficha.nombre, style: Tipografia.tituloPantalla),
            const SizedBox(height: 12),
            Opciones<PlanCobro>(
              opciones: {
                for (final p in PlanCobro.values) p: Textos.nombrePlan(p),
              },
              elegida: _plan,
              alElegir: (p) => setState(() => _plan = p),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nota,
              maxLength: 200,
              decoration: const InputDecoration(hintText: Textos.notaDelPago),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context, (_plan, _nota.text)),
              child: const Text(Textos.registrarPago),
            ),
          ],
        ),
      ),
    );
  }
}
