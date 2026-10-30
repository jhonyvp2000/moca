import '../../dominio/modelos.dart';
import '../../dominio/voz.dart';
import 'categorias.dart';

// Interpreta en el teléfono, con reglas, lo que el dueño dijo en español de
// Perú: «Hoy vendí 350 en efectivo y 120 por Yape», «Pagué 80 de luz»,
// «Saqué 100 para mí». No adivina: lo que no está claro queda vacío para que
// Moca lo pregunte.

/// Por debajo de esta confianza, Moca confirma el monto antes de usarlo.
const confianzaMinima = 0.5;

LecturaVoz interpretarVoz(
  List<AlternativaVoz> alternativas, {
  bool soloVenta = false,
}) {
  if (alternativas.isEmpty || alternativas.first.texto.trim().isEmpty) {
    return LecturaVoz.vacia;
  }
  final principal = alternativas.first;
  final frase = _leerFrase(principal.texto);

  var tipo = frase.tipo;
  var categoria = frase.categoria;
  if (soloVenta) {
    tipo = TipoMovimiento.ingreso;
    categoria = categoriaVentaDelDia;
  }

  // ¿Hay duda sobre el monto? Solo cuando se dijo un único monto.
  var posibles = <int>[];
  if (frase.partidas.length <= 1) {
    final opciones = <int>{
      ...frase.partidas.map((p) => p.centimos),
      for (final otra in alternativas.skip(1))
        ..._leerFrase(otra.texto).partidas.take(1).map((p) => p.centimos),
    };
    final confianzaBaja =
        principal.confianza != null && principal.confianza! < confianzaMinima;
    if (opciones.length > 1 || frase.cortada || confianzaBaja) {
      posibles = opciones.take(2).toList();
    }
  }

  return LecturaVoz(
    textoDicho: principal.texto.trim(),
    tipo: tipo,
    // Con duda, la partida conserva la cuenta dicha; el monto se confirma.
    partidas: frase.partidas,
    montosPosibles: posibles,
    categoria: categoria,
    prestamo: !soloVenta && frase.prestamo,
    cuentaDestino: soloVenta ? null : frase.destino,
  );
}

class _Frase {
  _Frase(
    this.tipo,
    this.partidas,
    this.categoria,
    this.cortada, {
    this.prestamo = false,
    this.destino,
  });

  final TipoMovimiento? tipo;
  final List<PartidaVoz> partidas;
  final String? categoria;

  /// La frase quedó a medias («Pagué trescientos…»).
  final bool cortada;

  /// Dijo que le prestaron plata (entrega 14.14).
  final bool prestamo;

  /// En un pase, a dónde va la plata (entrega 21.1).
  final TipoCuenta? destino;
}

_Frase _leerFrase(String original) {
  final cortada = original.contains('...') || original.contains('…');
  final texto = normalizar(original);
  final fichas = _fichas(texto);
  // Un préstamo recibido no es venta: hasta que lleguen los préstamos
  // (V1.1), se sugiere «Puse de mi bolsillo» y Moca lo avisa.
  final prestamo = _prestamoRecibido.hasMatch(texto) && !_pagoDeCuota(texto);
  // «Pasé 500 de la caja a Yape», «deposité 1,000 al banco» (entrega 21.1).
  if (!prestamo && _pase.hasMatch(texto)) {
    final (origen, destino) = _cuentasDelPase(texto);
    final monto = _partidas(fichas).firstOrNull;
    return _Frase(
      TipoMovimiento.transferencia,
      [if (monto != null) PartidaVoz(monto.centimos, origen)],
      null,
      cortada,
      destino: destino,
    );
  }
  final tipo = prestamo ? TipoMovimiento.aporte : _tipo(texto);
  return _Frase(
    tipo,
    _partidas(fichas),
    _categoria(texto, tipo),
    cortada,
    prestamo: prestamo,
  );
}

/// Minúsculas, sin tildes y sin la moneda.
String normalizar(String texto) {
  const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
  var t = texto.toLowerCase();
  tildes.forEach((con, sin) => t = t.replaceAll(con, sin));
  t = t
      .replaceAll('…', ' ')
      .replaceAll('...', ' ')
      .replaceAll(RegExp(r's/\.?'), ' ')
      .replaceAll(r'$', ' ')
      .replaceAll(RegExp(r'\b(soles|sol|lucas|luca|nuevos)\b'), ' ');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

// --- Tipo ----------------------------------------------------------------------

/// Plata que el dueño pone de su bolsillo (entrega 14.11).
final _aporte = RegExp(
  r'\bde mi bolsillo\b|\bmeti (plata|dinero|\d)|\bmeti al negocio\b|'
  r'\bmeti .* al negocio\b|\bpuse (plata|dinero) de mi\b|\baporte\b',
);
final _retiro = RegExp(
  r'\bpara mi\b(?! (personal|trabajador|trabajadora|ayudante|negocio|tienda|bodega))|'
  r'\bpara la casa\b|\bpara mis gastos\b|\bretir(e|o|amos)\b|'
  // «Gasto personal» es del dueño, no sueldo del personal (entrega 14.14).
  r'\b(gasto|gastos|uso|compra|compras|cosa|cosas) personal(es)?\b',
);

/// «Pasé 500 de la caja a Yape», «deposité 1,000 al banco» (entrega 21.1).
final _pase = RegExp(
  r'\b(pase|pasamos|deposite|depositamos|transferi|transferimos|movi)\b',
);

/// De dónde y a dónde, por las palabras de antes: «de la caja», «a Yape».
/// Sin «de» ni «a», la primera es el origen y la segunda el destino; al
/// depositar, el origen que no se dice es el efectivo.
(TipoCuenta?, TipoCuenta?) _cuentasDelPase(String texto) {
  final palabras = texto.split(' ');
  TipoCuenta? origen;
  TipoCuenta? destino;
  final sueltas = <TipoCuenta>[];
  for (final (i, palabra) in palabras.indexed) {
    final cuenta = _palabrasCuenta[palabra.replaceAll('.', '')];
    if (cuenta == null) continue;
    // Lo que va delante, saltando «la», «el», «mi».
    var j = i - 1;
    while (j >= 0 && const {'la', 'el', 'mi', 'su'}.contains(palabras[j])) {
      j--;
    }
    final antes = j >= 0 ? palabras[j] : '';
    if (const {'de', 'del', 'desde'}.contains(antes)) {
      origen ??= cuenta;
    } else if (const {'a', 'al', 'hacia', 'en'}.contains(antes)) {
      destino ??= cuenta;
    } else {
      sueltas.add(cuenta);
    }
  }
  for (final cuenta in sueltas) {
    if (origen == null) {
      origen = cuenta;
    } else {
      destino ??= cuenta;
    }
  }
  if (origen == null && RegExp(r'\bdeposit').hasMatch(texto)) {
    origen = TipoCuenta.efectivo;
  }
  return (origen, destino == origen ? null : destino);
}

/// «Me prestaron 2,000», «saqué un préstamo».
final _prestamoRecibido = RegExp(
  r'\bme prest(aron|o)\b|\b(saque|pedi|recibi) (un|el) (prestamo|credito)\b|'
  r'\bme (dieron|dio|desembolsaron|aprobaron) (un|el) (prestamo|credito)\b|'
  r'\bme desembolsaron\b',
);

bool _pagoDeCuota(String t) =>
    RegExp(r'\b(cuota|cuotas|pague|pagamos|pago)\b').hasMatch(t);
final _ingresoConPago = RegExp(
  r'\bme (pagaron|pago|yapearon|yapeo|depositaron)\b',
);
final _egreso = RegExp(
  r'\b(pague|pago|pagamos|gaste|gasto|gastamos|compre|compro|compramos|'
  r'salio|salieron|invert[ií])\b',
);
final _ingreso = RegExp(
  r'\b(vendi|vendio|vendimos|vendo|venta|ventas|entro|entraron|cobre|cobro|'
  r'cobramos|ingreso|ingresaron|gane)\b',
);

TipoMovimiento? _tipo(String t) {
  if (_aporte.hasMatch(t)) return TipoMovimiento.aporte;
  if (_retiro.hasMatch(t)) return TipoMovimiento.retiro;
  if (_ingresoConPago.hasMatch(t)) return TipoMovimiento.ingreso;
  if (_egreso.hasMatch(t)) return TipoMovimiento.egreso;
  if (_ingreso.hasMatch(t)) return TipoMovimiento.ingreso;
  return null;
}

// --- Categoría -------------------------------------------------------------------

const _servicios = 'Servicios (luz, agua, internet, teléfono)';
const _sueldos = 'Sueldos del personal';
const _movilidad = 'Movilidad del negocio';
const _contador = 'Contador o gestoría';

/// «Pagué al personal»: sueldos. «Personal» solo no elige nada (entrega
/// 14.14).
final _alPersonal = RegExp(r'\b(al|del|el|mi|nuestro|a mi) personal\b');

/// «Cobré el fiado», «me pagó lo que me debía».
final _fiado = RegExp(r'\bfiado\b|\bfiados\b|\bme debia(n)?\b');

/// Palabra que se dice → categoría provisional (prototipo-v1.md).
const _palabrasEgreso = {
  'luz': _servicios,
  'agua': _servicios,
  'internet': _servicios,
  'telefono': _servicios,
  'celular': _servicios,
  'recibo': _servicios,
  'cable': _servicios,
  'alquiler': 'Alquiler',
  'renta': 'Alquiler',
  'local': 'Alquiler',
  'sueldo': _sueldos,
  'sueldos': _sueldos,
  'ayudante': _sueldos,
  'trabajador': _sueldos,
  'trabajadora': _sueldos,
  'trabajadores': _sueldos,
  'empleado': _sueldos,
  'empleada': _sueldos,
  'planilla': _sueldos,
  'jornal': _sueldos,
  'pasaje': _movilidad,
  'pasajes': _movilidad,
  'taxi': _movilidad,
  'mototaxi': _movilidad,
  'movilidad': _movilidad,
  // El combustible tiene su categoría desde la entrega 14.14.1.
  'gasolina': categoriaCombustible,
  'combustible': categoriaCombustible,
  'petróleo': categoriaCombustible,
  'petroleo': categoriaCombustible,
  'diésel': categoriaCombustible,
  'diesel': categoriaCombustible,
  'grifo': categoriaCombustible,
  'flete': 'Flete',
  'fletes': 'Flete',
  'encomienda': 'Flete',
  'publicidad': 'Publicidad',
  'propaganda': 'Publicidad',
  'volantes': 'Publicidad',
  'afiches': 'Publicidad',
  'anuncio': 'Publicidad',
  'letrero': 'Publicidad',
  'contador': _contador,
  'contadora': _contador,
  'contabilidad': _contador,
  'gestoria': _contador,
  'cuota': categoriaCuotaDePrestamo,
  'cuotas': categoriaCuotaDePrestamo,
  'prestamo': categoriaCuotaDePrestamo,
  'arreglo': 'Mantenimiento y reparaciones',
  'reparacion': 'Mantenimiento y reparaciones',
  'mantenimiento': 'Mantenimiento y reparaciones',
  'impuesto': 'Impuestos y trámites',
  'sunat': 'Impuestos y trámites',
  'municipalidad': 'Impuestos y trámites',
  'licencia': 'Impuestos y trámites',
  'tramite': 'Impuestos y trámites',
  'mercaderia': 'Mercadería',
  'proveedor': 'Mercadería',
  'distribuidora': 'Mercadería',
  'productos': 'Mercadería',
  'abarrotes': 'Mercadería',
  'gaseosas': 'Mercadería',
  'bolsas': 'Bolsas y envases',
  'envases': 'Bolsas y envases',
  'tapers': 'Bolsas y envases',
  'gas': 'Gas',
  'balon': 'Gas',
  'insumos': 'Insumos de cocina',
  'verduras': 'Insumos de cocina',
  'pollo': 'Insumos de cocina',
  'carne': 'Insumos de cocina',
  'pescado': 'Insumos de cocina',
  'bebidas': 'Bebidas',
  'cerveza': 'Bebidas',
  'descartables': 'Descartables',
  'vasos': 'Descartables',
  'platos': 'Descartables',
  'materiales': 'Materiales',
  'herramientas': 'Herramientas y repuestos',
  'repuestos': 'Herramientas y repuestos',
};

final _palabraVenta = RegExp(
  r'\b(vendi|vendio|vendimos|vendo|venta|ventas|cobre|cobro|cobramos|'
  r'yapearon|yapeo)\b',
);

String? _categoria(String t, TipoMovimiento? tipo) {
  switch (tipo) {
    case TipoMovimiento.egreso:
      if (_alPersonal.hasMatch(t)) return _sueldos;
      for (final palabra in t.split(' ')) {
        final categoria = _palabrasEgreso[palabra];
        if (categoria != null) return categoria;
      }
      return null;
    case TipoMovimiento.ingreso:
      if (_fiado.hasMatch(t)) return categoriaCobroDeFiado;
      return _palabraVenta.hasMatch(t) ? categoriaVentaDelDia : null;
    case TipoMovimiento.retiro ||
        TipoMovimiento.aporte ||
        TipoMovimiento.transferencia ||
        null:
      return null;
  }
}

// --- Montos y cuentas ----------------------------------------------------------

sealed class _Ficha {}

class _Numero extends _Ficha {
  _Numero(this.centimos);

  final int centimos;
}

class _Cuenta extends _Ficha {
  _Cuenta(
    this.cuenta, {
    this.bancoSinNombre = false,
    this.plinSinBanco = false,
  });

  final TipoCuenta cuenta;
  final bool bancoSinNombre;
  final bool plinSinBanco;
}

class _Palabra extends _Ficha {}

const _palabrasCuenta = {
  'efectivo': TipoCuenta.efectivo,
  'cash': TipoCuenta.efectivo,
  'contado': TipoCuenta.efectivo,
  'caja': TipoCuenta.efectivo,
  'yape': TipoCuenta.yape,
  'yapearon': TipoCuenta.yape,
  'yapeo': TipoCuenta.yape,
  'yapeado': TipoCuenta.yape,
  'plin': TipoCuenta.plin,
  'plineo': TipoCuenta.plin,
  'plinearon': TipoCuenta.plin,
  'sip': TipoCuenta.sip,
  'banco': TipoCuenta.banco,
  'transferencia': TipoCuenta.banco,
  'transfirieron': TipoCuenta.banco,
  'deposito': TipoCuenta.banco,
  'depositaron': TipoCuenta.banco,
  'tarjeta': TipoCuenta.banco,
  'bcp': TipoCuenta.banco,
  'interbank': TipoCuenta.interbank,
  'bbva': TipoCuenta.bbva,
  'continental': TipoCuenta.bbva,
  'scotiabank': TipoCuenta.scotiabank,
  'scotia': TipoCuenta.scotiabank,
};

/// Palabras de banco que no dicen cuál (decisiones.md, 15-10-2026).
const _bancoSinNombre = {
  'banco',
  'transferencia',
  'transfirieron',
  'deposito',
  'depositaron',
  'tarjeta',
};

const _cajasEntidad = {
  'piura',
  'cusco',
  'arequipa',
  'trujillo',
  'huancayo',
  'sullana',
  'ica',
  'tacna',
  'maynas',
  'municipal',
  'rural',
  'raiz',
  'los',
};

const _antesDeSip = {'por', 'con', 'en', 'a', 'al', 'mi', 'de', 'del'};

/// «Plin» con su banco al lado: «BBVA Plin», «Plin de Scotiabank»
/// (entrega 14.10).
const _palabrasPlin = {'plin', 'plineo', 'plinearon'};
const _plinDelBanco = {
  'interbank': TipoCuenta.plin,
  'bbva': TipoCuenta.bbvaPlin,
  'continental': TipoCuenta.bbvaPlin,
  'scotiabank': TipoCuenta.scotiabankPlin,
  'scotia': TipoCuenta.scotiabankPlin,
};

List<_Ficha> _fichas(String texto) {
  final palabras = texto
      // La coma entre cifras es de miles («1,200»); fuera de cifras, separa.
      .split(RegExp(r'[\s;:!?¿¡()]+|,(?!\d)|(?<!\d),'))
      .where((p) => p.isNotEmpty)
      .toList();
  final fichas = <_Ficha>[];
  var i = 0;
  while (i < palabras.length) {
    final leido = _leerNumero(palabras, i);
    if (leido != null) {
      fichas.add(_Numero(leido.$1));
      i = leido.$2;
      continue;
    }
    final palabra = palabras[i].replaceAll('.', '');
    if (_palabrasPlin.contains(palabra)) {
      // El banco justo antes («BBVA Plin»): reemplaza al banco ya leído.
      final antes = i > 0 ? palabras[i - 1].replaceAll('.', '') : '';
      if (_plinDelBanco[antes] case final plin? when fichas.last is _Cuenta) {
        fichas.last = _Cuenta(plin);
        i++;
        continue;
      }
      // O justo después, con o sin «de» («Plin de Scotiabank»).
      var j = i + 1;
      if (j < palabras.length && const {'de', 'del'}.contains(palabras[j])) {
        j++;
      }
      final despues = j < palabras.length
          ? palabras[j].replaceAll('.', '')
          : '';
      if (_plinDelBanco[despues] case final plin?) {
        fichas.add(_Cuenta(plin));
        i = j + 1;
        continue;
      }
      fichas.add(_Cuenta(TipoCuenta.plin, plinSinBanco: true));
      i++;
      continue;
    }
    var cuenta = _palabrasCuenta[palabra];
    // «La cuota de la Caja Piura»: es la entidad, no el efectivo.
    if (palabra == 'caja' &&
        i + 1 < palabras.length &&
        _cajasEntidad.contains(palabras[i + 1])) {
      cuenta = null;
    }
    // «Sip» también es «sí»: solo es la billetera tras «por», «con», «en»…
    if (cuenta == TipoCuenta.sip &&
        (i == 0 || !_antesDeSip.contains(palabras[i - 1]))) {
      cuenta = null;
    }
    fichas.add(
      cuenta == null
          ? _Palabra()
          : _Cuenta(cuenta, bancoSinNombre: _bancoSinNombre.contains(palabra)),
    );
    i++;
  }
  return fichas;
}

/// Empareja cada monto con la cuenta más cercana que se haya dicho. Un monto
/// sin cuenta cercana queda sin cuenta, para que Moca la pregunte.
List<PartidaVoz> _partidas(List<_Ficha> fichas) {
  final numeros = [
    for (final (i, f) in fichas.indexed)
      if (f is _Numero) (i, f.centimos),
  ];
  final cuentas = [
    for (final (i, f) in fichas.indexed)
      if (f is _Cuenta) (i, f.cuenta, f.bancoSinNombre, f.plinSinBanco),
  ];
  final usadas = <int>{};
  final resultado = <PartidaVoz>[];
  for (final (posicion, centimos) in numeros) {
    if (centimos <= 0) continue;
    (int, TipoCuenta, bool, bool)? cercana;
    for (final (j, cuenta) in cuentas.indexed) {
      if (usadas.contains(j)) continue;
      final distancia = (cuenta.$1 - posicion).abs();
      if (cercana == null || distancia < (cercana.$1 - posicion).abs()) {
        cercana = cuenta;
      }
    }
    if (cercana != null) {
      usadas.add(cuentas.indexWhere((c) => c.$1 == cercana!.$1));
    }
    resultado.add(
      PartidaVoz(
        centimos,
        cercana?.$2,
        cercana?.$3 ?? false,
        cercana?.$4 ?? false,
      ),
    );
  }
  return resultado;
}

// --- Números -------------------------------------------------------------------

const _unidades = {
  'cero': 0,
  'uno': 1,
  'dos': 2,
  'tres': 3,
  'cuatro': 4,
  'cinco': 5,
  'seis': 6,
  'siete': 7,
  'ocho': 8,
  'nueve': 9,
  'diez': 10,
  'once': 11,
  'doce': 12,
  'trece': 13,
  'catorce': 14,
  'quince': 15,
  'dieciseis': 16,
  'diecisiete': 17,
  'dieciocho': 18,
  'diecinueve': 19,
  'veinte': 20,
  'veintiun': 21,
  'veintiuno': 21,
  'veintidos': 22,
  'veintitres': 23,
  'veinticuatro': 24,
  'veinticinco': 25,
  'veintiseis': 26,
  'veintisiete': 27,
  'veintiocho': 28,
  'veintinueve': 29,
  'treinta': 30,
  'cuarenta': 40,
  'cincuenta': 50,
  'sesenta': 60,
  'setenta': 70,
  'ochenta': 80,
  'noventa': 90,
  'cien': 100,
  'ciento': 100,
  'doscientos': 200,
  'trescientos': 300,
  'cuatrocientos': 400,
  'quinientos': 500,
  'seiscientos': 600,
  'setecientos': 700,
  'ochocientos': 800,
  'novecientos': 900,
};

/// Lee un número desde la palabra `i`, en cifras («350», «1,200», «80.50») o
/// en letras («trescientos cincuenta», «dos mil quinientos»). Devuelve el
/// monto en céntimos y la posición de la palabra siguiente.
(int, int)? _leerNumero(List<String> palabras, int i) {
  final cifras = _leerCifras(palabras[i]);
  if (cifras != null) {
    var centimos = cifras;
    var siguiente = i + 1;
    if (siguiente < palabras.length && palabras[siguiente] == 'mil') {
      centimos *= 1000;
      siguiente++;
    }
    return _conCentimos(palabras, centimos, siguiente);
  }

  final letras = _leerLetras(palabras, i);
  if (letras == null) return null;
  return _conCentimos(palabras, letras.$1 * 100, letras.$2);
}

/// «350 con 50» son S/ 350.50, no dos montos.
(int, int) _conCentimos(List<String> palabras, int centimos, int siguiente) {
  if (siguiente + 1 < palabras.length && palabras[siguiente] == 'con') {
    final cifras = _leerCifras(palabras[siguiente + 1]);
    final letras = cifras == null ? _leerLetras(palabras, siguiente + 1) : null;
    final valor = cifras != null ? cifras ~/ 100 : letras?.$1;
    if (valor != null && valor < 100) {
      return (centimos + valor, cifras != null ? siguiente + 2 : letras!.$2);
    }
  }
  return (centimos, siguiente);
}

/// Cifras en céntimos: «350» → 35000; «1,200» → 120000; «80.50» → 8050.
int? _leerCifras(String palabra) {
  final p = palabra.replaceAll(RegExp(r'[^0-9.,]'), '');
  if (p.isEmpty || !RegExp(r'^\d').hasMatch(p)) return null;
  if (RegExp(r'^\d{1,3}([.,]\d{3})+$').hasMatch(p)) {
    return int.parse(p.replaceAll(RegExp('[.,]'), '')) * 100;
  }
  final decimal = RegExp(r'^(\d+)[.,](\d{1,2})$').firstMatch(p);
  if (decimal != null) {
    final centimos = decimal.group(2)!.padRight(2, '0');
    return int.parse(decimal.group(1)!) * 100 + int.parse(centimos);
  }
  final entero = RegExp(r'^\d+').firstMatch(p);
  return entero == null ? null : int.parse(entero.group(0)!) * 100;
}

/// Soles en letras. «un» y «una» solo cuentan antes de «mil».
(int, int)? _leerLetras(List<String> palabras, int i) {
  var total = 0;
  var actual = 0;
  var j = i;
  var leyo = false;
  while (j < palabras.length) {
    final p = palabras[j];
    if ((p == 'un' || p == 'una') &&
        j + 1 < palabras.length &&
        palabras[j + 1] == 'mil') {
      actual += 1;
      leyo = true;
      j++;
      continue;
    }
    final valor = _unidades[p];
    if (valor != null) {
      actual += valor;
      leyo = true;
      j++;
      continue;
    }
    if (p == 'mil' && (leyo || j == i)) {
      total += (actual == 0 ? 1 : actual) * 1000;
      actual = 0;
      leyo = true;
      j++;
      continue;
    }
    // «treinta y cinco»
    if (p == 'y' &&
        leyo &&
        actual % 10 == 0 &&
        actual % 100 >= 30 &&
        j + 1 < palabras.length &&
        (_unidades[palabras[j + 1]] ?? 10) < 10) {
      j++;
      continue;
    }
    break;
  }
  if (!leyo) return null;
  return (total + actual, j);
}
