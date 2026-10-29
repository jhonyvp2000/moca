import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/icono_trazo.dart';
import '../../comun/tarjeta.dart';
import '../../comun/videos.dart';
import '../../dominio/informe.dart';
import '../../dominio/tutoria.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import 'pdf_informe.dart';
import '../../dominio/medicion.dart';

/// S14 · Informe del mes. Sin «Lo que te deben», «Ver a quiénes», «Cerrar
/// el mes», «Usarlo para pedir crédito» ni la pregunta de la mercadería
/// (ajustes respecto al mockup).
class PantallaInforme extends ConsumerStatefulWidget {
  const PantallaInforme({super.key});

  @override
  ConsumerState<PantallaInforme> createState() => _EstadoInforme();
}

class _EstadoInforme extends ConsumerState<PantallaInforme> {
  /// Nulo: el mes en curso.
  DateTime? _mes;
  bool _armandoPdf = false;

  Future<void> _compartir(InformeMes informe) async {
    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _armandoPdf = true);
    try {
      final nombre = ref.read(resumenInicioProvider).value?.nombreNegocio ?? '';
      final ruta = await guardarPdfDelInforme(
        informe,
        nombreNegocio: nombre,
        hoy: ref.read(relojProvider)(),
      );
      await ref
          .read(compartidorProvider)
          .compartirArchivo(
            ruta,
            asunto: Textos.informeDe(
              nombreDelMes(informe.mes),
              informe.mes.year,
            ),
          );
      await ref.read(medicionProvider).anotar(EventoMedicion.pdfCompartido);
    } on Exception {
      mensajes.showSnackBar(const SnackBar(content: Text(Textos.pdfNoSeArmo)));
    } finally {
      if (mounted) setState(() => _armandoPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final informe = ref.watch(informeProvider(_mes)).value;
    if (informe == null) return const SizedBox.shrink();
    final i = informe;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          12,
          Medidas.margenLateral,
          16,
        ),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Flecha(
                    icono: Icono.volver,
                    etiqueta: Textos.mesAnterior,
                    alTocar: i.mesPrevio == null
                        ? null
                        : () => setState(() => _mes = i.mesPrevio),
                  ),
                  Semantics(
                    header: true,
                    child: Text(
                      nombreDelMesConMayuscula(i.mes),
                      style: Tipografia.tituloPantalla,
                    ),
                  ),
                  _Flecha(
                    icono: Icono.derecha,
                    etiqueta: Textos.mesSiguiente,
                    alTocar: i.mesSiguiente == null
                        ? null
                        : () => setState(() => _mes = i.mesSiguiente),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: i.sinRegistros || _armandoPdf
                    ? null
                    : () => _compartir(i),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, Medidas.objetivoTactilMinimo),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const IconoTrazo(
                  Icono.compartir,
                  color: Colores.textoPrincipal,
                  tamano: 20,
                ),
                label: Text(
                  _armandoPdf ? Textos.armandoPdf : Textos.compartirPdf,
                ),
              ),
            ],
          ),
          if (_periodo(i) case final periodo?)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 2),
              child: Text(periodo, style: Tipografia.secundario),
            ),
          const SizedBox(height: 12),
          const TarjetaPrimeraVez(
            video: VideoTutoria.informe,
            margen: EdgeInsets.only(bottom: Medidas.separacionTarjetas),
          ),
          if (i.sinRegistros)
            Tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(Textos.mesSinRegistros, style: Tipografia.texto),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push(Rutas.registrar),
                    child: const Text(Textos.registrar),
                  ),
                ],
              ),
            )
          else
            ..._contenido(i),
        ],
      ),
    );
  }

  static String? _periodo(InformeMes i) {
    if (i.desdeDia case final dia?) {
      return i.enCurso
          ? Textos.desdeElDiaHastaHoy(dia)
          : Textos.desdeElDia(dia);
    }
    return i.enCurso ? Textos.hastaHoy : null;
  }

  List<Widget> _contenido(InformeMes i) {
    final anterior = i.mesAnterior == null ? '' : nombreDelMes(i.mesAnterior!);
    final crecio = i.crecioCentimos;
    final diferencia = i.diferenciaConAnteriorCentimos;
    const separacion = SizedBox(height: Medidas.separacionTarjetas);

    return [
      // Cuánto creció o bajó la plata (entrega 14.9)
      Tarjeta(
        relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              crecio > 0
                  ? Textos.tuPlataCrecio
                  : crecio < 0
                  ? Textos.tuPlataBajo
                  : Textos.tuPlataIgual,
              style: Tipografia.textoFuerte.copyWith(
                color: Colores.textoSecundario,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatearSoles(crecio.abs()),
                maxLines: 1,
                style: Tipografia.cifra(
                  const TextStyle(
                    fontFamily: Tipografia.familia,
                    fontSize: 46,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Colores.textoPrincipal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (diferencia == null)
              const Text(Textos.primerMesConMoca, style: Tipografia.secundario)
            else
              Row(
                children: [
                  if (diferencia != 0) ...[
                    IconoTrazo(
                      diferencia > 0 ? Icono.entro : Icono.salio,
                      color: Colores.textoPrincipal,
                      tamano: 18,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      diferencia > 0
                          ? Textos.masQueEn(
                              formatearSoles(diferencia),
                              anterior,
                            )
                          : diferencia < 0
                          ? Textos.menosQueEn(
                              formatearSoles(-diferencia),
                              anterior,
                            )
                          : Textos.igualQueEn(anterior),
                      style: Tipografia.cifra(Tipografia.textoFuerte),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              Textos.entroSalio(
                formatearSoles(i.entroCentimos),
                formatearSoles(i.salioCentimos),
              ),
              style: Tipografia.cifra(Tipografia.secundario),
            ),
          ],
        ),
      ),
      separacion,

      // Cómo se movió la plata: cuadra con el saldo
      Tarjeta(
        relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(Textos.comoSeMovio, style: Tipografia.tituloTarjeta),
            const SizedBox(height: 8),
            _Fila(
              i.desdeDia == null
                  ? Textos.empezasteElMesCon
                  : Textos.empezasteCon,
              formatearSoles(i.inicioCentimos),
            ),
            _Fila(Textos.masEntro, formatearSoles(i.entroCentimos)),
            if (i.aportesCentimos > 0)
              _Fila(
                Textos.masPusisteDeTuBolsillo,
                formatearSoles(i.aportesCentimos),
              ),
            _Fila(
              Textos.menosSalioDelNegocio,
              formatearSoles(i.salioCentimos),
              salida: true,
            ),
            _Fila(
              Textos.menosRetirasteParaTi,
              formatearSoles(i.retirosCentimos),
              salida: true,
            ),
            if (i.ajustesCentimos != 0)
              _Fila(
                i.ajustesCentimos > 0
                    ? Textos.masSobroEnElArqueo
                    : Textos.menosFaltoEnElArqueo,
                formatearSoles(i.ajustesCentimos.abs()),
                salida: i.ajustesCentimos < 0,
              ),
            const Divider(),
            _Fila(
              i.enCurso ? Textos.tienesHoy : Textos.terminasteElMesCon,
              formatearSoles(i.finCentimos),
              fuerte: true,
            ),
            const SizedBox(height: 8),
            const Text(Textos.cuentasDePlata, style: Tipografia.secundario),
          ],
        ),
      ),
      separacion,

      // En qué se fue la plata
      Tarjeta(
        relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(Textos.enQueSeFue, style: Tipografia.tituloTarjeta),
            const SizedBox(height: 8),
            if (i.gastos.isEmpty)
              const Text(Textos.sinGastos, style: Tipografia.secundario)
            else
              for (final (n, g) in i.gastos.indexed)
                _Barra(
                  nombre: g.nombre ?? Textos.loDemas,
                  centimos: g.centimos,
                  proporcion: g.centimos / i.gastos.first.centimos,
                  primera: n == 0,
                ),
            if (i.mesAnterior != null && i.gastos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                switch (i.cambio) {
                  final c? when c.centimos > 0 => Textos.subioFrente(
                    c.nombre,
                    formatearSoles(c.centimos),
                    anterior,
                  ),
                  final c? => Textos.bajoFrente(
                    c.nombre,
                    formatearSoles(-c.centimos),
                    anterior,
                  ),
                  null => Textos.casiNadaCambio(anterior),
                },
                style: Tipografia.cifra(
                  Tipografia.textoFuerte.copyWith(color: Colores.azulOscuro),
                ),
              ),
            ],
          ],
        ),
      ),
      separacion,

      // Lo que debes
      Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(Textos.loQueDebesTitulo, style: Tipografia.secundario),
            Text(
              formatearSoles(i.loQueDebesCentimos),
              style: Tipografia.cifra(
                Tipografia.tituloPantalla.copyWith(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
      if (i.confianza case final c?) ...[
        separacion,
        Tarjeta(
          relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _Confianza(confianza: c),
        ),
      ],
      if (i.advertenciaMercaderia) ...[
        separacion,
        const TarjetaMoca(texto: Textos.advertenciaMercaderia),
      ],
    ];
  }
}

class _Flecha extends StatelessWidget {
  const _Flecha({
    required this.icono,
    required this.etiqueta,
    required this.alTocar,
  });

  final Icono icono;
  final String etiqueta;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: etiqueta,
      onPressed: alTocar,
      constraints: const BoxConstraints.tightFor(
        width: Medidas.objetivoTactilMinimo,
        height: Medidas.objetivoTactilMinimo,
      ),
      icon: IconoTrazo(
        icono,
        color: alTocar == null
            ? Colores.bordeBotonSecundario
            : Colores.textoPrincipal,
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(
    this.etiqueta,
    this.monto, {
    this.fuerte = false,
    this.salida = false,
  });

  final String etiqueta;
  final String monto;
  final bool fuerte;

  /// El monto de una salida va en rojo sobrio (entrega 14.9.2).
  final bool salida;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: fuerte ? Tipografia.textoFuerte : Tipografia.secundario,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            monto,
            style: Tipografia.cifra(
              Tipografia.textoFuerte.copyWith(
                fontWeight: FontWeight.w700,
                color: salida ? Colores.salida : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.nombre,
    required this.centimos,
    required this.proporcion,
    required this.primera,
  });

  final String nombre;
  final int centimos;
  final double proporcion;
  final bool primera;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: primera ? Tipografia.textoFuerte : Tipografia.texto,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: proporcion.clamp(0.04, 1),
                minHeight: 12,
                backgroundColor: Colores.separador,
                color: primera ? Colores.marca : Colores.bordeCampo,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Ancho fijo para que las barras queden alineadas.
          SizedBox(
            width: 84,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                formatearSoles(centimos),
                style: Tipografia.cifra(
                  Tipografia.textoFuerte.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Confianza extends StatelessWidget {
  const _Confianza({required this.confianza});

  final ConfianzaDelMes confianza;

  static const colores = [
    Colores.marca,
    Colores.azulMedio,
    Colores.grisAzulado,
  ];

  @override
  Widget build(BuildContext context) {
    final c = confianza;
    final partes = [
      (c.conComprobante, Textos.conComprobante(c.conComprobante)),
      (c.conFoto, Textos.conFoto(c.conFoto)),
      (c.sinPapel, Textos.sinPapel(c.sinPapel)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(Textos.queTanSeguras, style: Tipografia.tituloTarjeta),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (final (n, (pct, _)) in partes.indexed)
                  if (pct > 0)
                    Expanded(
                      flex: pct,
                      child: Container(
                        margin: EdgeInsets.only(right: n < 2 ? 2 : 0),
                        color: colores[n],
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final (n, (_, texto)) in partes.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colores[n],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(texto, style: Tipografia.cifra(Tipografia.texto)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
