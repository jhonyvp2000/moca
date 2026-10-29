import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/campo_monto.dart';
import '../../comun/estructura.dart';
import '../../comun/icono_trazo.dart';
import '../../comun/isotipo.dart';
import '../../comun/opciones.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/modelos.dart';
import '../../dominio/movimientos.dart';
import '../../dominio/voz.dart';
import '../../inyeccion.dart';
import '../../pais/peru/categorias.dart';
import '../../pais/peru/formato.dart';
import '../../pais/peru/interprete_voz.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import '../registrar/confirmacion.dart';
import '../registrar/franja_sin_senal.dart';
import '../../dominio/medicion.dart';

/// En qué modo se abre la voz.
enum ModoVoz {
  /// «Anotar mi primera venta» (antes del alta): solo venta del día.
  primeraVenta,

  /// «Anotar la venta de hoy»: si no se dice otra cosa, es venta.
  ventaDelDia,

  /// «Decirlo con voz» en Registrar: Moca deduce si entró o salió.
  libre,
}

enum _Fase {
  explicandoMicrofono,
  preparando,
  escuchando,
  sinPermiso,
  noDisponible,
  noEntendio,
  revisando,
}

/// S07 · Venta de hoy por voz, y S18 · Voz con duda.
class PantallaVoz extends ConsumerStatefulWidget {
  const PantallaVoz({super.key, required this.modo});

  final ModoVoz modo;

  @override
  ConsumerState<PantallaVoz> createState() => _EstadoVoz();
}

class _EstadoVoz extends ConsumerState<PantallaVoz> {
  _Fase _fase = _Fase.preparando;
  String _parcial = '';
  LecturaVoz _lectura = LecturaVoz.vacia;
  StreamSubscription<EventoVoz>? _escucha;
  ReconocedorVoz? _reconocedor;
  bool _guardando = false;
  final _otroMonto = TextEditingController();
  bool _escribiendoMonto = false;

  bool get _esVenta => widget.modo != ModoVoz.libre;

  /// Para medir una sola vez que Moca dudó del monto.
  bool _dudaMedida = false;

  @override
  void initState() {
    super.initState();
    if (_esVenta) {
      ref.read(medicionProvider).anotar(EventoMedicion.ventaAbierta, {
        'modo': 'voz',
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _empezar());
  }

  @override
  void dispose() {
    _escucha?.cancel();
    _reconocedor?.detener();
    _otroMonto.dispose();
    super.dispose();
  }

  Future<void> _empezar() async {
    final explicado = await ref
        .read(repositorioAjustesProvider)
        .microfonoExplicado();
    if (!mounted) return;
    if (!explicado && ref.read(fraseElegidaProvider) == null) {
      setState(() => _fase = _Fase.explicandoMicrofono);
      return;
    }
    await _escuchar();
  }

  Future<void> _aceptarMicrofono() async {
    await ref.read(repositorioAjustesProvider).marcarMicrofonoExplicado();
    await _escuchar();
  }

  Future<void> _escuchar() async {
    setState(() {
      _fase = _Fase.preparando;
      _parcial = '';
      _lectura = LecturaVoz.vacia;
      _escribiendoMonto = false;
    });
    final reconocedor = ref.read(reconocedorVozProvider);
    _reconocedor = reconocedor;
    final disponible = await reconocedor.preparar();
    if (!mounted) return;
    if (disponible != DisponibilidadVoz.disponible) {
      setState(
        () => _fase = disponible == DisponibilidadVoz.sinPermiso
            ? _Fase.sinPermiso
            : _Fase.noDisponible,
      );
      return;
    }
    setState(() => _fase = _Fase.escuchando);
    await _escucha?.cancel();
    _escucha = reconocedor.escuchar().listen(_alOir);
  }

  void _alOir(EventoVoz evento) {
    if (!mounted) return;
    switch (evento) {
      case VozParcial(:final texto):
        setState(() => _parcial = texto);
      case VozFinal(:final alternativas):
        // La frase de ejemplo del operador se usa una sola vez.
        ref.read(fraseElegidaProvider.notifier).usar();
        final lectura = interpretarVoz(
          alternativas,
          soloVenta: widget.modo == ModoVoz.primeraVenta,
        ).conPlinDelNegocio({...ref.read(tiposDeCuentaProvider)});
        setState(() {
          _lectura = widget.modo == ModoVoz.ventaDelDia && lectura.tipo == null
              ? lectura.conTipo(TipoMovimiento.ingreso)
              : lectura;
          _parcial = lectura.textoDicho;
          _fase = lectura.entendida ? _Fase.revisando : _Fase.noEntendio;
        });
      case VozFallida(:final motivo):
        setState(
          () => _fase = switch (motivo) {
            FalloVoz.sinPermiso => _Fase.sinPermiso,
            FalloVoz.noDisponible => _Fase.noDisponible,
            FalloVoz.nadaQueEscuchar => _Fase.noEntendio,
          },
        );
    }
  }

  Future<void> _tocarMicrofono() async {
    if (_fase == _Fase.escuchando) {
      await _reconocedor?.detener();
    } else {
      await _escuchar();
    }
  }

  // --- Escribirlo en lugar de decirlo ---------------------------------------

  /// «Prefiero escribirlo» y «Corregir un dato»: la venta va a la venta
  /// escrita; lo demás, a «Escribirlo». Con los datos que ya se tengan.
  void _escribir({Map<TipoCuenta, int>? montos, BorradorMovimiento? borrador}) {
    final esVenta = montos != null || (borrador == null && _esVenta);
    if (widget.modo == ModoVoz.primeraVenta) {
      context.go(Rutas.ventaDeHoy, extra: montos);
    } else if (esVenta) {
      context.pushReplacement(Rutas.ventaDelDia, extra: montos);
    } else {
      context.pushReplacement(
        Rutas.escribir,
        extra: borrador ?? const BorradorMovimiento(),
      );
    }
  }

  Map<TipoCuenta, int> get _montosPorCuenta {
    final montos = <TipoCuenta, int>{};
    for (final p in _lectura.partidas) {
      final cuenta = p.cuenta ?? TipoCuenta.efectivo;
      montos[cuenta] = (montos[cuenta] ?? 0) + p.centimos;
    }
    return montos;
  }

  bool get _esVentaDelDia =>
      _lectura.tipo == TipoMovimiento.ingreso &&
      _lectura.categoria == categoriaVentaDelDia;

  void _corregir(List<CategoriaVista> categorias) {
    ref.read(medicionProvider).anotar(EventoMedicion.vozCorregida);
    if (_esVentaDelDia || widget.modo == ModoVoz.primeraVenta) {
      _escribir(montos: _montosPorCuenta);
      return;
    }
    final partida = _lectura.partidas.isEmpty ? null : _lectura.partidas.first;
    _escribir(
      borrador: BorradorMovimiento(
        tipo: _lectura.tipo,
        montoCentimos: partida?.centimos,
        cuenta: partida?.cuenta,
        categoriaId: _idCategoria(categorias),
      ),
    );
  }

  String? _idCategoria(List<CategoriaVista> categorias) {
    for (final c in categorias) {
      if (c.nombre == _lectura.categoria) return c.id;
    }
    return null;
  }

  // --- Guardar --------------------------------------------------------------

  Future<void> _guardar(List<CategoriaVista> categorias) async {
    if (_guardando) return;
    setState(() => _guardando = true);
    try {
      if (widget.modo == ModoVoz.primeraVenta) {
        await ref
            .read(repositorioPrimerDiaProvider)
            .anotarPrimeraVenta(_montosPorCuenta, fuente: Fuente.voz);
        await ref.read(medicionProvider).anotar(EventoMedicion.ventaGuardada, {
          'modo': 'voz',
        });
        // Al guardar, la app pasa sola a «Guarda tu avance».
        return;
      }
      final repo = ref.read(repositorioMovimientosProvider);
      final Guardado guardado;
      if (_esVentaDelDia) {
        guardado = await repo.anotarVentaDelDia(
          _montosPorCuenta,
          fuente: Fuente.voz,
        );
        await ref.read(medicionProvider).anotar(EventoMedicion.ventaGuardada, {
          'modo': 'voz',
        });
      } else {
        final movimientos = [
          for (final p in _lectura.partidas)
            NuevoMovimiento(
              tipo: _lectura.tipo!,
              montoCentimos: p.centimos,
              cuenta: p.cuenta!,
              categoriaId: _idCategoria(categorias),
              fuente: Fuente.voz,
            ),
        ];
        // Moca pregunta antes de dejar una cuenta en negativo.
        for (final m in movimientos) {
          final quedaria = await repo.saldoSiSeGuarda(m);
          if (quedaria < 0 && mounted) {
            if (!await _preguntarNegativo(m.cuenta, quedaria)) return;
          }
        }
        final ids = <String>[];
        var tienesHoy = 0;
        for (final m in movimientos) {
          final g = await repo.registrar(m);
          ids.addAll(g.ids);
          tienesHoy = g.tienesHoyCentimos;
        }
        guardado = Guardado(ids: ids, tienesHoyCentimos: tienesHoy);
      }
      if (!mounted) return;
      final mensajes = ScaffoldMessenger.of(context);
      context.pop();
      mostrarGuardado(mensajes, guardado, repo.deshacer);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<bool> _preguntarNegativo(TipoCuenta cuenta, int quedaria) async {
    final seguir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Textos.quedariaNegativoTitulo),
        content: Text(
          Textos.quedariaNegativo(
            Textos.nombreCuenta(cuenta),
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

  // --- Pantalla ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tipo = _lectura.tipo;
    final categorias = tipo == null || tipo.delDueno
        ? const <CategoriaVista>[]
        : ref.watch(categoriasProvider(tipo)).value ?? const <CategoriaVista>[];
    final validas = {for (final c in categorias) c.nombre};
    final pregunta = _fase == _Fase.revisando
        ? siguientePregunta(
            _lectura,
            categoriasValidas: widget.modo == ModoVoz.primeraVenta
                ? {categoriaVentaDelDia}
                : validas,
            cuentasValidas: {...ref.watch(tiposDeCuentaProvider)},
          )
        : null;
    final completo = _fase == _Fase.revisando && pregunta == null;

    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: _esVenta ? Textos.ventaDeHoy : Textos.registroPorVoz,
        alVolver: () => widget.modo == ModoVoz.primeraVenta
            ? context.go(Rutas.bienvenida)
            : context.pop(),
      ),
      contenido: [
        const FranjaSinSenal(),
        _TarjetaMicrofono(
          fase: _fase,
          textoDicho: _parcial,
          alTocar: _fase == _Fase.explicandoMicrofono ? null : _tocarMicrofono,
        ),
        const SizedBox(height: 16),
        ..._detalle(pregunta, categorias),
      ],
      acciones: [
        if (_fase == _Fase.explicandoMicrofono)
          FilledButton(
            onPressed: _aceptarMicrofono,
            child: const Text(Textos.empezarAEscuchar),
          ),
        if (completo)
          FilledButton(
            onPressed: _guardando ? null : () => _guardar(categorias),
            child: const Text(Textos.guardar),
          ),
        if (completo)
          BotonTexto(
            texto: Textos.corregirUnDato,
            alTocar: () => _corregir(categorias),
          ),
        if (_fase == _Fase.noEntendio)
          FilledButton(
            onPressed: _escuchar,
            child: const Text(Textos.decirloOtraVez),
          ),
        if (!completo)
          BotonTexto(
            texto: Textos.prefieroEscribirlo,
            alTocar: () => _escribir(),
          ),
      ],
    );
  }

  List<Widget> _detalle(
    PreguntaVoz? pregunta,
    List<CategoriaVista> categorias,
  ) {
    switch (_fase) {
      case _Fase.explicandoMicrofono:
        return const [TarjetaMoca(texto: Textos.microfonoExplicacion)];
      case _Fase.preparando || _Fase.escuchando:
        return const [
          Text(
            Textos.ejemploQueDecir,
            textAlign: TextAlign.center,
            style: Tipografia.secundario,
          ),
        ];
      case _Fase.sinPermiso:
        return const [Aviso(texto: Textos.sinPermisoMicrofono)];
      case _Fase.noDisponible:
        return const [Aviso(texto: Textos.vozNoDisponible)];
      case _Fase.noEntendio:
        return const [TarjetaMoca(texto: Textos.noTeEntendi)];
      case _Fase.revisando:
        return [
          // Un préstamo no es venta (entrega 14.14).
          if (_lectura.prestamo) ...[
            const Aviso(texto: Textos.prestamoNoEsVenta),
            const SizedBox(height: 12),
          ],
          if (pregunta != null)
            _pregunta(pregunta, categorias)
          else
            ..._entendido(categorias),
        ];
    }
  }

  Widget _pregunta(PreguntaVoz pregunta, List<CategoriaVista> categorias) {
    switch (pregunta) {
      case PreguntaMonto(:final opciones):
        if (!_dudaMedida) {
          _dudaMedida = true;
          ref.read(medicionProvider).anotar(EventoMedicion.vozConDuda);
        }
        return _TarjetaPregunta(
          texto: Textos.noEscucheElMonto,
          pie: Textos.mocaNuncaAdivina,
          hijo: _escribiendoMonto
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GrupoMontos(
                      filas: [
                        FilaMonto(
                          etiqueta: Textos.otroMonto,
                          controlador: _otroMonto,
                          autofocus: true,
                          alCambiar: (_) => setState(() {}),
                          accionTeclado: TextInputAction.done,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: (leerSolesEnCentimos(_otroMonto.text) ?? 0) > 0
                          ? () => setState(
                              () => _lectura = _lectura.conMonto(
                                leerSolesEnCentimos(_otroMonto.text)!,
                              ),
                            )
                          : null,
                      child: const Text(Textos.confirmarMonto),
                    ),
                  ],
                )
              : Opciones<int>(
                  opciones: {
                    for (final o in opciones) o: formatearSolesComprobante(o),
                    -1: Textos.otroMonto,
                  },
                  elegida: null,
                  alElegir: (o) => setState(() {
                    if (o < 0) {
                      _escribiendoMonto = true;
                    } else {
                      _lectura = _lectura.conMonto(o);
                    }
                  }),
                ),
        );
      case PreguntaTipo():
        return _TarjetaPregunta(
          texto: Textos.entroOSalio,
          hijo: Opciones<TipoMovimiento>(
            opciones: const {
              TipoMovimiento.ingreso: Textos.entro,
              TipoMovimiento.egreso: Textos.salio,
              TipoMovimiento.retiro: Textos.retiroParaMi,
              TipoMovimiento.aporte: Textos.puseDeMiBolsillo,
            },
            elegida: null,
            alElegir: (t) => setState(() {
              _lectura = _lectura.conTipo(t);
              if (t == TipoMovimiento.ingreso && _esVenta) {
                _lectura = _lectura.conCategoria(categoriaVentaDelDia);
              }
            }),
          ),
        );
      case PreguntaCuenta(:final indicePartida):
        final monto = formatearSolesComprobante(
          _lectura.partidas[indicePartida].centimos,
        );
        return _TarjetaPregunta(
          texto: _lectura.tipo?.entraPlata ?? false
              ? Textos.dondeEntro(monto)
              : Textos.deDondeSalioMonto(monto),
          hijo: Opciones<TipoCuenta>(
            opciones: {
              for (final c in ref.watch(tiposDeCuentaProvider))
                c: Textos.nombreCuenta(c),
            },
            elegida: null,
            alElegir: (c) =>
                setState(() => _lectura = _lectura.conCuenta(indicePartida, c)),
          ),
        );
      case PreguntaCategoria():
        return _TarjetaPregunta(
          texto: _lectura.tipo == TipoMovimiento.ingreso
              ? Textos.deQueFue
              : Textos.enQueFue,
          hijo: Opciones<String>(
            opciones: {for (final c in categorias) c.nombre: c.nombre},
            elegida: null,
            alElegir: (nombre) =>
                setState(() => _lectura = _lectura.conCategoria(nombre)),
          ),
        );
    }
  }

  List<Widget> _entendido(List<CategoriaVista> categorias) {
    final tipo = _lectura.tipo!;
    final titulo = switch (tipo) {
      TipoMovimiento.retiro => Textos.retiroParaMi,
      TipoMovimiento.aporte => Textos.puseDeMiBolsillo,
      _ => _lectura.categoria ?? '',
    };
    final total = _lectura.partidas.fold<int>(0, (s, p) => s + p.centimos);
    return [
      Row(
        children: [
          const IconoTrazo(Icono.check, color: Colores.azulOscuro, tamano: 18),
          const SizedBox(width: 8),
          Text(
            Textos.mocaEntendio,
            style: Tipografia.etiquetaMoca.copyWith(fontSize: 14),
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (final p in _lectura.partidas) ...[
        _TarjetaPartida(
          icono: tipo.entraPlata ? Icono.entro : Icono.salio,
          titulo: titulo,
          detalle: '${Textos.nombreCuenta(p.cuenta!)} · ${Textos.loQueDijiste}',
          monto: formatearSolesComprobante(p.centimos),
        ),
        const SizedBox(height: 8),
      ],
      if (_lectura.partidas.length > 1)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tipo.entraPlata
                      ? Textos.totalQueEntroHoy
                      : Textos.totalQueSale,
                  style: Tipografia.secundario.copyWith(fontSize: 15),
                ),
              ),
              Text(
                formatearSolesComprobante(total),
                style: Tipografia.cifra(
                  Tipografia.textoFuerte.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

class _TarjetaMicrofono extends StatelessWidget {
  const _TarjetaMicrofono({
    required this.fase,
    required this.textoDicho,
    required this.alTocar,
  });

  final _Fase fase;
  final String textoDicho;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final escuchando = fase == _Fase.escuchando;
    final leyenda = switch (fase) {
      _Fase.escuchando => Textos.teEscucho,
      _Fase.preparando => Textos.preparandoMicrofono,
      _Fase.explicandoMicrofono => Textos.registroPorVoz,
      _ => Textos.tocaParaGrabarOtraVez,
    };
    return Tarjeta(
      relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Semantics(
            button: true,
            label: escuchando ? Textos.tocaParaTerminar : Textos.decirloOtraVez,
            child: Material(
              color: alTocar == null ? Colores.bordeTarjeta : Colores.marca,
              shape: CircleBorder(
                side: escuchando
                    ? const BorderSide(color: Colores.tinteAzul, width: 8)
                    : BorderSide.none,
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: alTocar,
                child: const SizedBox.square(
                  dimension: 72,
                  child: Center(
                    child: IconoTrazo(
                      Icono.microfono,
                      color: Colores.sobreMarca,
                      tamano: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            escuchando ? '$leyenda ${Textos.tocaParaTerminar}.' : leyenda,
            textAlign: TextAlign.center,
            style: Tipografia.secundario,
          ),
          if (textoDicho.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '«$textoDicho»',
              textAlign: TextAlign.center,
              style: Tipografia.texto.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Moca pregunta (S18): tarjeta de Moca con las opciones.
class _TarjetaPregunta extends StatelessWidget {
  const _TarjetaPregunta({required this.texto, required this.hijo, this.pie});

  final String texto;
  final Widget hijo;
  final String? pie;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colores.tinteAzul,
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Isotipo(tamano: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          Textos.pestanaMoca,
                          style: Tipografia.etiquetaMoca,
                        ),
                        const SizedBox(height: 2),
                        Text(texto, style: Tipografia.textoFuerte),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              hijo,
            ],
          ),
        ),
        if (pie != null) ...[
          const SizedBox(height: 10),
          Text(pie!, style: Tipografia.secundario),
        ],
      ],
    );
  }
}

class _TarjetaPartida extends StatelessWidget {
  const _TarjetaPartida({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.monto,
  });

  final Icono icono;
  final String titulo;
  final String detalle;
  final String monto;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colores.tinteAzul,
              borderRadius: BorderRadius.circular(Medidas.radioBoton),
            ),
            child: Center(
              child: IconoTrazo(icono, color: Colores.azulOscuro, tamano: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Tipografia.textoFuerte.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(detalle, style: Tipografia.secundario),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            monto,
            style: Tipografia.cifra(
              Tipografia.tituloTarjeta.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
