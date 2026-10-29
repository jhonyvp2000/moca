import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/equipo.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Mi equipo» (entrega 19): quiénes están en el negocio, con su rol, y las
/// invitaciones que esperan. Un dueño invita, anula y quita; los demás solo
/// miran. Necesita señal: el equipo vive en el servidor.
class PantallaEquipo extends ConsumerStatefulWidget {
  const PantallaEquipo({super.key});

  @override
  ConsumerState<PantallaEquipo> createState() => _EstadoEquipo();
}

class _EstadoEquipo extends ConsumerState<PantallaEquipo> {
  Equipo? _equipo;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final equipo = await ref.read(servicioEquipoProvider).equipo();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _equipo = equipo;
      _error = equipo == null ? Textos.necesitasSenalParaEquipo : null;
    });
  }

  Future<void> _quitar(PersonaDelEquipo persona) async {
    final quien = _nombreDe(persona);
    final si = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(Textos.quitarPregunta(quien)),
        content: const Text(Textos.quitarDetalle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text(Textos.quitar),
          ),
        ],
      ),
    );
    if (si != true) return;
    _mostrar(
      await ref.read(servicioEquipoProvider).quitar(persona.membresiaId),
    );
  }

  Future<void> _anular(InvitacionPendiente invitacion) async =>
      _mostrar(await ref.read(servicioEquipoProvider).anular(invitacion.id));

  void _mostrar(ResultadoEquipo resultado) {
    if (!mounted) return;
    if (resultado == ResultadoEquipo.listo) {
      _cargar();
      return;
    }
    setState(
      () => _error = switch (resultado) {
        ResultadoEquipo.sinSenal => Textos.necesitasSenalParaEquipo,
        ResultadoEquipo.sinPermiso => Textos.soloLosDuenos,
        _ => Textos.noPudimosComprobar,
      },
    );
  }

  Future<void> _invitar() async {
    final invito = await context.push<bool>(Rutas.invitar);
    if (invito == true) _cargar();
  }

  static String _nombreDe(PersonaDelEquipo p) =>
      p.nombre ??
      (p.celular == null ? Textos.sinNombre : formatearCelular(p.celular!));

  @override
  Widget build(BuildContext context) {
    final equipo = _equipo;
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.miEquipo,
        alVolver: () => context.pop(),
      ),
      contenido: [
        if (_cargando && equipo == null)
          const Center(child: CircularProgressIndicator())
        else if (equipo != null) ...[
          const Text(Textos.tuEquipo, style: Tipografia.tituloTarjeta),
          const SizedBox(height: 8),
          Tarjeta(
            relleno: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, p) in equipo.personas.indexed)
                  _Fila(
                    titulo: p.soyYo ? Textos.tu : _nombreDe(p),
                    detalle: [
                      Textos.nombreRol(p.rol),
                      if (p.titular) Textos.titular,
                      if (p.nombre != null && p.celular != null)
                        formatearCelular(p.celular!),
                    ].join(' · '),
                    accion: equipo.soyDueno && !p.titular && !p.soyYo
                        ? (Textos.quitar, () => _quitar(p))
                        : null,
                    conSeparador: i < equipo.personas.length - 1,
                  ),
              ],
            ),
          ),
          if (equipo.invitaciones.isNotEmpty) ...[
            const SizedBox(height: Medidas.separacionTarjetas),
            const Text(
              Textos.invitacionesPendientes,
              style: Tipografia.tituloTarjeta,
            ),
            const SizedBox(height: 8),
            Tarjeta(
              relleno: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, inv) in equipo.invitaciones.indexed)
                    _Fila(
                      titulo: inv.nombre ?? formatearCelular(inv.celular),
                      detalle: [
                        Textos.nombreRol(inv.rol),
                        if (inv.nombre != null) formatearCelular(inv.celular),
                        Textos.venceEl(formatearDiaYMes(inv.venceEn)),
                      ].join(' · '),
                      accion: (Textos.anularInvitacion, () => _anular(inv)),
                      conSeparador: i < equipo.invitaciones.length - 1,
                    ),
                ],
              ),
            ),
          ],
          if (equipo.soyDueno) ...[
            const SizedBox(height: 12),
            Text(
              Textos.lugaresLibres(equipo.lugaresLibres, equipo.maximo),
              style: Tipografia.secundario,
            ),
          ],
        ],
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Aviso(texto: error),
        ],
      ],
      acciones: [
        if (equipo?.soyDueno ?? false)
          FilledButton(
            onPressed: _invitar,
            child: const Text(Textos.invitarAAlguien),
          )
        else if (equipo == null && !_cargando)
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
  final (String, VoidCallback)? accion;

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
