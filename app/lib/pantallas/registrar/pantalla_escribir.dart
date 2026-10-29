import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/campo_monto.dart';
import '../../comun/estructura.dart';
import '../../comun/opciones.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/historial.dart';
import '../../dominio/equipo.dart';
import '../../dominio/modelos.dart';
import '../../dominio/movimientos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/categorias.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import 'confirmacion.dart';
import 'franja_sin_senal.dart';

/// «Escribirlo» (estado no dibujado, aprobado el 12-10-2026): entró, salió o
/// retiro para mí; monto; cuenta; categoría y nota. La fecha es hoy.
///
/// También sirve para «Corregir registro» desde el Historial (aprobado el
/// 13-10-2026): con los datos puestos y la fecha original.
class PantallaEscribir extends ConsumerStatefulWidget {
  const PantallaEscribir({
    super.key,
    this.tipoInicial,
    this.borrador,
    this.corrigiendo,
  });

  /// «Anotar un gasto» abre el formulario con «Salió» elegido.
  final TipoMovimiento? tipoInicial;

  /// Datos ya puestos, por ejemplo al corregir lo que se dijo por voz.
  final BorradorMovimiento? borrador;

  /// El registro que se corrige. Al guardar, la pantalla devuelve el id del
  /// registro nuevo.
  final DetalleMovimiento? corrigiendo;

  @override
  ConsumerState<PantallaEscribir> createState() => _EstadoEscribir();
}

class _EstadoEscribir extends ConsumerState<PantallaEscribir> {
  final _monto = TextEditingController();
  final _nota = TextEditingController();
  TipoMovimiento? _tipo;
  TipoCuenta _cuenta = TipoCuenta.efectivo;
  String? _categoriaId;
  bool _guardando = false;

  static const _nombresTipo = {
    TipoMovimiento.ingreso: Textos.entro,
    TipoMovimiento.egreso: Textos.salio,
    TipoMovimiento.retiro: Textos.retiroParaMi,
    TipoMovimiento.aporte: Textos.puseDeMiBolsillo,
  };

  /// En una compra con comprobante, el monto y el tipo no se corrigen.
  bool get _conComprobante => widget.corrigiendo?.comprobante != null;

  /// El monto original, con céntimos si los tenía, mientras no se toque.
  int? _montoOriginal;

  @override
  void initState() {
    super.initState();
    if (widget.corrigiendo case final d?) {
      _tipo = d.fila.tipo;
      _cuenta = d.fila.cuenta;
      _categoriaId = d.categoriaId;
      _montoOriginal = d.fila.montoCentimos;
      _monto.text = separarMiles(d.fila.montoCentimos ~/ 100);
      _nota.text = d.fila.nota ?? '';
      return;
    }
    final borrador = widget.borrador;
    _tipo = borrador?.tipo ?? widget.tipoInicial;
    _cuenta = borrador?.cuenta ?? _cuenta;
    _categoriaId = borrador?.categoriaId;
    if (borrador?.montoCentimos case final centimos?) {
      _monto.text = separarMiles(centimos ~/ 100);
    }
  }

  @override
  void dispose() {
    _monto.dispose();
    _nota.dispose();
    super.dispose();
  }

  int get _montoCentimos =>
      _montoOriginal ?? leerSolesEnCentimos(_monto.text) ?? 0;

  bool get _completo =>
      _tipo != null &&
      _montoCentimos > 0 &&
      ((_tipo?.delDueno ?? false) || _categoriaId != null);

  /// Al corregir, si no cambió nada no se guarda nada.
  bool get _sinCambios {
    final d = widget.corrigiendo!;
    final nota = _nota.text.trim();
    return _tipo == d.fila.tipo &&
        _montoCentimos == d.fila.montoCentimos &&
        _cuenta == d.fila.cuenta &&
        ((_tipo?.delDueno ?? false) || _categoriaId == d.categoriaId) &&
        (nota.isEmpty ? null : nota) == d.fila.nota;
  }

  Future<void> _guardarCorreccion(NuevoMovimiento correccion) async {
    if (_sinCambios) {
      context.pop();
      return;
    }
    final repo = ref.read(repositorioHistorialProvider);
    final id = widget.corrigiendo!.fila.id;
    final quedaria = await repo.saldoSiSeCorrige(id, correccion);
    if (quedaria != null && quedaria < 0) {
      if (!mounted) return;
      final seguir = await _preguntarNegativo(quedaria);
      if (!seguir) return;
    }
    final guardado = await repo.corregir(id, correccion);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            Textos.cambiosGuardados(formatearSoles(guardado.tienesHoyCentimos)),
          ),
        ),
      );
    context.pop(guardado.ids.single);
  }

  void _elegirTipo(TipoMovimiento tipo) => setState(() {
    _tipo = tipo;
    _categoriaId = null;
  });

  Future<void> _guardar() async {
    if (!_completo || _guardando) return;
    final movimiento = NuevoMovimiento(
      tipo: _tipo!,
      montoCentimos: _montoCentimos,
      cuenta: _cuenta,
      categoriaId: _categoriaId,
      nota: _nota.text,
    );
    final repo = ref.read(repositorioMovimientosProvider);
    setState(() => _guardando = true);
    try {
      if (widget.corrigiendo != null) {
        await _guardarCorreccion(movimiento);
        return;
      }
      // Moca pregunta antes de dejar una cuenta en negativo.
      final quedaria = await repo.saldoSiSeGuarda(movimiento);
      if (quedaria < 0) {
        if (!mounted) return;
        final seguir = await _preguntarNegativo(quedaria);
        if (!seguir) return;
      }
      final guardado = await repo.registrar(movimiento);
      if (!mounted) return;
      final mensajes = ScaffoldMessenger.of(context);
      context.pop();
      mostrarGuardado(mensajes, guardado, repo.deshacer);
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
            Textos.nombreCuenta(_cuenta),
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

  @override
  Widget build(BuildContext context) {
    final tipo = _tipo;
    final categorias = tipo == null || tipo.delDueno
        ? null
        : ref.watch(categoriasProvider(tipo)).value;

    // «Entró» viene con «Venta del día» elegida.
    if (tipo == TipoMovimiento.ingreso &&
        _categoriaId == null &&
        categorias != null) {
      final venta = categorias.where((c) => c.nombre == categoriaVentaDelDia);
      if (venta.isNotEmpty) _categoriaId = venta.first.id;
    }

    const etiqueta = TextStyle(
      fontFamily: Tipografia.familia,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Colores.textoPrincipal,
    );

    final corrigiendo = widget.corrigiendo;

    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: corrigiendo == null
            ? Textos.escribirlo
            : Textos.corregirRegistro,
        alVolver: () => context.pop(),
      ),
      contenido: [
        const FranjaSinSenal(),
        if (_conComprobante) ...[
          Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Textos.nombreTipo(corrigiendo!.fila.tipo)} · '
                  '${formatearSolesComprobante(corrigiendo.fila.montoCentimos)}',
                  style: Tipografia.cifra(Tipografia.tituloTarjeta),
                ),
                const SizedBox(height: 4),
                const Text(
                  Textos.datosDelComprobante,
                  style: Tipografia.secundario,
                ),
              ],
            ),
          ),
        ] else ...[
          const Text(Textos.queFue, style: etiqueta),
          const SizedBox(height: 8),
          Opciones<TipoMovimiento>(
            // Retiros y aportes, solo los dueños (entrega 20).
            opciones:
                (ref.watch(permisosProvider).value ?? Permisos.delDueno)
                    .anotaLoDelDueno
                ? _nombresTipo
                : {
                    for (final e in _nombresTipo.entries)
                      if (!e.key.delDueno) e.key: e.value,
                  },
            elegida: tipo,
            alElegir: _elegirTipo,
          ),
          if (tipo == TipoMovimiento.retiro) ...[
            const SizedBox(height: 8),
            const Text(Textos.retiroDetalle, style: Tipografia.secundario),
          ],
          if (tipo == TipoMovimiento.aporte) ...[
            const SizedBox(height: 8),
            const Text(Textos.aporteDetalle, style: Tipografia.secundario),
          ],
          const SizedBox(height: 18),
          GrupoMontos(
            filas: [
              FilaMonto(
                etiqueta: Textos.cuanto,
                controlador: _monto,
                autofocus: corrigiendo == null,
                alCambiar: (_) => setState(() => _montoOriginal = null),
                accionTeclado: TextInputAction.done,
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Text(
          tipo?.entraPlata ?? false ? Textos.aDondeEntro : Textos.deDondeSalio,
          style: etiqueta,
        ),
        const SizedBox(height: 8),
        Opciones<TipoCuenta>(
          opciones: {
            for (final cuenta in ref.watch(tiposDeCuentaProvider))
              cuenta: Textos.nombreCuenta(cuenta),
          },
          elegida: _cuenta,
          alElegir: (cuenta) => setState(() => _cuenta = cuenta),
        ),
        if (categorias != null) ...[
          const SizedBox(height: 18),
          Text(
            tipo == TipoMovimiento.ingreso ? Textos.deQue : Textos.enQue,
            style: etiqueta,
          ),
          const SizedBox(height: 8),
          Opciones<String>(
            opciones: {for (final c in categorias) c.id: c.nombre},
            elegida: _categoriaId,
            alElegir: (id) => setState(() => _categoriaId = id),
          ),
        ],
        const SizedBox(height: 18),
        const Text(Textos.nota, style: etiqueta),
        const SizedBox(height: 8),
        TextField(
          controller: _nota,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          style: Tipografia.texto,
          decoration: const InputDecoration(
            hintText: Textos.notaEjemplo,
            counterText: '',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: Medidas.separacionTarjetas,
            ),
          ),
        ),
      ],
      acciones: [
        FilledButton(
          onPressed: _completo && !_guardando ? _guardar : null,
          child: Text(
            corrigiendo == null ? Textos.guardar : Textos.guardarCambios,
          ),
        ),
      ],
    );
  }
}
