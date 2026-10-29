import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../dominio/informe.dart';
import '../../dominio/modelos.dart';
import '../../pais/peru/formato.dart';
import '../../textos/textos.dart';
import '../../comun/xlsx.dart';
import '../../pais/peru/flujo_credito.dart';

const tipoExcel =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// El Excel de las operaciones del mes (entrega 14.13): las operaciones una
/// por una, el resumen que cuadra con el PDF, los saldos por cuenta y lo que
/// debes. Los montos son números y las fechas, fechas.
Uint8List armarExcelDelInforme(
  InformeMes i,
  DetalleParaPdf d, {
  required String nombreNegocio,
  required DateTime hoy,
}) {
  CeldaTexto t(String? texto, {bool fuerte = false}) =>
      CeldaTexto(texto ?? '', fuerte: fuerte);
  CeldaNumero soles(
    int centimos, {
    bool enteros = false,
    bool fuerte = false,
  }) => CeldaNumero.soles(centimos, enteros: enteros, fuerte: fuerte);

  final operaciones = HojaXlsx(
    nombre: Textos.hojaOperaciones,
    encabezado: true,
    anchos: const [12, 18, 22, 28, 28, 13, 20, 11, 16, 13, 18, 13, 22, 22],
    filas: [
      [
        for (final c in const [
          Textos.columnaFecha,
          Textos.columnaTipo,
          Textos.columnaCategoria,
          Textos.columnaNota,
          Textos.columnaProveedor,
          Textos.columnaRuc,
          Textos.columnaComprobante,
          Textos.columnaIgv,
          Textos.columnaCuenta,
          Textos.columnaMonto,
          Textos.columnaPagado,
          Textos.columnaFechaPago,
          Textos.etiquetaComoSeAnoto,
          Textos.columnaConfianza,
        ])
          t(c),
      ],
      for (final o in d.operaciones)
        [
          CeldaFecha(o.fecha),
          t(Textos.nombreTipo(o.tipo)),
          t(o.categoria),
          t(o.nota),
          t(o.proveedor),
          t(o.ruc),
          t(o.comprobante),
          if (o.igvCentimos case final igv?) soles(igv) else null,
          t(Textos.nombreCuenta(o.cuenta)),
          soles(o.centimos),
          t(switch (o.estadoPago) {
            EstadoPago.pagado => Textos.si,
            EstadoPago.pendiente => Textos.loDebes,
            EstadoPago.parcial => Textos.pagadoEnParte(
              formatearSolesComprobante(o.pagadoCentimos),
            ),
          }),
          if (o.fechaPago case final f?) CeldaFecha(f) else null,
          t(Textos.comoSeAnoto(o.fuente)),
          t(Textos.nivelConfianza(o.confianza)),
        ],
    ],
  );

  // Las mismas cifras de «Cómo se movió tu plata», en soles enteros como en
  // el PDF; la celda guarda los céntimos.
  final resumen = HojaXlsx(
    nombre: Textos.hojaResumen,
    anchos: const [34, 40],
    filas: [
      [t(Textos.negocio, fuerte: true), t(nombreNegocio)],
      [
        t(Textos.periodo, fuerte: true),
        t(Textos.periodoDelAl(d.desde, d.hasta)),
      ],
      [t(Textos.hechoElCorto, fuerte: true), CeldaFecha(hoy)],
      [],
      [t(Textos.comoSeMovio, fuerte: true)],
      [
        t(i.desdeDia == null ? Textos.empezasteElMesCon : Textos.empezasteCon),
        soles(i.inicioCentimos, enteros: true),
      ],
      [t(Textos.masEntro), soles(i.entroCentimos, enteros: true)],
      if (i.aportesCentimos > 0)
        [
          t(Textos.masPusisteDeTuBolsillo),
          soles(i.aportesCentimos, enteros: true),
        ],
      [t(Textos.menosSalioDelNegocio), soles(i.salioCentimos, enteros: true)],
      [t(Textos.menosRetirasteParaTi), soles(i.retirosCentimos, enteros: true)],
      if (i.ajustesCentimos != 0)
        [
          t(
            i.ajustesCentimos > 0
                ? Textos.masSobroEnElArqueo
                : Textos.menosFaltoEnElArqueo,
          ),
          soles(i.ajustesCentimos.abs(), enteros: true),
        ],
      [
        t(
          i.enCurso ? Textos.tienesHoy : Textos.terminasteElMesCon,
          fuerte: true,
        ),
        soles(i.finCentimos, enteros: true, fuerte: true),
      ],
      [],
      [
        t(Textos.loQueDebesTitulo, fuerte: true),
        soles(i.loQueDebesCentimos, enteros: true, fuerte: true),
      ],
      [],
      [t(Textos.notaCajaExcel)],
      [t(Textos.aclaracionPdf)],
    ],
  );

  final saldos = HojaXlsx(
    nombre: Textos.hojaSaldos,
    encabezado: true,
    anchos: const [22, 16],
    filas: [
      [t(Textos.columnaCuenta), t(Textos.columnaSaldo)],
      for (final e in d.saldosAlCierre.entries)
        [t(Textos.nombreCuenta(e.key)), soles(e.value, enteros: true)],
      [
        t(Textos.columnaTotal, fuerte: true),
        soles(
          d.saldosAlCierre.values.fold(0, (s, v) => s + v),
          enteros: true,
          fuerte: true,
        ),
      ],
    ],
  );

  final deudas = HojaXlsx(
    nombre: Textos.hojaLoQueDebes,
    encabezado: true,
    anchos: const [11, 28, 22, 14],
    filas: [
      [
        t(Textos.columnaDesde),
        t(Textos.columnaProveedor),
        t(Textos.columnaDetalle),
        t(Textos.columnaMonto),
      ],
      for (final x in d.deudas)
        [
          CeldaFecha(x.fecha),
          t(x.proveedor),
          t(x.categoria),
          soles(x.centimos),
        ],
      if (d.deudas.isNotEmpty)
        [
          t(Textos.columnaTotal, fuerte: true),
          null,
          null,
          soles(d.deudas.fold(0, (s, x) => s + x.centimos), fuerte: true),
        ],
    ],
  );

  return armarXlsx([operaciones, resumen, saldos, deudas]);
}

/// «Moca-Bodega-Don-Lucho-operaciones-octubre-2026.xlsx».
String nombreDelExcel(String nombreNegocio, DateTime mes) {
  final limpio = nombreNegocio
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9áéíóúüñÁÉÍÓÚÜÑ]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final partes = [
    'Moca',
    if (limpio.isNotEmpty) limpio,
    'operaciones',
    nombreDelMes(mes),
    '${mes.year}',
  ];
  return '${partes.join('-')}.xlsx';
}

/// Arma el Excel y lo guarda en la carpeta temporal del teléfono. Devuelve
/// la ruta para compartirlo.
Future<String> guardarExcelDelInforme(
  InformeMes informe,
  DetalleParaPdf detalle, {
  required String nombreNegocio,
  required DateTime hoy,
}) async {
  final bytes = armarExcelDelInforme(
    informe,
    detalle,
    nombreNegocio: nombreNegocio,
    hoy: hoy,
  );
  final carpeta = await getTemporaryDirectory();
  final archivo = File(
    '${carpeta.path}/${nombreDelExcel(nombreNegocio, informe.mes)}',
  );
  await archivo.writeAsBytes(bytes, flush: true);
  return archivo.path;
}

/// Arma el flujo en el formato de la caja (entrega 14.15) y lo guarda en la
/// carpeta temporal del teléfono.
Future<String> guardarFlujoParaCredito(
  FlujoParaCredito flujo, {
  required String nombreNegocio,
  required DateTime hoy,
}) async {
  final carpeta = await getTemporaryDirectory();
  final archivo = File(
    '${carpeta.path}/${nombreDelFlujoParaCredito(nombreNegocio, hoy)}',
  );
  await archivo.writeAsBytes(
    armarFlujoParaCredito(flujo, nombreNegocio: nombreNegocio, hoy: hoy),
    flush: true,
  );
  return archivo.path;
}
