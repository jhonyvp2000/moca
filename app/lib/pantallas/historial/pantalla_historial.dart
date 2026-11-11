import '../../comun/actualizar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/boton_redondo.dart';
import '../../comun/estado_vacio.dart';
import '../../comun/monto_text.dart';
import '../../comun/opciones.dart';
import '../../comun/tono.dart';
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
    FiltroHistorial.pendientes => Textos.sinPendientes,
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
          // Espacio para el + que sobresale de la barra.
          padding: const EdgeInsets.only(bottom: Medidas.e8 + Medidas.e4),
          children: [
            // El título y, a la derecha, «Filtrar» (entrega 39), aparte de
            // los filtros rápidos (mejora 01).
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                Medidas.e4,
                Medidas.margenLateral,
                Medidas.e3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: const Text(
                        Textos.tituloHistorial,
                        style: Tipografia.tituloPantalla,
                      ),
                    ),
                  ),
                  Badge(
                    isLabelVisible: _filtros.puestos > 0,
                    label: Text('${_filtros.puestos}'),
                    backgroundColor: Colores.marca,
                    child: BotonRedondo(
                      icono: Icons.tune_rounded,
                      nombre: _filtros.puestos == 0
                          ? Textos.filtrar
                          : Textos.filtrarCon(_filtros.puestos),
                      alTocar: () => _abrirFiltros(visibles),
                    ),
                  ),
                ],
              ),
            ),
            // Buscar (entrega 39): cada palabra tiene que estar.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                0,
                Medidas.margenLateral,
                Medidas.e3,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Medidas.radioMedio),
                  boxShadow: Sombras.nivel1,
                ),
                child: TextField(
                  controller: _buscar,
                  textInputAction: TextInputAction.search,
                  onChanged: (t) =>
                      setState(() => _filtros = _filtros.conTexto(t)),
                  decoration: InputDecoration(
                    hintText: Textos.buscarEnTuHistorial,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colores.textoSecundario,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: Medidas.e4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Medidas.radioMedio),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Medidas.radioMedio),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            // Los filtros rápidos se deslizan; el borde que se desvanece dice
            // que hay más (mejora 01).
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => LinearGradient(
                colors: [
                  Colores.superficie,
                  Colores.superficie,
                  Colores.superficie.withValues(alpha: 0),
                ],
                stops: const [0, 0.88, 1],
              ).createShader(r),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: Medidas.margenLateral,
                ),
                child: Row(
                  children: [
                    for (final (i, filtro)
                        in FiltroHistorial.values.indexed) ...[
                      if (i > 0) const SizedBox(width: Medidas.e2),
                      _Filtro(
                        texto: switch (filtro) {
                          FiltroHistorial.todo => Textos.filtroTodo,
                          FiltroHistorial.entro => Textos.entro,
                          FiltroHistorial.salio => Textos.salio,
                          FiltroHistorial.pendientes => Textos.filtroPendientes(
                            resumen?.pendientes ?? 0,
                          ),
                          FiltroHistorial.porSubir => Textos.filtroPorSubir(
                            resumen?.porSubir ?? 0,
                          ),
                        },
                        punto: switch (filtro) {
                          FiltroHistorial.todo => null,
                          FiltroHistorial.entro => Colores.ingreso,
                          FiltroHistorial.salio => Colores.egreso,
                          FiltroHistorial.pendientes => Colores.pendiente,
                          FiltroHistorial.porSubir => Colores.neutro,
                        },
                        elegido: filtro == _filtro,
                        alTocar: () => setState(() => _filtro = filtro),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Medidas.e2),
            // Lo encontrado, con su suma, y cómo volver a ver todo.
            if (buscando && filas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.margenLateral,
                  0,
                  Medidas.margenLateral,
                  Medidas.e1,
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
                  Medidas.e3,
                ),
                child: Text(
                  Textos.soloLoDeHoyAyudante,
                  style: Tipografia.secundario,
                ),
              ),
            if (resumen != null && filas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Medidas.margenLateral,
                ),
                child: EstadoVacio(
                  icono: buscando
                      ? Icons.search_off_rounded
                      : Icons.receipt_long_rounded,
                  titulo: buscando ? Textos.sinResultados : _vacio(_filtro),
                  accion: buscando
                      ? TextButton(
                          onPressed: _quitarFiltros,
                          child: const Text(Textos.quitarFiltros),
                        )
                      : _filtro == FiltroHistorial.todo
                      ? FilledButton(
                          onPressed: () => context.push(Rutas.registrar),
                          child: const Text(Textos.registrar),
                        )
                      : null,
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
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        Medidas.e3,
                        0,
                        Medidas.e2,
                      ),
                      child: _EncabezadoDelDia(
                        titulo: formatearDiaHistorial(dia, hoy),
                        filas: delDia,
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
            // El final de la lista: no hay más (mejora 01). El ayudante ve
            // solo lo de hoy, y eso ya se lo dice su aviso.
            if (filas.isNotEmpty &&
                !buscando &&
                _filtro == FiltroHistorial.todo &&
                !soloHoy)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  Medidas.margenLateral,
                  Medidas.e6,
                  Medidas.margenLateral,
                  0,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 32,
                      color: Colores.grisAzulado,
                    ),
                    SizedBox(height: Medidas.e2),
                    Text(
                      Textos.esoEsTodo,
                      textAlign: TextAlign.center,
                      style: Tipografia.secundario,
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

/// El día y, a la derecha, lo que entró y salió ese día y, si hubo de los
/// dos, lo que quedó (entrega 55). Solo la plata que se movió: lo fiado, lo
/// que se debe, los pases y los ajustes del arqueo no suman, como en «Esta
/// semana» (decisiones.md, 10-11-2026). Una deuda cobrada o pagada otro día
/// suma el día del pago, no el de la venta o la compra.
class _EncabezadoDelDia extends StatelessWidget {
  const _EncabezadoDelDia({required this.titulo, required this.filas});

  final String titulo;
  final List<FilaHistorial> filas;

  @override
  Widget build(BuildContext context) {
    final movio = filas.where(
      (f) =>
          !f.loDebes && !f.pagadoOtroDia && !f.ajusteArqueo && !f.tipo.esPase,
    );
    final entro = movio
        .where((f) => f.tipo.entraPlata)
        .fold(0, (s, f) => s + f.montoCentimos);
    final salio = movio
        .where((f) => !f.tipo.entraPlata)
        .fold(0, (s, f) => s + f.montoCentimos);
    final estilo = Tipografia.apoyo.copyWith(fontWeight: FontWeight.w700);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(titulo, style: Tipografia.tituloTarjeta),
          ),
        ),
        // Con letra grande, el total se achica antes que desbordarse.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entro > 0)
                  MontoText(
                    entro,
                    estilo: estilo,
                    tono: Tono.ingreso,
                    conSigno: true,
                    conCentimos: true,
                  ),
                if (entro > 0 && salio > 0) Text(' · ', style: estilo),
                if (salio > 0)
                  MontoText(
                    salio,
                    estilo: estilo,
                    tono: Tono.egreso,
                    conSigno: true,
                    conCentimos: true,
                  ),
                // Lo que quedó, solo si hubo de los dos (entrega 55).
                if (entro > 0 && salio > 0) ...[
                  Text(' · = ', style: estilo),
                  Text(
                    // Con su signo menos si salió más de lo que entró.
                    formatearSolesComprobante(entro - salio),
                    key: const ValueKey('quedoDelDia'),
                    style: Tipografia.cifra(
                      estilo.copyWith(
                        color: entro - salio < 0
                            ? Colores.egreso
                            : Colores.textoPrincipal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Un filtro rápido (mejora 01): azul de marca cuando está elegido y, si
/// tiene, el punto de su color.
class _Filtro extends StatelessWidget {
  const _Filtro({
    required this.texto,
    required this.elegido,
    required this.alTocar,
    this.punto,
  });

  final String texto;
  final bool elegido;
  final VoidCallback alTocar;
  final Color? punto;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medidas.radioPildora),
      side: elegido
          ? BorderSide.none
          : const BorderSide(color: Colores.bordeTarjeta),
    );
    return Semantics(
      selected: elegido,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: elegido ? Colores.marca : Colores.superficie,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: Medidas.objetivoTactilMinimo,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Medidas.e4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (punto case final color?) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: elegido ? Colores.sobreMarca : color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: Medidas.e2),
                  ],
                  Text(
                    texto,
                    style: Tipografia.etiquetaBarra.copyWith(
                      fontWeight: elegido ? FontWeight.w700 : FontWeight.w600,
                      color: elegido
                          ? Colores.sobreMarca
                          : Colores.textoPrincipal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
