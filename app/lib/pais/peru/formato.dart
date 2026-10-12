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
