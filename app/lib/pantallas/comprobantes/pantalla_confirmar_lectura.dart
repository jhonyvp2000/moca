import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/icono_trazo.dart';
import '../../comun/opciones.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/comprobantes.dart';
import '../../dominio/modelos.dart';
import '../../dominio/movimientos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import '../registrar/confirmacion.dart';

/// S08 · Revisa la lectura. Nada se guarda sin que el dueño confirme: la
/// cuenta y si ya pagó se eligen siempre; Moca no las adivina.
class PantallaConfirmarLectura extends ConsumerStatefulWidget {
  const PantallaConfirmarLectura({super.key, required this.lectura});

  final LecturaComprobante lectura;

  @override
  ConsumerState<PantallaConfirmarLectura> createState() =>
      _EstadoConfirmarLectura();
}

class _EstadoConfirmarLectura extends ConsumerState<PantallaConfirmarLectura> {
  late final _total = TextEditingController(
    text: _textoMonto(widget.lectura.totalCentimos),
  );
  late final _aQuien = TextEditingController(
    text: widget.lectura.emisorNombre ?? '',
  );
  late bool _corrigiendo = !widget.lectura.legible;
  TipoCuenta? _cuenta;
  bool? _pagado;
  String? _categoriaId;
  bool _guardando = false;

  static String _textoMonto(int? centimos) {
    if (centimos == null) return '';
    final resto = centimos % 100;
    return resto == 0
        ? '${centimos ~/ 100}'
        : '${centimos ~/ 100}.${resto.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _total.dispose();
    _aQuien.dispose();
    super.dispose();
  }

  int get _totalCentimos => leerSolesConCentimos(_total.text) ?? 0;

  bool get _completo =>
      _totalCentimos > 0 &&
      _cuenta != null &&
      _pagado != null &&
      _categoriaId != null;

  Future<void> _guardar() async {
    if (!_completo || _guardando) return;
    final l = widget.lectura;
    final compra = CompraConfirmada(
      lectura: l,
      totalCentimos: _totalCentimos,
      cuenta: _cuenta!,
      pagado: _pagado!,
      categoriaId: _categoriaId!,
      emisorNombre: _aQuien.text.trim().isEmpty ? null : _aQuien.text.trim(),
      fecha: l.fechaEmision ?? ref.read(relojProvider)(),
    );
    final movimientos = ref.read(repositorioMovimientosProvider);
    setState(() => _guardando = true);
    try {
      // Moca pregunta antes de dejar una cuenta en negativo.
      if (compra.pagado) {
        final quedaria = await movimientos.saldoSiSeGuarda(
          NuevoMovimiento(
            tipo: TipoMovimiento.egreso,
            montoCentimos: compra.totalCentimos,
            cuenta: compra.cuenta,
            categoriaId: compra.categoriaId,
          ),
        );
        if (quedaria < 0 && mounted && !await _preguntarNegativo(quedaria)) {
          return;
        }
      }
      final Guardado guardado;
      try {
        guardado = await ref
            .read(repositorioComprobantesProvider)
            .guardarCompra(compra);
      } on StateError {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(Textos.comprobanteYaAnotado)),
          );
        }
        return;
      }
      if (!mounted) return;
      final mensajes = ScaffoldMessenger.of(context);
      context.pop();
      mostrarGuardado(mensajes, guardado, movimientos.deshacer);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<bool> _preguntarNegativo(int quedaria) async {
    final seguir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Textos.quedariaNegativoTitulo),
        content: Text(
          Textos.quedariaNegativo(
            Textos.nombreCuenta(_cuenta!),
            formatearSoles(quedaria),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Textos.revisar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Textos.guardarIgual),
          ),
        ],
      ),
    );
    return seguir == true;
  }

  Future<void> _elegirCategoria(List<CategoriaVista> categorias) async {
    final elegida = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                0,
                Medidas.margenLateral,
                8,
              ),
              child: Text(Textos.tipoDeGasto, style: Tipografia.tituloPantalla),
            ),
            for (final c in categorias)
              ListTile(
                minTileHeight: Medidas.objetivoTactilMinimo + 8,
                title: Text(c.nombre, style: Tipografia.texto),
                trailing: c.id == _categoriaId
                    ? const IconoTrazo(Icono.check, color: Colores.marca)
                    : null,
                onTap: () => Navigator.of(context).pop(c.id),
              ),
          ],
        ),
      ),
    );
    if (elegida != null) setState(() => _categoriaId = elegida);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lectura;
    final categorias =
        ref.watch(categoriasProvider(TipoMovimiento.egreso)).value ??
        const <CategoriaVista>[];
    // La categoría que sugiere la lectura, si el negocio la tiene.
    if (_categoriaId == null && l.categoria != null) {
      final sugerida = categorias.where((c) => c.nombre == l.categoria);
      if (sugerida.isNotEmpty) _categoriaId = sugerida.first.id;
    }
    final nombreCategoria = categorias
        .where((c) => c.id == _categoriaId)
        .map((c) => c.nombre)
        .firstOrNull;
    final fecha = l.fechaEmision ?? ref.read(relojProvider)();

    const etiqueta = TextStyle(
      fontFamily: Tipografia.familia,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Colores.textoPrincipal,
    );

    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.revisaLaLectura,
        alVolver: () => context.pop(),
      ),
      contenido: [
        Tarjeta(
          relleno: const EdgeInsets.all(14),
          child: Row(
            children: [
              _Miniatura(lectura: l),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconoTrazo(
                          Icono.salio,
                          color: Colores.textoSecundario,
                          tamano: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            Textos.salioCompra,
                            style: Tipografia.secundario.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_corrigiendo)
                      TextField(
                        controller: _total,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d{0,7}(\.\d{0,2})?'),
                          ),
                        ],
                        onChanged: (_) => setState(() {}),
                        style: Tipografia.cifra(
                          Tipografia.tituloPantalla.copyWith(fontSize: 24),
                        ),
                        decoration: const InputDecoration(
                          prefixText: 'S/ ',
                          hintText: '0.00',
                        ),
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatearSolesComprobante(_totalCentimos),
                          style: Tipografia.cifra(
                            Tipografia.tituloPantalla.copyWith(
                              fontSize: 32,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${l.tipo ?? 'Compra'} · ${formatearFechaLarga(fecha)}',
                      style: Tipografia.secundario,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Tarjeta(
          relleno: EdgeInsets.zero,
          child: Column(
            children: [
              _Fila(
                etiqueta: Textos.aQuien,
                valor: _corrigiendo
                    ? SizedBox(
                        width: 190,
                        child: TextField(
                          controller: _aQuien,
                          textAlign: TextAlign.right,
                          textCapitalization: TextCapitalization.words,
                          style: Tipografia.textoFuerte,
                          decoration: InputDecoration(
                            hintText: l.emisorIdentificacion == null
                                ? Textos.aQuienEjemplo
                                : Textos.rucDe(l.emisorIdentificacion!),
                          ),
                        ),
                      )
                    : Text(
                        _aQuien.text.isNotEmpty
                            ? _aQuien.text
                            : l.emisorIdentificacion != null
                            ? Textos.rucDe(l.emisorIdentificacion!)
                            : Textos.noSeLee,
                        textAlign: TextAlign.right,
                        style: Tipografia.textoFuerte,
                      ),
              ),
              if (l.cantidadItems != null) ...[
                const Divider(),
                _Fila(
                  etiqueta: Textos.queCompraste,
                  valor: Text(
                    Textos.productos(l.cantidadItems!),
                    style: Tipografia.textoFuerte,
                  ),
                ),
              ],
              const Divider(),
              InkWell(
                onTap: () => _elegirCategoria(categorias),
                child: _Fila(
                  etiqueta: Textos.tipoDeGasto,
                  valor: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          nombreCategoria ?? Textos.eligeTipoDeGasto,
                          textAlign: TextAlign.right,
                          style: Tipografia.textoFuerte.copyWith(
                            color: nombreCategoria == null
                                ? Colores.marca
                                : Colores.textoPrincipal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const IconoTrazo(
                        Icono.abajo,
                        color: Colores.textoPrincipal,
                        tamano: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(Textos.deDondeSalio, style: etiqueta),
        const SizedBox(height: 8),
        OpcionesRejilla<TipoCuenta>(
          opciones: {
            for (final c in ref.watch(tiposDeCuentaProvider))
              c: Textos.nombreCuenta(c),
          },
          elegida: _cuenta,
          alElegir: (c) => setState(() => _cuenta = c),
        ),
        const SizedBox(height: 14),
        const Text(Textos.yaLoPagaste, style: etiqueta),
        const SizedBox(height: 8),
        OpcionesRejilla<bool>(
          opciones: const {true: Textos.siPagado, false: Textos.todaviaLoDebo},
          elegida: _pagado,
          alElegir: (p) => setState(() => _pagado = p),
        ),
        const SizedBox(height: 14),
        _Nota(
          texto: !l.legible
              ? Textos.completadoAMano
              : l.origen == OrigenLectura.qr
              ? Textos.leidoDelQr
              : Textos.leidoDeLaFoto,
        ),
      ],
      acciones: [
        FilledButton(
          onPressed: _completo && !_guardando ? _guardar : null,
          child: const Text(Textos.guardar),
        ),
        if (!_corrigiendo)
          BotonTexto(
            texto: Textos.corregirUnDato,
            alTocar: () => setState(() => _corrigiendo = true),
          ),
      ],
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.lectura});

  final LecturaComprobante lectura;

  @override
  Widget build(BuildContext context) {
    final ruta = lectura.rutaImagen;
    final archivo = ruta == null ? null : File(ruta);
    return Container(
      width: 76,
      height: 100,
      decoration: BoxDecoration(
        color: Colores.fondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colores.bordeCampo),
      ),
      clipBehavior: Clip.antiAlias,
      child: archivo != null && archivo.existsSync()
          ? Image.file(archivo, fit: BoxFit.cover)
          : Center(
              child: lectura.origen == OrigenLectura.qr
                  ? const IconoTrazo(
                      Icono.qr,
                      color: Colores.textoSecundario,
                      tamano: 32,
                    )
                  : const Text(Textos.foto, style: Tipografia.secundario),
            ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final Widget valor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Text(etiqueta, style: Tipografia.secundario),
            const SizedBox(width: 12),
            Expanded(
              child: Align(alignment: Alignment.centerRight, child: valor),
            ),
          ],
        ),
      ),
    );
  }
}

class _Nota extends StatelessWidget {
  const _Nota({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colores.tinteAzul,
        borderRadius: BorderRadius.circular(Medidas.radioBoton),
      ),
      child: Row(
        children: [
          const IconoTrazo(Icono.check, color: Colores.azulOscuro, tamano: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: Tipografia.secundario.copyWith(color: Colores.azulOscuro),
            ),
          ),
        ],
      ),
    );
  }
}
