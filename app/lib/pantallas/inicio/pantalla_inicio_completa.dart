import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../comun/boton_redondo.dart';

import '../../comun/tarjeta.dart';
import '../../dominio/arqueo.dart';
import '../../dominio/equipo.dart';
import '../../dominio/moca.dart';
import '../../dominio/modelos.dart';
import '../../dominio/movimientos.dart';
import '../../pais/peru/formato.dart';
import '../../tema/medidas.dart';
import '../../textos/textos.dart';
import '../moca/avisos.dart';
import 'desglose_cuentas.dart';
import 'bloque_pendientes.dart';
import 'encabezado_negocio.dart';
import 'tarjeta_semana.dart';
import 'tarjeta_tienes_hoy.dart';

/// S04 · Inicio. Sin la franja de planes ni «Lo que viene» (ajustes respecto
/// al mockup), y sin la flecha para cambiar de empresa.
class PantallaInicioCompleta extends StatefulWidget {
  const PantallaInicioCompleta({
    super.key,
    required this.resumen,
    required this.alAnotarVenta,
    required this.alHacerArqueo,
    this.aviso,
    this.tarjetaAvisos,
    this.actualizado,
    this.permisos = Permisos.delDueno,
  });

  final ResumenInicio resumen;
  final VoidCallback alAnotarVenta;
  final VoidCallback alHacerArqueo;

  /// El aviso más importante, si hay alguno.
  final Aviso? aviso;

  /// El permiso de avisos, si falta pedirlo.
  final Widget? tarjetaAvisos;

  /// «Actualizado hace 5 min», si hay varias personas (entrega 18).
  final String? actualizado;

  /// Lo que el rol deja ver y hacer (entrega 20).
  final Permisos permisos;

  @override
  State<PantallaInicioCompleta> createState() => _EstadoInicioCompleta();
}

class _EstadoInicioCompleta extends State<PantallaInicioCompleta> {
  bool _ocultar = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.resumen;
    final permisos = widget.permisos;
    // El encargado y el ayudante ven solo sus cajas (entrega 21).
    final misCajas = permisos.misCajas;
    final saldos = misCajas == null
        ? r.saldosPorCuenta
        : {
            for (final e in r.saldosPorCuenta.entries)
              if (misCajas.contains(e.key)) e.key: e.value,
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
              extra: BotonRedondo(
                icono: _ocultar
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                nombre: _ocultar ? Textos.mostrarMontos : Textos.ocultarMontos,
                alTocar: () => setState(() => _ocultar = !_ocultar),
              ),
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
                explicacion: Textos.notaConMovimientos,
                // El ayudante ve siempre lo que anotó hoy (entrega 20).
                pildora: _pildora(r, permisos, hoy),
              ),
            ),
            if (misCajas == null || saldos.length > 1) ...[
              const SizedBox(height: Medidas.e5),
              DesgloseDeCuentas(
                saldos: saldos,
                ocultar: _ocultar,
                conVerTodas: permisos.cambiaCuentas,
              ),
            ],
            // «Hacer arqueo» vive en el + (entrega 57); aquí, solo cuando
            // toca, en la tarjeta de Moca.
            // Lo pendiente, para quien ve los informes (mejora 01).
            if (permisos.veInformes) BloquePendientes(ocultar: _ocultar),
            // La semana es de todo el negocio: la ven el dueño y el contador.
            if (misCajas == null) ...[
              const SizedBox(height: Medidas.separacionTarjetas),
              _conMargen(TarjetaSemana(resumen: r, ocultar: _ocultar)),
            ],
            if (permisos.anota) ...[
              const SizedBox(height: Medidas.separacionTarjetas),
              // El aviso más importante; si no hay, la venta de hoy y el arqueo.
              _conMargen(_tarjetaMoca(r)),
            ],
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

  /// La tarjeta de Moca no repite el +: la venta de hoy mientras falta (es
  /// el hábito que se mide), el arqueo cuando toca y, con todo hecho,
  /// «Escuchar mi semana» (mejora 01).
  Widget _tarjetaMoca(ResumenInicio r) {
    if (widget.aviso case final aviso?) {
      return TarjetaMoca(
        texto: textoAvisoEnInicio(aviso),
        accion: FilledButton(
          onPressed: () => abrirAviso(context, aviso),
          child: Text(accionAviso(aviso)),
        ),
      );
    }
    final ventaHecha = r.ventaDeHoyCentimos > 0;
    final venta = ventaHecha
        ? Textos.mocaYaAnotasteHoy
        : Textos.mocaFaltaVentaDeHoy;
    final anotarVenta = FilledButton.icon(
      onPressed: widget.alAnotarVenta,
      icon: const Icon(Icons.mic_rounded),
      label: const Text(Textos.anotarVentaDeHoy),
    );
    final escucharSemana = widget.permisos.veAvisos
        ? Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  StatefulNavigationShell.maybeOf(context)?.goBranch(3),
              iconAlignment: IconAlignment.end,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(Textos.escucharMiSemana),
            ),
          )
        : null;
    final arqueo = FilledButton(
      onPressed: widget.alHacerArqueo,
      child: const Text(Textos.hacerArqueo),
    );
    // Sin arqueo para su rol, solo la venta de hoy (entrega 20).
    final estado = widget.permisos.haceArqueo
        ? r.estadoArqueo
        : EstadoArqueo.nada;
    return switch (estado) {
      EstadoArqueo.falta || EstadoArqueo.toca => TarjetaMoca(
        texto: estado == EstadoArqueo.falta
            ? Textos.mocaFaltaArqueo
            : Textos.mocaTocaArqueo,
        accion: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            arqueo,
            if (!ventaHecha) ...[
              const SizedBox(height: Medidas.e2),
              OutlinedButton(
                onPressed: widget.alAnotarVenta,
                child: const Text(Textos.anotarVentaDeHoy),
              ),
            ],
          ],
        ),
      ),
      EstadoArqueo.hecho || EstadoArqueo.nada => TarjetaMoca(
        texto: estado == EstadoArqueo.hecho
            ? '$venta ${Textos.mocaArqueoHecho}'
            : venta,
        accion: ventaHecha ? escucharSemana : anotarVenta,
      ),
    };
  }

  Widget _conMargen(Widget hijo) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Medidas.margenLateral),
    child: hijo,
  );
}
