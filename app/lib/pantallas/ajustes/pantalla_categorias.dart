import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/icono_trazo.dart';
import '../../comun/opciones.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/categorias.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Mis categorías» (entrega 31), solo para dueños: las de Moca, que no se
/// cambian, y las propias del negocio.
class PantallaCategorias extends ConsumerWidget {
  const PantallaCategorias({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todas =
        ref.watch(categoriasDelNegocioProvider).value ??
        const <CategoriaDelNegocio>[];
    Widget grupo(String titulo, TipoMovimiento tipo) {
      final lista = todas.where((c) => c.tipo == tipo).toList();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titulo, style: Tipografia.tituloTarjeta),
            const SizedBox(height: 8),
            Tarjeta(
              relleno: EdgeInsets.zero,
              child: Material(
                color: Colores.superficie,
                borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, c) in lista.indexed)
                      _FilaCategoria(
                        categoria: c,
                        conSeparador: i < lista.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.misCategorias,
        alVolver: () => context.pop(),
      ),
      contenido: [
        const Text(Textos.categoriasDeMoca, style: Tipografia.secundario),
        const SizedBox(height: 16),
        grupo(Textos.entro, TipoMovimiento.ingreso),
        grupo(Textos.salio, TipoMovimiento.egreso),
      ],
      acciones: [
        FilledButton(
          onPressed: () => context.push(Rutas.categoriaNueva(null)),
          child: const Text(Textos.agregarCategoria),
        ),
      ],
    );
  }
}

class _FilaCategoria extends StatelessWidget {
  const _FilaCategoria({required this.categoria, required this.conSeparador});

  final CategoriaDelNegocio categoria;
  final bool conSeparador;

  @override
  Widget build(BuildContext context) {
    final c = categoria;
    final fila = Container(
      constraints: const BoxConstraints(
        minHeight: Medidas.objetivoTactilMinimo + 8,
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
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
                Text(
                  c.nombre,
                  style: c.activa
                      ? Tipografia.texto
                      : Tipografia.texto.copyWith(
                          color: Colores.textoSecundario,
                        ),
                ),
                Text(
                  !c.propia
                      ? Textos.deMoca
                      : c.activa
                      ? Textos.tuya
                      : Textos.yaNoLaUsas,
                  style: Tipografia.secundario,
                ),
              ],
            ),
          ),
          if (c.propia)
            const IconoTrazo(Icono.derecha, color: Colores.textoSecundario),
        ],
      ),
    );
    if (!c.propia) return fila;
    return InkWell(
      onTap: () => context.push(Rutas.categoriaPropia(c.id)),
      child: fila,
    );
  }
}

/// Una categoría propia: nueva (con o sin tipo elegido) o la que se cambia.
/// La nueva vuelve con su id, para dejarla elegida al anotar.
class PantallaCategoria extends ConsumerStatefulWidget {
  const PantallaCategoria({super.key, this.id, this.tipo});

  final String? id;
  final TipoMovimiento? tipo;

  @override
  ConsumerState<PantallaCategoria> createState() => _EstadoCategoria();
}

class _EstadoCategoria extends ConsumerState<PantallaCategoria> {
  final _nombre = TextEditingController();
  TipoMovimiento? _tipo;
  bool _cargada = false;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipo;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  CategoriaDelNegocio? _actual(List<CategoriaDelNegocio> todas) =>
      widget.id == null
      ? null
      : todas.where((c) => c.id == widget.id && c.propia).firstOrNull;

  String _textoDelError(ErrorCategoria error, TipoMovimiento tipo) =>
      switch (error) {
        ErrorCategoria.repetida => Textos.categoriaRepetida,
        ErrorCategoria.sinLugar => Textos.sinLugarCategoria(
          maximoPropias(tipo),
          tipo == TipoMovimiento.ingreso,
        ),
        ErrorCategoria.vacia ||
        ErrorCategoria.sinPermiso => Textos.noSePudoCategoria,
      };

  Future<void> _resultado(
    Future<ResultadoCategoria> Function() accion,
    TipoMovimiento tipo,
    String listo, {
    bool conId = false,
  }) async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    final mensajes = ScaffoldMessenger.of(context);
    final resultado = await accion();
    if (!mounted) return;
    if (resultado.error case final error?) {
      setState(() {
        _guardando = false;
        _error = _textoDelError(error, tipo);
      });
      return;
    }
    mensajes.showSnackBar(SnackBar(content: Text(listo)));
    context.pop(conId ? resultado.id : null);
  }

  @override
  Widget build(BuildContext context) {
    final todas = ref.watch(categoriasDelNegocioProvider).value;
    final actual = todas == null ? null : _actual(todas);
    if (actual != null && !_cargada) {
      _cargada = true;
      _nombre.text = actual.nombre;
      _tipo = actual.tipo;
    }
    final repositorio = ref.read(repositorioCategoriasProvider);
    final tipo = _tipo;
    final nombre = _nombre.text.trim();
    final esNueva = widget.id == null;
    final puedeGuardar =
        !_guardando &&
        tipo != null &&
        nombre.isNotEmpty &&
        (esNueva || (actual != null && nombre != actual.nombre));
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: esNueva ? Textos.categoriaNueva : Textos.cambiarCategoria,
        alVolver: () => context.pop(),
      ),
      contenido: [
        const Text(Textos.nombreCategoria, style: Tipografia.textoFuerte),
        const SizedBox(height: 8),
        TextField(
          controller: _nombre,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [
            LengthLimitingTextInputFormatter(largoNombreCategoria),
          ],
          onChanged: (_) => setState(() => _error = null),
          decoration: const InputDecoration(
            hintText: Textos.nombreCategoriaEjemplo,
          ),
        ),
        // El tipo se elige al crearla; después no cambia.
        if (esNueva && widget.tipo == null) ...[
          const SizedBox(height: 16),
          const Text(Textos.esDeLoQue, style: Tipografia.textoFuerte),
          const SizedBox(height: 8),
          Opciones<TipoMovimiento>(
            opciones: const {
              TipoMovimiento.ingreso: Textos.loQueEntra,
              TipoMovimiento.egreso: Textos.loQueSale,
            },
            elegida: tipo,
            alElegir: (t) => setState(() {
              _tipo = t;
              _error = null;
            }),
          ),
        ],
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Aviso(texto: error),
        ],
      ],
      acciones: [
        FilledButton(
          onPressed: puedeGuardar
              ? () => esNueva
                    ? _resultado(
                        () => repositorio.agregar(nombre, tipo),
                        tipo,
                        Textos.categoriaAgregada,
                        conId: true,
                      )
                    : _resultado(
                        () => repositorio.renombrar(actual!.id, nombre),
                        tipo,
                        Textos.categoriaGuardada,
                      )
              : null,
          child: const Text(Textos.guardar),
        ),
        if (actual != null)
          OutlinedButton(
            onPressed: _guardando
                ? null
                : () => _resultado(
                    () => repositorio.usar(actual.id, activa: !actual.activa),
                    actual.tipo,
                    actual.activa
                        ? Textos.categoriaSinUso
                        : Textos.categoriaOtraVez,
                  ),
            child: Text(
              actual.activa ? Textos.yaNoLaUso : Textos.usarlaOtraVez,
            ),
          ),
      ],
    );
  }
}
