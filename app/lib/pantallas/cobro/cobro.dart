import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/badge_estado.dart';
import '../../comun/tarjeta.dart';
import '../inicio/encabezado_negocio.dart';
import '../../dominio/cobro.dart';
import '../informe/excel_informe.dart';
import '../../dominio/equipo.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../rutas.dart';
import '../../textos/textos.dart';
import 'elegir_plan.dart';

/// El estado del cobro en la pestaña Moca, para los dueños (entrega 25).
class TarjetaCobro extends ConsumerWidget {
  const TarjetaCobro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cobro = ref.watch(cobroProvider).value ?? Cobro.sinCobro;
    final permisos = ref.watch(permisosProvider).value ?? Permisos.delDueno;
    if (cobro.estado == EstadoDelCobro.sinCobro || permisos.rol != Rol.dueno) {
      return const SizedBox.shrink();
    }
    final hasta = cobro.hasta == null ? '' : formatearDiaYMes(cobro.hasta!);
    final texto = switch (cobro.estado) {
      EstadoDelCobro.prueba when cobro.hasta == null => Textos.pruebaSinEmpezar,
      EstadoDelCobro.prueba => Textos.pruebaTeQuedan(cobro.dias ?? 0, hasta),
      EstadoDelCobro.pagado => Textos.pagadoHasta(hasta),
      _ =>
        cobro.plan == null
            ? '${Textos.pruebaTermino}.'
            : '${Textos.pagoVencio(hasta)}.',
    };
    final pagar =
        cobro.estado == EstadoDelCobro.prueba ||
        cobro.estado == EstadoDelCobro.vencido ||
        cobro.porVencer;
    // La prueba en curso (mejora 01): los días en grande, su barra y
    // «Activar mi plan».
    if (cobro.estado == EstadoDelCobro.prueba && cobro.hasta != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Medidas.separacionTarjetas),
        child: _TarjetaPrueba(
          dias: cobro.dias ?? 0,
          hasta: hasta,
          alActivar: () => mostrarComoPagar(context, ref, cobro),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Medidas.separacionTarjetas),
      child: Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(texto, style: Tipografia.textoFuerte),
            if (pagar) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => mostrarComoPagar(context, ref, cobro),
                  child: const Text(Textos.comoPagar),
                ),
              ),
            ] else if (cobro.puedeAdelantar)
              // Por adelantado (entrega 32.2): un enlace, no un aviso.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      mostrarComoPagar(context, ref, cobro, otroMes: true),
                  child: const Text(Textos.pagarOtroMes),
                ),
              ),
            // Ya pagó alguna vez: sus pagos (entrega 33).
            if (cobro.plan != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.push(Rutas.misPagos),
                  child: const Text(Textos.verMisPagos),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// La prueba gratis en el Asistente (mejora 01): «PRUEBA GRATIS», hasta
/// cuándo, los días que quedan con su barra y «Activar mi plan».
class _TarjetaPrueba extends StatelessWidget {
  const _TarjetaPrueba({
    required this.dias,
    required this.hasta,
    required this.alActivar,
  });

  final int dias;
  final String hasta;
  final VoidCallback alActivar;

  /// La prueba es de 14 días (decisiones.md); con días de regalo, la barra
  /// empieza llena.
  static const _diasDePrueba = 14;

  @override
  Widget build(BuildContext context) {
    final usados = (_diasDePrueba - dias).clamp(0, _diasDePrueba);
    return Container(
      padding: const EdgeInsets.all(Medidas.e5),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Medidas.radioMayor),
        border: Border.all(color: Colores.pendiente.withValues(alpha: 0.4)),
        boxShadow: Sombras.nivel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: Medidas.e2,
            children: [
              const BadgeEstado(Textos.pruebaGratisEtiqueta),
              Text(Textos.hastaEl(hasta), style: Tipografia.secundario),
            ],
          ),
          const SizedBox(height: Medidas.e3),
          if (dias == 0)
            Text(
              Textos.pruebaTeQuedan(0, hasta),
              style: Tipografia.tituloSeccion,
            )
          else
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: Textos.cuantosDias(dias),
                    style: Tipografia.montoGrande,
                  ),
                  TextSpan(
                    text: '  ${Textos.teQuedanDias(dias)}',
                    style: Tipografia.texto.copyWith(
                      color: Colores.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Medidas.e3),
          ClipRRect(
            borderRadius: BorderRadius.circular(Medidas.radioPildora),
            child: LinearProgressIndicator(
              value: usados / _diasDePrueba,
              minHeight: 8,
              color: Colores.pendiente,
              backgroundColor: Colores.pendienteFondo,
            ),
          ),
          const SizedBox(height: Medidas.e4),
          FilledButton(
            onPressed: alActivar,
            child: const Text(Textos.activarMiPlan),
          ),
        ],
      ),
    );
  }
}

/// «Tu prueba gratis termina en 2 días», arriba en el Inicio del dueño.
class AvisoDelCobro extends ConsumerWidget {
  const AvisoDelCobro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cobro = ref.watch(cobroProvider).value ?? Cobro.sinCobro;
    final permisos = ref.watch(permisosProvider).value ?? Permisos.delDueno;
    if (!cobro.porVencer || permisos.rol != Rol.dueno) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Medidas.separacionTarjetas),
      child: Container(
        padding: const EdgeInsets.fromLTRB(Medidas.e4, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colores.avisoFondo,
          borderRadius: BorderRadius.circular(Medidas.radioBoton),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                Textos.avisoPorVencer(
                  cobro.estado == EstadoDelCobro.prueba,
                  cobro.dias ?? 0,
                ),
                style: Tipografia.textoFuerte,
              ),
            ),
            TextButton(
              onPressed: () => mostrarComoPagar(context, ref, cobro),
              child: const Text(Textos.comoPagar),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pagar con Mercado Pago (entrega 32), como en TVSamGo: se abre la página
/// de pago en el navegador y, mientras tanto, la app pregunta cada 3
/// segundos, unos 3 minutos. Si el dueño no espera, el pago se activa igual.
Future<void> pagarConMercadoPago(
  BuildContext context, {
  NivelDePlan nivel = NivelDePlan.full,
  PeriodoDePlan periodo = PeriodoDePlan.mes,
}) async {
  final mensajes = ScaffoldMessenger.of(context);
  // El diálogo va en el navegador raíz; «Cómo pagar», en el de su pestaña.
  final raiz = Navigator.of(context, rootNavigator: true);
  final contenedor = ProviderScope.containerOf(context, listen: false);
  final servicio = contenedor.read(servicioCobroProvider);
  void decir(String texto) => mensajes.showSnackBar(
    SnackBar(content: Text(texto), duration: const Duration(seconds: 6)),
  );

  final r = await servicio.pagarConMercadoPago(nivel: nivel, periodo: periodo);
  final inicio = r.inicio;
  if (inicio == null) {
    decir(switch (r.error) {
      ErrorDePago.sinSenal => Textos.pagoSinSenal,
      ErrorDePago.noDisponible => Textos.pagoNoDisponible,
      ErrorDePago.soloDuenos => Textos.pagoSoloDuenos,
      _ => Textos.pagoFallo,
    });
    return;
  }
  if (!await contenedor.read(abridorProvider).abrir(inicio.enlace)) {
    decir(Textos.noSeAbrioElPago);
    return;
  }
  if (!context.mounted) return;

  var esperando = true;
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogo) => AlertDialog(
        content: const Row(
          children: [
            SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(Textos.esperandoElPago, style: Tipografia.texto),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              esperando = false;
              Navigator.of(dialogo).pop();
            },
            child: const Text(Textos.seguirSinEsperar),
          ),
        ],
      ),
    ).then((_) => esperando = false),
  );
  void cerrar() {
    if (esperando) {
      esperando = false;
      raiz.pop();
    }
  }

  for (var i = 0; i < 60 && esperando; i++) {
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!esperando) return;
    final orden = await servicio.estadoDeOrden(inicio.orden);
    if (!esperando) return;
    switch (orden.estado) {
      case EstadoDeOrden.pagada:
        cerrar();
        final hasta = orden.hasta;
        // También se cierran «Elige tu plan» y «Pagar tu plan»: ya está
        // pagado.
        if (context.mounted) {
          Navigator.of(context).popUntil(
            (r) =>
                r.settings.name != rutaPagarPlan &&
                r.settings.name != rutaElegirPlan,
          );
        }
        decir(
          hasta == null
              ? Textos.mocaPagada
              : Textos.mocaPagadaHasta(formatearDiaYMes(hasta)),
        );
        return;
      case EstadoDeOrden.revisar:
        cerrar();
        decir(Textos.pagoPorRevisar);
        return;
      case EstadoDeOrden.reembolsada:
        cerrar();
        decir(Textos.pagoDevuelto);
        return;
      case EstadoDeOrden.pendiente || EstadoDeOrden.sinSenal:
        break;
    }
  }
  if (esperando) {
    cerrar();
    decir(Textos.siYaPagaste);
  }
}

/// «Elige tu plan» y «Pagar tu plan» (entrega 60). Antes era la hoja
/// «Paga tu mes».
Future<void> mostrarComoPagar(
  BuildContext context,
  WidgetRef ref,
  Cobro cobro, {
  bool otroMes = false,
}) => abrirPlanes(context, cobro, otroMes: otroMes);

/// La pregunta del día 10 de la prueba, una sola vez, en la pestaña Moca.
class PreguntaDelPrecio extends ConsumerStatefulWidget {
  const PreguntaDelPrecio({super.key});

  @override
  ConsumerState<PreguntaDelPrecio> createState() => _EstadoPregunta();
}

class _EstadoPregunta extends ConsumerState<PreguntaDelPrecio> {
  final _motivo = TextEditingController();
  RespuestaPrecio? _elegida;
  bool _enviando = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final elegida = _elegida;
    if (elegida == null) return;
    setState(() => _enviando = true);
    final mensajes = ScaffoldMessenger.of(context);
    final resultado = await ref
        .read(servicioCobroProvider)
        .responderPrecio(elegida, motivo: _motivo.text);
    if (!mounted) return;
    setState(() => _enviando = false);
    mensajes.showSnackBar(
      SnackBar(
        content: Text(
          resultado == ResultadoEquipo.listo
              ? Textos.graciasPorResponder
              : Textos.necesitasSenalParaResponder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cobro = ref.watch(cobroProvider).value ?? Cobro.sinCobro;
    final permisos = ref.watch(permisosProvider).value ?? Permisos.delDueno;
    if (!cobro.tocaPreguntar || permisos.rol != Rol.dueno) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Medidas.separacionTarjetas),
      child: Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              Textos.preguntaPrecio(
                formatearSolesComprobante(cobro.precioCentimos),
              ),
              style: Tipografia.textoFuerte,
            ),
            const SizedBox(height: Medidas.e3),
            Wrap(
              spacing: 8,
              children: [
                for (final (respuesta, texto) in const [
                  (RespuestaPrecio.si, Textos.respuestaSi),
                  (RespuestaPrecio.noSe, Textos.respuestaNoSe),
                  (RespuestaPrecio.no, Textos.respuestaNo),
                ])
                  ChoiceChip(
                    label: Text(texto),
                    selected: _elegida == respuesta,
                    onSelected: (_) => setState(() => _elegida = respuesta),
                  ),
              ],
            ),
            if (_elegida != null) ...[
              const SizedBox(height: Medidas.e3),
              TextField(
                controller: _motivo,
                maxLength: 300,
                decoration: const InputDecoration(
                  hintText: Textos.porQueOpcional,
                ),
              ),
              FilledButton(
                onPressed: _enviando ? null : _enviar,
                child: const Text(Textos.enviarRespuesta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// El Inicio al vencer (entrega 25): se anota y se baja el Excel del mes.
class InicioSoloAnotar extends ConsumerWidget {
  const InicioSoloAnotar({
    super.key,
    required this.alAnotarVenta,
    required this.alBajarExcel,
  });

  final VoidCallback alAnotarVenta;
  final VoidCallback alBajarExcel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cobro = ref.watch(cobroProvider).value ?? Cobro.sinCobro;
    final permisos = ref.watch(permisosProvider).value ?? Permisos.delDueno;
    final dueno = permisos.rol == Rol.dueno;
    final nombre = ref.watch(resumenInicioProvider).value?.nombreNegocio ?? '';
    final hasta = cobro.hasta == null ? '' : formatearDiaYMes(cobro.hasta!);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          0,
          Medidas.margenLateral,
          Medidas.e4,
        ),
        children: [
          // Con la prueba vencida también se llega a Ajustes (mejora 01).
          EncabezadoNegocio(nombre: nombre, conMargen: false),
          const SizedBox(height: Medidas.e2),
          Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  cobro.plan == null
                      ? Textos.pruebaTermino
                      : Textos.pagoVencio(hasta),
                  style: Tipografia.tituloTarjeta,
                ),
                const SizedBox(height: 4),
                Text(
                  dueno ? Textos.soloAnotarDetalle : Textos.soloAnotarOtros,
                  style: Tipografia.secundario,
                ),
                if (dueno) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => mostrarComoPagar(context, ref, cobro),
                    child: const Text(Textos.comoPagar),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Medidas.separacionTarjetas),
          if (permisos.anota)
            FilledButton(
              onPressed: alAnotarVenta,
              child: const Text(Textos.anotarVentaDeHoy),
            ),
          if (dueno) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: alBajarExcel,
              child: const Text(Textos.bajarMisOperaciones),
            ),
          ],
        ],
      ),
    );
  }
}

/// El Excel de las operaciones del mes en curso, también al vencer.
Future<void> bajarExcelDelMes(BuildContext context, WidgetRef ref) async {
  final mensajes = ScaffoldMessenger.of(context);
  try {
    final informe = await ref
        .read(repositorioInformeProvider)
        .observarMes(null)
        .first;
    final detalle = await ref
        .read(repositorioInformeProvider)
        .detalleParaPdf(informe);
    final ruta = await guardarExcelDelInforme(
      informe,
      detalle,
      nombreNegocio: ref.read(resumenInicioProvider).value?.nombreNegocio ?? '',
      hoy: ref.read(relojProvider)(),
    );
    await ref
        .read(compartidorProvider)
        .compartirArchivo(
          ruta,
          asunto: Textos.operacionesDe(
            nombreDelMes(informe.mes),
            informe.mes.year,
          ),
          tipo: tipoExcel,
        );
  } on Exception {
    mensajes.showSnackBar(const SnackBar(content: Text(Textos.excelNoSeArmo)));
  }
}
