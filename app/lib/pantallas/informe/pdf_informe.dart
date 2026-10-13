import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../dominio/informe.dart';
import '../../pais/peru/formato.dart';
import '../../textos/textos.dart';

/// El PDF del informe del mes: lo mismo que muestra S14, en una hoja A4.
/// Se arma en el teléfono, sin servidor.
Future<Uint8List> armarPdfDelInforme(
  InformeMes i, {
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

  pw.TextStyle estilo(double tamano, {bool fuerte = false, PdfColor? color}) =>
      pw.TextStyle(
        font: fuerte ? negrita : normal,
        fontSize: tamano,
        color: color ?? textoPrincipal,
      );

  pw.Widget seccion(String titulo, List<pw.Widget> hijos) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: borde),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(titulo, style: estilo(12, fuerte: true)),
        pw.SizedBox(height: 8),
        ...hijos,
      ],
    ),
  );

  pw.Widget fila(String etiqueta, String monto, {bool fuerte = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                etiqueta,
                style: estilo(
                  11,
                  fuerte: fuerte,
                  color: fuerte ? null : textoSecundario,
                ),
              ),
            ),
            pw.Text(monto, style: estilo(11, fuerte: true)),
          ],
        ),
      );

  final ganancia = i.gananciaCentimos;
  final anterior = i.mesAnterior == null ? '' : nombreDelMes(i.mesAnterior!);
  final diferencia = i.diferenciaConAnteriorCentimos;
  final periodo = i.desdeDia != null
      ? (i.enCurso
            ? Textos.desdeElDiaHastaHoy(i.desdeDia!)
            : Textos.desdeElDia(i.desdeDia!))
      : (i.enCurso ? Textos.hastaHoy : null);

  final documento = pw.Document(
    title: Textos.informeDe(nombreDelMes(i.mes), i.mes.year),
    author: 'Moca',
  );
  documento.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (context) =>
          pw.Text(Textos.pieDelPdf, style: estilo(9, color: textoSecundario)),
      build: (context) => [
        pw.Text(nombreNegocio, style: estilo(11, color: textoSecundario)),
        pw.Text(
          Textos.informeDe(nombreDelMes(i.mes), i.mes.year),
          style: estilo(20, fuerte: true),
        ),
        pw.Text(
          [?periodo, Textos.hechoEl(formatearFechaLarga(hoy))].join(' · '),
          style: estilo(10, color: textoSecundario),
        ),
        pw.SizedBox(height: 16),
        seccion(ganancia >= 0 ? Textos.ganaste : Textos.perdiste, [
          pw.Text(
            formatearSoles(ganancia.abs()),
            style: estilo(28, fuerte: true),
          ),
          pw.Text(
            diferencia == null
                ? Textos.primerMesConMoca
                : diferencia > 0
                ? Textos.masQueEn(formatearSoles(diferencia), anterior)
                : diferencia < 0
                ? Textos.menosQueEn(formatearSoles(-diferencia), anterior)
                : Textos.igualQueEn(anterior),
            style: estilo(11),
          ),
          pw.Text(
            Textos.entroSalio(
              formatearSoles(i.entroCentimos),
              formatearSoles(i.salioCentimos),
            ),
            style: estilo(10, color: textoSecundario),
          ),
        ]),
        seccion(Textos.loQueGanasteYRetiraste, [
          fila(
            ganancia >= 0 ? Textos.ganoElNegocio : Textos.perdioElNegocio,
            formatearSoles(ganancia.abs()),
          ),
          fila(Textos.retirasteParaTi, formatearSoles(i.retirosCentimos)),
          i.quedoCentimos >= 0 || ganancia <= 0
              ? fila(
                  Textos.quedoEnElNegocio,
                  formatearSoles(i.quedoCentimos),
                  fuerte: true,
                )
              : pw.Text(
                  Textos.sacasteMas(formatearSoles(-i.quedoCentimos)),
                  style: estilo(11, fuerte: true),
                ),
        ]),
        seccion(Textos.enQueSeFue, [
          if (i.gastos.isEmpty)
            pw.Text(Textos.sinGastos, style: estilo(11))
          else
            for (final g in i.gastos)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 150,
                      child: pw.Text(
                        g.nombre ?? Textos.loDemas,
                        style: estilo(11),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Stack(
                        children: [
                          pw.Container(height: 8, color: pista),
                          pw.LayoutBuilder(
                            builder: (context, limites) => pw.Container(
                              height: 8,
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
                        style: estilo(11, fuerte: true),
                      ),
                    ),
                  ],
                ),
              ),
          if (i.mesAnterior != null && i.gastos.isNotEmpty) ...[
            pw.SizedBox(height: 6),
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
            }, style: estilo(11, color: azul)),
          ],
        ]),
        seccion(Textos.loQueDebesTitulo, [
          pw.Text(
            formatearSoles(i.loQueDebesCentimos),
            style: estilo(16, fuerte: true),
          ),
        ]),
        if (i.confianza case final c?)
          seccion(Textos.queTanSeguras, [
            pw.Text(Textos.conComprobante(c.conComprobante), style: estilo(11)),
            pw.Text(Textos.conFoto(c.conFoto), style: estilo(11)),
            pw.Text(Textos.sinPapel(c.sinPapel), style: estilo(11)),
          ]),
        if (i.advertenciaMercaderia)
          pw.Text(Textos.advertenciaMercaderia, style: estilo(11)),
      ],
    ),
  );
  return documento.save();
}

/// «Moca-Bodega-Don-Lucho-octubre-2026.pdf».
String nombreDelPdf(String nombreNegocio, DateTime mes) {
  final limpio = nombreNegocio
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9áéíóúüñÁÉÍÓÚÜÑ]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final partes = [
    'Moca',
    if (limpio.isNotEmpty) limpio,
    nombreDelMes(mes),
    '${mes.year}',
  ];
  return '${partes.join('-')}.pdf';
}

/// Arma el PDF y lo guarda en la carpeta temporal del teléfono. Devuelve la
/// ruta para compartirlo.
Future<String> guardarPdfDelInforme(
  InformeMes informe, {
  required String nombreNegocio,
  required DateTime hoy,
}) async {
  final bytes = await armarPdfDelInforme(
    informe,
    nombreNegocio: nombreNegocio,
    hoy: hoy,
  );
  final carpeta = await getTemporaryDirectory();
  final archivo = File(
    '${carpeta.path}/${nombreDelPdf(nombreNegocio, informe.mes)}',
  );
  await archivo.writeAsBytes(bytes, flush: true);
  return archivo.path;
}
