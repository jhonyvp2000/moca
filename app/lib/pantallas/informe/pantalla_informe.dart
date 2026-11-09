import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/icono_trazo.dart';
import '../../comun/tarjeta.dart';
import '../../comun/videos.dart';
import '../../dominio/informe.dart';
import '../../dominio/tutoria.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../dominio/cobro.dart';
import '../../dominio/historial.dart';
import '../cobro/cobro.dart';
import '../../dominio/modelos.dart';
import '../../textos/textos.dart';
import 'excel_informe.dart';
import 'pdf_informe.dart';
import '../../dominio/medicion.dart';

/// S14 · Informe del mes. Sin «Lo que te deben», «Ver a quiénes», «Cerrar
/// el mes», «Usarlo para pedir crédito» ni la pregunta de la mercadería
/// (ajustes respecto al mockup).
class PantallaInforme extends ConsumerStatefulWidget {
  const PantallaInforme({super.key});

  @override
  ConsumerState<PantallaInforme> createState() => _EstadoInforme();
}

class _EstadoInforme extends ConsumerState<PantallaInforme> {
  /// Nulo: el mes en curso.
  DateTime? _mes;

  /// El resumen del año (entrega 40); nulo es el actual.
  bool _verAnio = false;
  int? _anio;
  bool _armandoPdf = false;
  bool _armandoExcel = false;

  /// Pregunta para quién es el PDF (entrega 14.12). Nulo si cierra la hoja.
  Future<DestinoInforme?> _elegirDestino() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              Medidas.margenLateral,
              0,
              Medidas.margenLateral,
              8,
            ),
            child: Text(
              Textos.paraQuienEsPdf,
              style: Tipografia.tituloPantalla,
            ),
          ),
          for (final (destino, titulo, detalle) in const [
            (DestinoInforme.dueno, Textos.pdfParaMi, Textos.pdfParaMiDetalle),
            (
              DestinoInforme.contador,
              Textos.pdfParaContador,
              Textos.pdfParaContadorDetalle,
            ),
            (
              DestinoInforme.credito,
              Textos.pdfParaCredito,
              Textos.pdfParaCreditoDetalle,
            ),
          ])
            ListTile(
              minTileHeight: Medidas.objetivoTactilMinimo + 12,
              title: Text(titulo, style: Tipografia.textoFuerte),
              // «Para pedir un crédito» es del plan Full (entrega 43); en la
              // prueba y sin cobro, funciona igual.
              trailing: destino == DestinoInforme.credito
                  ? Text(
                      Textos.planFull,
                      style: Tipografia.etiquetaMoca.copyWith(fontSize: 14),
                    )
                  : null,
              subtitle: Text(detalle, style: Tipografia.secundario),
              onTap: () => Navigator.of(context).pop(destino),
            ),
        ],
      ),
    ),
  );

  /// Antes de compartir lo de la caja, dice qué llenó Moca y qué falta
  /// (entrega 14.15).
  Future<bool> _confirmarFlujo(FlujoParaCredito flujo) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(Textos.flujoParaCajaTitulo),
          content: Text(
            Textos.flujoParaCaja(
              flujo.conMoca.length,
              hastaHoy: switch (flujo.meses.last) {
                final m when m.estado == EstadoMesFlujo.enCurso => nombreDelMes(
                  m.mes,
                ),
                _ => null,
              },
            ),
            style: Tipografia.texto,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(Textos.cancelar),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(Textos.compartir),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _compartir(InformeMes informe) async {
    final mensajes = ScaffoldMessenger.of(context);
    final destino = await _elegirDestino();
    if (destino == null || !mounted) return;
    // El Básico no arma lo del crédito: se explica y se ofrece el Full.
    final cobro = ref.read(cobroProvider).value ?? Cobro.sinCobro;
    if (destino == DestinoInforme.credito && !cobro.credito) {
      final cambiar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(Textos.creditoEsDelFull),
          content: const Text(
            Textos.creditoEsDelFullDetalle,
            style: Tipografia.texto,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(Textos.ahoraNoCorto),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(Textos.comoPagar),
            ),
          ],
        ),
      );
      if (cambiar == true && mounted) {
        await mostrarComoPagar(context, ref, cobro);
      }
      return;
    }
    final repositorio = ref.read(repositorioInformeProvider);
    final flujo = destino == DestinoInforme.credito
        ? await repositorio.flujoParaCredito()
        : null;
    if (flujo != null && !(mounted && await _confirmarFlujo(flujo))) return;
    setState(() => _armandoPdf = true);
    try {
      final nombre = ref.read(resumenInicioProvider).value?.nombreNegocio ?? '';
      final hoy = ref.read(relojProvider)();
      final detalle = await repositorio.detalleParaPdf(informe);
      final ruta = await guardarPdfDelInforme(
        informe,
        detalle,
        destino: destino,
        nombreNegocio: nombre,
        hoy: hoy,
      );
      final compartidor = ref.read(compartidorProvider);
      if (flujo != null) {
        // El resumen en PDF y el flujo en el formato de la caja, juntos.
        final rutaFlujo = await guardarFlujoParaCredito(
          flujo,
          nombreNegocio: nombre,
          hoy: hoy,
        );
        await compartidor.compartirArchivos([
          (ruta, 'application/pdf'),
          (rutaFlujo, tipoExcel),
        ], asunto: Textos.resumenDeMeses(detalle.meses.length));
      } else {
        await compartidor.compartirArchivo(
          ruta,
          asunto: Textos.informeDe(nombreDelMes(informe.mes), informe.mes.year),
        );
      }
      await ref.read(medicionProvider).anotar(EventoMedicion.pdfCompartido, {
        'para': destino.name,
      });
    } on Exception {
      mensajes.showSnackBar(const SnackBar(content: Text(Textos.pdfNoSeArmo)));
    } finally {
      if (mounted) setState(() => _armandoPdf = false);
    }
  }

  Future<void> _compartirExcel(InformeMes informe) async {
    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _armandoExcel = true);
    try {
      final nombre = ref.read(resumenInicioProvider).value?.nombreNegocio ?? '';
      final detalle = await ref
          .read(repositorioInformeProvider)
          .detalleParaPdf(informe);
      final ruta = await guardarExcelDelInforme(
        informe,
        detalle,
        nombreNegocio: nombre,
        hoy: ref.read(relojProvider)(),
      );
      await ref
          .read(compartidorProvider)
          .compartirArchivo(
            ruta,
            asunto: Textos.operacionesDe(
              nombreDelMes(informe.mes),
              informe.mes.year,
            ),
            tipo: tipoExcel,
          );
      await ref.read(medicionProvider).anotar(EventoMedicion.excelCompartido);
    } on Exception {
      mensajes.showSnackBar(
        const SnackBar(content: Text(Textos.excelNoSeArmo)),
      );
    } finally {
      if (mounted) setState(() => _armandoExcel = false);
    }
  }

  /// «Mes · Año» (entrega 40).
  Widget _selector() => Align(
    alignment: Alignment.centerLeft,
    child: SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: false, label: Text(Textos.verMes)),
        ButtonSegment(value: true, label: Text(Textos.verAnio)),
      ],
      selected: {_verAnio},
      onSelectionChanged: (v) => setState(() {
        _verAnio = v.first;
        // El año del mes que estaba mirando.
        if (_verAnio) _anio = _mes?.year;
      }),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_verAnio) {
      return SafeArea(
        bottom: false,
        child: _VistaAnio(
          anio: _anio,
          selector: _selector(),
          alCambiarAnio: (a) => setState(() => _anio = a),
          alElegirMes: (m) => setState(() {
            _mes = m;
            _verAnio = false;
          }),
        ),
      );
    }
    final informe = ref.watch(informeProvider(_mes)).value;
    if (informe == null) return const SizedBox.shrink();
    final i = informe;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          12,
          Medidas.margenLateral,
          16,
        ),
        children: [
          _selector(),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Flecha(
                icono: Icono.volver,
                etiqueta: Textos.mesAnterior,
                alTocar: i.mesPrevio == null
                    ? null
                    : () => setState(() => _mes = i.mesPrevio),
              ),
              Semantics(
                header: true,
                child: Text(
                  nombreDelMesConMayuscula(i.mes),
                  style: Tipografia.tituloPantalla,
                ),
              ),
              _Flecha(
                icono: Icono.derecha,
                etiqueta: Textos.mesSiguiente,
                alTocar: i.mesSiguiente == null
                    ? null
                    : () => setState(() => _mes = i.mesSiguiente),
              ),
            ],
          ),
          if (_periodo(i) case final periodo?)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 2),
              child: Text(periodo, style: Tipografia.secundario),
            ),
          // El PDF y el Excel de las operaciones (entrega 14.13).
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _BotonCompartir(
                  texto: _armandoPdf ? Textos.armandoPdf : Textos.compartirPdf,
                  alTocar: i.sinRegistros || _armandoPdf
                      ? null
                      : () => _compartir(i),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BotonCompartir(
                  texto: _armandoExcel
                      ? Textos.armandoExcel
                      : Textos.compartirExcel,
                  alTocar: i.sinRegistros || _armandoExcel
                      ? null
                      : () => _compartirExcel(i),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const TarjetaPrimeraVez(
            video: VideoTutoria.informe,
            margen: EdgeInsets.only(bottom: Medidas.separacionTarjetas),
          ),
          if (i.sinRegistros)
            Tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(Textos.mesSinRegistros, style: Tipografia.texto),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push(Rutas.registrar),
                    child: const Text(Textos.registrar),
                  ),
                ],
              ),
            )
          else
            ..._contenido(i),
        ],
      ),
    );
  }

  static String? _periodo(InformeMes i) {
    if (i.desdeDia case final dia?) {
      return i.enCurso
          ? Textos.desdeElDiaHastaHoy(dia)
          : Textos.desdeElDia(dia);
    }
    return i.enCurso ? Textos.hastaHoy : null;
  }

  List<Widget> _contenido(InformeMes i) {
    final anterior = i.mesAnterior == null ? '' : nombreDelMes(i.mesAnterior!);
    // De qué periodo es cada sección (entrega 36).
    final periodo = Textos.periodoDelMes(
      i.mes,
      enCurso: i.enCurso,
      hoy: ref.read(relojProvider)(),
      desdeDia: i.desdeDia,
    );
    final crecio = i.crecioCentimos;
    final diferencia = i.diferenciaConAnteriorCentimos;
    const separacion = SizedBox(height: Medidas.separacionTarjetas);

    return [
      // Cuánto creció o bajó la plata (entrega 14.9)
      Tarjeta(
        relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              crecio > 0
                  ? Textos.tuPlataCrecio
                  : crecio < 0
                  ? Textos.tuPlataBajo
                  : Textos.tuPlataIgual,
              style: Tipografia.textoFuerte.copyWith(
                color: Colores.textoSecundario,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatearSoles(crecio.abs()),
                maxLines: 1,
                style: Tipografia.cifra(
                  const TextStyle(
                    fontFamily: Tipografia.familia,
                    fontSize: 46,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Colores.textoPrincipal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (diferencia == null)
              const Text(Textos.primerMesConMoca, style: Tipografia.secundario)
            else
              Row(
                children: [
                  if (diferencia != 0) ...[
                    IconoTrazo(
                      diferencia > 0 ? Icono.entro : Icono.salio,
                      color: Colores.textoPrincipal,
                      tamano: 18,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      diferencia > 0
                          ? Textos.masQueEn(
                              formatearSoles(diferencia),
                              anterior,
                            )
                          : diferencia < 0
                          ? Textos.menosQueEn(
                              formatearSoles(-diferencia),
                              anterior,
                            )
                          : Textos.igualQueEn(anterior),
                      style: Tipografia.cifra(Tipografia.textoFuerte),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              Textos.entroSalio(
                formatearSoles(i.entroCentimos),
                formatearSoles(i.salioCentimos),
              ),
              style: Tipografia.cifra(Tipografia.secundario),
            ),
          ],
        ),
      ),
      separacion,

      // Cómo se movió la plata: cuadra con el saldo
      Tarjeta(
        relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(Textos.comoSeMovio, style: Tipografia.tituloTarjeta),
            Text(periodo, style: Tipografia.secundario),
            const SizedBox(height: 8),
            _Fila(
              i.desdeDia == null
                  ? Textos.empezasteElMesCon
                  : Textos.empezasteCon,
              formatearSoles(i.inicioCentimos),
            ),
            _Fila(Textos.masEntro, formatearSoles(i.entroCentimos)),
            if (i.aportesCentimos > 0)
              _Fila(
                Textos.masPusisteDeTuBolsillo,
                formatearSoles(i.aportesCentimos),
              ),
            _Fila(
              Textos.menosSalioDelNegocio,
              formatearSoles(i.salioCentimos),
              salida: true,
            ),
            _Fila(
              Textos.menosRetirasteParaTi,
              formatearSoles(i.retirosCentimos),
              salida: true,
            ),
            if (i.ajustesCentimos != 0)
              _Fila(
                i.ajustesCentimos > 0
                    ? Textos.masSobroEnElArqueo
                    : Textos.menosFaltoEnElArqueo,
                formatearSoles(i.ajustesCentimos.abs()),
                salida: i.ajustesCentimos < 0,
              ),
            const Divider(),
            _Fila(
              i.enCurso ? Textos.tienesHoy : Textos.terminasteElMesCon,
              formatearSoles(i.finCentimos),
              fuerte: true,
            ),
            const SizedBox(height: 8),
            const Text(Textos.cuentasDePlata, style: Tipografia.secundario),
          ],
        ),
      ),
      separacion,

      // Con qué entró la plata (entrega 35)
      Tarjeta(
        relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(Textos.conQueEntro, style: Tipografia.tituloTarjeta),
            Text(periodo, style: Tipografia.secundario),
            const SizedBox(height: 8),
            if (i.ingresos.isEmpty)
              const Text(Textos.sinIngresosDelMes, style: Tipografia.secundario)
            else
              for (final (n, g) in i.ingresos.indexed)
                _Barra(
                  nombre: g.nombre ?? Textos.loDemas,
                  centimos: g.centimos,
                  proporcion: g.centimos / i.ingresos.first.centimos,
                  primera: n == 0,
                  alTocar: () => context.push(
                    Rutas.deCategoria,
                    extra: ConsultaDeCategoria(
                      mes: i.mes,
                      tipo: TipoMovimiento.ingreso,
                      titulo: g.nombre ?? Textos.loDemas,
                      nombres: g.nombre == null ? null : {g.nombre!},
                      salvo: {
                        for (final o in i.ingresos)
                          if (o.nombre != null) o.nombre!,
                      },
                    ),
                  ),
                ),
          ],
        ),
      ),
      separacion,

      // En qué se fue la plata
      Tarjeta(
        relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(Textos.enQueSeFue, style: Tipografia.tituloTarjeta),
            Text(periodo, style: Tipografia.secundario),
            const SizedBox(height: 8),
            if (i.gastos.isEmpty)
              const Text(Textos.sinGastos, style: Tipografia.secundario)
            else
              for (final (n, g) in i.gastos.indexed)
                _Barra(
                  nombre: g.nombre ?? Textos.loDemas,
                  centimos: g.centimos,
                  proporcion: g.centimos / i.gastos.first.centimos,
                  primera: n == 0,
                  alTocar: () => context.push(
                    Rutas.deCategoria,
                    extra: ConsultaDeCategoria(
                      mes: i.mes,
                      tipo: TipoMovimiento.egreso,
                      titulo: g.nombre ?? Textos.loDemas,
                      nombres: g.nombre == null ? null : {g.nombre!},
                      salvo: {
                        for (final o in i.gastos)
                          if (o.nombre != null) o.nombre!,
                      },
                    ),
                  ),
                ),
            if (i.mesAnterior != null && i.gastos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                switch (i.cambio) {
                  final c? when c.centimos > 0 => Textos.subioFrente(
                    c.nombre,
                    formatearSoles(c.centimos),
                    anterior,
                  ),
                  final c? => Textos.bajoFrente(
                    c.nombre,
                    formatearSoles(-c.centimos),
                    anterior,
                  ),
                  null => Textos.casiNadaCambio(anterior),
                },
                style: Tipografia.cifra(
                  Tipografia.textoFuerte.copyWith(color: Colores.azulOscuro),
                ),
              ),
            ],
          ],
        ),
      ),
      separacion,

      // Lo que debes: se toca y abre el detalle (entrega 38).
      _TarjetaDeuda(
        titulo: Textos.loQueDebesTitulo,
        nota: Textos.todoLoQueDebes,
        centimos: i.loQueDebesCentimos,
        ruta: Rutas.loQueDebes,
      ),
      separacion,
      // Lo que te deben: las ventas a crédito (entrega 42).
      _TarjetaDeuda(
        titulo: Textos.loQueTeDebenTitulo,
        nota: Textos.todoLoQueTeDeben,
        centimos: (ref.watch(loQueTeDebenProvider).value ?? const []).fold(
          0,
          (s, f) => s + f.montoCentimos,
        ),
        ruta: Rutas.loQueTeDeben,
      ),
      if (i.confianza case final c?) ...[
        separacion,
        Tarjeta(
          relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _Confianza(confianza: c),
        ),
      ],
      if (i.advertenciaMercaderia) ...[
        separacion,
        const TarjetaMoca(texto: Textos.advertenciaMercaderia),
      ],
    ];
  }
}

/// Una tarjeta con un total que se toca y abre su lista: «Lo que debes»
/// (entrega 38) y «Lo que te deben» (entrega 42).
class _TarjetaDeuda extends StatelessWidget {
  const _TarjetaDeuda({
    required this.titulo,
    required this.nota,
    required this.centimos,
    required this.ruta,
  });

  final String titulo;
  final String nota;
  final int centimos;
  final String ruta;

  @override
  Widget build(BuildContext context) => Tarjeta(
    relleno: EdgeInsets.zero,
    child: Material(
      color: Colores.superficie,
      borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      child: InkWell(
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        onTap: () => context.push(ruta),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: Tipografia.secundario),
                    Text(nota, style: Tipografia.secundario),
                    Text(
                      formatearSoles(centimos),
                      style: Tipografia.cifra(
                        Tipografia.tituloPantalla.copyWith(fontSize: 24),
                      ),
                    ),
                  ],
                ),
              ),
              if (centimos > 0)
                Text(
                  Textos.verDetalle,
                  style: Tipografia.textoFuerte.copyWith(color: Colores.marca),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// El resumen del año calendario (entrega 40): cuánto creció la plata, los
/// meses uno por uno y con qué entró y en qué se fue, con las mismas reglas
/// del informe de cada mes.
class _VistaAnio extends ConsumerWidget {
  const _VistaAnio({
    required this.anio,
    required this.selector,
    required this.alCambiarAnio,
    required this.alElegirMes,
  });

  final int? anio;
  final Widget selector;
  final ValueChanged<int> alCambiarAnio;
  final ValueChanged<DateTime> alElegirMes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(resumenAnioProvider(anio)).value;
    if (r == null) return const SizedBox.shrink();
    final periodo = Textos.periodoDelAnio(r.desde, enCurso: r.enCurso);
    final crecio = r.crecioCentimos;
    const separacion = SizedBox(height: Medidas.separacionTarjetas);
    final mayorEntrada = r.meses.fold(
      0,
      (s, m) => m.entroCentimos > s ? m.entroCentimos : s,
    );

    Widget categorias(
      String titulo,
      String vacio,
      List<GastoPorCategoria> filas,
      TipoMovimiento tipo,
    ) => Tarjeta(
      relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: Tipografia.tituloTarjeta),
          Text(periodo, style: Tipografia.secundario),
          const SizedBox(height: 8),
          if (filas.isEmpty)
            Text(vacio, style: Tipografia.secundario)
          else
            for (final (n, g) in filas.indexed)
              _Barra(
                nombre: g.nombre ?? Textos.loDemas,
                centimos: g.centimos,
                proporcion: g.centimos / filas.first.centimos,
                primera: n == 0,
                alTocar: () => context.push(
                  Rutas.deCategoria,
                  extra: ConsultaDeCategoria(
                    mes: r.desde,
                    anual: true,
                    tipo: tipo,
                    titulo: g.nombre ?? Textos.loDemas,
                    nombres: g.nombre == null ? null : {g.nombre!},
                    salvo: {
                      for (final o in filas)
                        if (o.nombre != null) o.nombre!,
                    },
                  ),
                ),
              ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Medidas.margenLateral,
        12,
        Medidas.margenLateral,
        16,
      ),
      children: [
        selector,
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Flecha(
              icono: Icono.volver,
              etiqueta: Textos.anioAnterior,
              alTocar: r.anioPrevio == null
                  ? null
                  : () => alCambiarAnio(r.anioPrevio!),
            ),
            Semantics(
              header: true,
              child: Text('${r.anio}', style: Tipografia.tituloPantalla),
            ),
            _Flecha(
              icono: Icono.derecha,
              etiqueta: Textos.anioSiguiente,
              alTocar: r.anioSiguiente == null
                  ? null
                  : () => alCambiarAnio(r.anioSiguiente!),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 44, top: 2),
          child: Text(periodo, style: Tipografia.secundario),
        ),
        const SizedBox(height: 12),

        // Cuánto creció la plata en el año, y de dónde salió esa cifra.
        Tarjeta(
          relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                crecio > 0
                    ? Textos.enElAnioCrecio(r.anio)
                    : crecio < 0
                    ? Textos.enElAnioBajo(r.anio)
                    : Textos.enElAnioIgual(r.anio),
                style: Tipografia.textoFuerte.copyWith(
                  color: Colores.textoSecundario,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatearSoles(crecio.abs()),
                  maxLines: 1,
                  style: Tipografia.cifra(
                    const TextStyle(
                      fontFamily: Tipografia.familia,
                      fontSize: 46,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: Colores.textoPrincipal,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _Fila(Textos.entro, formatearSoles(r.entroCentimos)),
              if (r.aportesCentimos > 0)
                _Fila(
                  Textos.pusisteDeTuBolsillo,
                  formatearSoles(r.aportesCentimos),
                ),
              _Fila(
                Textos.salioDelNegocio,
                formatearSoles(r.salioCentimos),
                salida: true,
              ),
              _Fila(
                Textos.retirasteParaTi,
                formatearSoles(r.retirosCentimos),
                salida: true,
              ),
              if (r.ajustesCentimos != 0)
                _Fila(
                  r.ajustesCentimos > 0
                      ? Textos.sobroEnLosArqueos
                      : Textos.faltoEnLosArqueos,
                  formatearSoles(r.ajustesCentimos.abs()),
                  salida: r.ajustesCentimos < 0,
                ),
            ],
          ),
        ),
        separacion,

        // Mes por mes: cada uno abre su informe.
        Tarjeta(
          relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(Textos.mesPorMes, style: Tipografia.tituloTarjeta),
              const Text(Textos.tocaUnMes, style: Tipografia.secundario),
              const SizedBox(height: 8),
              const _FilaDeMes.encabezado(),
              for (final m in r.meses)
                if (m.estado != EstadoMesDelAnio.porVenir)
                  _FilaDeMes(
                    mes: m,
                    proporcion: mayorEntrada == 0
                        ? 0
                        : m.entroCentimos / mayorEntrada,
                    alTocar: m.cuenta ? () => alElegirMes(m.mes) : null,
                  ),
            ],
          ),
        ),
        separacion,
        categorias(
          Textos.conQueEntro,
          Textos.sinIngresosDelAnio,
          r.ingresos,
          TipoMovimiento.ingreso,
        ),
        separacion,
        categorias(
          Textos.enQueSeFue,
          Textos.sinGastosDelAnio,
          r.gastos,
          TipoMovimiento.egreso,
        ),
      ],
    );
  }
}

/// Un mes en la tabla del año: entró, salió y cuánto creció, con una barra
/// de lo que entró frente al mes que más entró.
class _FilaDeMes extends StatelessWidget {
  const _FilaDeMes({
    required MesDelAnio this.mes,
    required this.proporcion,
    required this.alTocar,
  });

  const _FilaDeMes.encabezado() : mes = null, proporcion = 0, alTocar = null;

  /// Nulo: la fila de los títulos.
  final MesDelAnio? mes;
  final double proporcion;
  final VoidCallback? alTocar;

  static const _anchoCifra = 66.0;

  static Widget _cifra(String texto, {Color? color, bool fuerte = false}) =>
      SizedBox(
        width: _anchoCifra,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            texto,
            maxLines: 1,
            style: Tipografia.cifra(
              (fuerte ? Tipografia.textoFuerte : Tipografia.texto).copyWith(
                color: color,
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final m = mes;
    if (m == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            const Expanded(
              child: Text(Textos.columnaMes, style: Tipografia.secundario),
            ),
            for (final t in const [
              Textos.columnaEntro,
              Textos.columnaSalio,
              Textos.columnaCrecio,
            ]) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: _anchoCifra,
                child: Text(
                  t,
                  textAlign: TextAlign.right,
                  style: Tipografia.secundario,
                ),
              ),
            ],
          ],
        ),
      );
    }
    final nombre = nombreDelMesCorto(m.mes);
    if (m.estado == EstadoMesDelAnio.antesDeMoca) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: Medidas.objetivoTactilMinimo,
        ),
        child: Row(
          children: [
            Expanded(child: Text(nombre, style: Tipografia.secundario)),
            const Text(Textos.antesDeMoca, style: Tipografia.secundario),
          ],
        ),
      );
    }
    final crecio = m.crecioCentimos;
    return InkWell(
      onTap: alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: Medidas.objetivoTactilMinimo,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre, style: Tipografia.textoFuerte),
                        if (m.estado == EstadoMesDelAnio.enCurso)
                          const Text(
                            Textos.hastaHoyMinuscula,
                            style: Tipografia.secundario,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _cifra(formatearSoles(m.entroCentimos)),
                  const SizedBox(width: 6),
                  _cifra(
                    formatearSoles(m.salioCentimos),
                    color: Colores.salida,
                  ),
                  const SizedBox(width: 6),
                  _cifra(
                    formatearSoles(crecio),
                    color: crecio < 0 ? Colores.salida : null,
                    fuerte: true,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: proporcion.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: Colores.separador,
                  color: Colores.marca,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Flecha extends StatelessWidget {
  const _Flecha({
    required this.icono,
    required this.etiqueta,
    required this.alTocar,
  });

  final Icono icono;
  final String etiqueta;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: etiqueta,
      onPressed: alTocar,
      constraints: const BoxConstraints.tightFor(
        width: Medidas.objetivoTactilMinimo,
        height: Medidas.objetivoTactilMinimo,
      ),
      icon: IconoTrazo(
        icono,
        color: alTocar == null
            ? Colores.bordeBotonSecundario
            : Colores.textoPrincipal,
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(
    this.etiqueta,
    this.monto, {
    this.fuerte = false,
    this.salida = false,
  });

  final String etiqueta;
  final String monto;
  final bool fuerte;

  /// El monto de una salida va en rojo sobrio (entrega 14.9.2).
  final bool salida;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: fuerte ? Tipografia.textoFuerte : Tipografia.secundario,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            monto,
            style: Tipografia.cifra(
              Tipografia.textoFuerte.copyWith(
                fontWeight: FontWeight.w700,
                color: salida ? Colores.salida : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.nombre,
    required this.centimos,
    required this.proporcion,
    required this.primera,
    this.alTocar,
  });

  final String nombre;
  final int centimos;
  final double proporcion;
  final bool primera;

  /// Abre sus registros del mes (entrega 38).
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: alTocar,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: Medidas.objetivoTactilMinimo,
      ),
      child: _contenido(),
    ),
  );

  Widget _contenido() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: primera ? Tipografia.textoFuerte : Tipografia.texto,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: proporcion.clamp(0.04, 1),
                minHeight: 12,
                backgroundColor: Colores.separador,
                color: primera ? Colores.marca : Colores.bordeCampo,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Ancho fijo para que las barras queden alineadas.
          SizedBox(
            width: 84,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                formatearSoles(centimos),
                style: Tipografia.cifra(
                  Tipografia.textoFuerte.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Confianza extends StatelessWidget {
  const _Confianza({required this.confianza});

  final ConfianzaDelMes confianza;

  static const colores = [
    Colores.marca,
    Colores.azulMedio,
    Colores.grisAzulado,
  ];

  @override
  Widget build(BuildContext context) {
    final c = confianza;
    final partes = [
      (c.conComprobante, Textos.conComprobante(c.conComprobante)),
      (c.conFoto, Textos.conFoto(c.conFoto)),
      (c.sinPapel, Textos.sinPapel(c.sinPapel)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(Textos.queTanSeguras, style: Tipografia.tituloTarjeta),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (final (n, (pct, _)) in partes.indexed)
                  if (pct > 0)
                    Expanded(
                      flex: pct,
                      child: Container(
                        margin: EdgeInsets.only(right: n < 2 ? 2 : 0),
                        color: colores[n],
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final (n, (_, texto)) in partes.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colores[n],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(texto, style: Tipografia.cifra(Tipografia.texto)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BotonCompartir extends StatelessWidget {
  const _BotonCompartir({required this.texto, required this.alTocar});

  final String texto;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: alTocar,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, Medidas.objetivoTactilMinimo),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    icon: const IconoTrazo(
      Icono.compartir,
      color: Colores.textoPrincipal,
      tamano: 20,
    ),
    label: Text(texto),
  );
}
