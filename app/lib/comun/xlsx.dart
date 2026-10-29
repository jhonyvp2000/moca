import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Un .xlsx mínimo (entrega 14.13): un zip con el XML de Office Open. Basta
/// para texto, montos, fechas, fórmulas, rellenos, encabezado fijo y filtros;
/// así no hace falta otra librería. Las fórmulas se recalculan al abrir el
/// archivo (entrega 14.15).

/// Cómo se ve un número.
enum FormatoNumero { general, soles, solesEnteros, fecha, porcentaje }

/// El fondo de la celda. En el flujo para la caja, amarillo es lo que llena
/// el dueño y gris lo que se calcula solo, como en la plantilla.
enum Relleno { ninguno, encabezado, paraLlenar, calculado }

sealed class Celda {
  const Celda({
    this.fuerte = false,
    this.relleno = Relleno.ninguno,
    this.ajustar = false,
  });
  final bool fuerte;
  final Relleno relleno;

  /// El texto largo baja a otra línea dentro de la celda.
  final bool ajustar;
}

class CeldaTexto extends Celda {
  const CeldaTexto(this.texto, {super.fuerte, super.relleno, super.ajustar});
  final String texto;
}

class CeldaNumero extends Celda {
  const CeldaNumero(
    this.valor, {
    this.formato = FormatoNumero.general,
    super.fuerte,
    super.relleno,
  });

  /// Un monto en soles con sus céntimos.
  CeldaNumero.soles(
    int centimos, {
    bool enteros = false,
    bool fuerte = false,
    Relleno relleno = Relleno.ninguno,
  }) : this(
         centimos / 100,
         formato: enteros ? FormatoNumero.solesEnteros : FormatoNumero.soles,
         fuerte: fuerte,
         relleno: relleno,
       );

  final num valor;
  final FormatoNumero formato;
}

class CeldaFecha extends Celda {
  const CeldaFecha(this.fecha);
  final DateTime fecha;
}

/// Una fórmula de Excel, en inglés y sin el «=» del inicio
/// («SUM(B5:B8)»).
class CeldaFormula extends Celda {
  const CeldaFormula(
    this.formula, {
    this.formato = FormatoNumero.general,
    super.fuerte,
    super.relleno = Relleno.calculado,
  });
  final String formula;
  final FormatoNumero formato;
}

/// Una celda vacía con formato: la que llena el dueño.
class CeldaVacia extends Celda {
  const CeldaVacia({
    this.formato = FormatoNumero.general,
    super.relleno = Relleno.paraLlenar,
  });
  final FormatoNumero formato;
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
        // Las fórmulas van sin resultado guardado: se calculan al abrir.
        '<calcPr calcId="191029" fullCalcOnLoad="1"/>'
        '</workbook>',
  );
  agregar(
    'xl/_rels/workbook.xml.rels',
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '${[for (var n = 1; n <= hojas.length; n++) '<Relationship Id="rId$n" Type="$_relaciones/worksheet" Target="worksheets/sheet$n.xml"/>'].join()}'
        '<Relationship Id="rId${hojas.length + 1}" Type="$_relaciones/styles" Target="styles.xml"/>'
        '</Relationships>',
  );
  final estilos = _Estilos();
  final xmlHojas = [for (final h in hojas) _hoja(h, estilos)];
  agregar('xl/styles.xml', estilos.xml());
  for (final (i, xml) in xmlHojas.indexed) {
    agregar('xl/worksheets/sheet${i + 1}.xml', xml);
  }
  return ZipEncoder().encodeBytes(archivo);
}

const _cabecera = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';
const _principal = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
const _relaciones =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

/// Los estilos que se usan, en el orden en que aparecen. El 0 es el normal.
class _Estilos {
  final _lista = <(FormatoNumero, bool, Relleno, bool)>[
    (FormatoNumero.general, false, Relleno.ninguno, false),
  ];

  int indice(
    FormatoNumero formato,
    bool fuerte,
    Relleno relleno,
    bool ajustar,
  ) {
    final estilo = (formato, fuerte, relleno, ajustar);
    final i = _lista.indexOf(estilo);
    if (i >= 0) return i;
    _lista.add(estilo);
    return _lista.length - 1;
  }

  static int _formato(FormatoNumero f) => switch (f) {
    FormatoNumero.general => 0,
    FormatoNumero.fecha => 164,
    FormatoNumero.soles => 165,
    FormatoNumero.solesEnteros => 166,
    FormatoNumero.porcentaje => 167,
  };

  static int _relleno(Relleno r) => switch (r) {
    Relleno.ninguno => 0,
    Relleno.encabezado => 2,
    Relleno.paraLlenar => 3,
    Relleno.calculado => 4,
  };

  String xml() {
    final xfs = [
      for (final (formato, fuerte, relleno, ajustar) in _lista)
        '<xf numFmtId="${_formato(formato)}" fontId="${fuerte ? 1 : 0}" '
            'fillId="${_relleno(relleno)}" borderId="0" xfId="0"'
            '${formato == FormatoNumero.general ? '' : ' applyNumberFormat="1"'}'
            '${fuerte ? ' applyFont="1"' : ''}'
            '${relleno == Relleno.ninguno ? '' : ' applyFill="1"'}'
            '${ajustar ? ' applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>' : '/>'}',
    ];
    String solido(String rgb) =>
        '<fill><patternFill patternType="solid"><fgColor rgb="$rgb"/>'
        '<bgColor indexed="64"/></patternFill></fill>';
    return '<styleSheet xmlns="$_principal">'
        '<numFmts count="4">'
        '<numFmt numFmtId="164" formatCode="dd/mm/yyyy"/>'
        '<numFmt numFmtId="165" formatCode="&quot;S/ &quot;#,##0.00"/>'
        '<numFmt numFmtId="166" formatCode="&quot;S/ &quot;#,##0"/>'
        '<numFmt numFmtId="167" formatCode="0.0%"/>'
        '</numFmts>'
        '<fonts count="2">'
        '<font><sz val="11"/><name val="Calibri"/></font>'
        '<font><b/><sz val="11"/><name val="Calibri"/></font>'
        '</fonts>'
        '<fills count="5">'
        '<fill><patternFill patternType="none"/></fill>'
        '<fill><patternFill patternType="gray125"/></fill>'
        '${solido('FFE3ECFB')}${solido('FFFFF2CC')}${solido('FFF2F2F2')}'
        '</fills>'
        '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/>'
        '</border></borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" '
        'borderId="0"/></cellStyleXfs>'
        '<cellXfs count="${xfs.length}">${xfs.join()}</cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" '
        'builtinId="0"/></cellStyles>'
        '</styleSheet>';
  }
}

String _hoja(HojaXlsx h, _Estilos estilos) {
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
      String s(FormatoNumero formato) {
        final i = estilos.indice(
          formato,
          celda.fuerte || encabezado,
          encabezado ? Relleno.encabezado : celda.relleno,
          celda.ajustar,
        );
        return i == 0 ? '' : ' s="$i"';
      }

      switch (celda) {
        case CeldaTexto(:final texto):
          if (texto.isEmpty && celda.relleno == Relleno.ninguno) continue;
          b.write(
            '<c r="$ref" t="inlineStr"${s(FormatoNumero.general)}><is>'
            '<t xml:space="preserve">${_escapar(texto)}</t></is></c>',
          );
        case CeldaNumero(:final valor, :final formato):
          b.write('<c r="$ref"${s(formato)}><v>$valor</v></c>');
        case CeldaFecha(:final fecha):
          b.write(
            '<c r="$ref"${s(FormatoNumero.fecha)}><v>${_serial(fecha)}</v></c>',
          );
        case CeldaFormula(:final formula, :final formato):
          b.write('<c r="$ref"${s(formato)}><f>${_escapar(formula)}</f></c>');
        case CeldaVacia(:final formato):
          b.write('<c r="$ref"${s(formato)}/>');
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
String columnaXlsx(int i) => _columna(i);

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
