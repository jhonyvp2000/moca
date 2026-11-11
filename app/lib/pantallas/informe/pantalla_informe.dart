import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/icono_trazo.dart';
import '../../comun/monto_text.dart';
import '../../comun/seccion_plegable.dart';
import '../../comun/tarjeta.dart';
import '../../comun/tarjeta_resumen.dart';
import '../../comun/tono.dart';
import '../inicio/bloque_pendientes.dart';
import 'grafico_semanas.dart';
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
                  ? Text(Textos.planFull, style: Tipografia.etiquetaMoca)
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

  /// «Compartir» (mejora 01): el PDF del mes o el Excel de las operaciones.
  Future<void> _elegirQueCompartir(InformeMes informe) async {
    final cual = await showModalBottomSheet<bool>(
      context: context,
      builder: (hoja) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: Medidas.e4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  Medidas.margenLateral,
                  0,
                  Medidas.margenLateral,
                  Medidas.e2,
                ),
                child: Text(Textos.compartir, style: Tipografia.tituloPantalla),
              ),
              for (final (pdf, icono, titulo, detalle) in const [
                (
                  true,
                  Icons.picture_as_pdf_rounded,
                  Textos.compartirPdf,
                  Textos.compartirPdfDetalle,
                ),
                (
                  false,
                  Icons.table_chart_rounded,
                  Textos.compartirExcel,
                  Textos.compartirExcelDetalle,
                ),
              ])
                ListTile(
                  minTileHeight: Medidas.objetivoTactilMinimo + Medidas.e3,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colores.azul100,
                      borderRadius: BorderRadius.circular(Medidas.radioChico),
                    ),
                    child: Icon(icono, color: Colores.marca),
                  ),
                  title: Text(titulo, style: Tipografia.textoFuerte),
                  subtitle: Text(detalle, style: Tipografia.secundario),
                  onTap: () => Navigator.of(hoja).pop(pdf),
                ),
            ],
          ),
        ),
      ),
    );
    if (cual == null || !mounted) return;
    await (cual ? _compartir(informe) : _compartirExcel(informe));
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
          // El mismo título que el mes (mejora 01).
          selector: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: const Text(
                  Textos.pestanaInformes,
                  style: Tipografia.tituloPantalla,
                ),
              ),
              const SizedBox(height: Medidas.e3),
              _selector(),
            ],
          ),
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

    // Todo armado de una vez: así cada sección existe aunque no se vea.
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          Medidas.e4,
          Medidas.margenLateral,
          Medidas.e8 + Medidas.e4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // «Informes» y un solo «Compartir» que abre PDF o Excel
            // (mejora 01): el resultado queda arriba.
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: const Text(
                      Textos.pestanaInformes,
                      style: Tipografia.tituloPantalla,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: i.sinRegistros || _armandoPdf || _armandoExcel
                      ? null
                      : () => _elegirQueCompartir(i),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, Medidas.objetivoTactilMinimo),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  label: Text(
                    _armandoPdf
                        ? Textos.armandoPdf
                        : _armandoExcel
                        ? Textos.armandoExcel
                        : Textos.compartir,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Medidas.e3),
            // «Mes · Año» y las flechas del mes, en una fila.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: Medidas.e2,
              children: [
                _selector(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Flecha(
                      icono: Icono.izquierda,
                      etiqueta: Textos.mesAnterior,
                      alTocar: i.mesPrevio == null
                          ? null
                          : () => setState(() => _mes = i.mesPrevio),
                    ),
                    // Con letra grande se achica antes que desbordarse.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Semantics(
                          header: true,
                          child: Text(
                            nombreDelMesConMayuscula(i.mes),
                            style: Tipografia.tituloDestacado,
                          ),
                        ),
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
              ],
            ),
            if (_periodo(i) case final periodo?)
              Padding(
                padding: const EdgeInsets.only(top: Medidas.e1),
                child: Text(periodo, style: Tipografia.secundario),
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
      // Cuánto creció o bajó la plata (entrega 14.9). Subió: azul con su
      // flecha; bajó: gris, sin rojo (decisiones.md, 10-11-2026).
      Tarjeta(
        relleno: const EdgeInsets.all(Medidas.e5),
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
            const SizedBox(height: Medidas.e1),
            Row(
              children: [
                if (crecio != 0) ...[
                  Icon(
                    crecio > 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 32,
                    color: crecio > 0 ? Colores.marca : Colores.neutro,
                  ),
                  const SizedBox(width: Medidas.e2),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: MontoText(
                      crecio,
                      estilo: Tipografia.montoGrande.copyWith(
                        color: crecio < 0 ? Colores.neutro : null,
                      ),
                      tono: crecio > 0 ? Tono.ingreso : null,
                      conSigno: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Medidas.e2),
            if (diferencia == null)
              const Text(Textos.primerMesConMoca, style: Tipografia.secundario)
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Medidas.e3,
                  vertical: Medidas.e1,
                ),
                decoration: BoxDecoration(
                  color: diferencia > 0 ? Colores.azul100 : Colores.neutroFondo,
                  borderRadius: BorderRadius.circular(Medidas.radioPildora),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (diferencia != 0) ...[
                      Icon(
                        diferencia > 0
                            ? Icons.north_east_rounded
                            : Icons.south_east_rounded,
                        size: 16,
                        color: diferencia > 0 ? Colores.marca : Colores.neutro,
                      ),
                      const SizedBox(width: Medidas.e1),
                    ],
                    Flexible(
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
                        style: Tipografia.cifra(
                          Tipografia.apoyo.copyWith(
                            color: diferencia > 0
                                ? Colores.azul900
                                : Colores.neutro,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: Medidas.e4),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TarjetaResumen(
                      etiqueta: Textos.entro,
                      centimos: i.entroCentimos,
                      tono: i.entroCentimos == 0 ? Tono.neutro : Tono.ingreso,
                    ),
                  ),
                  const SizedBox(width: Medidas.e3),
                  Expanded(
                    child: TarjetaResumen(
                      etiqueta: Textos.salio,
                      centimos: i.salioCentimos,
                      tono: i.salioCentimos == 0 ? Tono.neutro : Tono.egreso,
                    ),
                  ),
                ],
              ),
            ),
            // Lo que también movió la plata, para que el número se entienda
            // sin bajar (entrega 59).
            if (_tambien(i) case final texto?) ...[
              const SizedBox(height: Medidas.e3),
              Text(texto, style: Tipografia.cifra(Tipografia.secundario)),
            ],
          ],
        ),
      ),
      separacion,

      // Lo que se debe, en dos fichas como en el Inicio (entrega 59).
      const BloquePendientes(
        margen: EdgeInsets.only(bottom: Medidas.separacionTarjetas),
      ),
      // El resto del mes, a un toque (entrega 59).
      SeccionPlegable(
        clave: 'informe_mes',
        titulo: Textos.verDetalleDelMes,
        hijo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Por semana (mejora 01)
            if (i.semanas.isNotEmpty) ...[
              Tarjeta(
                relleno: const EdgeInsets.all(Medidas.e5),
                child: GraficoSemanas(semanas: i.semanas),
              ),
              separacion,
            ],

            // Cómo se movió la plata: cuadra con el saldo
            Tarjeta(
              relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    Textos.comoSeMovio,
                    style: Tipografia.tituloTarjeta,
                  ),
                  Text(periodo, style: Tipografia.secundario),
                  const SizedBox(height: 8),
                  _Fila(
                    i.desdeDia == null
                        ? Textos.empezasteElMesCon
                        : Textos.empezasteCon,
                    i.inicioCentimos,
                  ),
                  _Fila(Textos.masEntro, i.entroCentimos, tono: Tono.ingreso),
                  if (i.aportesCentimos > 0)
                    _Fila(
                      Textos.masPusisteDeTuBolsillo,
                      i.aportesCentimos,
                      tono: Tono.ingreso,
                    ),
                  _Fila(
                    Textos.menosSalioDelNegocio,
                    i.salioCentimos,
                    tono: Tono.egreso,
                  ),
                  _Fila(
                    Textos.menosRetirasteParaTi,
                    i.retirosCentimos,
                    tono: Tono.egreso,
                  ),
                  if (i.ajustesCentimos != 0)
                    _Fila(
                      i.ajustesCentimos > 0
                          ? Textos.masSobroEnElArqueo
                          : Textos.menosFaltoEnElArqueo,
                      i.ajustesCentimos.abs(),
                      tono: i.ajustesCentimos < 0 ? Tono.egreso : Tono.ingreso,
                    ),
                  const Divider(),
                  _Fila(
                    i.enCurso ? Textos.tienesHoy : Textos.terminasteElMesCon,
                    i.finCentimos,
                    fuerte: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    Textos.cuentasDePlata,
                    style: Tipografia.secundario,
                  ),
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
                  const Text(
                    Textos.conQueEntro,
                    style: Tipografia.tituloTarjeta,
                  ),
                  Text(periodo, style: Tipografia.secundario),
                  const SizedBox(height: 8),
                  if (i.ingresos.isEmpty)
                    const Text(
                      Textos.sinIngresosDelMes,
                      style: Tipografia.secundario,
                    )
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
                  const Text(
                    Textos.enQueSeFue,
                    style: Tipografia.tituloTarjeta,
                  ),
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
                        Tipografia.textoFuerte.copyWith(
                          color: Colores.azulOscuro,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (i.confianza case final c?) ...[
              separacion,
              Tarjeta(
                relleno: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: _Confianza(confianza: c),
              ),
            ],
            if (i.advertenciaMercaderia) ...[
              separacion,
              const TarjetaMoca(texto: Textos.advertenciaMercaderia),
            ],
          ],
        ),
      ),
    ];
  }
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
              icono: Icono.izquierda,
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
          padding: const EdgeInsets.only(left: 44, top: Medidas.e1),
          child: Text(periodo, style: Tipografia.secundario),
        ),
        const SizedBox(height: 12),

        // Cuánto creció la plata en el año, y de dónde salió esa cifra.
        Tarjeta(
          relleno: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: Medidas.e5,
          ),
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
              // Como el mes: signo y flecha, azul si subió y gris si bajó
              // (mejora 01).
              Row(
                children: [
                  if (crecio != 0) ...[
                    Icon(
                      crecio > 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 32,
                      color: crecio > 0 ? Colores.marca : Colores.neutro,
                    ),
                    const SizedBox(width: Medidas.e2),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: MontoText(
                        crecio,
                        estilo: Tipografia.montoGrande.copyWith(
                          color: crecio < 0 ? Colores.neutro : null,
                        ),
                        tono: crecio > 0 ? Tono.ingreso : null,
                        conSigno: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Fila(Textos.entro, r.entroCentimos, tono: Tono.ingreso),
              if (r.aportesCentimos > 0)
                _Fila(
                  Textos.pusisteDeTuBolsillo,
                  r.aportesCentimos,
                  tono: Tono.ingreso,
                ),
              _Fila(Textos.salioDelNegocio, r.salioCentimos, tono: Tono.egreso),
              _Fila(
                Textos.retirasteParaTi,
                r.retirosCentimos,
                tono: Tono.egreso,
              ),
              if (r.ajustesCentimos != 0)
                _Fila(
                  r.ajustesCentimos > 0
                      ? Textos.sobroEnLosArqueos
                      : Textos.faltoEnLosArqueos,
                  r.ajustesCentimos.abs(),
                  tono: r.ajustesCentimos < 0 ? Tono.egreso : Tono.ingreso,
                ),
            ],
          ),
        ),
        separacion,

        // Mes por mes y en qué entró y se fue, a un toque (entrega 59).
        SeccionPlegable(
          clave: 'informe_anio',
          titulo: Textos.verDetalleDelAnio,
          hijo: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mes por mes: cada uno abre su informe.
              Tarjeta(
                relleno: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      Textos.mesPorMes,
                      style: Tipografia.tituloTarjeta,
                    ),
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
          ),
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
              const SizedBox(width: Medidas.e2),
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
          padding: const EdgeInsets.symmetric(vertical: Medidas.e2),
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
                  const SizedBox(width: Medidas.e2),
                  _cifra(formatearSoles(m.entroCentimos)),
                  const SizedBox(width: Medidas.e2),
                  _cifra(
                    formatearSoles(m.salioCentimos),
                    color: Colores.salida,
                  ),
                  const SizedBox(width: Medidas.e2),
                  _cifra(
                    formatearSoles(crecio),
                    color: crecio < 0 ? Colores.salida : null,
                    fuerte: true,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(Medidas.radioMini),
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

/// Una fila de «Cómo se movió tu plata»: lo que entró en azul, lo que salió
/// en coral y el cero siempre en gris (mejora 01).
class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.centimos, {this.fuerte = false, this.tono});

  final String etiqueta;
  final int centimos;
  final bool fuerte;
  final Tono? tono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Medidas.e2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: fuerte ? Tipografia.tituloSeccion : Tipografia.secundario,
            ),
          ),
          const SizedBox(width: Medidas.e3),
          MontoText(
            centimos,
            estilo: fuerte
                ? Tipografia.montoMediano
                : Tipografia.textoFuerte.copyWith(fontWeight: FontWeight.w700),
            tono: tono,
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
      padding: const EdgeInsets.symmetric(vertical: Medidas.e2),
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
              borderRadius: BorderRadius.circular(Medidas.radioMini),
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
          borderRadius: BorderRadius.circular(Medidas.radioMini),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (final (n, (pct, _)) in partes.indexed)
                  if (pct > 0)
                    Expanded(
                      flex: pct,
                      child: Container(
                        margin: EdgeInsets.only(
                          right: n < Medidas.e1 ? Medidas.e1 : 0,
                        ),
                        color: colores[n],
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Medidas.e3),
        for (final (n, (_, texto)) in partes.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Medidas.e1),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colores[n],
                    borderRadius: BorderRadius.circular(Medidas.radioMini),
                  ),
                ),
                const SizedBox(width: Medidas.e3),
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

/// «También retiraste S/ 3,030 para ti y pusiste S/ 500 de tu bolsillo.»:
/// lo que movió la plata además de lo que entró y salió (entrega 59). Nulo
/// si no hubo nada de eso.
String? _tambien(InformeMes i) {
  final partes = [
    if (i.retirosCentimos > 0)
      Textos.retirastePara(formatearSoles(i.retirosCentimos)),
    if (i.aportesCentimos > 0)
      Textos.pusisteDeTuBolsilloMonto(formatearSoles(i.aportesCentimos)),
    if (i.ajustesCentimos > 0)
      Textos.enElArqueoSobro(formatearSoles(i.ajustesCentimos)),
    if (i.ajustesCentimos < 0)
      Textos.enElArqueoFalto(formatearSoles(-i.ajustesCentimos)),
  ];
  return partes.isEmpty ? null : Textos.tambien(partes);
}
