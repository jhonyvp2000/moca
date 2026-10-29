import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Un .xlsx mínimo (entrega 14.13): un zip con el XML de Office Open. Basta
/// para texto, montos y fechas con formato, encabezado fijo y filtros; así
/// no hace falta otra librería.

/// Cómo se ve un número.
enum FormatoNumero { general, soles, solesEnteros }

sealed class Celda {
  const Celda({this.fuerte = false});
  final bool fuerte;
}

class CeldaTexto extends Celda {
  const CeldaTexto(this.texto, {super.fuerte});
  final String texto;
}

class CeldaNumero extends Celda {
  const CeldaNumero(
    this.valor, {
    this.formato = FormatoNumero.general,
    super.fuerte,
  });

  /// Un monto en soles con sus céntimos.
  CeldaNumero.soles(int centimos, {bool enteros = false, bool fuerte = false})
    : this(
        centimos / 100,
        formato: enteros ? FormatoNumero.solesEnteros : FormatoNumero.soles,
        fuerte: fuerte,
      );

  final num valor;
  final FormatoNumero formato;
}

class CeldaFecha extends Celda {
  const CeldaFecha(this.fecha);
  final DateTime fecha;
}

class HojaXlsx {
  const HojaXlsx({
    required this.nombre,
    required this.filas,
    this.anchos = const [],
    this.encabezado = false,
  });

  /// Hasta 31 caracteres, sin []:*?/\.
  final String nombre;

  /// Una fila vacía o una celda nula quedan en blanco.
  final List<List<Celda?>> filas;

  /// El ancho de cada columna, en caracteres.
  final List<double> anchos;

  /// La primera fila es el encabezado: en negrita, fija al bajar y con
  /// filtros.
  final bool encabezado;
}

Uint8List armarXlsx(List<HojaXlsx> hojas) {
  final archivo = Archive();
  void agregar(String nombre, String xml) =>
      archivo.addFile(ArchiveFile.bytes(nombre, utf8.encode(_cabecera + xml)));

  agregar(
    '[Content_Types].xml',
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '${[for (var n = 1; n <= hojas.length; n++) '<Override PartName="/xl/worksheets/sheet$n.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join()}'
        '</Types>',
  );
  agregar(
    '_rels/.rels',
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
  );

  final filtros = [
    for (final (i, h) in hojas.indexed)
      if (h.encabezado && h.filas.length > 1)
        '<definedName name="_xlnm._FilterDatabase" localSheetId="$i" '
            'hidden="1">${_escapar("'${h.nombre}'")}!${_rango(h, absoluto: true)}'
            '</definedName>',
  ];
  agregar(
    'xl/workbook.xml',
    '<workbook xmlns="$_principal" xmlns:r="$_relaciones"><sheets>'
        '${[for (final (i, h) in hojas.indexed) '<sheet name="${_escapar(h.nombre)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join()}'
        '</sheets>'
        '${filtros.isEmpty ? '' : '<definedNames>${filtros.join()}</definedNames>'}'
        '</workbook>',
  );
  agregar(
    'xl/_rels/workbook.xml.rels',
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '${[for (var n = 1; n <= hojas.length; n++) '<Relationship Id="rId$n" Type="$_relaciones/worksheet" Target="worksheets/sheet$n.xml"/>'].join()}'
        '<Relationship Id="rId${hojas.length + 1}" Type="$_relaciones/styles" Target="styles.xml"/>'
        '</Relationships>',
  );
  agregar('xl/styles.xml', _estilos);
  for (final (i, h) in hojas.indexed) {
    agregar('xl/worksheets/sheet${i + 1}.xml', _hoja(h));
  }
  return ZipEncoder().encodeBytes(archivo);
}

const _cabecera = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';
const _principal = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
const _relaciones =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

// Los estilos, por posición: 0 normal, 1 encabezado, 2 fecha, 3 soles,
// 4 soles enteros, 5 soles enteros en negrita, 6 soles en negrita, 7 texto
// en negrita.
const _estilos =
    '<styleSheet xmlns="$_principal">'
    '<numFmts count="3">'
    '<numFmt numFmtId="164" formatCode="dd/mm/yyyy"/>'
    '<numFmt numFmtId="165" formatCode="&quot;S/ &quot;#,##0.00"/>'
    '<numFmt numFmtId="166" formatCode="&quot;S/ &quot;#,##0"/>'
    '</numFmts>'
    '<fonts count="2">'
    '<font><sz val="11"/><name val="Calibri"/></font>'
    '<font><b/><sz val="11"/><name val="Calibri"/></font>'
    '</fonts>'
    '<fills count="3">'
    '<fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill>'
    '<fill><patternFill patternType="solid"><fgColor rgb="FFE3ECFB"/>'
    '<bgColor indexed="64"/></patternFill></fill>'
    '</fills>'
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/>'
    '</border></borders>'
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" '
    'borderId="0"/></cellStyleXfs>'
    '<cellXfs count="8">'
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
    '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" '
    'applyFont="1" applyFill="1"/>'
    '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" '
    'applyNumberFormat="1"/>'
    '<xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" '
    'applyNumberFormat="1"/>'
    '<xf numFmtId="166" fontId="0" fillId="0" borderId="0" xfId="0" '
    'applyNumberFormat="1"/>'
    '<xf numFmtId="166" fontId="1" fillId="0" borderId="0" xfId="0" '
    'applyNumberFormat="1" applyFont="1"/>'
    '<xf numFmtId="165" fontId="1" fillId="0" borderId="0" xfId="0" '
    'applyNumberFormat="1" applyFont="1"/>'
    '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" '
    'applyFont="1"/>'
    '</cellXfs>'
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/>'
    '</cellStyles>'
    '</styleSheet>';

String _hoja(HojaXlsx h) {
  final b = StringBuffer('<worksheet xmlns="$_principal">');
  if (h.encabezado) {
    b.write(
      '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" '
      'topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
      '</sheetView></sheetViews>',
    );
  }
  if (h.anchos.isNotEmpty) {
    b.write('<cols>');
    for (final (i, ancho) in h.anchos.indexed) {
      b.write(
        '<col min="${i + 1}" max="${i + 1}" width="$ancho" customWidth="1"/>',
      );
    }
    b.write('</cols>');
  }
  b.write('<sheetData>');
  for (final (f, fila) in h.filas.indexed) {
    b.write('<row r="${f + 1}">');
    for (final (c, celda) in fila.indexed) {
      if (celda == null) continue;
      final ref = '${_columna(c)}${f + 1}';
      final encabezado = h.encabezado && f == 0;
      switch (celda) {
        case CeldaTexto(:final texto):
          if (texto.isEmpty) continue;
          final s = encabezado
              ? 1
              : celda.fuerte
              ? 7
              : 0;
          b.write(
            '<c r="$ref" t="inlineStr"${s == 0 ? '' : ' s="$s"'}><is>'
            '<t xml:space="preserve">${_escapar(texto)}</t></is></c>',
          );
        case CeldaNumero(:final valor, :final formato):
          final s = switch (formato) {
            FormatoNumero.general => celda.fuerte ? 7 : 0,
            FormatoNumero.soles => celda.fuerte ? 6 : 3,
            FormatoNumero.solesEnteros => celda.fuerte ? 5 : 4,
          };
          b.write('<c r="$ref"${s == 0 ? '' : ' s="$s"'}><v>$valor</v></c>');
        case CeldaFecha(:final fecha):
          b.write('<c r="$ref" s="2"><v>${_serial(fecha)}</v></c>');
      }
    }
    b.write('</row>');
  }
  b.write('</sheetData>');
  if (h.encabezado && h.filas.length > 1) {
    b.write('<autoFilter ref="${_rango(h)}"/>');
  }
  b.write('</worksheet>');
  return b.toString();
}

String _rango(HojaXlsx h, {bool absoluto = false}) {
  final columnas = h.filas.fold(0, (n, f) => f.length > n ? f.length : n);
  final d = absoluto ? r'$' : '';
  return '${d}A${d}1:$d${_columna(columnas - 1)}$d${h.filas.length}';
}

/// 0 → A, 25 → Z, 26 → AA.
String _columna(int i) =>
    (i >= 26 ? _columna(i ~/ 26 - 1) : '') + String.fromCharCode(65 + i % 26);

/// Días desde el 30 de diciembre de 1899, como cuenta Excel.
int _serial(DateTime f) => DateTime.utc(
  f.year,
  f.month,
  f.day,
).difference(DateTime.utc(1899, 12, 30)).inDays;

String _escapar(String s) => s
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
