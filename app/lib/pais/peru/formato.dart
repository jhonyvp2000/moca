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

/// La fecha y la hora de una fila de lista sin días (entrega 68): «Hoy ·
/// 10:33 a. m.», «Ayer · 7:38 p. m.», «10 nov. 2026 · 9:06 a. m.».
String formatearFechaYHoraDeFila(DateTime momento, DateTime hoy) {
  final d = DateTime(momento.year, momento.month, momento.day);
  final h = DateTime(hoy.year, hoy.month, hoy.day);
  final dia = d == h
      ? 'Hoy'
      : d == DateTime(h.year, h.month, h.day - 1)
      ? 'Ayer'
      : '${d.day} ${_meses[d.month - 1].substring(0, 3)}. ${d.year}';
  return '$dia · ${formatearHora(momento.hour * 60 + momento.minute)}';
}

/// El momento en que se mira el Inicio (entrega 62): «Jueves 12:13 p. m.».
String formatearDiaYHora(DateTime momento) {
  final dia = _dias[momento.weekday - 1];
  return '${dia[0].toUpperCase()}${dia.substring(1)} '
      '${formatearHora(momento.hour * 60 + momento.minute)}';
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

/// «octubre».
String nombreDelMes(DateTime fecha) => _meses[fecha.month - 1];

/// «Oct», «Set».
String nombreDelMesCorto(DateTime fecha) =>
    _mayuscula(nombreDelMes(fecha).substring(0, 3));

/// «Octubre».
String nombreDelMesConMayuscula(DateTime fecha) =>
    _mayuscula(nombreDelMes(fecha));

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

/// El celular de un cliente (entrega 53), escrito como venga: «987 654 321»,
/// «+51 987654321». Nulo si no es un celular de Perú (9 cifras que empiezan
/// con 9).
String? celularDeCliente(String texto) {
  var cifras = texto.replaceAll(RegExp(r'[^0-9]'), '');
  if (cifras.length == 11 && cifras.startsWith('51')) {
    cifras = cifras.substring(2);
  }
  return RegExp(r'^9\d{8}$').hasMatch(cifras) ? cifras : null;
}

/// El número para el enlace de WhatsApp, con el código de Perú.
String celularParaWhatsApp(String celular) => '51$celular';

/// Los montos como se dicen en voz alta (entrega 73): «S/ 30» → «30 soles»,
/// «S/ 1,350» → «1350 soles», «S/ 1» → «un sol», «S/ 3.40» → «3 soles con 40
/// céntimos», «S/ 0.50» → «50 céntimos», «−S/ 50» → «menos 50 soles». Las
/// cifras las pronuncia la voz del teléfono; lo demás no cambia.
String montosParaDecir(String texto) => texto.replaceAllMapped(
  RegExp(r'([−-][\s ]?)?S/[\s ]?(\d{1,3}(?:,\d{3})*|\d+)(?:\.(\d{1,2}))?'),
  (m) {
    final menos = m.group(1) == null ? '' : 'menos ';
    final soles = int.parse(m.group(2)!.replaceAll(',', ''));
    final centimos = int.parse((m.group(3) ?? '0').padRight(2, '0'));
    String deSoles(int n) => n == 1 ? 'un sol' : '$n soles';
    String deCentimos(int n) => n == 1 ? 'un céntimo' : '$n céntimos';
    if (soles == 0 && centimos > 0) return '$menos${deCentimos(centimos)}';
    return centimos > 0
        ? '$menos${deSoles(soles)} con ${deCentimos(centimos)}'
        : '$menos${deSoles(soles)}';
  },
);
