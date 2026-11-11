import 'package:flutter/material.dart';

import '../../comun/opciones.dart';
import '../../dominio/historial.dart';
import '../../dominio/modelos.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// La hoja «Filtrar» del Historial (entregas 39 y 56): periodo, cuenta,
/// categoría y persona. Lo de arriba se desplaza; «Ver N registros» y
/// «Quitar filtros» quedan fijos abajo, siempre a la vista.
class HojaFiltros extends StatefulWidget {
  const HojaFiltros({
    super.key,
    required this.todas,
    required this.inicial,
    required this.contar,
    required this.hoy,
    this.conPeriodo = true,
  });

  /// Lo que hay en el Historial, para saber qué opciones mostrar.
  final List<FilaHistorial> todas;
  final FiltrosDelHistorial inicial;

  /// Cuántos registros quedarían con estos filtros.
  final int Function(FiltrosDelHistorial) contar;
  final DateTime hoy;

  /// El ayudante ve solo lo de hoy: sin «Periodo».
  final bool conPeriodo;

  /// Las categorías que se ven sin desplegar.
  static const categoriasALaVista = 8;

  @override
  State<HojaFiltros> createState() => _EstadoHojaFiltros();
}

class _EstadoHojaFiltros extends State<HojaFiltros> {
  late var _elegidas = widget.inicial;
  var _todasLasCategorias = false;

  DateTime get _hoy =>
      DateTime(widget.hoy.year, widget.hoy.month, widget.hoy.day);

  /// El primer día con registros: antes no hay nada que ver.
  DateTime get _primerDia {
    final fechas = widget.todas.map((f) => f.fecha);
    if (fechas.isEmpty) return _hoy;
    final primera = fechas.reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(primera.year, primera.month, primera.day);
  }

  void _cambiar(FiltrosDelHistorial nuevas) =>
      setState(() => _elegidas = nuevas);

  static Set<T> _alternar<T>(Set<T> conjunto, T valor) =>
      conjunto.contains(valor)
      ? ({...conjunto}..remove(valor))
      : {...conjunto, valor};

  Future<void> _elegirTipo(TipoPeriodo? tipo) async {
    switch (tipo) {
      case null:
        _cambiar(_elegidas.con(sinPeriodo: true));
      case TipoPeriodo.dia:
        _cambiar(_elegidas.con(periodo: PeriodoHistorial.dia(_hoy)));
      case TipoPeriodo.mes:
        _cambiar(_elegidas.con(periodo: PeriodoHistorial.mes(_hoy)));
      case TipoPeriodo.anio:
        _cambiar(_elegidas.con(periodo: PeriodoHistorial.anio(_hoy.year)));
      case TipoPeriodo.rango:
        await _elegirRango();
    }
  }

  Future<void> _elegirDia() async {
    final actual = _elegidas.periodo!.desde;
    final dia = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: _primerDia,
      lastDate: _hoy,
    );
    if (dia != null) {
      _cambiar(_elegidas.con(periodo: PeriodoHistorial.dia(dia)));
    }
  }

  Future<void> _elegirRango() async {
    final actual = _elegidas.periodo;
    final inicio = actual?.tipo == TipoPeriodo.rango
        ? DateTimeRange(start: actual!.desde, end: actual.ultimoDia)
        : null;
    final rango = await showDateRangePicker(
      context: context,
      initialDateRange: inicio,
      firstDate: _primerDia,
      lastDate: _hoy,
      helpText: Textos.elegirFechas,
    );
    if (rango != null) {
      _cambiar(
        _elegidas.con(periodo: PeriodoHistorial.rango(rango.start, rango.end)),
      );
    }
  }

  String _nombreDelPeriodo(PeriodoHistorial p) => switch (p.tipo) {
    TipoPeriodo.dia => formatearFechaLarga(
      p.desde,
    ).replaceRange(0, 1, formatearFechaLarga(p.desde)[0].toUpperCase()),
    TipoPeriodo.mes => '${nombreDelMesConMayuscula(p.desde)} ${p.desde.year}',
    TipoPeriodo.anio => '${p.desde.year}',
    TipoPeriodo.rango => Textos.delAl(p.desde, p.ultimoDia),
  };

  /// «‹ Noviembre 2026 ›»: las flechas, y tocar el nombre abre el
  /// calendario (el día y el rango).
  Widget _selectorDePeriodo(PeriodoHistorial p) {
    final (anterior, siguiente) = switch (p.tipo) {
      TipoPeriodo.dia => (Textos.diaAnterior, Textos.diaSiguiente),
      TipoPeriodo.mes => (Textos.mesAnterior, Textos.mesSiguiente),
      _ => (Textos.anioAnterior, Textos.anioSiguiente),
    };
    final nombre = Text(
      _nombreDelPeriodo(p),
      textAlign: TextAlign.center,
      style: Tipografia.textoFuerte.copyWith(color: Colores.marca),
    );
    if (p.tipo == TipoPeriodo.rango) {
      return OutlinedButton.icon(
        onPressed: _elegirRango,
        icon: const Icon(Icons.date_range_rounded),
        label: nombre,
      );
    }
    final antes = p.mover(-1);
    final despues = p.mover(1);
    return Row(
      children: [
        IconButton(
          tooltip: anterior,
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: antes.hasta.isAfter(_primerDia)
              ? () => _cambiar(_elegidas.con(periodo: antes))
              : null,
        ),
        Expanded(
          child: p.tipo == TipoPeriodo.dia
              ? TextButton(onPressed: _elegirDia, child: nombre)
              : nombre,
        ),
        IconButton(
          tooltip: siguiente,
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: !despues.desde.isAfter(_hoy)
              ? () => _cambiar(_elegidas.con(periodo: despues))
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final todas = widget.todas;
    final cuentas = {for (final f in todas) f.cuenta}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    // Las categorías, de la más usada a la menos.
    final usos = <String, int>{};
    for (final f in todas) {
      if (f.categoria case final c?) usos[c] = (usos[c] ?? 0) + 1;
    }
    final categorias = usos.keys.toList()
      ..sort((a, b) {
        final porUso = usos[b]!.compareTo(usos[a]!);
        return porUso != 0 ? porUso : a.compareTo(b);
      });
    final ocultas = categorias.length - HojaFiltros.categoriasALaVista;
    // Las elegidas se ven siempre, aunque no estén entre las más usadas.
    final aLaVista = _todasLasCategorias || ocultas <= 0
        ? categorias
        : [
            for (final (i, c) in categorias.indexed)
              if (i < HojaFiltros.categoriasALaVista ||
                  _elegidas.categorias.contains(c))
                c,
          ];
    final personas = <String, String>{
      for (final f in todas)
        FiltrosDelHistorial.personaDe(f): f.deOtro
            ? (f.autorNombre ?? Textos.otraPersona)
            : Textos.tu,
    };
    final cuantos = widget.contar(_elegidas);
    final periodo = _elegidas.periodo;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // El título y la ✕ para cerrar sin cambiar nada.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                Medidas.e2,
                Medidas.e2,
                0,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      Textos.filtrar,
                      style: Tipografia.tituloPantalla,
                    ),
                  ),
                  IconButton(
                    tooltip: Textos.cerrar,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.margenLateral,
                  Medidas.e2,
                  Medidas.margenLateral,
                  Medidas.e4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.conPeriodo) ...[
                      const Text(Textos.periodo, style: Tipografia.textoFuerte),
                      const SizedBox(height: Medidas.e2),
                      Opciones<TipoPeriodo?>(
                        opciones: const {
                          null: Textos.periodoTodo,
                          TipoPeriodo.dia: Textos.unDia,
                          TipoPeriodo.mes: Textos.unMes,
                          TipoPeriodo.anio: Textos.unAnio,
                          TipoPeriodo.rango: Textos.entreFechas,
                        },
                        elegida: periodo?.tipo,
                        alElegir: _elegirTipo,
                      ),
                      if (periodo != null) ...[
                        const SizedBox(height: Medidas.e2),
                        _selectorDePeriodo(periodo),
                      ],
                      const SizedBox(height: Medidas.e4),
                    ],
                    const Text(
                      Textos.filtroCuenta,
                      style: Tipografia.textoFuerte,
                    ),
                    const SizedBox(height: Medidas.e2),
                    OpcionesVarias<TipoCuenta>(
                      opciones: {
                        for (final c in cuentas) c: Textos.nombreCuenta(c),
                      },
                      elegidas: _elegidas.cuentas,
                      alTocar: (c) => _cambiar(
                        _elegidas.con(cuentas: _alternar(_elegidas.cuentas, c)),
                      ),
                    ),
                    if (categorias.isNotEmpty) ...[
                      const SizedBox(height: Medidas.e4),
                      const Text(
                        Textos.filtroCategoria,
                        style: Tipografia.textoFuerte,
                      ),
                      const SizedBox(height: Medidas.e2),
                      OpcionesVarias<String>(
                        opciones: {for (final c in aLaVista) c: c},
                        elegidas: _elegidas.categorias,
                        alTocar: (c) => _cambiar(
                          _elegidas.con(
                            categorias: _alternar(_elegidas.categorias, c),
                          ),
                        ),
                      ),
                      // Con muchas categorías, «+ N más» despliega el resto.
                      if (ocultas > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => setState(
                              () => _todasLasCategorias = !_todasLasCategorias,
                            ),
                            child: Text(
                              _todasLasCategorias
                                  ? Textos.verMenos
                                  : Textos.nMas(
                                      categorias.length - aLaVista.length,
                                    ),
                            ),
                          ),
                        ),
                    ],
                    // Solo si en el negocio anota más de una persona.
                    if (personas.length > 1) ...[
                      const SizedBox(height: Medidas.e4),
                      const Text(
                        Textos.quienAnoto,
                        style: Tipografia.textoFuerte,
                      ),
                      const SizedBox(height: Medidas.e2),
                      OpcionesVarias<String>(
                        opciones: personas,
                        elegidas: _elegidas.personas,
                        alTocar: (p) => _cambiar(
                          _elegidas.con(
                            personas: _alternar(_elegidas.personas, p),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Fijo abajo, siempre a la vista (entrega 56).
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colores.superficie,
                border: Border(top: BorderSide(color: Colores.separador)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.margenLateral,
                  Medidas.e3,
                  Medidas.margenLateral,
                  Medidas.e2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      key: const ValueKey('verRegistros'),
                      onPressed: cuantos == 0
                          ? null
                          : () => Navigator.of(context).pop(_elegidas),
                      child: Text(
                        cuantos == 0
                            ? Textos.ningunRegistroConFiltros
                            : Textos.verRegistros(cuantos),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_elegidas.sinHoja()),
                      child: const Text(Textos.quitarFiltros),
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
}
