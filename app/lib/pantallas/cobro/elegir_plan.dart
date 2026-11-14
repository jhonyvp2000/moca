import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/cobro.dart';
import '../../dominio/google_play.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import 'cobro.dart';

/// Los nombres de las dos pantallas, para volver de una vez al pagar.
const rutaElegirPlan = 'elegir_plan';
const rutaPagarPlan = 'pagar_plan';

/// «Elige tu plan» (entrega 60; mockup aprobado): Mensual o Anual, el Full
/// primero y recomendado, el Básico debajo, cada uno con lo que incluye.
class PantallaElegirPlan extends ConsumerStatefulWidget {
  const PantallaElegirPlan({super.key, required this.cobro});

  final Cobro cobro;

  @override
  ConsumerState<PantallaElegirPlan> createState() => _EstadoElegirPlan();
}

class _EstadoElegirPlan extends ConsumerState<PantallaElegirPlan> {
  Cobro get cobro => widget.cobro;

  /// Viene el periodo del plan que tiene, si es anual.
  late PeriodoDePlan _periodo =
      (cobro.plan == 'anual' || cobro.plan == 'basico_anual') && cobro.hayAnual
      ? PeriodoDePlan.anio
      : PeriodoDePlan.mes;

  bool get _anual => _periodo == PeriodoDePlan.anio;

  void _elegir(OpcionDePlan opcion) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: rutaPagarPlan),
      builder: (_) => PantallaPagarPlan(cobro: cobro, opcion: opcion),
    ),
  );

  String? get _aviso => switch (cobro.estado) {
    EstadoDelCobro.prueba when cobro.dias != null => Textos.avisoPruebaPlanes(
      cobro.dias! + 1,
    ),
    EstadoDelCobro.vencido => Textos.avisoVencidoPlanes,
    EstadoDelCobro.pagado when cobro.hasta != null => Textos.pagadaHastaPlanes(
      formatearDiaYMes(cobro.hasta!),
    ),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final full = cobro.opcion(NivelDePlan.full, _periodo) ?? cobro.full;
    final basico = cobro.opcion(NivelDePlan.basico, _periodo);
    final pagado = cobro.estado == EstadoDelCobro.pagado;
    final aviso = _aviso;
    return Scaffold(
      backgroundColor: Colores.fondo,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.margenLateral,
            Medidas.e3,
            Medidas.margenLateral,
            Medidas.e6,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: Textos.cerrar,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
                const SizedBox(width: Medidas.e2),
                Expanded(
                  child: Text(Textos.eligeTuPlan, style: Tipografia.encabezado),
                ),
              ],
            ),
            if (aviso != null) ...[
              const SizedBox(height: Medidas.e3),
              Container(
                padding: const EdgeInsets.all(Medidas.e4),
                decoration: BoxDecoration(
                  color: Colores.pendienteFondo,
                  borderRadius: BorderRadius.circular(Medidas.radioMedio),
                ),
                child: Text(
                  aviso,
                  style: Tipografia.texto.copyWith(
                    color: Colores.avisoTextoFuerte,
                  ),
                ),
              ),
            ],
            // Mensual o Anual, si el servidor ya ofrece el año.
            if (cobro.hayAnual) ...[
              const SizedBox(height: Medidas.e4),
              SegmentedButton<PeriodoDePlan>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: PeriodoDePlan.mes,
                    label: Text(Textos.mensual),
                  ),
                  ButtonSegment(
                    value: PeriodoDePlan.anio,
                    label: Text(Textos.anual),
                  ),
                ],
                selected: {_periodo},
                onSelectionChanged: (p) => setState(() => _periodo = p.first),
              ),
              const SizedBox(height: Medidas.e1),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(Textos.ahorrasDosMeses, style: Tipografia.apoyo),
              ),
            ],
            const SizedBox(height: Medidas.e4),
            _TarjetaPlan(
              recomendado: true,
              nombre: Textos.planFull,
              para: Textos.fullPara,
              opcion: full,
              anual: _anual,
              esTuPlan: pagado && cobro.nivel == NivelDePlan.full,
              nota: full.plan == PlanCobro.fundador
                  ? Textos.tuPrecioDeSiempre
                  : null,
              boton: Textos.elegirFull,
              personas: cobro.personas,
              alElegir: () => _elegir(full),
              incluye: const [
                (true, Textos.fullTresPersonas),
                (true, Textos.fullCredito),
                (true, Textos.fullTodoElBasico),
              ],
            ),
            if (basico != null) ...[
              const SizedBox(height: Medidas.separacionTarjetas),
              _TarjetaPlan(
                recomendado: false,
                nombre: Textos.planBasico,
                para: Textos.basicoPara,
                opcion: basico,
                anual: _anual,
                esTuPlan: pagado && cobro.nivel == NivelDePlan.basico,
                boton: Textos.elegirBasico,
                personas: cobro.personas,
                // Con varias personas el Básico puede salir más caro: se
                // dice, como antes (entrega 43).
                fullMasBarato: full.precioCentimos <= basico.precioCentimos
                    ? full.precioCentimos
                    : null,
                alElegir: () => _elegir(basico),
                incluye: [
                  (true, Textos.basicoUnaPersona),
                  for (final t in Textos.basicoIncluye) (true, t),
                  (false, Textos.basicoSinCredito),
                ],
              ),
            ],
            const SizedBox(height: Medidas.e5),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 20,
                  color: Colores.textoSecundario,
                ),
                SizedBox(width: Medidas.e2),
                Expanded(
                  child: Text(Textos.pieDePlanes, style: Tipografia.secundario),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaPlan extends StatelessWidget {
  const _TarjetaPlan({
    required this.recomendado,
    required this.nombre,
    required this.para,
    required this.opcion,
    required this.anual,
    required this.esTuPlan,
    required this.boton,
    required this.alElegir,
    required this.incluye,
    required this.personas,
    this.nota,
    this.fullMasBarato,
  });

  /// Personas del negocio, sin el contador.
  final int personas;

  /// Lo que costaría el Full, si sale igual o más barato que este.
  final int? fullMasBarato;

  final bool recomendado;
  final String nombre;
  final String para;
  final OpcionDePlan opcion;
  final bool anual;
  final bool esTuPlan;
  final String boton;
  final VoidCallback alElegir;

  /// Lo que incluye: verdadero con ✓, falso con ✕.
  final List<(bool, String)> incluye;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final base = opcion.precioBaseCentimos;
    // Al año: cuánto sale al mes y cuánto ahorra frente a 12 meses.
    final mensual = anual
        ? precioDelPlan(
            opcion.nivel == NivelDePlan.basico
                ? PlanCobro.basico
                : PlanCobro.normal,
          )
        : null;
    final etiqueta = esTuPlan
        ? Textos.tuPlan
        : recomendado
        ? Textos.recomendado
        : null;
    return Container(
      padding: const EdgeInsets.all(Medidas.e5),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Medidas.radioMayor),
        border: Border.all(
          color: recomendado ? Colores.marca : Colores.bordeTarjeta,
          width: recomendado ? 2 : 1,
        ),
        boxShadow: recomendado ? Sombras.nivel2 : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(nombre, style: Tipografia.encabezado)),
              if (etiqueta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Medidas.e3,
                    vertical: Medidas.e1,
                  ),
                  decoration: BoxDecoration(
                    color: Colores.marca,
                    borderRadius: BorderRadius.circular(Medidas.radioPildora),
                  ),
                  child: Text(
                    etiqueta,
                    style: Tipografia.apoyo.copyWith(
                      color: Colores.sobreMarca,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Medidas.e1),
          Text(para, style: Tipografia.secundario),
          const SizedBox(height: Medidas.e3),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: Medidas.e2,
            children: [
              Text(
                formatearSolesComprobante(base),
                style: Tipografia.cifra(Tipografia.montoDetalle),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  anual ? Textos.alAnio : Textos.alMes,
                  style: Tipografia.secundario,
                ),
              ),
            ],
          ),
          if (nota != null)
            Text(nota!, style: Tipografia.apoyo.copyWith(color: Colores.marca)),
          if (mensual != null)
            Text(
              Textos.equivaleAlMes(
                formatearSolesComprobante((base / 12).round()),
                formatearSolesComprobante(mensual * 12 - base),
              ),
              style: Tipografia.cifra(
                Tipografia.apoyo.copyWith(color: Colores.pendienteTexto),
              ),
            ),
          // Con más personas de las que incluye, lo que pagaría de verdad.
          if (opcion.extras > 0)
            Text(
              Textos.conTusPersonas(
                personas,
                formatearSolesComprobante(opcion.precioCentimos),
                anual: anual,
              ),
              style: Tipografia.cifra(Tipografia.textoFuerte),
            ),
          if (fullMasBarato case final precio?) ...[
            const SizedBox(height: Medidas.e2),
            Text(
              Textos.conFullPagasMenos(
                formatearSolesComprobante(precio),
                anual: anual,
              ),
              style: Tipografia.textoFuerte.copyWith(color: Colores.azulOscuro),
            ),
          ],
          const SizedBox(height: Medidas.e4),
          if (recomendado)
            FilledButton(onPressed: alElegir, child: Text(boton))
          else
            OutlinedButton(onPressed: alElegir, child: Text(boton)),
          const SizedBox(height: Medidas.e4),
          const Divider(height: 1),
          const SizedBox(height: Medidas.e3),
          for (final (si, texto) in incluye)
            Padding(
              padding: const EdgeInsets.only(bottom: Medidas.e2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    si ? Icons.check_rounded : Icons.close_rounded,
                    size: 20,
                    color: si ? Colores.marca : Colores.neutro,
                    semanticLabel: si ? null : Textos.noIncluye,
                  ),
                  const SizedBox(width: Medidas.e2),
                  Expanded(
                    child: Text(
                      texto,
                      style: Tipografia.texto.copyWith(
                        color: si ? null : Colores.neutro,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            Textos.cadaPersonaMas(
              anual ? 'S/ 34.80 ${Textos.alAnio}' : 'S/ 2.90 ${Textos.alMes}',
            ),
            style: Tipografia.secundario,
          ),
        ],
      ),
    );
  }
}

/// «Pagar tu plan» (entrega 60): el resumen, Mercado Pago primero (se
/// activa solo) y el Yape directo aparte, porque una persona lo revisa.
class PantallaPagarPlan extends ConsumerStatefulWidget {
  const PantallaPagarPlan({
    super.key,
    required this.cobro,
    required this.opcion,
  });

  final Cobro cobro;
  final OpcionDePlan opcion;

  @override
  ConsumerState<PantallaPagarPlan> createState() => _EstadoPagarPlan();
}

class _EstadoPagarPlan extends ConsumerState<PantallaPagarPlan> {
  Cobro get cobro => widget.cobro;
  OpcionDePlan get opcion => widget.opcion;

  /// Sin Mercado Pago, el Yape va abierto: es la única forma.
  late bool _conYape = !cobro.mercadoPago;

  String get _nombrePlan => Textos.planYPeriodo(
    opcion.nivel == NivelDePlan.basico ? Textos.planBasico : Textos.planFull,
    anual: opcion.periodo == PeriodoDePlan.anio,
  );

  Future<void> _mandarCaptura() async {
    final mensajes = ScaffoldMessenger.of(context);
    final negocio =
        ref.read(resumenInicioProvider).value?.nombreNegocio ?? 'mi negocio';
    final celular = ref.read(situacionCuentaProvider).value?.celular;
    final texto = Textos.mensajeDePago(
      negocio,
      celular == null ? '' : formatearCelular(celular),
      _nombrePlan,
    );
    // Con %20 y no «+»: WhatsApp muestra los «+» tal cual.
    final enlace =
        'https://wa.me/51${cobro.yape}?text=${Uri.encodeComponent(texto)}';
    if (!await ref.read(abridorProvider).abrir(enlace)) {
      mensajes.showSnackBar(
        const SnackBar(content: Text(Textos.noSeAbrioWhatsApp)),
      );
    }
  }

  Widget _fila(String etiqueta, String valor, {bool fuerte = false}) => Padding(
    padding: const EdgeInsets.only(bottom: Medidas.e2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: fuerte ? Tipografia.tituloFila : Tipografia.secundario,
          ),
        ),
        Text(
          valor,
          style: Tipografia.cifra(
            fuerte ? Tipografia.tituloFila : Tipografia.textoFuerte,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final anual = opcion.periodo == PeriodoDePlan.anio;
    final precio = formatearSolesComprobante(opcion.precioCentimos);
    final extras = opcion.precioCentimos - opcion.precioBaseCentimos;
    final cubre = cobro.periodoQueCubre(
      ref.read(relojProvider)(),
      opcion.periodo,
    );
    // En la versión de Play no se nombran otros medios de pago (entrega 77).
    final dePlay = ref.read(versionInstaladaProvider).dePlay;
    final mercadoPago = cobro.mercadoPago && !dePlay;
    final yape = dePlay ? null : cobro.yape;
    final nombre = cobro.nombreYape;
    return Scaffold(
      backgroundColor: Colores.fondo,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Medidas.margenLateral,
            Medidas.e3,
            Medidas.margenLateral,
            Medidas.e6,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: Textos.volver,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: Medidas.e2),
                Expanded(
                  child: Text(Textos.pagarTuPlan, style: Tipografia.encabezado),
                ),
              ],
            ),
            const SizedBox(height: Medidas.e3),
            Container(
              padding: const EdgeInsets.all(Medidas.e5),
              decoration: BoxDecoration(
                color: Colores.superficie,
                borderRadius: BorderRadius.circular(Medidas.radioGrande),
                boxShadow: Sombras.nivel1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _fila(Textos.etiquetaPlan, _nombrePlan),
                  _fila(
                    Textos.personasIncluidasEnPlan(
                      personasIncluidas(opcion.plan),
                    ),
                    formatearSolesComprobante(opcion.precioBaseCentimos),
                  ),
                  if (opcion.extras > 0)
                    _fila(
                      Textos.personasDeMas(opcion.extras),
                      formatearSolesComprobante(extras),
                    ),
                  const Divider(height: Medidas.e4),
                  _fila(
                    anual ? Textos.totalAlAnio : Textos.totalAlMes,
                    precio,
                    fuerte: true,
                  ),
                  Text(
                    Textos.cubreDelAl(
                      formatearDiaYMes(cubre.desde),
                      formatearDiaYMes(cubre.hasta),
                    ),
                    style: Tipografia.secundario,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Medidas.e4),
            // Mercado Pago, grande: se activa solo (entrega 60).
            if (mercadoPago)
              Container(
                padding: const EdgeInsets.all(Medidas.e5),
                decoration: BoxDecoration(
                  color: Colores.superficie,
                  borderRadius: BorderRadius.circular(Medidas.radioMayor),
                  border: Border.all(color: Colores.marca, width: 2),
                  boxShadow: Sombras.nivel2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colores.marca),
                        const SizedBox(width: Medidas.e2),
                        Expanded(
                          child: Text(
                            Textos.seActivaAlInstante,
                            style: Tipografia.tituloFila,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Medidas.e2),
                    const Text(
                      Textos.mercadoPagoExplica,
                      style: Tipografia.secundario,
                    ),
                    const SizedBox(height: Medidas.e4),
                    FilledButton(
                      onPressed: () => pagarConMercadoPago(
                        context,
                        nivel: opcion.nivel,
                        periodo: opcion.periodo,
                      ),
                      child: Text(Textos.pagarMontoConMercadoPago(precio)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: Medidas.e4),
            // El Yape directo, aparte: lo activa una persona.
            if (dePlay)
              _PagarConGoogle(cobro: cobro, opcion: opcion, precio: precio)
            else if (yape == null || nombre == null)
              (mercadoPago
                  ? const SizedBox.shrink()
                  : const Text(Textos.pagoSinDatos, style: Tipografia.texto))
            else
              Container(
                padding: const EdgeInsets.all(Medidas.e4),
                decoration: BoxDecoration(
                  color: Colores.superficie,
                  borderRadius: BorderRadius.circular(Medidas.radioGrande),
                  boxShadow: Sombras.nivel1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      Textos.prefieresYapear,
                      style: Tipografia.textoFuerte,
                    ),
                    const SizedBox(height: Medidas.e1),
                    const Text(
                      Textos.yapeTardaMas,
                      style: Tipografia.secundario,
                    ),
                    if (!_conYape)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => setState(() => _conYape = true),
                          child: const Text(Textos.verComoYapear),
                        ),
                      )
                    else ...[
                      const SizedBox(height: Medidas.e3),
                      Text(
                        Textos.yapeaA(precio, formatearCelular(yape), nombre),
                        style: Tipografia.textoFuerte,
                      ),
                      const SizedBox(height: Medidas.e2),
                      const Text(
                        Textos.luegoMandaLaCaptura,
                        style: Tipografia.texto,
                      ),
                      const SizedBox(height: Medidas.e3),
                      OutlinedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: yape));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text(Textos.numeroCopiado)),
                          );
                        },
                        child: const Text(Textos.copiarElNumero),
                      ),
                      const SizedBox(height: Medidas.e2),
                      if (mercadoPago)
                        OutlinedButton(
                          onPressed: _mandarCaptura,
                          child: const Text(Textos.mandarLaCaptura),
                        )
                      else
                        FilledButton(
                          onPressed: _mandarCaptura,
                          child: const Text(Textos.mandarLaCaptura),
                        ),
                    ],
                  ],
                ),
              ),
            if (mercadoPago) ...[
              const SizedBox(height: Medidas.e5),
              const Text(
                Textos.mercadoPagoSinTarjeta,
                style: Tipografia.secundario,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// La versión de Play Store (entrega 80): se paga con Google Play, que
/// renueva solo. Sin Google Play en el servidor, todavía no; con más de 5
/// personas extra, por WhatsApp; con una suscripción viva, no se ofrece otra.
class _PagarConGoogle extends ConsumerWidget {
  const _PagarConGoogle({
    required this.cobro,
    required this.opcion,
    required this.precio,
  });

  final Cobro cobro;
  final OpcionDePlan opcion;
  final String precio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anual = opcion.periodo == PeriodoDePlan.anio;
    final producto = productoDePlay(opcion.plan.delServidor, opcion.extras);
    if (!cobro.googlePlay) {
      return const Text(
        Textos.pagoConGooglePlayPronto,
        style: Tipografia.texto,
      );
    }
    if (cobro.googleVigente) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(Textos.yaTienesGooglePlay, style: Tipografia.texto),
          const SizedBox(height: Medidas.e3),
          OutlinedButton(
            onPressed: () =>
                ref.read(abridorProvider).abrir(administrarEnGooglePlay(null)),
            child: const Text(Textos.administrarEnGooglePlay),
          ),
        ],
      );
    }
    if (producto == null) {
      return const Text(Textos.masDeCincoExtras, style: Tipografia.texto);
    }
    return Container(
      padding: const EdgeInsets.all(Medidas.e5),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Medidas.radioMayor),
        border: Border.all(color: Colores.marca, width: 2),
        boxShadow: Sombras.nivel2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Textos.googlePlayExplica(anual: anual),
            style: Tipografia.secundario,
          ),
          const SizedBox(height: Medidas.e4),
          FilledButton(
            onPressed: () => pagarConGooglePlay(context, producto),
            child: Text(Textos.suscribirmePor(precio, anual: anual)),
          ),
        ],
      ),
    );
  }
}

/// Abre «Elige tu plan»; «Pagar otro mes» ([otroMes]) va directo a «Pagar
/// tu plan» con el plan que ya tiene.
Future<void> abrirPlanes(
  BuildContext context,
  Cobro cobro, {
  bool otroMes = false,
}) {
  final navegador = Navigator.of(context);
  final directo = otroMes && cobro.estado == EstadoDelCobro.pagado;
  final actual = cobro.opcion(
    cobro.nivel,
    cobro.plan == 'anual' || cobro.plan == 'basico_anual'
        ? PeriodoDePlan.anio
        : PeriodoDePlan.mes,
  );
  if (directo && actual != null) {
    return navegador.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: rutaPagarPlan),
        builder: (_) => PantallaPagarPlan(cobro: cobro, opcion: actual),
      ),
    );
  }
  return navegador.push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: rutaElegirPlan),
      fullscreenDialog: true,
      builder: (_) => PantallaElegirPlan(cobro: cobro),
    ),
  );
}
