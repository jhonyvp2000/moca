import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/opciones.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/equipo.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Me invitaron» (entrega 19): a qué negocio y con qué rol, el
/// consentimiento de la Ley 29733 y «Aceptar y entrar». Al aceptar baja lo
/// del negocio que su rol puede ver y la app pasa sola al Inicio.
class PantallaInvitacion extends ConsumerStatefulWidget {
  const PantallaInvitacion({super.key});

  @override
  ConsumerState<PantallaInvitacion> createState() => _EstadoInvitacion();
}

class _EstadoInvitacion extends ConsumerState<PantallaInvitacion> {
  bool _entrando = false;
  String? _error;
  String? _elegida;

  Future<void> _aceptar(InvitacionRecibida invitacion) async {
    setState(() {
      _entrando = true;
      _error = null;
    });
    final mensajes = ScaffoldMessenger.of(context);
    final resultado = await ref
        .read(servicioEquipoProvider)
        .aceptar(invitacion.id);
    if (resultado == ResultadoEquipo.listo) {
      mensajes.showSnackBar(
        SnackBar(content: Text(Textos.yaEstasEn(invitacion.negocio))),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _entrando = false;
      _error = switch (resultado) {
        ResultadoEquipo.sinSenal => Textos.necesitasSenalParaEntrar,
        ResultadoEquipo.vencida => Textos.invitacionVencida,
        ResultadoEquipo.yaTieneNegocio => Textos.yaTienesNegocio,
        ResultadoEquipo.sinLugar => Textos.sinLugar,
        _ => Textos.noPudimosComprobar,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final invitaciones = ref
        .watch(servicioEquipoProvider)
        .invitacionesRecibidas;
    final elegida =
        invitaciones.where((i) => i.id == _elegida).firstOrNull ??
        invitaciones.firstOrNull;

    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.entraAlNegocio,
        alVolver: () => context.pop(),
      ),
      contenido: [
        if (elegida == null)
          const Aviso(texto: Textos.invitacionVencida)
        else ...[
          // Casi siempre es una; si hay varias, se elige.
          if (invitaciones.length > 1) ...[
            Opciones<String>(
              opciones: {for (final i in invitaciones) i.id: i.negocio},
              elegida: elegida.id,
              alElegir: (id) => setState(() => _elegida = id),
            ),
            const SizedBox(height: 16),
          ],
          Semantics(
            header: true,
            child: Text(
              Textos.teInvitaron(elegida.negocio),
              style: Tipografia.tituloPantalla.copyWith(fontSize: 26),
            ),
          ),
          const SizedBox(height: 12),
          Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  Textos.comoRol(Textos.nombreRol(elegida.rol)),
                  style: Tipografia.tituloTarjeta,
                ),
                const SizedBox(height: 4),
                Text(
                  Textos.detalleRol(elegida.rol),
                  style: Tipografia.secundario,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            Textos.consentimientoInvitado,
            style: Tipografia.secundario,
          ),
        ],
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Aviso(texto: error),
        ],
      ],
      acciones: [
        if (elegida != null)
          FilledButton(
            onPressed: _entrando ? null : () => _aceptar(elegida),
            child: Text(_entrando ? Textos.entrando : Textos.aceptarYEntrar),
          ),
        BotonTexto(
          texto: Textos.volver,
          alTocar: () => context.go(Rutas.bienvenida),
        ),
      ],
    );
  }
}
