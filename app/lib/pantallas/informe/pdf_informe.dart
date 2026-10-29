import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../dominio/informe.dart';
import '../../pais/peru/formato.dart';
import '../../textos/textos.dart';

/// El PDF del informe (entrega 14.12): una base común (periodo exacto, qué
/// es y qué no es, logo y páginas) y tres versiones según para quién es. Se
/// arma en el teléfono, sin servidor.
Future<Uint8List> armarPdfDelInforme(
  InformeMes i,
  DetalleParaPdf d, {
  required DestinoInforme destino,
  required String nombreNegocio,
  required DateTime hoy,
}) async {
  Future<pw.Font> fuente(String peso) async => pw.Font.ttf(
    await rootBundle.load('assets/fuentes/PlusJakartaSans-$peso.ttf'),
  );
  final normal = await fuente('Regular');
  final negrita = await fuente('Bold');

  const azul = PdfColor.fromInt(0xFF1D4ED8);
  const textoPrincipal = PdfColor.fromInt(0xFF0F1F3D);
  const textoSecundario = PdfColor.fromInt(0xFF4B5A75);
  const borde = PdfColor.fromInt(0xFFD8E0EC);
  const pista = PdfColor.fromInt(0xFFE4EAF3);
  const tinte = PdfColor.fromInt(0xFFE3ECFB);
  // El monto de una salida, en rojo sobrio (entrega 14.9.2).
  const salida = PdfColor.fromInt(0xFFB42318);

  pw.TextStyle estilo(double tamano, {bool fuerte = false, PdfColor? color}) =>
      pw.TextStyle(
        font: fuerte ? negrita : normal,
        fontSize: tamano,
        color: color ?? textoPrincipal,
      );

  // Un recuadro no se parte entre dos hojas, salvo una lista larga que no
  // cabría en una sola.
  pw.Widget seccion(
    String titulo,
    List<pw.Widget> hijos, {
    bool puedePartirse = false,
  }) => pw.Inseparable(
    canSpan: puedePartirse,
    child: pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borde),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(titulo, style: estilo(11.5, fuerte: true)),
          pw.SizedBox(height: 6),
          ...hijos,
        ],
      ),
    ),
  );

  pw.Widget fila(
    String etiqueta,
    String monto, {
    bool fuerte = false,
    bool deSalida = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            etiqueta,
            style: estilo(
              10.5,
              fuerte: fuerte,
              color: fuerte ? null : textoSecundario,
            ),
          ),
        ),
        pw.Text(
          monto,
          style: estilo(10.5, fuerte: true, color: deSalida ? salida : null),
        ),
      ],
    ),
  );

  /// Una tabla simple: encabezado en gris y las columnas de [derecha]
  /// alineadas a la derecha (montos).
  pw.Widget tabla(
    List<String> encabezado,
    List<List<String>> filas, {
    Set<int> derecha = const {},
    Map<int, pw.TableColumnWidth> anchos = const {},
  }) => pw.Table(
    columnWidths: anchos,
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: pista, width: 0.6),
    ),
    children: [
      pw.TableRow(
        children: [
          for (final (c, t) in encabezado.indexed)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4, right: 6),
              child: pw.Text(
                t,
                textAlign: derecha.contains(c)
                    ? pw.TextAlign.right
                    : pw.TextAlign.left,
                style: estilo(9, fuerte: true, color: textoSecundario),
              ),
            ),
        ],
      ),
      for (final f in filas)
        pw.TableRow(
          children: [
            for (final (c, t) in f.indexed)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3)
                    .copyWith(right: 6),
                child: pw.Text(
                  t,
                  textAlign: derecha.contains(c)
                      ? pw.TextAlign.right
                      : pw.TextAlign.left,
                  style: estilo(9.5),
                ),
              ),
          ],
        ),
    ],
  );

  String fechaCorta(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}';

  // --- Las piezas ---------------------------------------------------------

  final crecio = i.crecioCentimos;
  final anterior = i.mesAnterior == null ? '' : nombreDelMes(i.mesAnterior!);
  final diferencia = i.diferenciaConAnteriorCentimos;

  // Arriba, en grande: cuánto creció o bajó la plata.
  pw.Widget cuantoCrecio() => seccion(
    crecio > 0
        ? Textos.tuPlataCrecio
        : crecio < 0
        ? Textos.tuPlataBajo
        : Textos.tuPlataIgual,
    [
      pw.Text(formatearSoles(crecio.abs()), style: estilo(26, fuerte: true)),
      pw.Text(
        diferencia == null
            ? Textos.primerMesConMoca
            : diferencia > 0
            ? Textos.masQueEn(formatearSoles(diferencia), anterior)
            : diferencia < 0
            ? Textos.menosQueEn(formatearSoles(-diferencia), anterior)
            : Textos.igualQueEn(anterior),
        style: estilo(10.5),
      ),
    ],
  );

  // El flujo de caja del mes, que cuadra con el saldo (entrega 14.9).
  pw.Widget comoSeMovio() => seccion(Textos.comoSeMovio, [
    fila(
      i.desdeDia == null ? Textos.empezasteElMesCon : Textos.empezasteCon,
      formatearSoles(i.inicioCentimos),
    ),
    fila(Textos.masEntro, formatearSoles(i.entroCentimos)),
    if (i.aportesCentimos > 0)
      fila(Textos.masPusisteDeTuBolsillo, formatearSoles(i.aportesCentimos)),
    fila(
      Textos.menosSalioDelNegocio,
      formatearSoles(i.salioCentimos),
      deSalida: true,
    ),
    fila(
      Textos.menosRetirasteParaTi,
      formatearSoles(i.retirosCentimos),
      deSalida: true,
    ),
    if (i.ajustesCentimos != 0)
      fila(
        i.ajustesCentimos > 0
            ? Textos.masSobroEnElArqueo
            : Textos.menosFaltoEnElArqueo,
        formatearSoles(i.ajustesCentimos.abs()),
        deSalida: i.ajustesCentimos < 0,
      ),
    fila(
      i.enCurso ? Textos.tienesHoy : Textos.terminasteElMesCon,
      formatearSoles(i.finCentimos),
      fuerte: true,
    ),
  ]);

  // Cuánto hay en cada cuenta al cierre: suman lo de arriba.
  pw.Widget cuentas() => seccion(
    i.enCurso ? Textos.cuantoHayHoyEnCadaCuenta : Textos.cuantoHabiaAlCierre,
    [
      for (final e in d.saldosAlCierre.entries)
        fila(Textos.nombreCuenta(e.key), formatearSoles(e.value)),
    ],
  );

  pw.Widget enQueSeFue() => seccion(Textos.enQueSeFue, [
    if (i.gastos.isEmpty)
      pw.Text(Textos.sinGastos, style: estilo(10.5))
    else
      for (final g in i.gastos)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 150,
                child: pw.Text(g.nombre ?? Textos.loDemas, style: estilo(10.5)),
              ),
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    pw.Container(height: 7, color: pista),
                    pw.LayoutBuilder(
                      builder: (context, limites) => pw.Container(
                        height: 7,
                        width:
                            limites!.maxWidth *
                            (g.centimos / i.gastos.first.centimos).clamp(
                              0.03,
                              1,
                            ),
                        color: azul,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.SizedBox(
                width: 80,
                child: pw.Text(
                  formatearSoles(g.centimos),
                  textAlign: pw.TextAlign.right,
                  style: estilo(10.5, fuerte: true),
                ),
              ),
            ],
          ),
        ),
    if (i.mesAnterior != null && i.gastos.isNotEmpty) ...[
      pw.SizedBox(height: 4),
      pw.Text(switch (i.cambio) {
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
      }, style: estilo(10, color: azul)),
    ],
    if (i.advertenciaMercaderia) ...[
      pw.SizedBox(height: 4),
      pw.Text(Textos.advertenciaMercaderia, style: estilo(10)),
    ],
  ]);

  pw.Widget deDondeVino() => seccion(Textos.deDondeVino, [
    if (d.ingresos.isEmpty)
      pw.Text(Textos.sinIngresos, style: estilo(10.5))
    else
      for (final g in d.ingresos)
        fila(g.nombre ?? Textos.loDemas, formatearSoles(g.centimos)),
  ]);

  pw.Widget loQueDebesTotal() => seccion(Textos.loQueDebesTitulo, [
    fila(
      i.loQueDebesCentimos == 0 ? Textos.noDebesNada : Textos.columnaTotal,
      formatearSoles(i.loQueDebesCentimos),
      fuerte: true,
    ),
  ]);

  pw.Widget loQueDebesDetalle() =>
      seccion(Textos.loQueDebesTitulo, puedePartirse: d.deudas.length > 15, [
        if (d.deudas.isEmpty)
          pw.Text(Textos.noDebesNada, style: estilo(10.5))
        else ...[
          tabla(
            const [
              Textos.columnaFecha,
              Textos.columnaProveedor,
              Textos.columnaDetalle,
              Textos.columnaMonto,
            ],
            [
              for (final x in d.deudas)
                [
                  fechaCorta(x.fecha),
                  x.proveedor ?? '—',
                  x.categoria ?? '—',
                  formatearSolesComprobante(x.centimos),
                ],
            ],
            derecha: const {3},
            anchos: const {
              0: pw.FixedColumnWidth(48),
              3: pw.FixedColumnWidth(80),
            },
          ),
          pw.SizedBox(height: 4),
          fila(
            Textos.columnaTotal,
            formatearSoles(i.loQueDebesCentimos),
            fuerte: true,
          ),
        ],
      ]);

  pw.Widget comprobantes() => seccion(
    Textos.comprobantesDelMes,
    puedePartirse: d.comprobantes.length > 15,
    [
      if (d.comprobantes.isEmpty)
        pw.Text(Textos.sinComprobantes, style: estilo(10.5))
      else
        tabla(
          const [
            Textos.columnaFecha,
            Textos.columnaComprobante,
            Textos.columnaRuc,
            Textos.columnaProveedor,
            Textos.columnaIgv,
            Textos.columnaTotal,
          ],
          [
            for (final c in d.comprobantes)
              [
                fechaCorta(c.fecha),
                [
                  ?c.tipo,
                  if (c.serie != null || c.numero != null)
                    '${c.serie ?? ''}-${c.numero ?? ''}',
                ].join(' '),
                c.ruc ?? '—',
                c.proveedor ?? '—',
                c.igvCentimos == null
                    ? '—'
                    : formatearSolesComprobante(c.igvCentimos!),
                formatearSolesComprobante(c.totalCentimos) +
                    (c.pagado ? '' : ' (${Textos.loDebesCorto})'),
              ],
          ],
          derecha: const {4, 5},
          anchos: const {
            0: pw.FixedColumnWidth(40),
            2: pw.FixedColumnWidth(78),
            4: pw.FixedColumnWidth(56),
            5: pw.FixedColumnWidth(92),
          },
        ),
    ],
  );

  pw.Widget confianza() => switch (i.confianza) {
    final c? => seccion(Textos.queTanSeguras, [
      pw.Text(
        Textos.confianzaEnUnaLinea(c.conComprobante, c.conFoto, c.sinPapel),
        style: estilo(10.5),
      ),
    ]),
    null => pw.SizedBox(),
  };

  // Para un crédito: los últimos meses, uno por fila.
  pw.Widget mesPorMes() {
    final conAportes = d.meses.any((m) => m.aportesCentimos > 0);
    final completos = [
      for (final m in d.meses)
        if (!m.enCurso && m.desdeDia == null) m,
    ];
    final paraPromedio = completos.isEmpty ? d.meses : completos;
    final promedio = paraPromedio.isEmpty
        ? 0
        : paraPromedio.fold(0, (s, m) => s + m.entroCentimos) ~/
              paraPromedio.length;
    return seccion(Textos.mesPorMes, [
      fila(Textos.entroPorMes, formatearSoles(promedio), fuerte: true),
      if (completos.isNotEmpty && completos.length < d.meses.length)
        pw.Text(
          Textos.soloMesesCompletos,
          style: estilo(9, color: textoSecundario),
        ),
      pw.SizedBox(height: 6),
      tabla(
        [
          Textos.columnaMes,
          Textos.columnaEntro,
          if (conAportes) Textos.columnaPusiste,
          Textos.columnaSalio,
          Textos.columnaRetiraste,
          Textos.columnaCrecio,
          Textos.columnaAlCierre,
        ],
        [
          for (final m in d.meses)
            [
              '${nombreDelMesConMayuscula(m.mes)} ${m.mes.year}'
                  '${m.enCurso || m.desdeDia != null ? ' *' : ''}',
              formatearSoles(m.entroCentimos),
              if (conAportes) formatearSoles(m.aportesCentimos),
              formatearSoles(m.salioCentimos),
              formatearSoles(m.retirosCentimos),
              formatearSoles(m.crecioCentimos),
              formatearSoles(m.finCentimos),
            ],
        ],
        derecha: {for (var c = 1; c <= (conAportes ? 6 : 5); c++) c},
        anchos: const {0: pw.FixedColumnWidth(92)},
      ),
      if (completos.length < d.meses.length) ...[
        pw.SizedBox(height: 4),
        pw.Text(Textos.mesIncompleto, style: estilo(9, color: textoSecundario)),
      ],
    ]);
  }

  // --- La hoja ------------------------------------------------------------

  final (titulo, periodo) = switch (destino) {
    DestinoInforme.credito => (
      Textos.resumenDeMeses(d.meses.length),
      Textos.periodoDeMeses(d.meses.first.mes, d.meses.last.mes),
    ),
    _ => (
      Textos.informeDe(nombreDelMes(i.mes), i.mes.year),
      Textos.periodoDelAl(d.desde, d.hasta),
    ),
  };
  final etiqueta = switch (destino) {
    DestinoInforme.dueno => null,
    DestinoInforme.contador => Textos.etiquetaParaContador,
    DestinoInforme.credito => Textos.etiquetaParaCredito,
  };

  final cuerpo = switch (destino) {
    DestinoInforme.dueno => [
      cuantoCrecio(),
      comoSeMovio(),
      cuentas(),
      enQueSeFue(),
      loQueDebesTotal(),
    ],
    DestinoInforme.contador => [
      cuantoCrecio(),
      comoSeMovio(),
      cuentas(),
      deDondeVino(),
      enQueSeFue(),
      loQueDebesDetalle(),
      comprobantes(),
      confianza(),
    ],
    DestinoInforme.credito => [
      mesPorMes(),
      cuentas(),
      loQueDebesDetalle(),
      confianza(),
      pw.Text(Textos.notaCredito, style: estilo(10, fuerte: true)),
    ],
  };

  final documento = pw.Document(title: titulo, author: 'Moca');
  documento.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 30, 36, 30),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                '$nombreNegocio · $titulo',
                style: estilo(9, color: textoSecundario),
              ),
            ),
      footer: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Divider(color: borde, height: 10),
          pw.Text(Textos.aclaracionPdf, style: estilo(8.5)),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  Textos.pieDelPdf,
                  style: estilo(8.5, color: textoSecundario),
                ),
              ),
              pw.Text(
                Textos.paginaDe(context.pageNumber, context.pagesCount),
                style: estilo(8.5, color: textoSecundario),
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        // El logo de Moca y para quién es.
        pw.Row(
          children: [
            pw.Container(
              width: 22,
              height: 22,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: azul,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'M',
                style: estilo(13, fuerte: true, color: PdfColors.white),
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Text('Moca', style: estilo(12, fuerte: true, color: azul)),
            pw.Spacer(),
            if (etiqueta != null)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: tinte,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  etiqueta,
                  style: estilo(9, fuerte: true, color: azul),
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(nombreNegocio, style: estilo(10.5, color: textoSecundario)),
        pw.Text(titulo, style: estilo(18, fuerte: true)),
        pw.Text(
          '$periodo · ${Textos.hechoEl(formatearFechaLarga(hoy))}',
          style: estilo(9.5, color: textoSecundario),
        ),
        pw.SizedBox(height: 12),
        ...cuerpo,
      ],
    ),
  );
  return documento.save();
}

/// «Moca-Bodega-Don-Lucho-octubre-2026.pdf»; el de crédito y el del
/// contador lo dicen en el nombre.
String nombreDelPdf(
  String nombreNegocio,
  DateTime mes, {
  DestinoInforme destino = DestinoInforme.dueno,
}) {
  final limpio = nombreNegocio
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9áéíóúüñÁÉÍÓÚÜÑ]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final partes = [
    'Moca',
    if (limpio.isNotEmpty) limpio,
    ?switch (destino) {
      DestinoInforme.dueno => null,
      DestinoInforme.contador => 'contador',
      DestinoInforme.credito => 'credito',
    },
    nombreDelMes(mes),
    '${mes.year}',
  ];
  return '${partes.join('-')}.pdf';
}

/// Arma el PDF y lo guarda en la carpeta temporal del teléfono. Devuelve la
/// ruta para compartirlo.
Future<String> guardarPdfDelInforme(
  InformeMes informe,
  DetalleParaPdf detalle, {
  required DestinoInforme destino,
  required String nombreNegocio,
  required DateTime hoy,
}) async {
  final bytes = await armarPdfDelInforme(
    informe,
    detalle,
    destino: destino,
    nombreNegocio: nombreNegocio,
    hoy: hoy,
  );
  final carpeta = await getTemporaryDirectory();
  final archivo = File(
    '${carpeta.path}/${nombreDelPdf(nombreNegocio, informe.mes, destino: destino)}',
  );
  await archivo.writeAsBytes(bytes, flush: true);
  return archivo.path;
}
