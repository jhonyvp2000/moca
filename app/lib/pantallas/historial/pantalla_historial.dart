import '../../comun/actualizar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/opciones.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/equipo.dart';
import '../../dominio/historial.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import 'fila_movimiento.dart';

/// S10 · Historial, con buscar y filtrar (entrega 39). Sin el fiado.
class PantallaHistorial extends ConsumerStatefulWidget {
  const PantallaHistorial({super.key});

  @override
  ConsumerState<PantallaHistorial> createState() => _EstadoHistorial();
}

class _EstadoHistorial extends ConsumerState<PantallaHistorial> {
  FiltroHistorial _filtro = FiltroHistorial.todo;

  /// La búsqueda y la hoja «Filtrar» (entrega 39). Se borran al salir.
  final _buscar = TextEditingController();
  FiltrosDelHistorial _filtros = const FiltrosDelHistorial();

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  void _quitarFiltros() => setState(() {
    _buscar.clear();
    _filtros = const FiltrosDelHistorial();
  });

  /// La hoja «Filtrar»: cuenta, categoría y persona, con lo que hay.
  Future<void> _abrirFiltros(List<FilaHistorial> todas) async {
    final cuentas = {for (final f in todas) f.cuenta}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final categorias = {for (final f in todas) ?f.categoria}.toList()..sort();
    final personas = <String, String>{
      for (final f in todas)
        FiltrosDelHistorial.personaDe(f): f.deOtro
            ? (f.autorNombre ?? Textos.otraPersona)
            : Textos.tu,
    };
    var elegidas = _filtros;
    final aplicar = await showModalBottomSheet<FiltrosDelHistorial>(
      context: context,
      isScrollControlled: true,
      builder: (hoja) => StatefulBuilder(
        builder: (hoja, cambiar) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Medidas.margenLateral),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(Textos.filtrar, style: Tipografia.tituloPantalla),
                const SizedBox(height: 16),
                const Text(Textos.filtroCuenta, style: Tipografia.textoFuerte),
                const SizedBox(height: 8),
                OpcionesVarias<TipoCuenta>(
                  opciones: {
                    for (final c in cuentas) c: Textos.nombreCuenta(c),
                  },
                  elegidas: elegidas.cuentas,
                  alTocar: (c) => cambiar(
                    () => elegidas = FiltrosDelHistorial(
                      texto: elegidas.texto,
                      cuentas: _alternar(elegidas.cuentas, c),
                      categorias: elegidas.categorias,
                      personas: elegidas.personas,
                    ),
                  ),
                ),
                if (categorias.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    Textos.filtroCategoria,
                    style: Tipografia.textoFuerte,
                  ),
                  const SizedBox(height: 8),
                  OpcionesVarias<String>(
                    opciones: {for (final c in categorias) c: c},
                    elegidas: elegidas.categorias,
                    alTocar: (c) => cambiar(
                      () => elegidas = FiltrosDelHistorial(
                        texto: elegidas.texto,
                        cuentas: elegidas.cuentas,
                        categorias: _alternar(elegidas.categorias, c),
                        personas: elegidas.personas,
                      ),
                    ),
                  ),
                ],
                // Solo si en el negocio anota más de una persona.
                if (personas.length > 1) ...[
                  const SizedBox(height: 16),
                  const Text(Textos.quienAnoto, style: Tipografia.textoFuerte),
                  const SizedBox(height: 8),
                  OpcionesVarias<String>(
                    opciones: personas,
                    elegidas: elegidas.personas,
                    alTocar: (p) => cambiar(
                      () => elegidas = FiltrosDelHistorial(
                        texto: elegidas.texto,
                        cuentas: elegidas.cuentas,
                        categorias: elegidas.categorias,
                        personas: _alternar(elegidas.personas, p),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(hoja).pop(elegidas),
                  child: const Text(Textos.verResultados),
                ),
                TextButton(
                  onPressed: () => Navigator.of(hoja).pop(elegidas.sinHoja()),
                  child: const Text(Textos.quitarFiltros),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (aplicar != null) setState(() => _filtros = aplicar);
  }

  static Set<T> _alternar<T>(Set<T> conjunto, T valor) =>
      conjunto.contains(valor)
      ? ({...conjunto}..remove(valor))
      : {...conjunto, valor};

  static String _vacio(FiltroHistorial filtro) => switch (filtro) {
    FiltroHistorial.todo => Textos.historialVacio,
    FiltroHistorial.entro => Textos.sinEntradas,
    FiltroHistorial.salio => Textos.sinSalidas,
    FiltroHistorial.porSubir => Textos.nadaPorSubir,
  };

  @override
  Widget build(BuildContext context) {
    final resumen = ref.watch(historialProvider).value;
    final hoy = ref.watch(relojProvider)();
    // El ayudante ve solo lo de hoy: lo que anotó y lo que otros anotaron
    // en su caja, que es lo único que baja a su teléfono (entrega 20.2).
    final soloHoy =
        (ref.watch(permisosProvider).value ?? Permisos.delDueno).soloLoDeHoy;
    bool deHoy(FilaHistorial f) =>
        f.fecha.year == hoy.year &&
        f.fecha.month == hoy.month &&
        f.fecha.day == hoy.day;
    // Lo que este teléfono puede ver; sobre eso se busca y filtra.
    final visibles =
        resumen?.filas.where((f) => !soloHoy || deHoy(f)).toList() ??
        const <FilaHistorial>[];
    final filas = visibles
        .where(
          (f) =>
              f.cumple(_filtro) &&
              _filtros.cumple(f, cuenta: Textos.nombreCuenta),
        )
        .toList();
    final buscando = !_filtros.vacios;
    int suma(bool Function(FilaHistorial) cual) => filas
        .where((f) => !f.ajusteArqueo && cual(f))
        .fold(0, (s, f) => s + f.montoCentimos);

    // Agrupadas por el día en que se anotaron.
    final dias = <DateTime, List<FilaHistorial>>{};
    for (final f in filas) {
      dias
          .putIfAbsent(
            DateTime(f.fecha.year, f.fecha.month, f.fecha.day),
            () => [],
          )
          .add(f);
    }

    // Deslizar hacia abajo trae lo nuevo de los demás (entrega 18.1).
    return ConActualizar(
      child: SafeArea(
        bottom: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                16,
                Medidas.margenLateral,
                8,
              ),
              child: Semantics(
                header: true,
                child: const Text(
                  Textos.tituloHistorial,
                  style: Tipografia.tituloPantalla,
                ),
              ),
            ),
            // Buscar (entrega 39): cada palabra tiene que estar.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                0,
                Medidas.margenLateral,
                8,
              ),
              child: TextField(
                controller: _buscar,
                textInputAction: TextInputAction.search,
                onChanged: (t) =>
                    setState(() => _filtros = _filtros.conTexto(t)),
                decoration: const InputDecoration(
                  hintText: Textos.buscarEnTuHistorial,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: Medidas.margenLateral,
              ),
              child: Row(
                children: [
                  _Filtro(
                    texto: _filtros.puestos == 0
                        ? Textos.filtrar
                        : Textos.filtrarCon(_filtros.puestos),
                    elegido: _filtros.puestos > 0,
                    alTocar: () => _abrirFiltros(visibles),
                  ),
                  const SizedBox(width: 8),
                  for (final (i, filtro) in FiltroHistorial.values.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _Filtro(
                      texto: switch (filtro) {
                        FiltroHistorial.todo => Textos.filtroTodo,
                        FiltroHistorial.entro => Textos.entro,
                        FiltroHistorial.salio => Textos.salio,
                        FiltroHistorial.porSubir => Textos.filtroPorSubir(
                          resumen?.porSubir ?? 0,
                        ),
                      },
                      elegido: filtro == _filtro,
                      alTocar: () => setState(() => _filtro = filtro),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Lo encontrado, con su suma, y cómo volver a ver todo.
            if (buscando && filas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.margenLateral,
                  0,
                  Medidas.margenLateral,
                  4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        Textos.resumenDeBusqueda(
                          filas.length,
                          formatearSoles(suma((f) => f.tipo.entraPlata)),
                          formatearSoles(
                            suma((f) => !f.tipo.entraPlata && !f.tipo.esPase),
                          ),
                        ),
                        style: Tipografia.secundario,
                      ),
                    ),
                    TextButton(
                      onPressed: _quitarFiltros,
                      child: const Text(Textos.quitarFiltros),
                    ),
                  ],
                ),
              ),
            if (soloHoy)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  Medidas.margenLateral,
                  0,
                  Medidas.margenLateral,
                  12,
                ),
                child: Text(
                  Textos.soloLoDeHoyAyudante,
                  style: Tipografia.secundario,
                ),
              ),
            if (resumen != null && filas.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.margenLateral,
                  8,
                  Medidas.margenLateral,
                  0,
                ),
                child: Tarjeta(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        buscando ? Textos.sinResultados : _vacio(_filtro),
                        style: Tipografia.texto,
                      ),
                      if (buscando)
                        TextButton(
                          onPressed: _quitarFiltros,
                          child: const Text(Textos.quitarFiltros),
                        )
                      else if (_filtro == FiltroHistorial.todo) ...[
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.push(Rutas.registrar),
                          child: const Text(Textos.registrar),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            for (final MapEntry(key: dia, value: delDia) in dias.entries)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Medidas.margenLateral,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
                      child: Semantics(
                        header: true,
                        child: Text(
                          formatearDiaHistorial(dia, hoy),
                          style: Tipografia.secundario.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Tarjeta(
                      relleno: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Medidas.radioTarjeta,
                        ),
                        child: Material(
                          color: Colores.superficie,
                          child: Column(
                            children: [
                              for (final (i, f) in delDia.indexed)
                                FilaMovimiento(
                                  fila: f,
                                  conSeparador: i < delDia.length - 1,
                                  alTocar: () => context.push(
                                    Rutas.detalleMovimiento(f.id),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Filtro del mockup: azul oscuro cuando está elegido.
class _Filtro extends StatelessWidget {
  const _Filtro({
    required this.texto,
    required this.elegido,
    required this.alTocar,
  });

  final String texto;
  final bool elegido;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: elegido
          ? BorderSide.none
          : const BorderSide(color: Colores.bordeBotonSecundario),
    );
    return Semantics(
      selected: elegido,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: elegido ? Colores.textoPrincipal : Colores.superficie,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: Medidas.objetivoTactilMinimo,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: Text(
                  texto,
                  style: TextStyle(
                    fontFamily: Tipografia.familia,
                    fontSize: 14,
                    fontWeight: elegido ? FontWeight.w700 : FontWeight.w600,
                    color: elegido
                        ? Colores.sobreMarca
                        : Colores.textoPrincipal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
