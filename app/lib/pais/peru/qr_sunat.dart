import '../../dominio/comprobantes.dart';
import '../../dominio/modelos.dart';

// QR de los comprobantes electrónicos de SUNAT. Los campos van separados por
// «|»: RUC del emisor | tipo | serie | número | IGV | total | fecha |
// tipo de documento del cliente | número de documento del cliente | …

const _tiposComprobante = {
  '01': 'Factura',
  '03': 'Boleta',
  '07': 'Nota de crédito',
  '08': 'Nota de débito',
  '12': 'Ticket',
};

/// Devuelve la lectura del QR, o nulo si no es de un comprobante de SUNAT.
LecturaComprobante? leerQrSunat(String contenido) {
  final campos = contenido.trim().split('|').map((c) => c.trim()).toList();
  if (campos.length < 7) return null;

  final ruc = campos[0];
  final tipo = _tiposComprobante[campos[1].padLeft(2, '0')];
  final serie = campos[2].toUpperCase();
  final numero = campos[3].replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final igv = _montoEnCentimos(campos[4]);
  final total = _montoEnCentimos(campos[5]);
  final fecha = _fecha(campos[6]);

  if (!esRucValido(ruc) ||
      tipo == null ||
      !RegExp(r'^[A-Z0-9]{4}$').hasMatch(serie) ||
      !RegExp(r'^\d{1,8}$').hasMatch(numero) ||
      total == null ||
      total <= 0 ||
      fecha == null) {
    return null;
  }

  return LecturaComprobante(
    origen: OrigenLectura.qr,
    emisorIdentificacion: ruc,
    tipo: tipo,
    serie: serie,
    numero: numero,
    impuestoCentimos: igv,
    totalCentimos: total,
    fechaEmision: fecha,
  );
}

/// RUC de 11 dígitos con su dígito verificador (módulo 11).
bool esRucValido(String ruc) {
  if (!RegExp(r'^(10|15|16|17|20)\d{9}$').hasMatch(ruc)) return false;
  const factores = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
  var suma = 0;
  for (var i = 0; i < 10; i++) {
    suma += int.parse(ruc[i]) * factores[i];
  }
  final verificador = (11 - suma % 11) % 10;
  return verificador == int.parse(ruc[10]);
}

int? _montoEnCentimos(String texto) {
  final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(texto);
  if (m == null) return null;
  return int.parse(m.group(1)!) * 100 +
      int.parse((m.group(2) ?? '0').padRight(2, '0'));
}

/// «2026-10-08» o «08/10/2026».
DateTime? _fecha(String texto) {
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(texto);
  if (iso != null) {
    return DateTime(
      int.parse(iso.group(1)!),
      int.parse(iso.group(2)!),
      int.parse(iso.group(3)!),
    );
  }
  final peru = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(texto);
  if (peru != null) {
    return DateTime(
      int.parse(peru.group(3)!),
      int.parse(peru.group(2)!),
      int.parse(peru.group(1)!),
    );
  }
  return null;
}
