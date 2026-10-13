import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../dominio/moca.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../textos/textos.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/medicion.dart';
import '../../inyeccion.dart';

// Las plantillas de los avisos y del resumen. Las reglas viven en la capa
// de datos; aquí solo se redacta (en la V1 real, lo redacta la IA).

String textoAviso(Aviso a) => switch (a.tipo) {
  TipoAviso.faltaArqueo => Textos.avisoFaltaArqueo,
  TipoAviso.diferenciaArqueo => Textos.avisoDiferencia(
    formatearSoles(a.montoCentimos ?? 0),
    a.cuenta == null ? '' : Textos.nombreCuenta(a.cuenta!),
  ),
  TipoAviso.diasSinRegistrar => Textos.avisoDias(a.dias ?? 2),
  TipoAviso.gastoAtipico => Textos.avisoAtipico(
    formatearSoles(a.montoCentimos ?? 0),
    a.categoria ?? Textos.otro,
  ),
};

/// Lo que dice la tarjeta de Moca del Inicio para este aviso.
String textoAvisoEnInicio(Aviso a) => a.tipo == TipoAviso.faltaArqueo
    ? Textos.mocaFaltaArqueo
    : '${textoAviso(a)}.';

String accionAviso(Aviso a) => switch (a.tipo) {
  TipoAviso.faltaArqueo => Textos.hacerArqueo,
  TipoAviso.diferenciaArqueo => Textos.verElAjuste,
  TipoAviso.diasSinRegistrar => Textos.registrar,
  TipoAviso.gastoAtipico => Textos.verElGasto,
};

void abrirAviso(BuildContext context, Aviso a) {
  ProviderScope.containerOf(context, listen: false)
      .read(medicionProvider)
      .anotar(EventoMedicion.avisoTocado, {'tipo': a.tipo.name});
  switch (a.tipo) {
    case TipoAviso.faltaArqueo:
      context.push(Rutas.arqueo);
    case TipoAviso.diasSinRegistrar:
      context.push(Rutas.registrar);
    case TipoAviso.diferenciaArqueo || TipoAviso.gastoAtipico:
      if (a.destinoId case final id?) {
        context.push(Rutas.detalleMovimiento(id));
      }
  }
}

/// El resumen de la semana en una o dos frases. Sin «te alcanza» ni fiado.
String resumenEnTexto(ResumenSemana r) {
  if (!r.conMovimientos) {
    return r.semanaPasada
        ? Textos.semanaPasadaSinNada
        : Textos.semanaSinMovimientos;
  }
  final quedo = formatearSoles(r.quedoCentimos.abs());
  final inicio = switch ((r.semanaPasada, r.quedoCentimos >= 0)) {
    (true, true) => Textos.semanaPasadaQuedo(quedo),
    (true, false) => Textos.semanaPasadaPerdiste(quedo),
    (false, true) => Textos.estaSemanaQueda(quedo),
    (false, false) => Textos.estaSemanaPerdiste(quedo),
  };
  final diferencia = r.diferenciaCentimos;
  final comparacion = diferencia == null
      ? '.'
      : diferencia > 0
      ? Textos.masQueLaAnterior(formatearSoles(diferencia))
      : diferencia < 0
      ? Textos.menosQueLaAnterior(formatearSoles(-diferencia))
      : Textos.igualQueLaAnterior;
  final top = r.categoriaTop == null
      ? ''
      : Textos.loQueMasSalio(
          r.categoriaTop!,
          formatearSoles(r.categoriaTopCentimos ?? 0),
        );
  return '$inicio$comparacion$top';
}

/// Cuánto dura leerlo en voz alta, a unas 150 palabras por minuto.
int segundosDeLectura(String texto) {
  final palabras = texto.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final segundos = (palabras.length / 2.5).round();
  return segundos < 5 ? 5 : segundos;
}
