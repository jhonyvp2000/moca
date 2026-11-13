/// Los nombres que se sugieren al escribir una institución (entrega 69):
/// los que contienen lo escrito, sin distinguir tildes ni mayúsculas;
/// primero los que empiezan con eso. No se sugiere lo que ya está escrito
/// tal cual.
List<String> sugerenciasDeNombres(List<String> nombres, String escrito) {
  final texto = _comparable(escrito);
  if (texto.isEmpty) return const [];
  final empiezan = <String>[];
  final contienen = <String>[];
  for (final n in nombres) {
    if (n == escrito.trim()) continue;
    final c = _comparable(n);
    if (c.startsWith(texto)) {
      empiezan.add(n);
    } else if (c.contains(texto)) {
      contienen.add(n);
    }
  }
  return [...empiezan, ...contienen];
}

String _comparable(String texto) {
  const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
  final b = StringBuffer();
  for (final letra in texto.toLowerCase().split('')) {
    b.write(tildes[letra] ?? letra);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
