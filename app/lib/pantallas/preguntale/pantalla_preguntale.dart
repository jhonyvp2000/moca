import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dominio/medicion.dart';
import '../../dominio/pregunta.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Pregúntale a Moca» (entrega 74): el dueño pregunta por su negocio y la
/// IA responde con las cifras que el servidor ya calculó. La conversación
/// no se guarda: al cerrar, empieza de nuevo.
class PantallaPreguntale extends ConsumerStatefulWidget {
  const PantallaPreguntale({super.key});

  static const claveCampo = Key('pregunta');
  static const claveEnviar = Key('enviar-pregunta');

  @override
  ConsumerState<PantallaPreguntale> createState() => _EstadoPreguntale();
}

class _Mensaje {
  const _Mensaje.mio(this.texto) : deMoca = false, enlace = null, cuando = null;
  const _Mensaje.deMoca(this.texto, {this.enlace, this.cuando}) : deMoca = true;

  final String texto;
  final bool deMoca;
  final EnlaceRespuesta? enlace;

  /// Hasta cuándo eran las cifras.
  final DateTime? cuando;

  static List<_Mensaje> de(Intercambio i) => [
    _Mensaje.mio(i.pregunta),
    _Mensaje.deMoca(
      i.respuesta.texto,
      enlace: i.respuesta.enlace,
      cuando: i.cuando,
    ),
  ];
}

class _EstadoPreguntale extends ConsumerState<PantallaPreguntale> {
  final _pregunta = TextEditingController();
  final _desplazar = ScrollController();
  final _mensajes = <_Mensaje>[];

  /// Lo guardado en el teléfono más lo de ahora (entrega 90).
  final _intercambios = <Intercambio>[];
  bool _esperando = false;
  bool _sinSenal = false;
  int? _quedan;

  @override
  void initState() {
    super.initState();
    ref.read(medicionProvider).anotar(EventoMedicion.preguntaleAbierto);
    ref.read(servicioPreguntaProvider).preguntasQueQuedan().then((n) {
      if (mounted && n != null) setState(() => _quedan = n);
    });
    // La conversación de antes, arriba de lo que se pregunte mientras carga.
    ref.read(conversacionProvider).leer().then((guardada) {
      if (!mounted || guardada.isEmpty) return;
      setState(() {
        _intercambios.insertAll(0, guardada);
        _mensajes.insertAll(0, [for (final i in guardada) ..._Mensaje.de(i)]);
      });
      _alFinal(animar: false);
    });
  }

  @override
  void dispose() {
    _pregunta.dispose();
    _desplazar.dispose();
    super.dispose();
  }

  bool get _sinPreguntas => _quedan == 0;

  Future<void> _preguntar(String texto) async {
    final pregunta = texto.trim();
    if (pregunta.isEmpty || _esperando || _sinPreguntas) return;
    setState(() {
      _mensajes.add(_Mensaje.mio(pregunta));
      _pregunta.clear();
      _esperando = true;
      _sinSenal = false;
    });
    _alFinal();
    await ref.read(medicionProvider).anotar(EventoMedicion.preguntaHecha);
    final conversacion = ref.read(conversacionProvider);
    final r = await ref
        .read(servicioPreguntaProvider)
        .preguntar(pregunta, anteriores: List.of(_intercambios));
    final ahora = ref.read(relojProvider)();
    // Solo se guarda lo que respondió Moca, no los avisos.
    if (r.respuesta case final respuesta?) {
      final intercambio = Intercambio(
        pregunta: pregunta,
        respuesta: respuesta,
        cuando: ahora,
      );
      _intercambios.add(intercambio);
      await conversacion.agregar(intercambio);
    }
    if (!mounted) return;
    setState(() {
      _esperando = false;
      if (r.quedan != null) _quedan = r.quedan;
      if (r.respuesta case final respuesta?) {
        _mensajes.add(
          _Mensaje.deMoca(
            respuesta.texto,
            enlace: respuesta.enlace,
            cuando: ahora,
          ),
        );
        return;
      }
      switch (r.error) {
        case ErrorDePregunta.sinSenal:
          // La pregunta vuelve al campo, para mandarla con señal.
          _mensajes.removeLast();
          _pregunta.text = pregunta;
          _sinSenal = true;
        case ErrorDePregunta.topeDelDia:
          _mensajes.removeLast();
          _quedan = 0;
        case ErrorDePregunta.soloDuenos:
          _mensajes.add(const _Mensaje.deMoca(Textos.preguntaleSoloDuenos));
        case ErrorDePregunta.noDisponible || ErrorDePregunta.fallo || null:
          _mensajes.add(const _Mensaje.deMoca(Textos.preguntaleNoDisponible));
      }
    });
    _alFinal();
  }

  Future<void> _borrar() async {
    final borrar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Textos.borrarConversacionTitulo),
        content: const Text(Textos.borrarConversacionTexto),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Textos.borrar),
          ),
        ],
      ),
    );
    if (borrar != true || !mounted) return;
    await ref.read(conversacionProvider).borrar();
    if (!mounted) return;
    setState(() {
      _intercambios.clear();
      _mensajes.clear();
    });
  }

  void _alFinal({bool animar = true}) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_desplazar.hasClients) return;
        if (!animar) {
          _desplazar.jumpTo(_desplazar.position.maxScrollExtent);
          return;
        }
        _desplazar.animateTo(
          _desplazar.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });

  void _abrir(EnlaceRespuesta enlace) => switch (enlace) {
    EnlaceRespuesta.historial => context.go(Rutas.historial),
    EnlaceRespuesta.informe => context.go(Rutas.informes),
    EnlaceRespuesta.teDeben => context.push(Rutas.loQueTeDeben),
    EnlaceRespuesta.debes => context.push(Rutas.loQueDebes),
    EnlaceRespuesta.cuentas => context.push(Rutas.cuentas),
    EnlaceRespuesta.misPagos => context.push(Rutas.misPagos),
  };

  static String _textoDelEnlace(EnlaceRespuesta e) => switch (e) {
    EnlaceRespuesta.historial => Textos.verEnElHistorial,
    EnlaceRespuesta.teDeben => Textos.verLoQueTeDeben,
    EnlaceRespuesta.debes => Textos.verLoQueDebes,
    EnlaceRespuesta.informe => Textos.verElInformeDelMes,
    EnlaceRespuesta.cuentas => Textos.verMisCuentas,
    EnlaceRespuesta.misPagos => Textos.verMisPagosDeMoca,
  };

  @override
  Widget build(BuildContext context) {
    final yaPregunto = _mensajes.any((m) => !m.deMoca);
    return Scaffold(
      backgroundColor: Colores.fondo,
      body: SafeArea(
        child: Column(
          children: [
            // ✕, el título y para qué sirve.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                Medidas.e4,
                Medidas.margenLateral,
                Medidas.e3,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: Textos.cerrar,
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colores.superficie,
                      minimumSize: const Size.square(
                        Medidas.objetivoTactilMinimo,
                      ),
                      side: const BorderSide(color: Colores.bordeTarjeta),
                    ),
                  ),
                  const SizedBox(width: Medidas.e3),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Textos.preguntaleAMoca,
                          style: Tipografia.tituloPantalla,
                        ),
                        Text(
                          Textos.preguntaleSubtitulo,
                          style: Tipografia.secundario,
                        ),
                      ],
                    ),
                  ),
                  if (_intercambios.isNotEmpty && !_esperando)
                    IconButton(
                      tooltip: Textos.borrarConversacion,
                      onPressed: _borrar,
                      icon: const Icon(Icons.delete_outline_rounded),
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(
                          Medidas.objetivoTactilMinimo,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _desplazar,
                padding: const EdgeInsets.fromLTRB(
                  Medidas.margenLateral,
                  Medidas.e1,
                  Medidas.margenLateral,
                  Medidas.e3,
                ),
                children: [
                  if (_sinSenal) ...[
                    const _AvisoSinSenal(),
                    const SizedBox(height: Medidas.e3),
                  ],
                  const _Burbuja.deMoca(
                    child: Text(
                      Textos.preguntaleSaludo,
                      style: Tipografia.texto,
                    ),
                  ),
                  if (!yaPregunto && !_sinPreguntas) ...[
                    const SizedBox(height: Medidas.e3),
                    const Text(Textos.pruebaCon, style: Tipografia.apoyo),
                    const SizedBox(height: Medidas.e2),
                    Wrap(
                      spacing: Medidas.e2,
                      runSpacing: Medidas.e2,
                      children: [
                        for (final s in Textos.sugerenciasDelDia(
                          ref.watch(relojProvider)(),
                        ))
                          OutlinedButton(
                            onPressed: () => _preguntar(s),
                            child: Text(s),
                          ),
                      ],
                    ),
                  ],
                  for (final m in _mensajes) ...[
                    const SizedBox(height: Medidas.e3),
                    if (m.deMoca)
                      _Burbuja.deMoca(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.texto, style: Tipografia.texto),
                            if (m.enlace case final enlace?)
                              TextButton(
                                onPressed: () => _abrir(enlace),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text('${_textoDelEnlace(enlace)} ›'),
                              ),
                            if (m.cuando case final cuando?)
                              Text(
                                Textos.conLoAnotadoHasta(
                                  cuando,
                                  ref.watch(relojProvider)(),
                                ),
                                style: Tipografia.apoyo,
                              ),
                          ],
                        ),
                      )
                    else
                      _Burbuja.mia(texto: m.texto),
                  ],
                  if (_esperando) ...[
                    const SizedBox(height: Medidas.e3),
                    const _Burbuja.deMoca(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: Medidas.e3),
                          Flexible(
                            child: Text(
                              Textos.mocaPiensa,
                              style: Tipografia.secundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_sinPreguntas) ...[
                    const SizedBox(height: Medidas.e4),
                    const _AvisoDelTope(),
                  ],
                ],
              ),
            ),
            _CampoDePregunta(
              controlador: _pregunta,
              activo: !_esperando && !_sinPreguntas,
              quedan: _quedan,
              alEnviar: () => _preguntar(_pregunta.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja.deMoca({required this.child}) : texto = null, mia = false;
  const _Burbuja.mia({required this.texto}) : child = null, mia = true;

  final Widget? child;
  final String? texto;
  final bool mia;

  @override
  Widget build(BuildContext context) {
    const radio = Radius.circular(18);
    const pico = Radius.circular(6);
    return Align(
      alignment: mia ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: mia ? Colores.marca : Colores.superficie,
            borderRadius: BorderRadius.only(
              topLeft: radio,
              topRight: radio,
              bottomLeft: mia ? radio : pico,
              bottomRight: mia ? pico : radio,
            ),
            boxShadow: mia ? null : Sombras.nivel1,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Medidas.e4,
              vertical: Medidas.e3,
            ),
            child:
                child ??
                Text(
                  texto!,
                  style: Tipografia.texto.copyWith(color: Colores.sobreMarca),
                ),
          ),
        ),
      ),
    );
  }
}

class _AvisoSinSenal extends StatelessWidget {
  const _AvisoSinSenal();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colores.avisoFondo,
      borderRadius: BorderRadius.circular(Medidas.radioMedio),
    ),
    child: const Padding(
      padding: EdgeInsets.all(Medidas.e4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colores.avisoTextoFuerte),
          SizedBox(width: Medidas.e3),
          Expanded(
            child: Text(
              Textos.preguntaleSinSenal,
              style: TextStyle(color: Colores.avisoTextoFuerte),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AvisoDelTope extends StatelessWidget {
  const _AvisoDelTope();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colores.superficie,
      borderRadius: BorderRadius.circular(Medidas.radioMedio),
      boxShadow: Sombras.nivel1,
    ),
    child: const Padding(
      padding: EdgeInsets.all(Medidas.e4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Textos.topeDePreguntas, style: Tipografia.textoFuerte),
          SizedBox(height: Medidas.e1),
          Text(Textos.topeDePreguntasDetalle, style: Tipografia.secundario),
        ],
      ),
    ),
  );
}

class _CampoDePregunta extends StatelessWidget {
  const _CampoDePregunta({
    required this.controlador,
    required this.activo,
    required this.quedan,
    required this.alEnviar,
  });

  final TextEditingController controlador;
  final bool activo;
  final int? quedan;
  final VoidCallback alEnviar;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colores.superficie,
      border: Border(top: BorderSide(color: Colores.separador)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        Medidas.e4,
        Medidas.e3,
        Medidas.e4,
        Medidas.e4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: PantallaPreguntale.claveCampo,
                  controller: controlador,
                  enabled: activo,
                  maxLength: 300,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => alEnviar(),
                  style: Tipografia.texto,
                  decoration: const InputDecoration(
                    labelText: Textos.tuPregunta,
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    hintText: Textos.escribeTuPregunta,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Medidas.e4,
                      vertical: Medidas.e3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Medidas.e2),
              IconButton.filled(
                key: PantallaPreguntale.claveEnviar,
                tooltip: Textos.enviar,
                onPressed: activo ? alEnviar : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                style: IconButton.styleFrom(minimumSize: const Size.square(48)),
              ),
            ],
          ),
          const SizedBox(height: Medidas.e2),
          Text(
            quedan == null
                ? Textos.necesitaInternet
                : Textos.preguntasQueQuedan(quedan!),
            style: Tipografia.apoyo,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
