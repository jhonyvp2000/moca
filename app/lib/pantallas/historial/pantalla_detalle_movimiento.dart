import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/icono_trazo.dart';
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
import 'hoja_pagar.dart';

/// «Lunes 13 de octubre · 3:45 p. m.».
String fechaYHora(DateTime f) {
  final fecha = formatearFechaLarga(f);
  return '${fecha[0].toUpperCase()}${fecha.substring(1)} · '
      '${formatearHora(f.hour * 60 + f.minute)}';
}

/// Detalle de un movimiento (estado no dibujado, aprobado el 13-10-2026):
/// sus datos, el comprobante, «Ya lo pagué», «Corregir», «Deshacer» y la
/// lista «Cambios» de la bitácora.
class PantallaDetalleMovimiento extends ConsumerStatefulWidget {
  const PantallaDetalleMovimiento({super.key, required this.id});

  final String id;

  @override
  ConsumerState<PantallaDetalleMovimiento> createState() =>
      _EstadoDetalleMovimiento();
}

class _EstadoDetalleMovimiento
    extends ConsumerState<PantallaDetalleMovimiento> {
  /// Cambia al registro nuevo después de una corrección.
  late String _id = widget.id;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    // El aviso «Guardado · Deshacer» taparía los botones; aquí ya está
    // «Deshacer este registro».
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    });
  }

  Future<void> _corregir(DetalleMovimiento d) async {
    final nuevo = await context.push<String>(Rutas.corregir, extra: d);
    if (nuevo != null && mounted) setState(() => _id = nuevo);
  }

  Future<void> _deshacer(DetalleMovimiento d) async {
    final saldo = d.saldoSiSeDeshaceCentimos;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Textos.deshacerTitulo),
        content: Text(
          saldo == null
              ? Textos.deshacerSinSaldo
              : Textos.deshacerConSaldo(
                  Textos.nombreCuenta(d.fila.cuenta),
                  formatearSoles(saldo),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Textos.deshacer),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    setState(() => _ocupado = true);
    final mensajes = ScaffoldMessenger.of(context);
    try {
      await ref.read(repositorioHistorialProvider).deshacer(d.fila.id);
      if (!mounted) return;
      context.pop();
      mensajes
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(Textos.registroDeshecho)));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _pagar(DetalleMovimiento d) async {
    final mensajes = ScaffoldMessenger.of(context);
    final resultado = await mostrarHojaPagar(context, d);
    if (resultado == null) return;
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            Textos.pagadoAhoraTienes(
              formatearSoles(resultado.saldoCentimos),
              Textos.nombreCuenta(resultado.cuenta),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(detalleMovimientoProvider(_id)).value;
    if (d == null) {
      return Scaffold(
        body: SafeArea(
          child: EncabezadoConVolver(
            titulo: Textos.tituloDetalle,
            alVolver: () => context.pop(),
          ),
        ),
      );
    }
    final f = d.fila;
    final activo = d.vigente && !_ocupado;
    // Quién puede corregir, deshacer o pagar esto (entrega 20).
    final hoy = ref.watch(relojProvider)();
    final anotado = f.anotadoEn ?? f.fecha;
    final puedeCambiar =
        (ref.watch(permisosProvider).value ?? Permisos.delDueno).puedeCambiar(
          deOtro: f.deOtro,
          delDia:
              anotado.year == hoy.year &&
              anotado.month == hoy.month &&
              anotado.day == hoy.day,
        );

    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.tituloDetalle,
        alVolver: () => context.pop(),
      ),
      contenido: [
        Tarjeta(
          relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  montoConSigno(f.tipo, f.montoCentimos),
                  style: Tipografia.cifra(
                    Tipografia.tituloPantalla.copyWith(
                      fontSize: 32,
                      color: colorDelMonto(f.tipo),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tituloDeFila(f),
                style: Tipografia.tituloTarjeta.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 2),
              Text(fechaYHora(f.fecha), style: Tipografia.secundario),
              if (f.deOtro)
                Text(
                  Textos.loAnoto(f.autorNombre, f.autorRol),
                  style: Tipografia.secundario,
                ),
            ],
          ),
        ),
        if (!d.vigente) ...[
          const SizedBox(height: Medidas.separacionTarjetas),
          const Aviso(texto: Textos.yaNoCuenta),
        ] else if (f.loDebes) ...[
          const SizedBox(height: Medidas.separacionTarjetas),
          const Aviso(texto: Textos.todaviaLoDebes),
        ],
        if (f.porSubir) ...[
          const SizedBox(height: Medidas.separacionTarjetas),
          const FranjaInformativa(texto: Textos.guardadoPorSubir),
        ],
        const SizedBox(height: Medidas.separacionTarjetas),
        if (d.ajuste case final a?) ...[
          const FranjaInformativa(texto: Textos.ajusteExplicacion),
          const SizedBox(height: Medidas.separacionTarjetas),
          _TarjetaDeFilas(
            filas: [
              (Textos.etiquetaQueFue, Textos.ajusteDelArqueo),
              (Textos.etiquetaCuenta, Textos.nombreCuenta(f.cuenta)),
              (
                Textos.etiquetaMotivo,
                a.motivo == null
                    ? Textos.motivoCuadre
                    : Textos.motivoArqueo(a.motivo!),
              ),
              (
                Textos.etiquetaMocaCalculaba,
                formatearSolesComprobante(a.calculadoCentimos),
              ),
              (
                Textos.etiquetaContaste,
                formatearSolesComprobante(a.contadoCentimos),
              ),
            ],
          ),
        ] else
          _Datos(detalle: d),
        if (d.comprobante case final c?) ...[
          const _Subtitulo(Textos.etiquetaComprobante),
          _Comprobante(comprobante: c),
        ],
        const _Subtitulo(Textos.cambios),
        _Cambios(cambios: d.cambios),
      ],
      acciones: [
        // Un ajuste del arqueo se ve, pero no se corrige ni se deshace.
        if (puedeCambiar && d.vigente && d.ajuste == null && f.loDebes)
          FilledButton(
            onPressed: activo ? () => _pagar(d) : null,
            child: const Text(Textos.yaLoPague),
          ),
        if (puedeCambiar && d.vigente && d.ajuste == null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: activo ? () => _corregir(d) : null,
                  child: const Text(Textos.corregir),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: activo ? () => _deshacer(d) : null,
                  child: const Text(
                    Textos.deshacerRegistro,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Franja azul clara para avisos que no piden nada (el ámbar es para lo que
/// hay que atender).
class FranjaInformativa extends StatelessWidget {
  const FranjaInformativa({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colores.tinteAzul,
        borderRadius: BorderRadius.circular(Medidas.radioBoton),
      ),
      child: Text(
        texto,
        style: Tipografia.secundario.copyWith(color: Colores.azulOscuro),
      ),
    );
  }
}

class _Subtitulo extends StatelessWidget {
  const _Subtitulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
      child: Semantics(
        header: true,
        child: Text(texto, style: Tipografia.tituloTarjeta),
      ),
    );
  }
}

/// Filas de etiqueta y valor separadas por una línea.
class _TarjetaDeFilas extends StatelessWidget {
  const _TarjetaDeFilas({required this.filas});

  final List<(String, String)> filas;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      relleno: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, (etiqueta, valor)) in filas.indexed)
            Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: i < filas.length - 1
                  ? const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colores.separador),
                      ),
                    )
                  : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta, style: Tipografia.secundario),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      valor,
                      textAlign: TextAlign.right,
                      style: Tipografia.textoFuerte,
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

class _Datos extends StatelessWidget {
  const _Datos({required this.detalle});

  final DetalleMovimiento detalle;

  @override
  Widget build(BuildContext context) {
    final d = detalle;
    final f = d.fila;
    final pago = d.fechaPago;
    return _TarjetaDeFilas(
      filas: [
        (Textos.etiquetaQueFue, Textos.nombreTipo(f.tipo)),
        (Textos.etiquetaCuenta, Textos.nombreCuenta(f.cuenta)),
        if (f.categoria case final categoria?)
          (Textos.etiquetaCategoria, categoria),
        if (f.nota case final nota?) (Textos.etiquetaNota, nota),
        (Textos.etiquetaComoSeAnoto, Textos.comoSeAnoto(d.fuente)),
        if (d.comprobante != null)
          (
            Textos.etiquetaPago,
            f.loDebes
                ? Textos.loDebes
                : pago != null && !_mismoDia(pago, f.fecha)
                ? Textos.pagadoEl(formatearDiaYMes(pago))
                : Textos.pagado,
          ),
      ],
    );
  }

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Comprobante extends StatelessWidget {
  const _Comprobante({required this.comprobante});

  final ComprobanteVista comprobante;

  void _verFoto(BuildContext context, File archivo) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colores.textoPrincipal,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.file(archivo, fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Medidas.margenLateral),
                child: BotonVolver(
                  icono: Icono.cerrar,
                  alTocar: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = comprobante;
    final ruta = c.rutaImagen;
    final archivo = ruta == null ? null : File(ruta);
    final hayFoto = archivo != null && archivo.existsSync();
    final numero = [c.serie, c.numero].whereType<String>().join('-');
    final miniatura = Container(
      width: 64,
      height: 84,
      decoration: BoxDecoration(
        color: Colores.fondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colores.bordeCampo),
      ),
      clipBehavior: Clip.antiAlias,
      child: hayFoto
          ? Image.file(archivo, fit: BoxFit.cover)
          : Center(
              child: IconoTrazo(
                c.origen == OrigenLectura.qr ? Icono.qr : Icono.camara,
                color: Colores.textoSecundario,
                tamano: 28,
              ),
            ),
    );

    return Tarjeta(
      relleno: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hayFoto)
            Semantics(
              button: true,
              label: Textos.verFoto,
              child: InkWell(
                onTap: () => _verFoto(context, archivo),
                child: miniatura,
              ),
            )
          else
            miniatura,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.emisorNombre case final nombre?)
                  Text(nombre, style: Tipografia.textoFuerte),
                if (c.emisorIdentificacion case final ruc?)
                  Text(Textos.rucDe(ruc), style: Tipografia.secundario),
                if (c.tipo != null || numero.isNotEmpty)
                  Text(
                    [
                      c.tipo,
                      numero,
                    ].whereType<String>().where((x) => x.isNotEmpty).join(' '),
                    style: Tipografia.secundario,
                  ),
                if (c.fechaEmision case final fecha?)
                  Text(formatearDiaYMes(fecha), style: Tipografia.secundario),
                const SizedBox(height: 6),
                Text(
                  '${Textos.total} ${formatearSolesComprobante(c.totalCentimos)}',
                  style: Tipografia.cifra(Tipografia.textoFuerte),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cambios extends StatelessWidget {
  const _Cambios({required this.cambios});

  final List<Cambio> cambios;

  static String _valor(CampoMovimiento campo, Object? v) => switch (campo) {
    CampoMovimiento.tipo => v is TipoMovimiento ? Textos.nombreTipo(v) : '',
    CampoMovimiento.monto => v is int ? formatearSolesComprobante(v) : '',
    CampoMovimiento.cuenta => v is TipoCuenta ? Textos.nombreCuenta(v) : '',
    CampoMovimiento.categoria => v is String ? v : Textos.sinCategoria,
    CampoMovimiento.nota => v is String ? '«$v»' : Textos.sinNota,
  };

  static String _campo(CampoCambiado c) {
    final antes = _valor(c.campo, c.anterior);
    final despues = _valor(c.campo, c.nuevo);
    return switch (c.campo) {
      CampoMovimiento.tipo => Textos.cambiasteTipo(antes, despues),
      CampoMovimiento.monto => Textos.cambiasteMonto(antes, despues),
      CampoMovimiento.cuenta => Textos.cambiasteCuenta(antes, despues),
      CampoMovimiento.categoria => Textos.cambiasteCategoria(antes, despues),
      CampoMovimiento.nota => Textos.cambiasteNota(antes, despues),
    };
  }

  static List<String> _lineas(Cambio c) => switch (c) {
    CambioCreado(:final fuente) => [Textos.anotado(fuente)],
    CambioCorregido(:final campos) =>
      campos.isEmpty
          ? [Textos.corregisteSinCambios]
          : [for (final campo in campos) _campo(campo)],
    CambioPagado(:final cuenta, :final fechaPago) => [
      Textos.pagaste(Textos.nombreCuenta(cuenta), formatearDiaYMes(fechaPago)),
    ],
    CambioDeshecho() => [Textos.deshiciste],
  };

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      relleno: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, cambio) in cambios.indexed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: i < cambios.length - 1
                  ? const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colores.separador),
                      ),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final linea in _lineas(cambio))
                    Text(linea, style: Tipografia.textoFuerte),
                  const SizedBox(height: 2),
                  Text(
                    '${fechaYHora(cambio.fecha)} · ${Textos.autorTu}',
                    style: Tipografia.secundario,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
