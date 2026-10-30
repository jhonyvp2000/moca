import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/tarjeta.dart';
import '../../dominio/equipo.dart';
import '../../dominio/historial.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import 'fila_movimiento.dart';

/// S10 · Historial. Sin la búsqueda ni el fiado (fuera del alcance de la V1).
class PantallaHistorial extends ConsumerStatefulWidget {
  const PantallaHistorial({super.key});

  @override
  ConsumerState<PantallaHistorial> createState() => _EstadoHistorial();
}

class _EstadoHistorial extends ConsumerState<PantallaHistorial> {
  FiltroHistorial _filtro = FiltroHistorial.todo;

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
    final filas =
        resumen?.filas
            .where((f) => f.cumple(_filtro) && (!soloHoy || deHoy(f)))
            .toList() ??
        const [];

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

    return SafeArea(
      bottom: false,
      child: ListView(
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Medidas.margenLateral,
            ),
            child: Row(
              children: [
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
                    Text(_vacio(_filtro), style: Tipografia.texto),
                    if (_filtro == FiltroHistorial.todo) ...[
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
                      borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
                      child: Material(
                        color: Colores.superficie,
                        child: Column(
                          children: [
                            for (final (i, f) in delDia.indexed)
                              FilaMovimiento(
                                fila: f,
                                conSeparador: i < delDia.length - 1,
                                alTocar: () =>
                                    context.push(Rutas.detalleMovimiento(f.id)),
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
