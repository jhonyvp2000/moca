import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/campo_monto.dart';
import '../../comun/estructura.dart';
import '../../comun/icono_trazo.dart';
import '../../comun/isotipo.dart';
import '../../comun/opciones.dart';
import '../../comun/videos.dart';
import '../../dominio/arqueo.dart';
import '../../dominio/equipo.dart';
import '../../dominio/tutoria.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import '../../dominio/medicion.dart';

/// S12 · Arqueo de la semana. Moca propone lo calculado por cuenta, el dueño
/// corrige lo que no coincida y explica cada diferencia con una respuesta
/// rápida (estados aprobados el 13-10-2026).
class PantallaArqueo extends ConsumerStatefulWidget {
  const PantallaArqueo({super.key});

  @override
  ConsumerState<PantallaArqueo> createState() => _EstadoArqueo();
}

class _EstadoArqueo extends ConsumerState<PantallaArqueo> {
  List<CuentaArqueo>? _cuentas;
  final _campos = <TipoCuenta, TextEditingController>{};
  final _motivos = <TipoCuenta, MotivoArqueo>{};
  final _categorias = <TipoCuenta, String>{};
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    ref.read(medicionProvider).anotar(EventoMedicion.arqueoAbierto);
    _preparar();
  }

  Future<void> _preparar() async {
    // El encargado cuenta solo sus cajas (entrega 21).
    final misCajas =
        (ref.read(permisosProvider).value ?? Permisos.delDueno).misCajas;
    final cuentas = [
      for (final c in await ref.read(repositorioArqueoProvider).preparar())
        if (misCajas == null || misCajas.contains(c.cuenta)) c,
    ];
    if (!mounted) return;
    setState(() {
      _cuentas = cuentas;
      for (final c in cuentas) {
        final propuesto = c.propuestoSoles;
        _campos[c.cuenta] = TextEditingController(
          text: propuesto == null ? '' : separarMiles(propuesto),
        );
      }
    });
  }

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Lo contado, o nulo si el campo está vacío.
  int? _contado(CuentaArqueo c) => leerSolesEnCentimos(_campos[c.cuenta]!.text);

  /// Las cuentas cuya diferencia hay que explicar.
  Iterable<CuentaArqueo> _conDiferencia(List<CuentaArqueo> cuentas) =>
      cuentas.where((c) {
        final contado = _contado(c);
        return contado != null && !c.cuadra(contado);
      });

  bool _completo(List<CuentaArqueo> cuentas) =>
      cuentas.every((c) => _contado(c) != null) &&
      _conDiferencia(cuentas).every((c) {
        final motivo = _motivos[c.cuenta];
        if (motivo == null) return false;
        if (!motivosPara(c.diferencia(_contado(c)!)).contains(motivo)) {
          return false;
        }
        return motivo != MotivoArqueo.gastoOlvidado ||
            _categorias[c.cuenta] != null;
      });

  Future<void> _guardar(List<CuentaArqueo> cuentas) async {
    if (!_completo(cuentas) || _guardando) return;
    setState(() => _guardando = true);
    try {
      final tienes = await ref.read(repositorioArqueoProvider).guardar([
        for (final c in cuentas)
          ConteoCuenta(
            cuenta: c.cuenta,
            contadoCentimos: _contado(c)!,
            motivo: _motivos[c.cuenta],
            categoriaId: _categorias[c.cuenta],
          ),
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(Textos.arqueoGuardado(formatearSoles(tienes))),
          ),
        );
      context.pop();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentas = _cuentas;
    final encabezado = EncabezadoConVolver(
      titulo: Textos.arqueoDeLaSemana,
      alVolver: () => context.pop(),
    );
    if (cuentas == null) {
      return Scaffold(body: SafeArea(child: encabezado));
    }
    final todoPuntoDePartida = cuentas.every((c) => c.puntoDePartida);

    return PantallaConAcciones(
      encabezado: encabezado,
      contenido: [
        const TarjetaPrimeraVez(
          video: VideoTutoria.arqueo,
          margen: EdgeInsets.only(bottom: 14),
        ),
        Text(
          todoPuntoDePartida
              ? Textos.arqueoPuntoDePartidaDetalle
              : Textos.arqueoDetalle,
          style: Tipografia.secundario.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colores.superficie,
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
            border: Border.all(color: Colores.bordeTarjeta),
          ),
          child: Column(
            children: [
              for (final (i, c) in cuentas.indexed) ...[
                if (i > 0) const Divider(),
                _FilaCuenta(
                  cuenta: c,
                  controlador: _campos[c.cuenta]!,
                  contado: _contado(c),
                  alCambiar: () => setState(() {}),
                ),
              ],
            ],
          ),
        ),
        for (final c in _conDiferencia(cuentas)) ...[
          const SizedBox(height: Medidas.separacionTarjetas),
          _Pregunta(
            cuenta: c,
            diferencia: c.diferencia(_contado(c)!),
            motivo: _motivos[c.cuenta],
            categoriaId: _categorias[c.cuenta],
            alElegirMotivo: (m) => setState(() => _motivos[c.cuenta] = m),
            alElegirCategoria: (id) =>
                setState(() => _categorias[c.cuenta] = id),
          ),
        ],
      ],
      acciones: [
        FilledButton(
          onPressed: _completo(cuentas) && !_guardando
              ? () => _guardar(cuentas)
              : null,
          child: const Text(Textos.guardarArqueo),
        ),
      ],
    );
  }
}

class _FilaCuenta extends StatelessWidget {
  const _FilaCuenta({
    required this.cuenta,
    required this.controlador,
    required this.contado,
    required this.alCambiar,
  });

  final CuentaArqueo cuenta;
  final TextEditingController controlador;
  final int? contado;
  final VoidCallback alCambiar;

  @override
  Widget build(BuildContext context) {
    final contado = this.contado;
    final diferencia = contado == null ? 0 : cuenta.diferencia(contado);
    final noCuadra = contado != null && !cuenta.cuadra(contado);

    final Widget estado;
    if (cuenta.puntoDePartida) {
      estado = const Text(
        Textos.tuPuntoDePartida,
        style: Tipografia.secundario,
      );
    } else if (contado == null) {
      estado = const Text(
        Textos.escribeCuantoHay,
        style: Tipografia.secundario,
      );
    } else {
      final color = noCuadra ? Colores.avisoTexto : Colores.azulOscuro;
      final monto = formatearSoles(diferencia.abs());
      estado = Row(
        children: [
          IconoTrazo(
            noCuadra ? Icono.alerta : Icono.check,
            color: color,
            tamano: 18,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              !noCuadra
                  ? Textos.cuadra
                  : diferencia < 0
                  ? Textos.faltan(monto)
                  : Textos.sobran(monto),
              style: Tipografia.cifra(
                Tipografia.secundario.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    OutlineInputBorder borde(Color color, double ancho) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Medidas.radioCampo),
      borderSide: BorderSide(color: color, width: ancho),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Textos.nombreCuenta(cuenta.cuenta),
                  style: Tipografia.tituloTarjeta,
                ),
                const SizedBox(height: 2),
                estado,
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'S/',
            style: TextStyle(
              fontFamily: Tipografia.familia,
              fontSize: 15,
              color: Colores.textoSecundario,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Semantics(
              label: Textos.nombreCuenta(cuenta.cuenta),
              child: TextField(
                controller: controlador,
                onChanged: (_) => alCambiar(),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FormateadorSoles()],
                textAlign: TextAlign.right,
                style: Tipografia.cifra(
                  Tipografia.textoFuerte.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: Tipografia.cifra(
                    Tipografia.secundario.copyWith(fontSize: 18),
                  ),
                  enabledBorder: noCuadra ? borde(Colores.avisoMarca, 2) : null,
                  focusedBorder: noCuadra ? borde(Colores.avisoMarca, 2) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La pregunta de Moca por una diferencia, con las respuestas rápidas.
class _Pregunta extends ConsumerWidget {
  const _Pregunta({
    required this.cuenta,
    required this.diferencia,
    required this.motivo,
    required this.categoriaId,
    required this.alElegirMotivo,
    required this.alElegirCategoria,
  });

  final CuentaArqueo cuenta;
  final int diferencia;
  final MotivoArqueo? motivo;
  final String? categoriaId;
  final ValueChanged<MotivoArqueo> alElegirMotivo;
  final ValueChanged<String> alElegirCategoria;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faltan = diferencia < 0;
    final monto = formatearSoles(diferencia.abs());
    final nombre = Textos.nombreCuenta(cuenta.cuenta);
    final motivos = motivosPara(diferencia);
    final elegido = motivos.contains(motivo) ? motivo : null;
    final categorias = elegido == MotivoArqueo.gastoOlvidado
        ? ref.watch(categoriasProvider(TipoMovimiento.egreso)).value
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Medidas.rellenoTarjeta),
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
                      Textos.nombreApp,
                      style: Tipografia.etiquetaMoca,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      faltan
                          ? Textos.preguntaFaltan(monto, nombre)
                          : Textos.preguntaSobran(monto, nombre),
                      style: Tipografia.cifra(Tipografia.texto),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dos respuestas por fila, como en el mockup.
          for (var i = 0; i < motivos.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 8),
            OpcionesRejilla<MotivoArqueo>(
              opciones: {
                for (final m in motivos.skip(i).take(2))
                  m: Textos.motivoArqueo(m),
              },
              elegida: elegido,
              alElegir: alElegirMotivo,
            ),
          ],
          if (categorias != null) ...[
            const SizedBox(height: 14),
            const Text(
              Textos.enQue,
              style: TextStyle(
                fontFamily: Tipografia.familia,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colores.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Opciones<String>(
              opciones: {for (final c in categorias) c.id: c.nombre},
              elegida: categoriaId,
              alElegir: alElegirCategoria,
            ),
          ],
          if (elegido != null) ...[
            const SizedBox(height: 12),
            Text(
              Textos.notaMotivo(elegido, faltan: faltan),
              style: Tipografia.secundario,
            ),
          ],
        ],
      ),
    );
  }
}
