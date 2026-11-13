import 'dart:typed_data';

import '../../comun/xlsx.dart';
import '../../dominio/informe.dart';
import 'categorias.dart';
import 'formato.dart';

// El flujo de caja en el formato que piden las cajas municipales, cajas
// rurales, financieras y bancos del Perú (docs/credito/, entrega 14.15).
// Son las cuatro hojas de la plantilla, con sus fórmulas corregidas: Moca
// llena el negocio con lo anotado y el dueño, con su asesor, lo demás. Las
// celdas amarillas son para llenar y las grises se calculan solas.

const _hojaFlujo = 'FLUJO_MENSUAL';
const _hojaHogar = 'EXCEDENTE_FAMILIAR';

/// Las filas del negocio, en el orden y con los nombres de la plantilla.
const _ingresos = [
  (FilaFlujo.ventasContado, 'Ventas al contado'),
  (FilaFlujo.ventasCreditoCobradas, 'Ventas al crédito cobradas'),
  (FilaFlujo.otrosIngresos, 'Otros ingresos operativos'),
  (FilaFlujo.ingresosExtraordinarios, 'Ingresos extraordinarios'),
];
const _variables = [
  (FilaFlujo.mercaderia, 'Compra de mercadería / materia prima'),
  (FilaFlujo.envases, 'Envases, empaques, materiales'),
  (FilaFlujo.fletes, 'Fletes y transporte de compras'),
];
const _fijos = [
  (FilaFlujo.alquiler, 'Alquiler del local'),
  (FilaFlujo.servicios, 'Servicios (luz, agua, internet)'),
  (FilaFlujo.sueldos, 'Sueldos y gratificaciones'),
  (FilaFlujo.publicidad, 'Publicidad y marketing'),
  (FilaFlujo.mantenimiento, 'Mantenimiento y reparaciones'),
  (FilaFlujo.contabilidad, 'Contabilidad / gestión'),
  (FilaFlujo.otrosGastosFijos, 'Otros gastos fijos'),
];

/// «Moca-Bodega-Don-Lucho-flujo-credito-octubre-2026.xlsx».
String nombreDelFlujoParaCredito(String nombreNegocio, DateTime hoy) {
  final limpio = nombreNegocio
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9áéíóúüñÁÉÍÓÚÜÑ]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final partes = [
    'Moca',
    if (limpio.isNotEmpty) limpio,
    'flujo-credito',
    nombreDelMes(hoy),
    '${hoy.year}',
  ];
  return '${partes.join('-')}.xlsx';
}

Uint8List armarFlujoParaCredito(
  FlujoParaCredito f, {
  required String nombreNegocio,
  required DateTime hoy,
}) {
  final (flujo, deudas, excedente) = _flujo(f, nombreNegocio, hoy);
  final hogar = _Hogar(excedente: excedente, deudas: deudas);
  return armarXlsx([
    _instrucciones(nombreNegocio, hoy),
    flujo,
    _hogar(f, hogar),
    _resumen(hogar),
  ]);
}

CeldaTexto _t(String texto, {bool fuerte = false, bool ajustar = false}) =>
    CeldaTexto(texto, fuerte: fuerte, ajustar: ajustar);

CeldaTexto _seccion(String texto) =>
    CeldaTexto('▶  $texto', fuerte: true, relleno: Relleno.encabezado);

HojaXlsx _instrucciones(String negocio, DateTime hoy) => HojaXlsx(
  nombre: 'INSTRUCCIONES',
  anchos: const [36, 80],
  filas: [
    [
      _t(
        'PLANTILLA DE FLUJO DE CAJA MENSUAL – CRÉDITO EMPRESARIAL',
        fuerte: true,
      ),
    ],
    [_t('$negocio · Hecho con Moca el ${formatearFechaLarga(hoy)}')],
    [],
    [
      _t('QUÉ LLENÓ MOCA', fuerte: true),
      _t(
        'Las cifras del negocio en FLUJO_MENSUAL salen de lo que el dueño '
        'anotó en Moca, en flujo de caja: cada pago cuenta el día que se '
        'pagó. La columna «De dónde sale» lo dice fila por fila. Los meses '
        'antes de Moca y la hoja EXCEDENTE_FAMILIAR los completa el dueño '
        'con su asesor.',
        ajustar: true,
      ),
    ],
    [],
    [
      _t('¿QUÉ ES ESTA PLANTILLA?', fuerte: true),
      _t(
        'Un flujo de caja mensual que demuestra a bancos, cajas y '
        'financieras que tu negocio genera suficiente excedente para pagar '
        'una cuota de crédito.',
        ajustar: true,
      ),
    ],
    [],
    [_t('HOJAS DE ESTE ARCHIVO', fuerte: true)],
    [_t('  INSTRUCCIONES'), _t('Esta hoja — léela primero.')],
    [
      _t('  FLUJO_MENSUAL'),
      _t('Los ingresos y gastos del negocio de los últimos 6 meses.'),
    ],
    [
      _t('  EXCEDENTE_FAMILIAR'),
      _t('Los gastos del hogar, para calcular la capacidad de pago real.'),
    ],
    [
      _t('  RESUMEN_CREDITO'),
      _t(
        'Hoja automática que calcula cuánto puedes pedir y en cuántas '
        'cuotas.',
      ),
    ],
    [],
    [_t('CÓMO LLENAR LO QUE FALTA', fuerte: true)],
    [
      _t('  1. Llena solo las celdas AMARILLAS'),
      _t(
        'Las grises tienen fórmulas — no las borres. Las blancas con '
        'cifras las llenó Moca.',
        ajustar: true,
      ),
    ],
    [_t('  2. Si un rubro no aplica'), _t('Deja la celda en 0.')],
    [
      _t('  3. Usa los datos reales'),
      _t('Cuaderno de ventas, facturas, resúmenes Yape o Plin.'),
    ],
    [],
    [
      _t('REGLA CLAVE DEL EVALUADOR', fuerte: true),
      _t(
        'Todas tus cuotas (las que ya pagas más la nueva) ≤ 40 % del '
        'Excedente Neto. La hoja RESUMEN_CREDITO lo calcula sola.',
        ajustar: true,
      ),
    ],
    [],
    [_t('DOCUMENTOS QUE ACOMPAÑAN ESTE FLUJO', fuerte: true)],
    [_t('  ☐ DNI del titular (y del cónyuge si aplica)')],
    [_t('  ☐ Recibo de agua, luz o contrato de alquiler del local')],
    [_t('  ☐ 3 últimas boletas o facturas de compra a proveedores')],
    [
      _t(
        '  ☐ Registro de ventas de 3 meses: el Excel de operaciones de Moca '
        'sirve',
      ),
    ],
    [_t('  ☐ Declaración jurada de ingresos (SUNAT o la entidad la da)')],
    [_t('  ☐ Si tienes deudas activas: cronograma de pagos vigente')],
    [],
    [
      _t('NOTA IMPORTANTE', fuerte: true),
      _t(
        'Esta plantilla NO reemplaza la visita del asesor de crédito. '
        'Preséntala como apoyo para ordenar tu información.',
        ajustar: true,
      ),
    ],
  ],
);

/// Un resultado de fórmula: un número, o «""» si la celda queda vacía.
typedef _Valor = Object?;

double _n(_Valor v) => v is num ? v.toDouble() : 0;

/// Las cifras del hogar y del resumen, ya calculadas, para guardarlas junto
/// a sus fórmulas (entrega 14.15.1). El dueño llena lo demás y Excel
/// recalcula.
class _Hogar {
  _Hogar({required double excedente, required double deudas})
    : excedenteNegocio = excedente,
      cuotasActuales = deudas;

  final double excedenteNegocio;
  final double cuotasActuales;
  double get ingresos => excedenteNegocio;
  double get gastos => 0;
  double get excedenteNeto => ingresos - gastos;
  double get libre => excedenteNeto - cuotasActuales;
  double cuotaMaxima(double parte) =>
      (excedenteNeto * parte - cuotasActuales).clamp(0, double.infinity);
  double get montoMaximo {
    const tasa = 0.018;
    const plazo = 12;
    final cuota = cuotaMaxima(0.4);
    if (cuota <= 0) return 0;
    var factor = 1.0;
    for (var i = 0; i < plazo; i++) {
      factor /= 1 + tasa;
    }
    return cuota * (1 - factor) / tasa;
  }
}

/// La hoja del negocio, con lo que ya pagaba en cuotas y el excedente bruto
/// promedio (las celdas H31 y H34).
(HojaXlsx, double, double) _flujo(
  FlujoParaCredito f,
  String negocio,
  DateTime hoy,
) {
  // Columnas B a G: los seis meses. H: promedio. I: de dónde sale.
  final meses = f.meses;
  final columnas = [for (var i = 0; i < meses.length; i++) columnaXlsx(i + 1)];
  final cuentan = [for (final m in meses) f.entraEnPromedio(m)];
  final paraPromedio = [
    for (final (i, c) in columnas.indexed)
      if (cuentan[i]) c,
  ];

  // Lo que vale cada fila, mes por mes: nulo antes de Moca.
  final valores = <int, List<_Valor>>{};
  _Valor promedioDe(List<_Valor> fila) {
    final numeros = [
      for (final (i, v) in fila.indexed)
        if (cuentan[i] && v is num) v,
    ];
    if (numeros.isEmpty) return '';
    return numeros.fold<num>(0, (s, v) => s + v) / numeros.length;
  }

  CeldaFormula promedio(int fila, {bool fuerte = false}) => CeldaFormula(
    'IFERROR(AVERAGE(${[for (final c in paraPromedio) '$c$fila'].join(',')}),"")',
    valor: promedioDe(valores[fila]!),
    formato: FormatoNumero.solesEnteros,
    fuerte: fuerte,
  );

  String origen(FilaFlujo fila) {
    final nombres = f.categoriasPorFila[fila] ?? const [];
    return nombres.isEmpty
        ? 'Moca (sin categoría en este negocio)'
        : 'Moca: ${nombres.join(', ')}';
  }

  final filas = <List<Celda?>>[];
  int numero() => filas.length + 1;
  void filaDeDatos(
    String concepto,
    int Function(MesDelFlujo m) centimos,
    String fuente,
  ) {
    final n = numero();
    valores[n] = [
      for (final m in meses)
        m.estado == EstadoMesFlujo.antesDeMoca ? null : centimos(m) / 100,
    ];
    filas.add([
      _t(concepto),
      for (final v in valores[n]!)
        v == null
            ? const CeldaVacia(formato: FormatoNumero.solesEnteros)
            : CeldaNumero(v as num, formato: FormatoNumero.solesEnteros),
      promedio(n),
      _t(fuente),
    ]);
  }

  // Una fila de totales: «""» si el mes está vacío.
  void total(
    String concepto,
    String Function(String c) formula,
    _Valor Function(int mes) valor,
  ) {
    final n = numero();
    valores[n] = [for (var i = 0; i < meses.length; i++) valor(i)];
    filas.add([
      _t(concepto, fuerte: true),
      for (final (i, c) in columnas.indexed)
        CeldaFormula(
          formula(c),
          valor: valores[n]![i],
          formato: FormatoNumero.solesEnteros,
          fuerte: true,
        ),
      promedio(n, fuerte: true),
      _t('Se calcula solo'),
    ]);
  }

  _Valor suma(List<int> filasDeDatos, int mes) {
    final vs = [for (final r in filasDeDatos) valores[r]![mes]];
    if (vs.every((v) => v == null)) return '';
    return vs.fold<num>(0, (s, v) => s + _n(v));
  }

  String vacio(String rango, String suma) => 'IF(COUNT($rango)=0,"",$suma)';

  String marca(MesDelFlujo m) => switch (m.estado) {
    EstadoMesFlujo.completo => '',
    EstadoMesFlujo.incompleto => ' *',
    EstadoMesFlujo.antesDeMoca => ' —',
    EstadoMesFlujo.enCurso => ' (hasta hoy)',
  };

  filas.add([_t('FLUJO DE CAJA MENSUAL DEL NEGOCIO', fuerte: true)]);
  filas.add([
    _t(
      'Nombre del negocio: $negocio    Propietario: '
      '${f.propietario ?? '___________________'}    RUC/DNI: '
      '${f.identificacionFiscal ?? '______________'}',
    ),
  ]);
  filas.add([
    for (final t in [
      'CONCEPTO',
      for (final m in meses)
        '${nombreDelMesCorto(m.mes)} ${m.mes.year}${marca(m)}',
      'PROMEDIO',
      'DE DÓNDE SALE',
    ])
      CeldaTexto(t, fuerte: true, relleno: Relleno.encabezado),
  ]);

  List<int> bloque(List<(FilaFlujo, String)> lista) {
    final inicio = numero();
    for (final (fila, concepto) in lista) {
      filaDeDatos(concepto, (m) => m.centimos[fila] ?? 0, origen(fila));
    }
    return [for (var r = inicio; r < numero(); r++) r];
  }

  String rango(List<int> rs, String c) => '$c${rs.first}:$c${rs.last}';

  filas.add([_seccion('INGRESOS DEL NEGOCIO')]);
  final ingresos = bloque(_ingresos);
  total(
    'TOTAL INGRESOS',
    (c) => vacio(rango(ingresos, c), 'SUM(${rango(ingresos, c)})'),
    (i) => suma(ingresos, i),
  );
  final filaIngresos = numero() - 1;
  filas.add([]);

  filas.add([_seccion('COSTOS VARIABLES (varían con las ventas)')]);
  final variables = bloque(_variables);
  total(
    'TOTAL COSTOS VARIABLES',
    (c) => vacio(rango(variables, c), 'SUM(${rango(variables, c)})'),
    (i) => suma(variables, i),
  );
  filas.add([]);

  filas.add([_seccion('GASTOS FIJOS OPERATIVOS')]);
  final fijos = bloque(_fijos);
  total(
    'TOTAL GASTOS FIJOS',
    (c) => vacio(rango(fijos, c), 'SUM(${rango(fijos, c)})'),
    (i) => suma(fijos, i),
  );
  filas.add([]);

  filas.add([_seccion('PAGOS FINANCIEROS ACTUALES')]);
  final inicioCuotas = numero();
  for (var i = 0; i < 3; i++) {
    final entidad = i < f.entidades.length ? f.entidades[i] : '________';
    filaDeDatos(
      'Cuota crédito ${i + 1} (entidad: $entidad)',
      (m) => m.cuotas[i],
      'Moca: $categoriaCuotaDePrestamo (la entidad sale de la nota)',
    );
  }
  final cuotas = [for (var r = inicioCuotas; r < numero(); r++) r];
  total(
    'TOTAL DEUDAS ACTUALES',
    (c) => vacio(rango(cuotas, c), 'SUM(${rango(cuotas, c)})'),
    (i) => suma(cuotas, i),
  );
  final filaDeudas = numero() - 1;
  filas.add([]);

  // Los egresos del negocio, sin las cuotas: el excedente es antes de pagar
  // las deudas, y la capacidad de pago las resta después.
  String gastos(String c) => '${rango(variables, c)},${rango(fijos, c)}';
  total(
    'TOTAL EGRESOS DEL NEGOCIO',
    (c) => vacio(gastos(c), 'SUM(${gastos(c)})'),
    (i) => suma([...variables, ...fijos], i),
  );
  total(
    'EXCEDENTE BRUTO DEL NEGOCIO',
    (c) => vacio(
      '${rango(ingresos, c)},${gastos(c)}',
      'N($c$filaIngresos)-SUM(${gastos(c)})',
    ),
    (i) {
      final todo = suma([...ingresos, ...variables, ...fijos], i);
      if (todo == '') return '';
      return _n(suma(ingresos, i)) - _n(suma([...variables, ...fijos], i));
    },
  );
  final filaExcedente = numero() - 1;
  filas.add([]);

  final incompleto = meses
      .where((m) => m.estado == EstadoMesFlujo.incompleto)
      .firstOrNull;
  final enCurso = meses
      .where((m) => m.estado == EstadoMesFlujo.enCurso)
      .firstOrNull;
  filas.add([
    _t(
      'Flujo de caja: cada pago cuenta el día que se pagó. Lo que el dueño '
      'puso de su bolsillo no es ingreso del negocio; lo que retiró para él '
      'va en la hoja del hogar. El excedente es antes de las cuotas.',
    ),
  ]);
  if (incompleto != null && f.inicioMoca != null) {
    filas.add([
      _t(
        '* Mes incompleto: Moca empezó a anotar el '
        '${formatearFechaLarga(f.inicioMoca!)}.'
        '${f.hayMesCompleto ? ' No entra en el promedio.' : ''}',
      ),
    ]);
  }
  if (enCurso != null) {
    filas.add([
      _t(
        '${nombreDelMesConMayuscula(enCurso.mes)} va hasta hoy, porque Moca '
        'todavía no tiene un mes completo.',
      ),
    ]);
  }
  if (meses.any((m) => m.estado == EstadoMesFlujo.antesDeMoca)) {
    filas.add([
      _t(
        '— Antes de Moca: el dueño completa las celdas amarillas con su '
        'cuaderno o sus comprobantes.',
      ),
    ]);
  }
  filas.add([_t('Hecho con Moca el ${formatearFechaLarga(hoy)}.')]);

  // Las otras hojas leen H31 y H34.
  assert(filaDeudas == 31 && filaExcedente == 34);
  return (
    HojaXlsx(
      nombre: _hojaFlujo,
      anchos: [42, for (final _ in meses) 15, 13, 46],
      filas: filas,
    ),
    _n(promedioDe(valores[filaDeudas]!)),
    _n(promedioDe(valores[filaExcedente]!)),
  );
}

HojaXlsx _hogar(FlujoParaCredito f, _Hogar h) {
  const llenar = CeldaVacia(formato: FormatoNumero.solesEnteros);
  final retiros = f.retirosPromedioCentimos;
  CeldaFormula formula(String formula, double valor, {bool fuerte = false}) =>
      CeldaFormula(
        formula,
        valor: valor,
        formato: FormatoNumero.solesEnteros,
        fuerte: fuerte,
      );
  return HojaXlsx(
    nombre: _hojaHogar,
    anchos: const [46, 16, 58],
    filas: [
      [_t('GASTOS FAMILIARES Y CAPACIDAD DE PAGO', fuerte: true)],
      [_seccion('INGRESOS TOTALES DEL HOGAR')],
      [
        _t('Excedente bruto negocio (de FLUJO_MENSUAL)'),
        formula('N($_hojaFlujo!H34)', h.excedenteNegocio),
        _t('Promedio del EXCEDENTE BRUTO: se trae solo'),
      ],
      [_t('Sueldo cónyuge / otro ingreso fijo'), llenar, _t('Si aplica')],
      [
        _t('Otros ingresos familiares'),
        llenar,
        _t('Alquileres, pensiones, etc.'),
      ],
      [
        _t('TOTAL INGRESOS FAMILIARES', fuerte: true),
        formula('N(B3)+N(B4)+N(B5)', h.ingresos, fuerte: true),
      ],
      [],
      [_seccion('GASTOS FAMILIARES MENSUALES')],
      [_t('Alimentación'), llenar, _t('Mercado, restaurante, etc.')],
      [_t('Educación (colegios, universidades)'), llenar],
      [_t('Salud y medicamentos'), llenar],
      [_t('Transporte familiar'), llenar],
      [_t('Servicios del hogar (luz, agua, gas)'), llenar],
      [_t('Alquiler vivienda (si no es propia)'), llenar],
      [_t('Otros gastos del hogar'), llenar, _t('Ropa, entretenimiento, etc.')],
      [
        _t('TOTAL GASTOS FAMILIARES', fuerte: true),
        formula('SUM(B9:B15)', h.gastos, fuerte: true),
      ],
      [
        _t('Referencia: lo que retiró para él (Moca)'),
        if (retiros == null)
          _t('—')
        else
          CeldaNumero.soles(retiros, enteros: true),
        _t(
          'Promedio de «Retiro para mí» al mes. Sirve para comparar con los '
          'gastos del hogar.',
          ajustar: true,
        ),
      ],
      [
        _t('EXCEDENTE NETO DISPONIBLE', fuerte: true),
        formula('B6-B16', h.excedenteNeto, fuerte: true),
        _t('Antes de las cuotas que ya pagas'),
      ],
      [],
      [_seccion('REFERENCIA PARA EL CRÉDITO')],
      [
        _t('Cuotas que ya pagas (de FLUJO_MENSUAL)'),
        formula('N($_hojaFlujo!H31)', h.cuotasActuales),
        _t('Promedio del TOTAL DEUDAS ACTUALES'),
      ],
      [
        _t('Cuota nueva máxima (40 %)'),
        formula('MAX(0,B18*0.4-B21)', h.cuotaMaxima(0.4)),
        _t('Todas tus cuotas juntas, hasta el 40 % del excedente neto'),
      ],
      [
        _t('Cuota nueva máxima con entidad flexible (50 %)'),
        formula('MAX(0,B18*0.5-B21)', h.cuotaMaxima(0.5)),
        _t('Algunas cajas aceptan hasta 50 %'),
      ],
    ],
  );
}

HojaXlsx _resumen(_Hogar h) {
  CeldaFormula formula(String formula, double valor, {bool fuerte = false}) =>
      CeldaFormula(
        formula,
        valor: valor,
        formato: FormatoNumero.solesEnteros,
        fuerte: fuerte,
      );
  return HojaXlsx(
    nombre: 'RESUMEN_CREDITO',
    anchos: const [40, 44, 52],
    filas: [
      [_t('RESUMEN PARA SOLICITUD DE CRÉDITO', fuerte: true)],
      [_t('Esta hoja calcula sola la capacidad de endeudamiento')],
      [_seccion('DATOS CLAVE DE TU FLUJO')],
      [
        _t('Excedente Bruto Promedio (negocio)'),
        formula('N($_hojaFlujo!H34)', h.excedenteNegocio),
        _t('Promedio de los meses del negocio'),
      ],
      [
        _t('Gastos Familiares Mensuales'),
        formula('$_hojaHogar!B16', h.gastos),
        _t('Del hogar'),
      ],
      [
        _t('Excedente Neto Real'),
        formula('$_hojaHogar!B18', h.excedenteNeto),
        _t('= Negocio + otros ingresos del hogar − gastos del hogar'),
      ],
      [
        _t('Deudas actuales (cuota total)'),
        formula('N($_hojaFlujo!H31)', h.cuotasActuales),
        _t('Suma de las cuotas que ya pagas'),
      ],
      [
        _t('Excedente Libre'),
        formula('B6-B7', h.libre),
        _t('Excedente neto − cuotas actuales'),
      ],
      [],
      [_seccion('CAPACIDAD DE PAGO')],
      [
        _t('Cuota nueva máxima (regla del 40 %)'),
        formula('MAX(0,B6*0.4-B7)', h.cuotaMaxima(0.4)),
        _t('Todas las cuotas, con la nueva, hasta el 40 % del excedente neto'),
      ],
      [
        _t('Cuota nueva máxima (regla del 50 %)'),
        formula('MAX(0,B6*0.5-B7)', h.cuotaMaxima(0.5)),
        _t('Cajas más flexibles'),
      ],
      [],
      [_seccion('¿CUÁNTO PUEDO PEDIR?')],
      [
        _t('Ingresa la tasa mensual (%)'),
        const CeldaNumero(
          0.018,
          formato: FormatoNumero.porcentaje,
          relleno: Relleno.paraLlenar,
        ),
        _t('Ej: 1.8 % mensual ≈ 21.6 % anual'),
      ],
      [
        _t('Ingresa el plazo en meses'),
        const CeldaNumero(12, relleno: Relleno.paraLlenar),
        _t('Ej: 12, 18, 24, 36'),
      ],
      [
        _t('Monto máximo estimado', fuerte: true),
        formula(
          'IF(OR(B11<=0,B15<=0,B16<=0),0,B11*(1-(1+B15)^(-B16))/B15)',
          h.montoMaximo,
          fuerte: true,
        ),
        _t(
          'Cuota nueva máxima del 40 % × factor de valor presente — '
          'referencial',
        ),
      ],
      [],
      [_seccion('SEMÁFORO DE VIABILIDAD')],
      [
        _t('Estado del excedente libre'),
        CeldaFormula(
          'IF(B8>0,"POSITIVO — hay capacidad de pago",'
          'IF(B8=0,"EN CERO — riesgo alto","NEGATIVO — no recomendable"))',
          valor: h.libre > 0
              ? 'POSITIVO — hay capacidad de pago'
              : h.libre == 0
              ? 'EN CERO — riesgo alto'
              : 'NEGATIVO — no recomendable',
        ),
      ],
      [
        _t('¿Cabe una cuota nueva (regla del 40 %)?'),
        CeldaFormula(
          'IF(B11>0,"SÍ — hasta la cuota de B11",'
          '"NO — las cuotas actuales ya llegan al 40 %")',
          valor: h.cuotaMaxima(0.4) > 0
              ? 'SÍ — hasta la cuota de B11'
              : 'NO — las cuotas actuales ya llegan al 40 %',
        ),
      ],
      [],
      [
        _t(
          'Este cálculo es estimativo. El evaluador de la entidad financiera '
          'puede ajustar los valores según su metodología.',
        ),
      ],
    ],
  );
}
