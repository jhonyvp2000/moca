import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/campo_monto.dart';
import '../../comun/estructura.dart';
import '../../comun/chip_seleccion.dart';
import '../../comun/iconos.dart';
import '../../comun/opciones.dart';
import '../../comun/tono.dart';
import 'cuadros_de_categoria.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/historial.dart';
import '../../dominio/cuentas.dart';
import '../../dominio/equipo.dart';
import '../../dominio/modelos.dart';
import '../../dominio/movimientos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/categorias.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../rutas.dart';
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
  final _contraparte = TextEditingController();

  /// Falso: «Todavía lo debo» en «Salió» (entrega 41) o «Todavía me debe»
  /// en «Entró» (entrega 42).
  bool _pagado = true;
  TipoMovimiento? _tipo;
  TipoCuenta _cuenta = TipoCuenta.efectivo;

  /// En un pase, a dónde va la plata (entrega 21.1).
  TipoCuenta? _destino;
  String? _categoriaId;
  bool _guardando = false;

  static const _nombresTipo = {
    TipoMovimiento.ingreso: Textos.entro,
    TipoMovimiento.egreso: Textos.salio,
    TipoMovimiento.retiro: Textos.retiroParaMi,
    TipoMovimiento.aporte: Textos.puseDeMiBolsillo,
    TipoMovimiento.transferencia: Textos.pasePlata,
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
      _destino = d.fila.cuentaDestino;
      _categoriaId = d.categoriaId;
      _montoOriginal = d.fila.montoCentimos;
      _monto.text = separarMiles(d.fila.montoCentimos ~/ 100);
      _nota.text = d.fila.nota ?? '';
      _pagado = !d.fila.loDebes;
      _contraparte.text = d.fila.proveedor ?? '';
      return;
    }
    final borrador = widget.borrador;
    _tipo = borrador?.tipo ?? widget.tipoInicial;
    // El efectivo de un encargado o ayudante es su caja (entrega 21).
    final permisos = ref.read(permisosProvider).value ?? Permisos.delDueno;
    if (!permisos.puedeUsar(_cuenta)) _cuenta = permisos.misCajas!.first;
    _cuenta = borrador?.cuenta ?? _cuenta;
    _destino = borrador?.cuentaDestino;
    _categoriaId = borrador?.categoriaId;
    // Desde la voz, lo que se debe y quién (entrega 49).
    _pagado = borrador?.pagado ?? true;
    _contraparte.text = borrador?.contraparte ?? '';
    if (borrador?.montoCentimos case final centimos?) {
      _monto.text = separarMiles(centimos ~/ 100);
    }
  }

  @override
  void dispose() {
    _monto.dispose();
    _nota.dispose();
    _contraparte.dispose();
    super.dispose();
  }

  /// Se puede deber: una compra o una venta.
  bool get _sePuedeDeber =>
      !_conComprobante &&
      (_tipo == TipoMovimiento.egreso || _tipo == TipoMovimiento.ingreso);

  /// Todavía se debe: no se elige la cuenta, se elige al pagarlo.
  bool get _loDebe => _sePuedeDeber && !_pagado;

  /// Una venta a crédito (entrega 42).
  bool get _teDeben => _loDebe && _tipo == TipoMovimiento.ingreso;

  String? get _nombreContraparte =>
      _contraparte.text.trim().isEmpty ? null : _contraparte.text.trim();

  int get _montoCentimos =>
      _montoOriginal ?? leerSolesEnCentimos(_monto.text) ?? 0;

  bool get _completo =>
      _tipo != null &&
      _montoCentimos > 0 &&
      switch (_tipo!) {
        TipoMovimiento.transferencia => _destino != null && _destino != _cuenta,
        final t => t.delDueno || _categoriaId != null,
      } &&
      // Una venta a crédito lleva quién te debe (entrega 42).
      !(_teDeben && _nombreContraparte == null);

  /// Al corregir, si no cambió nada no se guarda nada.
  bool get _sinCambios {
    final d = widget.corrigiendo!;
    final nota = _nota.text.trim();
    return _tipo == d.fila.tipo &&
        _montoCentimos == d.fila.montoCentimos &&
        _cuenta == d.fila.cuenta &&
        _destino == d.fila.cuentaDestino &&
        ((_tipo?.sinCategoria ?? false) || _categoriaId == d.categoriaId) &&
        (nota.isEmpty ? null : nota) == d.fila.nota &&
        (_conComprobante ||
            (_loDebe == d.fila.loDebes &&
                (!_loDebe || _nombreContraparte == d.fila.proveedor)));
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
    _pagado = true;
    // El encargado y el ayudante pasan plata solo desde su caja.
    final misCajas =
        (ref.read(permisosProvider).value ?? Permisos.delDueno).misCajas;
    if (tipo.esPase && misCajas != null && !misCajas.contains(_cuenta)) {
      _cuenta = misCajas.first;
    }
  });

  Future<void> _guardar() async {
    if (!_completo || _guardando) return;
    final movimiento = NuevoMovimiento(
      tipo: _tipo!,
      montoCentimos: _montoCentimos,
      cuenta: _cuenta,
      cuentaDestino: _tipo!.esPase ? _destino : null,
      categoriaId: _categoriaId,
      nota: _nota.text,
      pagado: !_loDebe,
      contraparte: _loDebe ? _nombreContraparte : null,
    );
    final repo = ref.read(repositorioMovimientosProvider);
    setState(() => _guardando = true);
    try {
      if (widget.corrigiendo != null) {
        await _guardarCorreccion(movimiento);
        return;
      }
      // Moca pregunta antes de dejar una cuenta en negativo. Lo que se debe
      // todavía no baja la plata.
      final quedaria = movimiento.pendiente
          ? 0
          : await repo.saldoSiSeGuarda(movimiento);
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

  /// Lo que falta para poder guardar (mejora 01).
  List<String> get _loQueFalta => [
    if (_montoCentimos <= 0) Textos.faltaElMonto,
    if (_tipo == null) Textos.faltaQueFue,
    if (_tipo case final t?
        when !t.delDueno && !t.esPase && _categoriaId == null)
      t == TipoMovimiento.ingreso ? Textos.faltaDeQueFue : Textos.faltaEnQueFue,
    if (_tipo?.esPase == true && (_destino == null || _destino == _cuenta))
      Textos.faltaADondeVa,
    if (_teDeben && _nombreContraparte == null) Textos.faltaQuienTeDebe,
  ];

  /// Lo que se pregunta después de elegir qué fue: si ya se pagó, la
  /// cuenta, la categoría y la nota.
  List<Widget> _resto(
    TipoMovimiento tipo,
    List<CategoriaVista>? categorias,
    Permisos permisos,
    TextStyle etiqueta,
  ) {
    final saldos = permisos.veSaldos
        ? ref.watch(resumenInicioProvider).value?.saldosPorCuenta
        : null;
    final tono = tipo == TipoMovimiento.ingreso ? Tono.ingreso : Tono.egreso;
    return [
      // Una compra puede quedar debiéndose (entrega 41), y una venta, a
      // crédito (entrega 42).
      if (_sePuedeDeber) ...[
        const SizedBox(height: Medidas.e5),
        Text(
          tipo == TipoMovimiento.ingreso
              ? Textos.yaTePagaron
              : Textos.yaLoPagaste,
          style: etiqueta,
        ),
        const SizedBox(height: Medidas.e2),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: true,
                label: Text(
                  tipo == TipoMovimiento.ingreso
                      ? Textos.siMePago
                      : Textos.siPagado,
                ),
              ),
              ButtonSegment(
                value: false,
                label: Text(
                  tipo == TipoMovimiento.ingreso
                      ? Textos.todaviaMeDebe
                      : Textos.todaviaLoDebo,
                ),
              ),
            ],
            selected: {_pagado},
            onSelectionChanged: (p) => setState(() => _pagado = p.first),
          ),
        ),
      ],
      if (_loDebe) ...[
        const SizedBox(height: Medidas.e2),
        Text(
          _teDeben ? Textos.cuentaAlCobrar : Textos.cuentaAlPagar,
          style: Tipografia.secundario,
        ),
        const SizedBox(height: Medidas.e5),
        Text(
          _teDeben ? Textos.quienTeDebe : Textos.aQuienLeDebes,
          style: etiqueta,
        ),
        const SizedBox(height: Medidas.e2),
        TextField(
          controller: _contraparte,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          style: Tipografia.texto,
          // Una venta a crédito no se guarda sin nombre.
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: _teDeben
                ? Textos.quienTeDebeEjemplo
                : Textos.aQuienLeDebesEjemplo,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Medidas.e4,
              vertical: Medidas.e3,
            ),
          ),
        ),
      ] else ...[
        const SizedBox(height: Medidas.e5),
        Text(switch (tipo) {
          TipoMovimiento.transferencia => Textos.deDondeSalePase,
          final t when t.entraPlata => Textos.aDondeEntro,
          _ => Textos.deDondeSalio,
        }, style: etiqueta),
        const SizedBox(height: Medidas.e2),
        // Cada cuenta con su saldo, para quien lo ve (mejora 01).
        Wrap(
          spacing: Medidas.e2,
          runSpacing: Medidas.e2,
          children: [
            for (final cuenta in ref.watch(tiposDeCuentaProvider))
              // El encargado y el ayudante pasan plata solo desde su caja.
              if (tipo != TipoMovimiento.transferencia ||
                  (permisos.misCajas?.contains(cuenta) ?? true))
                ChipSeleccion(
                  etiqueta: Textos.nombreCuenta(cuenta),
                  detalle: switch (saldos?[cuenta]) {
                    final s? => formatearSoles(s),
                    null => null,
                  },
                  elegida: _cuenta == cuenta,
                  alTocar: () => setState(() {
                    _cuenta = cuenta;
                    if (_destino == cuenta) _destino = null;
                  }),
                ),
          ],
        ),
      ],
      // A cualquier cuenta del negocio, también a otra caja (entrega 21.1).
      if (tipo == TipoMovimiento.transferencia) ...[
        const SizedBox(height: Medidas.e5),
        Text(Textos.aDondeVaPase, style: etiqueta),
        const SizedBox(height: Medidas.e2),
        Opciones<TipoCuenta>(
          opciones: {
            for (final c
                in ref.watch(cuentasProvider).value ?? const <CuentaVista>[])
              if (c.tipo != _cuenta) c.tipo: Textos.nombreCuenta(c.tipo),
          },
          elegida: _destino,
          alElegir: (cuenta) => setState(() => _destino = cuenta),
        ),
      ],
      if (categorias != null) ...[
        const SizedBox(height: Medidas.e5),
        Text(
          tipo == TipoMovimiento.ingreso ? Textos.deQue : Textos.enQue,
          style: etiqueta,
        ),
        const SizedBox(height: Medidas.e2),
        CuadrosDeCategoria(
          categorias: categorias,
          elegida: _categoriaId,
          tono: tono,
          alElegir: (id) => setState(() => _categoriaId = id),
        ),
        // Una categoría propia, que queda elegida (entrega 31).
        if (permisos.cambiaCategorias)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () async {
                final id = await context.push<String>(
                  Rutas.categoriaNueva(tipo),
                );
                if (id != null && mounted) {
                  setState(() => _categoriaId = id);
                }
              },
              child: const Text(Textos.otraCategoria),
            ),
          ),
      ],
      const SizedBox(height: Medidas.e5),
      Text(Textos.nota, style: etiqueta),
      const SizedBox(height: Medidas.e2),
      TextField(
        controller: _nota,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        style: Tipografia.texto,
        decoration: const InputDecoration(
          hintText: Textos.notaEjemplo,
          counterText: '',
          contentPadding: EdgeInsets.symmetric(
            horizontal: Medidas.e4,
            vertical: Medidas.e3,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tipo = _tipo;
    final categorias = tipo == null || tipo.sinCategoria
        ? null
        : ref.watch(categoriasProvider(tipo)).value;

    // «Entró» viene con «Venta del día» elegida.
    if (tipo == TipoMovimiento.ingreso &&
        _categoriaId == null &&
        categorias != null) {
      final venta = categorias.where((c) => c.nombre == categoriaVentaDelDia);
      if (venta.isNotEmpty) _categoriaId = venta.first.id;
    }

    const etiqueta = Tipografia.tituloSeccion;

    final corrigiendo = widget.corrigiendo;
    final permisos = ref.watch(permisosProvider).value ?? Permisos.delDueno;

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
          // El monto, lo principal, arriba y grande (mejora 01).
          _CampoMonto(
            controlador: _monto,
            autofocus: corrigiendo == null,
            alCambiar: (_) => setState(() => _montoOriginal = null),
          ),
          const SizedBox(height: Medidas.e5),
          const Text(Textos.queFue, style: etiqueta),
          const SizedBox(height: Medidas.e2),
          // «Entró» y «Salió», grandes y con su color; lo interno, aparte.
          Row(
            children: [
              for (final (i, t) in const [
                TipoMovimiento.ingreso,
                TipoMovimiento.egreso,
              ].indexed) ...[
                if (i > 0) const SizedBox(width: Medidas.e3),
                Expanded(
                  child: ChipSeleccion(
                    etiqueta: _nombresTipo[t]!,
                    icono: Iconos.deTipo(t),
                    tono: t == TipoMovimiento.ingreso
                        ? Tono.ingreso
                        : Tono.egreso,
                    grande: true,
                    elegida: tipo == t,
                    alTocar: () => _elegirTipo(t),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Medidas.e2),
          Wrap(
            spacing: Medidas.e2,
            runSpacing: Medidas.e2,
            children: [
              for (final t in const [
                TipoMovimiento.retiro,
                TipoMovimiento.aporte,
                TipoMovimiento.transferencia,
              ])
                // Retiros y aportes, solo los dueños (entrega 20).
                if (permisos.anotaLoDelDueno || !t.delDueno)
                  ChipSeleccion(
                    etiqueta: _nombresTipo[t]!,
                    tono: Tono.marca,
                    elegida: tipo == t,
                    alTocar: () => _elegirTipo(t),
                  ),
            ],
          ),
          if (tipo == TipoMovimiento.retiro) ...[
            const SizedBox(height: Medidas.e2),
            const Text(Textos.retiroDetalle, style: Tipografia.secundario),
          ],
          if (tipo == TipoMovimiento.aporte) ...[
            const SizedBox(height: Medidas.e2),
            const Text(Textos.aporteDetalle, style: Tipografia.secundario),
          ],
          if (tipo == TipoMovimiento.transferencia) ...[
            const SizedBox(height: Medidas.e2),
            const Text(Textos.pasePlataDetalle, style: Tipografia.secundario),
          ],
        ],
        // Lo demás aparece al elegir qué fue (mejora 01).
        if (tipo != null) ..._resto(tipo, categorias, permisos, etiqueta),
      ],
      acciones: [
        // Qué falta para guardar, en vez de un botón gris mudo (mejora 01).
        if (!_completo && !_conComprobante)
          Padding(
            padding: const EdgeInsets.only(bottom: Medidas.e2),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 20,
                  color: Colores.pendienteTexto,
                ),
                const SizedBox(width: Medidas.e2),
                Expanded(
                  child: Text(
                    Textos.falta(_loQueFalta),
                    style: Tipografia.apoyo.copyWith(
                      color: Colores.pendienteTexto,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

/// El monto de «Escribirlo» (mejora 01): en su tarjeta, grande, con «S/»
/// fijo y teclado numérico.
class _CampoMonto extends StatelessWidget {
  const _CampoMonto({
    required this.controlador,
    required this.autofocus,
    required this.alCambiar,
  });

  final TextEditingController controlador;
  final bool autofocus;
  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) {
    final estilo = Tipografia.montoGrande;
    return Tarjeta(
      relleno: const EdgeInsets.fromLTRB(
        Medidas.e5,
        Medidas.e4,
        Medidas.e5,
        Medidas.e5,
      ),
      child: Column(
        children: [
          const Text(Textos.cuanto, style: Tipografia.apoyo),
          const SizedBox(height: Medidas.e2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'S/',
                style: Tipografia.montoTarjeta.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colores.textoSecundario,
                ),
              ),
              const SizedBox(width: Medidas.e3),
              Expanded(
                child: TextField(
                  controller: controlador,
                  autofocus: autofocus,
                  onChanged: alCambiar,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FormateadorSoles()],
                  style: estilo,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: estilo.copyWith(color: Colores.grisAzulado),
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: Medidas.e1,
                    ),
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colores.bordeCampo),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colores.bordeCampo),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colores.marca, width: 3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
