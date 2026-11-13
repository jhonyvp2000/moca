import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/cuenta_real.dart';
import '../../dominio/equipo.dart';
import '../../dominio/modelos.dart';
import '../../dominio/movimientos.dart';
import '../../pais/peru/formato.dart';
import '../../tema/medidas.dart';
import '../../textos/textos.dart';
import '../preguntale/barra_preguntale.dart';
import 'desglose_cuentas.dart';
import 'encabezado_negocio.dart';
import '../../inyeccion.dart';
import 'tarjeta_tienes_hoy.dart';

/// S04 · Inicio. Sin la franja de planes ni «Lo que viene» (ajustes respecto
/// al mockup), y sin la flecha para cambiar de empresa.
class PantallaInicioCompleta extends ConsumerStatefulWidget {
  const PantallaInicioCompleta({
    super.key,
    required this.resumen,
    this.tarjetaAvisos,
    this.actualizado,
    this.permisos = Permisos.delDueno,
  });

  final ResumenInicio resumen;

  /// El permiso de avisos, si falta pedirlo.
  final Widget? tarjetaAvisos;

  /// «Actualizado hace 5 min», si hay varias personas (entrega 18).
  final String? actualizado;

  /// Lo que el rol deja ver y hacer (entrega 20).
  final Permisos permisos;

  @override
  ConsumerState<PantallaInicioCompleta> createState() =>
      _EstadoInicioCompleta();
}

class _EstadoInicioCompleta extends ConsumerState<PantallaInicioCompleta> {
  bool _ocultar = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.resumen;
    final permisos = widget.permisos;
    // El encargado y el ayudante ven solo sus cajas (entrega 21).
    final misCajas = permisos.misCajas;
    // Las que se dejaron de usar no salen (entrega 58).
    final enDesuso = ref.watch(cuentasEnDesusoProvider);
    final saldos = {
      for (final e in r.saldosPorCuenta.entries)
        if ((misCajas == null || misCajas.contains(e.key)) &&
            !enDesuso.contains(e.key))
          e.key: e.value,
    };
    final total = misCajas == null
        ? r.tienesHoyCentimos
        : saldos.values.fold(0, (s, v) => s + v);
    final hoy = _ocultar
        ? Textos.montoOculto
        : formatearSoles(r.ventaDeHoyCentimos);

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
              nombre: r.nombreNegocio,
              detalle: widget.actualizado,
            ),
            ?widget.tarjetaAvisos,
            _conMargen(
              TarjetaTienesHoy(
                etiqueta: switch (misCajas?.length) {
                  null => Textos.tienesHoy,
                  1 => Textos.enTuCaja,
                  _ => Textos.enTusCajas,
                },
                centimos: total,
                ocultar: _ocultar,
                // El ojo vive en la tarjeta desde la entrega 61.
                alOcultar: () => setState(() => _ocultar = !_ocultar),
                explicacion: Textos.notaConMovimientos,
                // El ayudante ve siempre lo que anotó hoy (entrega 20).
                pildora: _pildora(r, permisos, hoy),
              ),
            ),
            // «Pregúntale a Moca» (entrega 74): solo el dueño con cuenta.
            if (permisos.rol == Rol.dueno &&
                ref.watch(situacionCuentaProvider).value?.estado ==
                    EstadoCuenta.guardada) ...[
              const SizedBox(height: Medidas.separacionTarjetas),
              _conMargen(const BarraPreguntale()),
            ],
            // Las cuentas, siempre a la vista (entrega 65): sin la fila
            // «Ver por cuenta / Ocultar».
            if (misCajas == null || saldos.length > 1) ...[
              const SizedBox(height: Medidas.separacionTarjetas),
              DesgloseDeCuentas(
                saldos: saldos,
                ocultar: _ocultar,
                conVerTodas: permisos.cambiaCuentas,
              ),
            ],
            // La tarjeta de Moca salió del Inicio (entrega 64): el aviso va
            // en Informes y en el Asistente; la venta de hoy y el arqueo, en
            // el +. «Te deben» y «Debes» viven en Informes (entrega 63).
          ],
        ),
      ),
    );
  }

  /// Lo de hoy, en la píldora de «Tienes hoy»: lo que anotó el ayudante o
  /// lo vendido, con lo que se fió (entrega 51): «Vendiste hoy S/ 480 ·
  /// S/ 130 al fiado».
  String? _pildora(ResumenInicio r, Permisos permisos, String hoy) {
    final base = permisos.rol == Rol.ayudante
        ? '${Textos.hoyAnotaste}: $hoy'
        : r.ventaDeHoyCentimos > 0
        ? Textos.vendisteHoy(hoy)
        : null;
    if (base == null || r.fiadoDeHoyCentimos <= 0) return base;
    final fiado = _ocultar
        ? Textos.montoOculto
        : formatearSoles(r.fiadoDeHoyCentimos);
    return '$base · ${Textos.alFiado(fiado)}';
  }

  Widget _conMargen(Widget hijo) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Medidas.margenLateral),
    child: hijo,
  );
}
