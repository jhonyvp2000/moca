import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/icono_trazo.dart';
import '../../comun/isotipo.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/modelos.dart';
import '../../dominio/moca.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import 'avisos.dart';

/// S16 · Moca: el resumen de la semana, que se puede escuchar, y los avisos
/// por prioridad. Sin «Pulso» ni «Pregúntale» (ajustes respecto al
/// mockup). El isotipo de la cabecera abre el ajuste oculto del operador.
class PantallaMoca extends ConsumerStatefulWidget {
  const PantallaMoca({super.key});

  /// Tiempo que hay que mantener presionado el isotipo (decisiones.md).
  static const esperaAjusteOculto = Duration(seconds: 3);

  static const claveIsotipo = Key('isotipo-moca');
  static const claveEscuchar = Key('escuchar-semana');

  @override
  ConsumerState<PantallaMoca> createState() => _EstadoMoca();
}

class _EstadoMoca extends ConsumerState<PantallaMoca> {
  bool _hablando = false;
  bool _sinVoz = false;

  @override
  void deactivate() {
    if (_hablando) ref.read(locutorProvider).detener();
    super.deactivate();
  }

  Future<void> _escuchar(String texto) async {
    final locutor = ref.read(locutorProvider);
    if (_hablando) {
      await locutor.detener();
      if (mounted) setState(() => _hablando = false);
      return;
    }
    if (!await locutor.disponible()) {
      if (mounted) setState(() => _sinVoz = true);
      return;
    }
    setState(() => _hablando = true);
    try {
      await locutor.decir(texto);
    } finally {
      if (mounted) setState(() => _hablando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumen = ref.watch(resumenSemanaProvider).value;
    final avisos = ref.watch(avisosProvider).value;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          16,
          Medidas.margenLateral,
          16,
        ),
        children: [
          Row(
            children: [
              RawGestureDetector(
                gestures: {
                  LongPressGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        LongPressGestureRecognizer
                      >(
                        () => LongPressGestureRecognizer(
                          duration: PantallaMoca.esperaAjusteOculto,
                        ),
                        (reconocedor) =>
                            reconocedor.onLongPress = () =>
                                context.push(Rutas.operador),
                      ),
                },
                child: const Isotipo(
                  key: PantallaMoca.claveIsotipo,
                  tamano: 40,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Textos.pestanaMoca, style: Tipografia.tituloPantalla),
                    Text(Textos.subtituloMoca, style: Tipografia.secundario),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (resumen != null) _tarjetaSemana(resumenEnTexto(resumen)),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(
              Textos.avisos,
              style: Tipografia.secundario.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (avisos != null)
            avisos.isEmpty
                ? const Tarjeta(
                    child: Text(Textos.sinAvisos, style: Tipografia.texto),
                  )
                : Tarjeta(
                    relleno: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
                      child: Material(
                        color: Colores.superficie,
                        child: Column(
                          children: [
                            for (final (i, a) in avisos.indexed)
                              _FilaAviso(
                                aviso: a,
                                conSeparador: i < avisos.length - 1,
                                alDescartar: () => ref
                                    .read(repositorioMocaProvider)
                                    .descartar(a),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _tarjetaSemana(String texto) {
    return Container(
      padding: const EdgeInsets.all(Medidas.rellenoTarjeta),
      decoration: BoxDecoration(
        color: Colores.tinteAzul,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Textos.tuSemanaEn(segundosDeLectura(texto)),
            style: Tipografia.tituloTarjeta.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Semantics(
                button: true,
                label: _hablando ? Textos.detener : Textos.escuchar,
                child: Material(
                  key: PantallaMoca.claveEscuchar,
                  color: Colores.marca,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _escuchar(texto),
                    child: SizedBox.square(
                      dimension: 52,
                      child: Center(
                        child: IconoTrazo(
                          _hablando ? Icono.detener : Icono.reproducir,
                          color: Colores.sobreMarca,
                          tamano: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ExcludeSemantics(
                child: Text(
                  _hablando ? Textos.detener : Textos.escuchar,
                  style: Tipografia.textoFuerte.copyWith(
                    color: Colores.textoSecundario,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(texto, style: Tipografia.cifra(Tipografia.texto)),
          if (_sinVoz) ...[
            const SizedBox(height: 8),
            const Text(Textos.sinVozEnEspanol, style: Tipografia.secundario),
          ],
        ],
      ),
    );
  }
}

class _FilaAviso extends StatelessWidget {
  const _FilaAviso({
    required this.aviso,
    required this.conSeparador,
    required this.alDescartar,
  });

  final Aviso aviso;
  final bool conSeparador;
  final VoidCallback alDescartar;

  @override
  Widget build(BuildContext context) {
    final importante = aviso.prioridad == PrioridadAlerta.importante;
    return InkWell(
      onTap: () => abrirAviso(context, aviso),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: conSeparador
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colores.separador)),
              )
            : null,
        child: Row(
          children: [
            importante
                ? Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                      width: 12,
                      height: 12,
                      color: Colores.avisoMarca,
                    ),
                  )
                : Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colores.bordeCampo,
                      shape: BoxShape.circle,
                    ),
                  ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    textoAviso(aviso),
                    style: Tipografia.cifra(
                      Tipografia.textoFuerte.copyWith(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    importante ? Textos.importante : Textos.paraTenerEnCuenta,
                    style: Tipografia.secundario.copyWith(
                      color: importante
                          ? Colores.avisoTexto
                          : Colores.textoSecundario,
                      fontWeight: importante
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (aviso.descartable)
                    TextButton(
                      onPressed: alDescartar,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(
                          0,
                          Medidas.objetivoTactilMinimo,
                        ),
                        foregroundColor: Colores.marca,
                        textStyle: Tipografia.textoFuerte,
                      ),
                      child: const Text(Textos.entendido),
                    ),
                ],
              ),
            ),
            const IconoTrazo(Icono.derecha, color: Colores.textoPrincipal),
          ],
        ),
      ),
    );
  }
}
