import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../comun/icono_trazo.dart';
import 'encabezado_negocio.dart';
import '../../comun/tarjeta.dart';
import '../../comun/videos.dart';
import '../../dominio/primer_dia.dart';
import '../../dominio/tutoria.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import 'bloque_pendientes.dart';
import 'desglose_cuentas.dart';
import 'tarjeta_tienes_hoy.dart';

/// S03 · Primer día. Es el Inicio durante la primera semana, hasta el primer
/// arqueo (prototipo-v1.md, «Comportamiento acordado»).
class PantallaPrimerDia extends StatelessWidget {
  const PantallaPrimerDia({
    super.key,
    required this.resumen,
    required this.alAnotarVenta,
    required this.alDeclararSaldo,
    required this.alHacerArqueo,
    this.tarjetaAvisos,
  });

  final ResumenPrimerDia resumen;
  final VoidCallback alAnotarVenta;
  final VoidCallback alDeclararSaldo;

  /// Paso 4: el primer arqueo se puede hacer cualquier día.
  final VoidCallback alHacerArqueo;

  /// El permiso de avisos, si falta pedirlo.
  final Widget? tarjetaAvisos;

  static const _ventaDiasMeta = 5;

  @override
  Widget build(BuildContext context) {
    final nota = resumen.saldoPendiente
        ? Textos.notaSaldoPendiente
        : resumen.conOtrosMovimientos
        ? Textos.notaConMovimientos
        : resumen.ventaDeHoyAnotada
        ? Textos.notaSaldoMasVenta
        : Textos.notaSoloSaldo;

    // Cada paso se marca con lo anotado; el primero que falta es el actual
    // (decisiones.md, 16-10-2026).
    final hechos = [
      !resumen.saldoPendiente,
      resumen.diasConVenta >= _ventaDiasMeta,
      resumen.gastoConComprobante,
      resumen.arqueoHecho,
    ];
    final actual = hechos.indexOf(false);
    _EstadoPaso estadoDelPaso(int i) => hechos[i]
        ? _EstadoPaso.hecho
        : i == actual
        ? _EstadoPaso.actual
        : _EstadoPaso.pendiente;

    final hechosCuantos = hechos.where((h) => h).length;
    return SafeArea(
      bottom: false,
      // Todo armado de una vez: el Inicio es corto, y así lo de abajo
      // (los pasos, la tarjeta de Moca) existe aunque no se vea todavía.
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Espacio para el + que sobresale de la barra.
        padding: const EdgeInsets.only(bottom: Medidas.e8 + Medidas.e4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EncabezadoNegocio(
              nombre: resumen.nombreNegocio,
              detalle: Textos.tuPrimerDia,
            ),
            ?tarjetaAvisos,
            _conMargen(
              TarjetaTienesHoy(
                etiqueta: Textos.tienesHoy,
                centimos: resumen.tienesHoyCentimos,
                explicacion: nota,
                pildora: resumen.ventaDeHoyAnotada
                    ? Textos.vendisteHoy(
                        formatearSoles(resumen.ventaDeHoyCentimos),
                      )
                    : null,
              ),
            ),
            // Qué hay en cada cuenta, como en el Inicio.
            if (resumen.saldosPorCuenta.isNotEmpty) ...[
              const SizedBox(height: Medidas.e5),
              DesgloseDeCuentas(
                saldos: resumen.saldosPorCuenta,
                conVerTodas: true,
              ),
            ],
            const BloquePendientes(),
            const SizedBox(height: Medidas.separacionTarjetas),
            // Moca no repite el +: la venta de hoy mientras falta y, ya
            // anotada, «Escuchar mi semana» (mejora 01).
            _conMargen(
              TarjetaMoca(
                texto: resumen.ventaDeHoyAnotada
                    ? Textos.mocaYaAnotaste
                    : Textos.mocaEmpiezaPorLaVenta,
                accion: resumen.ventaDeHoyAnotada
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              StatefulNavigationShell.maybeOf(context)
                                  ?.goBranch(3),
                          iconAlignment: IconAlignment.end,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text(Textos.escucharMiSemana),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: alAnotarVenta,
                        icon: const Icon(Icons.mic_rounded),
                        label: const Text(Textos.anotarVentaDeHoy),
                      ),
              ),
            ),
            const SizedBox(height: Medidas.separacionTarjetas),
            _conMargen(
              Tarjeta(
                relleno: const EdgeInsets.all(Medidas.e5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            Textos.tusPrimerosPasos,
                            style: Tipografia.tituloSeccion,
                          ),
                        ),
                        Text(
                          Textos.pasosHechos(hechosCuantos, hechos.length),
                          style: Tipografia.apoyo.copyWith(
                            color: Colores.marca,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Medidas.e3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Medidas.radioPildora),
                      child: LinearProgressIndicator(
                        value: hechosCuantos / hechos.length,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: Medidas.e2),
                    _Paso(
                      numero: 1,
                      texto: Textos.pasoDecirPlata,
                      estado: estadoDelPaso(0),
                      video: VideoTutoria.queEsMoca,
                      alTocar: resumen.saldoPendiente ? alDeclararSaldo : null,
                    ),
                    _Paso(
                      numero: 2,
                      texto: Textos.pasoVentaCincoDias(resumen.diasConVenta),
                      estado: estadoDelPaso(1),
                      video: VideoTutoria.ventaDelDia,
                    ),
                    _Paso(
                      numero: 3,
                      texto: Textos.pasoPrimerGasto,
                      estado: estadoDelPaso(2),
                      video: VideoTutoria.gastoConFoto,
                    ),
                    _Paso(
                      numero: 4,
                      texto: Textos.pasoPrimerArqueo,
                      estado: estadoDelPaso(3),
                      video: VideoTutoria.arqueo,
                      alTocar: alHacerArqueo,
                    ),
                    const SizedBox(height: Medidas.e1),
                    const Text(
                      Textos.conEstosPasos,
                      style: Tipografia.secundario,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conMargen(Widget hijo) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Medidas.margenLateral),
    child: hijo,
  );
}

enum _EstadoPaso { hecho, actual, pendiente }

class _Paso extends StatelessWidget {
  const _Paso({
    required this.numero,
    required this.texto,
    required this.estado,
    required this.video,
    this.alTocar,
  });

  final int numero;
  final String texto;
  final _EstadoPaso estado;

  /// «▶ Ver cómo» debajo del paso, mientras no esté hecho (entrega 14.6).
  final VideoTutoria video;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final circulo = switch (estado) {
      _EstadoPaso.hecho => Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Colores.marca,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: IconoTrazo(
            Icono.check,
            color: Colores.sobreMarca,
            tamano: 16,
            grosor: 2.6,
          ),
        ),
      ),
      _ => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 2,
            color: estado == _EstadoPaso.actual
                ? Colores.marca
                : Colores.bordeBotonSecundario,
          ),
        ),
        child: Center(
          child: Text(
            '$numero',
            style: Tipografia.apoyo.copyWith(
              fontWeight: FontWeight.w700,
              color: estado == _EstadoPaso.actual
                  ? Colores.azulOscuro
                  : Colores.textoSecundario,
            ),
          ),
        ),
      ),
    };

    final estilo = switch (estado) {
      _EstadoPaso.hecho => Tipografia.texto.copyWith(
        color: Colores.textoSecundario,
      ),
      _EstadoPaso.actual => Tipografia.texto.copyWith(
        fontWeight: FontWeight.w700,
      ),
      _EstadoPaso.pendiente => Tipografia.texto,
    };

    final fila = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          circulo,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: alTocar == null
                  ? estilo
                  : estilo.copyWith(
                      color: Colores.marca,
                      decoration: TextDecoration.underline,
                      decorationColor: Colores.marca,
                    ),
            ),
          ),
        ],
      ),
    );

    final paso = Semantics(
      button: alTocar != null,
      checked: estado == _EstadoPaso.hecho,
      child: alTocar == null ? fila : InkWell(onTap: alTocar, child: fila),
    );
    if (estado == _EstadoPaso.hecho) return paso;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        paso,
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: EnlaceVerComo(video: video, desde: DesdeVideo.pasos),
        ),
      ],
    );
  }
}
