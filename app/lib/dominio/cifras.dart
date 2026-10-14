import 'arqueo.dart';
import 'informe.dart';
import 'moca.dart';
import 'modelos.dart';

/// Las cifras que calcula el servidor (docs/v1-real.md, entrega 13). Con
/// cuenta y sin nada por subir, la app muestra estas; si no, calcula lo
/// mismo en el teléfono con las mismas reglas.
class Cifras {
  const Cifras({
    required this.dia,
    required this.saldos,
    required this.inicio,
    required this.resumenSemana,
    required this.avisos,
    required this.informes,
  });

  /// El día en que se calcularon («2026-10-14»): al día siguiente ya no
  /// valen (la semana, los días sin anotar y los avisos cambian).
  final String dia;
  final Map<TipoCuenta, int> saldos;
  final CifrasInicio inicio;
  final ResumenSemana resumenSemana;

  /// Sin los que el dueño marcó «Entendido».
  final List<Aviso> avisos;

  /// Del primer mes con registros al actual.
  final List<InformeMes> informes;

  static String textoDia(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _textoMes(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}';

  static DateTime _mes(Object? v) {
    final [anio, mes] = (v! as String).split('-').map(int.parse).toList();
    return DateTime(anio, mes);
  }

  static DateTime? _mesONulo(Object? v) => v == null ? null : _mes(v);

  factory Cifras.fromJson(Map<String, Object?> j) {
    final inicio = j['inicio']! as Map<String, Object?>;
    final resumen = j['resumenSemana']! as Map<String, Object?>;
    return Cifras(
      dia: j['dia']! as String,
      saldos: {
        for (final MapEntry(:key, :value)
            in (j['saldos']! as Map<String, Object?>).entries)
          TipoCuenta.values.byName(key): value! as int,
      },
      inicio: CifrasInicio(
        semanaEntroCentimos: inicio['semanaEntroCentimos']! as int,
        semanaSalioCentimos: inicio['semanaSalioCentimos']! as int,
        semanaConMovimientos: inicio['semanaConMovimientos']! as bool,
        diferenciaConSemanaAnteriorCentimos:
            inicio['diferenciaConSemanaAnteriorCentimos'] as int?,
        ventaDeHoyCentimos: inicio['ventaDeHoyCentimos']! as int,
        estadoArqueo: EstadoArqueo.values.byName(
          inicio['estadoArqueo']! as String,
        ),
      ),
      resumenSemana: ResumenSemana(
        semanaPasada: resumen['semanaPasada']! as bool,
        conMovimientos: resumen['conMovimientos']! as bool,
        quedoCentimos: resumen['quedoCentimos']! as int,
        diferenciaCentimos: resumen['diferenciaCentimos'] as int?,
        categoriaTop: resumen['categoriaTop'] as String?,
        categoriaTopCentimos: resumen['categoriaTopCentimos'] as int?,
      ),
      avisos: [
        for (final a in j['avisos']! as List)
          if (a case final Map<String, Object?> a)
            Aviso(
              clave: a['clave']! as String,
              tipo: TipoAviso.values.byName(a['tipo']! as String),
              prioridad: PrioridadAlerta.values.byName(
                a['prioridad']! as String,
              ),
              fecha: DateTime.parse(a['fecha']! as String).toLocal(),
              montoCentimos: a['montoCentimos'] as int?,
              cuenta: a['cuenta'] == null
                  ? null
                  : TipoCuenta.values.byName(a['cuenta']! as String),
              categoria: a['categoria'] as String?,
              dias: a['dias'] as int?,
              destinoId: a['destinoId'] as String?,
            ),
      ],
      informes: [
        for (final i in j['informes']! as List)
          if (i case final Map<String, Object?> i)
            InformeMes(
              mes: _mes(i['mes']),
              enCurso: i['enCurso']! as bool,
              sinRegistros: i['sinRegistros']! as bool,
              desdeDia: i['desdeDia'] as int?,
              mesAnterior: _mesONulo(i['mesAnterior']),
              diferenciaConAnteriorCentimos:
                  i['diferenciaConAnteriorCentimos'] as int?,
              entroCentimos: i['entroCentimos']! as int,
              salioCentimos: i['salioCentimos']! as int,
              retirosCentimos: i['retirosCentimos']! as int,
              gastos: [
                for (final g in i['gastos']! as List)
                  if (g case final Map<String, Object?> g)
                    GastoPorCategoria(
                      nombre: g['nombre'] as String?,
                      centimos: g['centimos']! as int,
                    ),
              ],
              cambio: switch (i['cambio']) {
                final Map<String, Object?> c => CambioDeCategoria(
                  nombre: c['nombre']! as String,
                  centimos: c['centimos']! as int,
                ),
                _ => null,
              },
              loQueDebesCentimos: i['loQueDebesCentimos']! as int,
              confianza: switch (i['confianza']) {
                final Map<String, Object?> c => ConfianzaDelMes(
                  conComprobante: c['conComprobante']! as int,
                  conFoto: c['conFoto']! as int,
                  sinPapel: c['sinPapel']! as int,
                ),
                _ => null,
              },
              advertenciaMercaderia: i['advertenciaMercaderia']! as bool,
              mesPrevio: _mesONulo(i['mesPrevio']),
              mesSiguiente: _mesONulo(i['mesSiguiente']),
            ),
      ],
    );
  }

  /// El mismo formato que manda el servidor: sirve para guardarlas en el
  /// teléfono y para la prueba de paridad con el servidor.
  Map<String, Object?> toJson() => {
    'dia': dia,
    'saldos': {for (final e in saldos.entries) e.key.name: e.value},
    'inicio': {
      'semanaEntroCentimos': inicio.semanaEntroCentimos,
      'semanaSalioCentimos': inicio.semanaSalioCentimos,
      'semanaConMovimientos': inicio.semanaConMovimientos,
      'diferenciaConSemanaAnteriorCentimos':
          inicio.diferenciaConSemanaAnteriorCentimos,
      'ventaDeHoyCentimos': inicio.ventaDeHoyCentimos,
      'estadoArqueo': inicio.estadoArqueo.name,
    },
    'resumenSemana': {
      'semanaPasada': resumenSemana.semanaPasada,
      'conMovimientos': resumenSemana.conMovimientos,
      'quedoCentimos': resumenSemana.quedoCentimos,
      'diferenciaCentimos': resumenSemana.diferenciaCentimos,
      'categoriaTop': resumenSemana.categoriaTop,
      'categoriaTopCentimos': resumenSemana.categoriaTopCentimos,
    },
    'avisos': [
      for (final a in avisos)
        {
          'clave': a.clave,
          'tipo': a.tipo.name,
          'prioridad': a.prioridad.name,
          'fecha': a.fecha.toUtc().toIso8601String(),
          'montoCentimos': a.montoCentimos,
          'cuenta': a.cuenta?.name,
          'categoria': a.categoria,
          'dias': a.dias,
          'destinoId': a.destinoId,
        },
    ],
    'informes': [
      for (final i in informes)
        {
          'mes': _textoMes(i.mes),
          'enCurso': i.enCurso,
          'sinRegistros': i.sinRegistros,
          'desdeDia': i.desdeDia,
          'mesAnterior': i.mesAnterior == null
              ? null
              : _textoMes(i.mesAnterior!),
          'diferenciaConAnteriorCentimos': i.diferenciaConAnteriorCentimos,
          'entroCentimos': i.entroCentimos,
          'salioCentimos': i.salioCentimos,
          'retirosCentimos': i.retirosCentimos,
          'gastos': [
            for (final g in i.gastos)
              {'nombre': g.nombre, 'centimos': g.centimos},
          ],
          'cambio': i.cambio == null
              ? null
              : {'nombre': i.cambio!.nombre, 'centimos': i.cambio!.centimos},
          'loQueDebesCentimos': i.loQueDebesCentimos,
          'confianza': i.confianza == null
              ? null
              : {
                  'conComprobante': i.confianza!.conComprobante,
                  'conFoto': i.confianza!.conFoto,
                  'sinPapel': i.confianza!.sinPapel,
                },
          'advertenciaMercaderia': i.advertenciaMercaderia,
          'mesPrevio': i.mesPrevio == null ? null : _textoMes(i.mesPrevio!),
          'mesSiguiente': i.mesSiguiente == null
              ? null
              : _textoMes(i.mesSiguiente!),
        },
    ],
  };
}

/// Lo del Inicio que sale de las cifras.
class CifrasInicio {
  const CifrasInicio({
    required this.semanaEntroCentimos,
    required this.semanaSalioCentimos,
    required this.semanaConMovimientos,
    required this.diferenciaConSemanaAnteriorCentimos,
    required this.ventaDeHoyCentimos,
    required this.estadoArqueo,
  });

  final int semanaEntroCentimos;
  final int semanaSalioCentimos;
  final bool semanaConMovimientos;
  final int? diferenciaConSemanaAnteriorCentimos;
  final int ventaDeHoyCentimos;

  /// Sin el pedido del operador, que vive solo en el teléfono.
  final EstadoArqueo estadoArqueo;
}
