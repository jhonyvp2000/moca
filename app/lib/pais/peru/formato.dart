// Formatos de Perú. Lo específico del país vive en lib/pais/peru/.

/// Espacio que no se parte: «S/ 4,250» nunca queda en dos líneas.
const _espacioFijo = ' ';

/// Monto en soles enteros, con el símbolo pegado a la cifra: `S/ 4,250`.
/// Los céntimos solo se muestran dentro del comprobante (diseno/estilo.md).
String formatearSoles(int centimos) {
  final soles = (centimos.abs() / 100).round();
  final signo = centimos < 0 && soles != 0 ? '−' : '';
  return '${signo}S/$_espacioFijo${separarMiles(soles)}';
}

/// 4250 → «4,250».
String separarMiles(int numero) {
  final texto = numero.abs().toString();
  final partes = <String>[];
  for (var fin = texto.length; fin > 0; fin -= 3) {
    partes.insert(0, texto.substring(fin - 3 < 0 ? 0 : fin - 3, fin));
  }
  return (numero < 0 ? '-' : '') + partes.join(',');
}

/// Lo que el dueño escribió en un campo de soles enteros («1,200») en
/// céntimos. Vacío es nulo.
int? leerSolesEnCentimos(String texto) {
  final digitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.isEmpty) return null;
  return int.parse(digitos) * 100;
}

/// Celular peruano: 9 dígitos que empiezan con 9.
bool esCelularValido(String digitos) => RegExp(r'^9\d{8}$').hasMatch(digitos);

/// 987654321 → «987 654 321».
String formatearCelular(String digitos) {
  final partes = <String>[];
  for (var i = 0; i < digitos.length; i += 3) {
    partes.add(
      digitos.substring(i, i + 3 > digitos.length ? digitos.length : i + 3),
    );
  }
  return partes.join(' ');
}

/// Minutos desde la medianoche → «9:00 p. m.».
String formatearHora(int minutos) {
  final h24 = minutos ~/ 60;
  final m = minutos % 60;
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final sufijo = h24 < 12 ? 'a. m.' : 'p. m.';
  return '$h12:${m.toString().padLeft(2, '0')}$_espacioFijo$sufijo';
}

/// Dentro del comprobante, el monto con céntimos si los tiene:
/// «S/ 980» o «S/ 142.30».
String formatearSolesComprobante(int centimos) {
  final resto = centimos.abs() % 100;
  if (resto == 0) return formatearSoles(centimos);
  final soles = centimos.abs() ~/ 100;
  final signo = centimos < 0 ? '−' : '';
  return '${signo}S/$_espacioFijo${separarMiles(soles)}.'
      '${resto.toString().padLeft(2, '0')}';
}

const _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'setiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// «jueves 8 de octubre».
String formatearFechaLarga(DateTime fecha) =>
    '${_dias[fecha.weekday - 1]} ${fecha.day} de ${_meses[fecha.month - 1]}';

/// «15 de octubre».
String formatearDiaYMes(DateTime fecha) =>
    '${fecha.day} de ${_meses[fecha.month - 1]}';

String _mayuscula(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

/// Encabezado de un día en el Historial: «Hoy · lunes 13», «Ayer · domingo
/// 12», «Viernes 10»; de otro mes, «Lunes 29 de setiembre»; de otro año,
/// con el año.
String formatearDiaHistorial(DateTime dia, DateTime hoy) {
  final d = DateTime(dia.year, dia.month, dia.day);
  final h = DateTime(hoy.year, hoy.month, hoy.day);
  final nombre = '${_dias[d.weekday - 1]} ${d.day}';
  if (d == h) return 'Hoy · $nombre';
  if (d == DateTime(h.year, h.month, h.day - 1)) return 'Ayer · $nombre';
  if (d.year == h.year && d.month == h.month) return _mayuscula(nombre);
  final conMes = '$nombre de ${_meses[d.month - 1]}';
  return _mayuscula(d.year == h.year ? conMes : '$conMes de ${d.year}');
}

/// Soles con céntimos escritos por el dueño («980.50»), en céntimos.
int? leerSolesConCentimos(String texto) {
  final limpio = texto.replaceAll(',', '').trim();
  final m = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(limpio);
  if (m == null) return null;
  return int.parse(m.group(1)!) * 100 +
      int.parse((m.group(2) ?? '').padRight(2, '0'));
}
