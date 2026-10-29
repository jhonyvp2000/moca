import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/modelos.dart';
import '../../dominio/cuentas.dart';
import '../../comun/opciones.dart';
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

  /// Qué cajas tiene a cargo un encargado o ayudante (entrega 21).
  Future<void> _elegirCajas(PersonaDelEquipo persona) async {
    final cajas = [
      for (final c in ref.read(cuentasProvider).value ?? const <CuentaVista>[])
        if (c.tipo.esCaja) c,
    ];
    final elegidas = {...persona.cajas};
    final listo = await showModalBottomSheet<bool>(
      context: context,
      builder: (contexto) => StatefulBuilder(
        builder: (contexto, cambiar) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Medidas.margenLateral),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  Textos.elegirCajas,
                  style: Tipografia.tituloPantalla,
                ),
                const SizedBox(height: 4),
                const Text(
                  Textos.elegirCajasDetalle,
                  style: Tipografia.secundario,
                ),
                const SizedBox(height: 12),
                OpcionesVarias<String>(
                  opciones: {for (final c in cajas) c.id: c.nombre},
                  elegidas: elegidas,
                  alTocar: (id) => cambiar(
                    () => elegidas.contains(id)
                        ? elegidas.remove(id)
                        : elegidas.add(id),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(contexto, true),
                  child: const Text(Textos.guardar),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (listo != true) return;
    final resultado = await ref
        .read(servicioEquipoProvider)
        .asignarCajas(persona.membresiaId, elegidas.toList());
    if (resultado == ResultadoEquipo.listo && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(Textos.cajasGuardadas)));
    }
    _mostrar(resultado);
  }

  /// «Caja delivery», o la principal si no tiene ninguna.
  String _cajasDe(PersonaDelEquipo p) {
    final nombres = {
      for (final c in ref.read(cuentasProvider).value ?? const <CuentaVista>[])
        c.id: c.nombre,
    };
    final suyas = [for (final id in p.cajas) ?nombres[id]];
    return suyas.isEmpty ? Textos.cajaPrincipal : suyas.join(', ');
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
                    // Las cajas del encargado y del ayudante (entrega 21).
                    cajas: p.rol == Rol.encargado || p.rol == Rol.ayudante
                        ? (
                            '${Textos.cajasDe}: ${_cajasDe(p)}',
                            equipo.soyDueno ? () => _elegirCajas(p) : null,
                          )
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
    this.cajas,
  });

  final String titulo;
  final String detalle;
  final bool conSeparador;
  final (String, VoidCallback)? accion;

  /// «Cajas: Caja delivery», que el dueño toca para cambiarlas.
  final (String, VoidCallback?)? cajas;

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
                if (cajas case (final texto, final alTocar))
                  InkWell(
                    onTap: alTocar,
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: Medidas.objetivoTactilMinimo,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        texto,
                        style: Tipografia.secundario.copyWith(
                          color: alTocar == null
                              ? Colores.textoSecundario
                              : Colores.marca,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
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
