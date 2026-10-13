import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/campo_monto.dart';
import '../../comun/estructura.dart';
import '../../comun/opciones.dart';
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

/// «Escribirlo» (estado no dibujado, aprobado el 12-10-2026): entró, salió o
/// retiro para mí; monto; cuenta; categoría y nota. La fecha es hoy.
class PantallaEscribir extends ConsumerStatefulWidget {
  const PantallaEscribir({super.key, this.tipoInicial, this.borrador});

  /// «Anotar un gasto» abre el formulario con «Salió» elegido.
  final TipoMovimiento? tipoInicial;

  /// Datos ya puestos, por ejemplo al corregir lo que se dijo por voz.
  final BorradorMovimiento? borrador;

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
  };

  @override
  void initState() {
    super.initState();
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

  int get _montoCentimos => leerSolesEnCentimos(_monto.text) ?? 0;

  bool get _completo =>
      _tipo != null &&
      _montoCentimos > 0 &&
      (_tipo == TipoMovimiento.retiro || _categoriaId != null);

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
    final categorias = tipo == null || tipo == TipoMovimiento.retiro
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

    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.escribirlo,
        alVolver: () => context.pop(),
      ),
      contenido: [
        const Text(Textos.queFue, style: etiqueta),
        const SizedBox(height: 8),
        Opciones<TipoMovimiento>(
          opciones: _nombresTipo,
          elegida: tipo,
          alElegir: _elegirTipo,
        ),
        if (tipo == TipoMovimiento.retiro) ...[
          const SizedBox(height: 8),
          const Text(Textos.retiroDetalle, style: Tipografia.secundario),
        ],
        const SizedBox(height: 18),
        GrupoMontos(
          filas: [
            FilaMonto(
              etiqueta: Textos.cuanto,
              controlador: _monto,
              autofocus: true,
              alCambiar: (_) => setState(() {}),
              accionTeclado: TextInputAction.done,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          tipo == TipoMovimiento.ingreso
              ? Textos.aDondeEntro
              : Textos.deDondeSalio,
          style: etiqueta,
        ),
        const SizedBox(height: 8),
        Opciones<TipoCuenta>(
          opciones: {
            for (final cuenta in TipoCuenta.values)
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
          child: const Text(Textos.guardar),
        ),
      ],
    );
  }
}
