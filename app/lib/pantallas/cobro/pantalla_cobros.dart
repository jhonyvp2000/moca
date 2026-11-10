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

  /// Los negocios del número buscado, cuando es más de uno (entrega 47).
  List<NegocioDeSoporte> _negocios = const [];
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
    ResultadoCobro.noEsElUltimo => Textos.noEsElUltimoPago,
    ResultadoCobro.yaPago => Textos.yaPagoSoporte,
    ResultadoCobro.demasiadosDias => Textos.demasiadosDiasSoporte,
    ResultadoCobro.sinConfirmacion => Textos.nombreNoCoincide,
    ResultadoCobro.error => Textos.noPudimosComprobar,
  };

  /// Cualquier número (entrega 47): si no tiene cuenta, lo dice; con un
  /// solo negocio, abre su ficha; con varios, los lista.
  Future<void> _buscar(String celular) async {
    setState(() {
      _cargando = true;
      _error = null;
      _ficha = null;
      _negocios = const [];
    });
    final (busqueda, resultado) = await ref
        .read(servicioPagosProvider)
        .buscarNumero(celular);
    if (!mounted) return;
    if (busqueda == null) {
      setState(() {
        _cargando = false;
        _error = _mensaje(resultado);
      });
      return;
    }
    if (busqueda.negocios.length == 1) {
      await _abrir(busqueda.negocios.single.empresaId);
      return;
    }
    setState(() {
      _cargando = false;
      _negocios = busqueda.negocios;
      _error = !busqueda.tieneCuenta
          ? Textos.numeroSinCuenta47
          : busqueda.negocios.isEmpty
          ? Textos.sinNegociosActivos
          : null;
    });
  }

  Future<void> _abrir(String empresaId) async {
    setState(() => _cargando = true);
    final (ficha, resultado) = await ref
        .read(servicioPagosProvider)
        .fichaDeNegocio(empresaId);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _ficha = ficha;
      _error = _mensaje(resultado);
    });
  }

  Future<void> _darDias(FichaDeCobro ficha) async {
    final dias = await showDialog<int>(
      context: context,
      builder: (contexto) => SimpleDialog(
        title: const Text(Textos.darDiasDePrueba),
        children: [
          for (final d in const [7, 14])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(contexto, d),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(Textos.diasDePrueba(d), style: Tipografia.texto),
              ),
            ),
        ],
      ),
    );
    if (dias == null || !mounted) return;
    final mensajes = ScaffoldMessenger.of(context);
    final (nueva, resultado) = await ref
        .read(servicioPagosProvider)
        .darDiasDePrueba(ficha.empresaId, dias);
    if (!mounted) return;
    if (nueva == null) {
      setState(() => _error = _mensaje(resultado));
      return;
    }
    mensajes.showSnackBar(
      SnackBar(
        content: Text(
          Textos.diasDadosHasta(
            nueva.cobro.hasta == null
                ? ''
                : formatearDiaYMes(nueva.cobro.hasta!),
          ),
        ),
      ),
    );
    await _abrir(ficha.empresaId);
  }

  Future<void> _borrar(FichaDeCobro ficha) async {
    final confirmacion = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoBorrar(nombre: ficha.nombre),
    );
    if (confirmacion == null || !mounted) return;
    final mensajes = ScaffoldMessenger.of(context);
    final resultado = await ref
        .read(servicioPagosProvider)
        .borrarNegocio(ficha.empresaId, confirmacion);
    if (!mounted) return;
    if (resultado != ResultadoCobro.listo) {
      setState(() => _error = _mensaje(resultado));
      return;
    }
    mensajes.showSnackBar(
      const SnackBar(content: Text(Textos.negocioBorrado47)),
    );
    setState(() => _ficha = null);
    await _cargarResumen();
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

  Future<void> _anular(PagoRegistrado pago) async {
    final si = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text(Textos.anularPagoPregunta),
        content: Text(
          '${Textos.pagoDe(formatearSolesComprobante(pago.montoCentimos), formatearDiaYMes(pago.desde), formatearDiaYMes(pago.hasta))}\n\n'
          '${Textos.anularPagoDetalle}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text(Textos.anularPago),
          ),
        ],
      ),
    );
    if (si != true || !mounted) return;
    final mensajes = ScaffoldMessenger.of(context);
    final (nueva, resultado) = await ref
        .read(servicioPagosProvider)
        .anularPago(pago.id);
    if (!mounted) return;
    if (nueva == null) {
      setState(() => _error = _mensaje(resultado));
      return;
    }
    mensajes.showSnackBar(const SnackBar(content: Text(Textos.pagoAnulado)));
    if (nueva.celular case final celular?) await _buscar(celular);
    await _cargarResumen();
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
        // Los negocios del número, si es más de uno (entrega 47).
        if (_negocios.length > 1) ...[
          const SizedBox(height: 12),
          const Text(Textos.enQueNegocios, style: Tipografia.textoFuerte),
          for (final n in _negocios)
            ListTile(
              title: Text(
                Textos.negocioYRolSoporte(n.nombre, n.rol, n.titular),
                style: Tipografia.texto,
              ),
              onTap: () => _abrir(n.empresaId),
            ),
        ],
        if (ficha != null) ...[
          const SizedBox(height: Medidas.separacionTarjetas),
          _Ficha(
            ficha: ficha,
            alRegistrar: () => _registrar(ficha),
            alAnular: _anular,
            alDarDias: () => _darDias(ficha),
            alBorrar: () => _borrar(ficha),
          ),
        ],
        // Lo que Mercado Pago cobró y no se aplicó solo (entrega 32).
        if (resumen != null && resumen.porRevisar.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(Textos.pagosPorRevisar, style: Tipografia.tituloTarjeta),
          const SizedBox(height: 8),
          for (final p in resumen.porRevisar)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                [
                  p.nombre,
                  if (p.celular != null) formatearCelular(p.celular!),
                  formatearSolesComprobante(p.montoCentimos),
                  if (p.operacion != null) 'op ${p.operacion}',
                  Textos.motivoPorRevisar(p.motivo),
                ].join(' · '),
                style: Tipografia.secundario,
              ),
            ),
        ],
        if (resumen != null) ...[
          const SizedBox(height: 24),
          const Text(Textos.sinAbrirMoca, style: Tipografia.tituloTarjeta),
          const SizedBox(height: 8),
          if (resumen.sinAbrir.isEmpty)
            const Text(Textos.todosAbren, style: Tipografia.secundario)
          else
            for (final n in resumen.sinAbrir)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  onTap: n.celular == null
                      ? null
                      : () {
                          _celular.text = n.celular!;
                          _buscar(n.celular!);
                        },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: Medidas.objetivoTactilMinimo,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        [
                          n.nombre,
                          if (n.celular != null) formatearCelular(n.celular!),
                          n.ultimaApertura == null
                              ? Textos.nuncaAbrio
                              : formatearDiaYMes(n.ultimaApertura!),
                        ].join(' · '),
                        style: Tipografia.secundario,
                      ),
                    ),
                  ),
                ),
              ),
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
  const _Ficha({
    required this.ficha,
    required this.alRegistrar,
    required this.alAnular,
    required this.alDarDias,
    required this.alBorrar,
  });

  final FichaDeCobro ficha;
  final VoidCallback alRegistrar;
  final ValueChanged<PagoRegistrado> alAnular;
  final VoidCallback alDarDias;
  final VoidCallback alBorrar;

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
          // Días de regalo, solo a quien nunca pagó (entrega 47).
          if (ficha.cobro.plan == null &&
              (ficha.cobro.estado == EstadoDelCobro.prueba ||
                  ficha.cobro.estado == EstadoDelCobro.vencido)) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: alDarDias,
              child: const Text(Textos.darDiasDePrueba),
            ),
          ],
          // Quiénes están, con su versión y su última subida (entrega 47).
          if (ficha.personas.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              [
                Textos.personasSoporte,
                if (ficha.registros case final n?) Textos.registrosSoporte(n),
              ].join(' · '),
              style: Tipografia.textoFuerte,
            ),
            for (final p in ficha.personas)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  Textos.personaSoporte(
                    rol: p.rol,
                    titular: p.titular,
                    nombre: p.nombre,
                    celular: p.celular == null
                        ? null
                        : formatearCelular(p.celular!),
                    version: p.version,
                    subio: p.subioEn == null
                        ? null
                        : formatearDiaYMes(p.subioEn!),
                  ),
                  style: Tipografia.secundario,
                ),
              ),
          ],
          if (ficha.invitaciones.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              Textos.invitacionesSoporte,
              style: Tipografia.textoFuerte,
            ),
            for (final i in ficha.invitaciones)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  Textos.invitacionSoporte(
                    formatearCelular(i.celular),
                    i.rol,
                    i.estado,
                    i.nombre,
                  ),
                  style: Tipografia.secundario,
                ),
              ),
          ],
          if (ficha.uso case final uso?) ...[
            const SizedBox(height: 16),
            const Text(Textos.usoDeLaSemana, style: Tipografia.textoFuerte),
            for (final linea in [
              Textos.usoDias(uso.diasQueAbrio, uso.diasQueAnoto),
              Textos.usoVentas(uso.ventasAnotadas, uso.segundosParaAnotar),
              Textos.usoVoz(
                uso.vozConDuda,
                uso.vozCorregida,
                uso.fotosIlegibles,
              ),
              Textos.usoAvisos(uso.avisosRespondidos, uso.avisosAbiertos),
              Textos.usoAbrio(uso.arqueosAbiertos, uso.informesAbiertos),
              uso.ultimaApertura == null
                  ? Textos.nuncaAbrio
                  : Textos.ultimaVezQueAbrio(
                      formatearDiaYMes(uso.ultimaApertura!),
                    ),
            ])
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(linea, style: Tipografia.secundario),
              ),
          ],
          if (ficha.pagos.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(Textos.pagosRegistrados, style: Tipografia.textoFuerte),
            for (final p in ficha.pagos)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        Textos.pagoDe(
                          formatearSolesComprobante(p.montoCentimos),
                          formatearDiaYMes(p.desde),
                          formatearDiaYMes(p.hasta),
                        ),
                        // El plan y sus personas extra (entrega 43).
                        Textos.planDelPago(p.plan, p.personasExtra),
                        if (p.nota != null) p.nota!,
                        if (p.anulado) Textos.anulado,
                      ].join(' · '),
                      style: Tipografia.secundario.copyWith(
                        decoration: p.anulado
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  // Solo el último pago vigente (vienen del más nuevo al
                  // más viejo).
                  if (p == ficha.pagos.where((x) => !x.anulado).firstOrNull)
                    TextButton(
                      onPressed: () => alAnular(p),
                      child: const Text(Textos.anularPago),
                    ),
                ],
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
          // A pedido del titular (entrega 47).
          const SizedBox(height: 16),
          TextButton(
            onPressed: alBorrar,
            child: const Text(Textos.borrarElNegocio),
          ),
        ],
      ),
    );
  }
}

/// Confirmar el borrado escribiendo el nombre del negocio (entrega 47).
/// Es su propio widget para que el campo viva lo mismo que el diálogo.
class _DialogoBorrar extends StatefulWidget {
  const _DialogoBorrar({required this.nombre});

  final String nombre;

  @override
  State<_DialogoBorrar> createState() => _EstadoDialogoBorrar();
}

class _EstadoDialogoBorrar extends State<_DialogoBorrar> {
  final _escrito = TextEditingController();

  @override
  void dispose() {
    _escrito.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text(Textos.borrarElNegocio),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          Textos.borrarElNegocioDetalle(widget.nombre),
          style: Tipografia.texto,
        ),
        const SizedBox(height: 12),
        TextField(controller: _escrito),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(Textos.cancelar),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _escrito.text),
        child: const Text(Textos.borrar),
      ),
    ],
  );
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

  /// Viene el plan que tiene, o el Full que le toca (entrega 43).
  late PlanCobro _plan = widget.ficha.cobro.nivel == NivelDePlan.basico
      ? PlanCobro.basico
      : widget.ficha.cobro.full.plan;

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
            const SizedBox(height: 8),
            // Con las personas de hoy: lo que se registra.
            Text(
              Textos.totalConPersonas(
                widget.ficha.cobro.personas,
                formatearSolesComprobante(
                  precioConExtras(_plan, widget.ficha.cobro.personas),
                ),
              ),
              style: Tipografia.textoFuerte,
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
