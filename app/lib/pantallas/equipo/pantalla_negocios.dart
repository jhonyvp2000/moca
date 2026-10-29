import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/equipo.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Mis negocios» (entrega 22): el contador de varios negocios elige cuál
/// mirar, y quien recibió una invitación a otro negocio la acepta aquí.
/// Cambiar de negocio lo baja y reemplaza lo que se ve en el teléfono.
class PantallaNegocios extends ConsumerStatefulWidget {
  const PantallaNegocios({super.key});

  @override
  ConsumerState<PantallaNegocios> createState() => _EstadoNegocios();
}

class _EstadoNegocios extends ConsumerState<PantallaNegocios> {
  List<NegocioDelUsuario>? _negocios;
  List<InvitacionRecibida> _invitaciones = const [];
  bool _cargando = true;
  String? _ocupado;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final servicio = ref.read(servicioEquipoProvider);
    final negocios = await servicio.misNegocios();
    final invitaciones = await servicio.buscarInvitaciones();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _negocios = negocios;
      _invitaciones = invitaciones ?? const [];
      _error = negocios == null ? Textos.necesitasSenalParaNegocios : null;
    });
  }

  Future<void> _resultado(ResultadoEquipo resultado, String negocio) async {
    if (!mounted) return;
    if (resultado == ResultadoEquipo.listo) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(Textos.ahoraVes(negocio))));
      context.go(Rutas.inicio);
      return;
    }
    setState(() {
      _ocupado = null;
      _error = switch (resultado) {
        ResultadoEquipo.sinSenal => Textos.necesitasSenalParaNegocios,
        ResultadoEquipo.vencida => Textos.invitacionVencida,
        ResultadoEquipo.yaTieneNegocio => Textos.yaTienesNegocio,
        ResultadoEquipo.sinLugar => Textos.sinLugar,
        _ => Textos.noPudimosComprobar,
      };
    });
  }

  Future<void> _cambiar(NegocioDelUsuario negocio) async {
    setState(() {
      _ocupado = negocio.empresaId;
      _error = null;
    });
    await _resultado(
      await ref
          .read(servicioEquipoProvider)
          .cambiarDeNegocio(negocio.empresaId),
      negocio.nombre,
    );
  }

  Future<void> _aceptar(InvitacionRecibida invitacion) async {
    setState(() {
      _ocupado = invitacion.id;
      _error = null;
    });
    await _resultado(
      await ref.read(servicioEquipoProvider).aceptar(invitacion.id),
      invitacion.negocio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final negocios = _negocios;
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.misNegocios,
        alVolver: () => context.pop(),
      ),
      contenido: [
        if (_cargando && negocios == null)
          const Center(child: CircularProgressIndicator())
        else if (negocios != null)
          Tarjeta(
            relleno: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, n) in negocios.indexed)
                  _Fila(
                    titulo: n.nombre,
                    detalle: n.actual
                        ? '${Textos.nombreRol(n.rol)} · ${Textos.estasAqui}'
                        : Textos.nombreRol(n.rol),
                    accion: n.actual
                        ? null
                        : (
                            _ocupado == n.empresaId
                                ? Textos.cambiandoA(n.nombre)
                                : Textos.verEsteNegocio,
                            _ocupado == null ? () => _cambiar(n) : null,
                          ),
                    conSeparador: i < negocios.length - 1,
                  ),
              ],
            ),
          ),
        if (_invitaciones.isNotEmpty) ...[
          const SizedBox(height: Medidas.separacionTarjetas),
          const Text(Textos.teInvitaronA, style: Tipografia.tituloTarjeta),
          const SizedBox(height: 8),
          Tarjeta(
            relleno: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, inv) in _invitaciones.indexed)
                  _Fila(
                    titulo: inv.negocio,
                    detalle: Textos.comoRol(Textos.nombreRol(inv.rol)),
                    accion: (
                      Textos.aceptar,
                      _ocupado == null ? () => _aceptar(inv) : null,
                    ),
                    conSeparador: i < _invitaciones.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
        if (negocios == null && !_cargando)
          OutlinedButton(
            onPressed: _cargar,
            child: const Text(Textos.intentarOtraVez),
          ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.titulo,
    required this.detalle,
    required this.conSeparador,
    this.accion,
  });

  final String titulo;
  final String detalle;
  final bool conSeparador;
  final (String, VoidCallback?)? accion;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: Medidas.objetivoTactilMinimo + 12,
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        border: conSeparador
            ? const Border(bottom: BorderSide(color: Colores.bordeTarjeta))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Tipografia.textoFuerte),
                Text(detalle, style: Tipografia.secundario),
              ],
            ),
          ),
          if (accion case (final texto, final alTocar))
            TextButton(onPressed: alTocar, child: Text(texto)),
        ],
      ),
    );
  }
}
