import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../cobro/cobro.dart';
import '../../comun/icono_trazo.dart';
import '../../comun/isotipo.dart';
import '../../comun/monto_text.dart';
import '../../comun/seccion_titulo.dart';
import '../../comun/tarjeta.dart';
import '../../comun/videos.dart';
import '../../dominio/equipo.dart';
import '../../dominio/modelos.dart';
import '../../dominio/moca.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import 'avisos.dart';
import 'tarjeta_guardar_avance.dart';
import '../../dominio/medicion.dart';

/// S16 · Moca: el resumen de la semana, que se puede escuchar, y los avisos
/// por prioridad. Sin «Pulso» ni «Pregúntale» (ajustes respecto al
/// mockup). El isotipo de la cabecera abre el ajuste oculto del operador.
class PantallaMoca extends ConsumerStatefulWidget {
  const PantallaMoca({super.key});

  /// Tiempo que hay que mantener presionado el isotipo (decisiones.md).
  static const esperaAjusteOculto = Duration(seconds: 3);

  static const claveIsotipo = Key('isotipo-moca');
  static const claveAjustes = Key('ajustes-desde-moca');
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
      await ref.read(medicionProvider).anotar(EventoMedicion.resumenEscuchado);
      await locutor.decir(texto);
    } finally {
      if (mounted) setState(() => _hablando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // El resumen y los avisos son del dueño y del contador (entrega 20).
    final permisos = ref.watch(permisosProvider).value ?? Permisos.delDueno;
    final resumen = permisos.veAvisos
        ? ref.watch(resumenSemanaProvider).value
        : null;
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
                        // Solo en el teléfono de quien registra los pagos
                        // (entrega 26.2): para los demás no hace nada.
                        (reconocedor) => reconocedor.onLongPress = () {
                          if (ref.read(cobroProvider).value?.admin ?? false) {
                            context.push(Rutas.operador);
                          }
                        },
                      ),
                },
                child: const Isotipo(
                  key: PantallaMoca.claveIsotipo,
                  tamano: 52,
                ),
              ),
              const SizedBox(width: Medidas.e3),
              // «Asistente» y el eslogan (mejora 01).
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Textos.pestanaMoca, style: Tipografia.tituloPantalla),
                    Text(Textos.eslogan, style: Tipografia.secundario),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Medidas.e4),
          const TarjetaGuardarAvance(),
          // La prueba o el pago, y la pregunta del día 10 (entrega 25).
          const TarjetaCobro(),
          const PreguntaDelPrecio(),
          if (resumen != null) _tarjetaSemana(resumen, resumenEnTexto(resumen)),
          if (permisos.veAvisos) ...[
            const SizedBox(height: Medidas.e5),
            Semantics(header: true, child: const SeccionTitulo(Textos.avisos)),
            if (avisos != null)
              avisos.isEmpty
                  // Sin avisos, un estado amable (mejora 01).
                  ? const Tarjeta(
                      child: Row(
                        children: [
                          _Circulo(
                            icono: Icons.check_rounded,
                            color: Colores.marca,
                            fondo: Colores.azul100,
                          ),
                          SizedBox(width: Medidas.e4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Textos.todoEnOrden,
                                  style: Tipografia.tituloSeccion,
                                ),
                                SizedBox(height: Medidas.e1),
                                Text(
                                  Textos.sinAvisos,
                                  style: Tipografia.secundario,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Tarjeta(
                      relleno: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Medidas.radioTarjeta,
                        ),
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
          const SeccionAprende(),
          // Ajustes también desde aquí (entrega 61): en el Inicio se abre
          // tocando el nombre del negocio.
          const SizedBox(height: Medidas.e5),
          Tarjeta(
            relleno: EdgeInsets.zero,
            child: Material(
              color: Colores.superficie,
              borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                key: PantallaMoca.claveAjustes,
                minTileHeight: Medidas.objetivoTactilMinimo + Medidas.e2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
                ),
                leading: const Icon(
                  Icons.settings_outlined,
                  color: Colores.marca,
                ),
                title: const Text(
                  Textos.ajustes,
                  style: Tipografia.textoFuerte,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colores.textoSecundario,
                ),
                onTap: () => context.push(Rutas.ajustes),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// «Tu semana» (mejora 01): tarjeta azul con lo que te quedó en grande y
  /// «Escuchar resumen» como acción.
  Widget _tarjetaSemana(ResumenSemana resumen, String texto) {
    return Container(
      padding: const EdgeInsets.all(Medidas.e5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Medidas.radioMayor),
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Colores.marca, Colores.azul400],
        ),
        boxShadow: Sombras.nivel2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Textos.tuSemanaEn(segundosDeLectura(texto)),
            style: Tipografia.tituloDestacado.copyWith(
              color: Colores.sobreMarca,
            ),
          ),
          // De qué periodo es (entrega 36). El lunes, el resumen es de la
          // semana pasada, y el dato grande lo dice.
          if (!resumen.semanaPasada)
            Text(
              Textos.deLunesAHoy,
              style: Tipografia.secundario.copyWith(
                color: Colores.sobreMarcaSuave,
              ),
            ),
          if (resumen.conMovimientos) ...[
            const SizedBox(height: Medidas.e4),
            Text(
              resumen.semanaPasada
                  ? Textos.laSemanaPasadaTeQuedo
                  : Textos.estaSemanaTeQuedo.trim(),
              style: Tipografia.texto.copyWith(color: Colores.sobreMarcaSuave),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MontoText(
                resumen.quedoCentimos,
                estilo: Tipografia.montoGrande,
                color: Colores.sobreMarca,
              ),
            ),
          ],
          const SizedBox(height: Medidas.e4),
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: _hablando ? Textos.detener : Textos.escuchar,
              child: Material(
                key: PantallaMoca.claveEscuchar,
                color: Colores.superficie,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => _escuchar(texto),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Medidas.e2,
                      Medidas.e2,
                      Medidas.e5,
                      Medidas.e2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colores.marca,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _hablando
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: Colores.sobreMarca,
                          ),
                        ),
                        const SizedBox(width: Medidas.e3),
                        Flexible(
                          child: ExcludeSemantics(
                            child: Text(
                              _hablando
                                  ? Textos.detener
                                  : Textos.escucharResumen,
                              style: Tipografia.textoFuerte.copyWith(
                                color: Colores.marca,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Medidas.e3),
          Text(
            texto,
            style: Tipografia.cifra(
              Tipografia.secundario.copyWith(color: Colores.sobreMarcaSuave),
            ),
          ),
          if (_sinVoz) ...[
            const SizedBox(height: Medidas.e2),
            Text(
              Textos.sinVozEnEspanol,
              style: Tipografia.secundario.copyWith(color: Colores.sobreMarca),
            ),
          ],
        ],
      ),
    );
  }
}

/// Un icono en un círculo de color suave.
class _Circulo extends StatelessWidget {
  const _Circulo({
    required this.icono,
    required this.color,
    required this.fondo,
  });

  final IconData icono;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
    child: Icon(icono, color: color),
  );
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
            // La prioridad con icono y color (mejora 01).
            ExcludeSemantics(
              child: _Circulo(
                icono: importante
                    ? Icons.priority_high_rounded
                    : Icons.info_outline_rounded,
                color: importante ? Colores.pendienteTexto : Colores.marca,
                fondo: importante ? Colores.pendienteFondo : Colores.azul100,
              ),
            ),
            const SizedBox(width: Medidas.e4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    textoAviso(aviso),
                    style: Tipografia.cifra(Tipografia.tituloTarjeta),
                  ),
                  const SizedBox(height: Medidas.e1),
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
