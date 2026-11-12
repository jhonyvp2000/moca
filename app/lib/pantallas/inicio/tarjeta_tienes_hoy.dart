import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/monto_text.dart';
import '../../dominio/medicion.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Tienes hoy» (mejora 01): la tarjeta azul del Inicio, con el monto grande
/// en blanco, de qué periodo es (entrega 36), una píldora con lo de hoy y la
/// explicación detrás del ⓘ.
class TarjetaTienesHoy extends StatelessWidget {
  const TarjetaTienesHoy({
    super.key,
    required this.etiqueta,
    required this.centimos,
    required this.explicacion,
    this.ocultar = false,
    this.alOcultar,
    this.pildora,
  });

  final String etiqueta;
  final int centimos;

  /// Lo que dice el ⓘ: cómo se llega a esta cifra.
  final String explicacion;
  final bool ocultar;

  /// El ojo que oculta o muestra los montos (entrega 61); sin él, no sale.
  final VoidCallback? alOcultar;

  /// «Vendiste hoy S/ 100».
  final String? pildora;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Medidas.radioMayor),
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Colores.marca, Colores.azul400],
        ),
        boxShadow: Sombras.nivel2,
      ),
      child: Stack(
        children: [
          // El círculo claro de fondo, solo adorno.
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colores.sobreMarca.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.e6,
              Medidas.e5,
              Medidas.e3,
              Medidas.e6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            etiqueta,
                            style: Tipografia.tituloFila.copyWith(
                              color: Colores.sobreMarca,
                            ),
                          ),
                          // De qué periodo es (entrega 36): no se reinicia.
                          Text(
                            Textos.desdeQueEmpezaste,
                            style: Tipografia.secundario.copyWith(
                              color: Colores.sobreMarcaSuave,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (alOcultar case final alTocar?)
                      IconButton(
                        tooltip: ocultar
                            ? Textos.mostrarMontos
                            : Textos.ocultarMontos,
                        onPressed: alTocar,
                        icon: Icon(
                          ocultar
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colores.sobreMarca,
                        ),
                      ),
                    IconButton(
                      tooltip: Textos.queEsEstaCifra,
                      onPressed: () => _explicar(context),
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        color: Colores.sobreMarca,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Medidas.e2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ocultar
                      ? Text(
                          Textos.montoOculto,
                          style: Tipografia.montoPrincipal.copyWith(
                            color: Colores.sobreMarca,
                          ),
                        )
                      : MontoAnimado(centimos, color: Colores.sobreMarca),
                ),
                // A qué momento corresponde la cifra (entrega 62).
                const SizedBox(height: Medidas.e1),
                const HoraDeAhora(),
                if (pildora case final texto?) ...[
                  const SizedBox(height: Medidas.e3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Medidas.e3,
                      vertical: Medidas.e2,
                    ),
                    decoration: BoxDecoration(
                      color: Colores.superficie,
                      borderRadius: BorderRadius.circular(Medidas.radioPildora),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          size: 18,
                          color: Colores.marca,
                        ),
                        const SizedBox(width: Medidas.e2),
                        Flexible(
                          child: Text(
                            texto,
                            style: Tipografia.cifra(
                              Tipografia.textoFuerte.copyWith(
                                color: Colores.marca,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _explicar(BuildContext context) {
    // Se mide cuánto se abre la explicación (entrega 59).
    ProviderScope.containerOf(context, listen: false)
        .read(medicionProvider)
        .anotar(EventoMedicion.seccionAbierta, {'seccion': 'tienes_hoy_info'});
    _mostrarExplicacion(context);
  }

  void _mostrarExplicacion(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (hoja) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          0,
          Medidas.margenLateral,
          Medidas.e6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(etiqueta, style: Tipografia.tituloPantalla),
            const SizedBox(height: Medidas.e1),
            const Text(Textos.desdeQueEmpezaste, style: Tipografia.secundario),
            const SizedBox(height: Medidas.e4),
            Text(explicacion, style: Tipografia.texto),
            const SizedBox(height: Medidas.e5),
            FilledButton(
              onPressed: () => Navigator.of(hoja).pop(),
              child: const Text(Textos.entendido),
            ),
          ],
        ),
      ),
    ),
  );
}

/// «Jueves 12:13 p. m.» (entrega 62): el día y la hora en que se mira la
/// tarjeta. Se pone al día al cambiar el minuto.
class HoraDeAhora extends ConsumerStatefulWidget {
  const HoraDeAhora({super.key});

  @override
  ConsumerState<HoraDeAhora> createState() => _HoraDeAhoraState();
}

class _HoraDeAhoraState extends ConsumerState<HoraDeAhora> {
  Timer? _siguiente;

  @override
  void initState() {
    super.initState();
    _programar();
  }

  void _programar() {
    final ahora = ref.read(relojProvider)();
    final falta = Duration(
      seconds: 60 - ahora.second,
      milliseconds: -ahora.millisecond,
    );
    _siguiente = Timer(falta, () {
      if (!mounted) return;
      setState(() {});
      _programar();
    });
  }

  @override
  void dispose() {
    _siguiente?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ahora = ref.watch(relojProvider)();
    return Text(
      formatearDiaYHora(ahora),
      style: Tipografia.cifra(
        Tipografia.secundario.copyWith(color: Colores.sobreMarcaSuave),
      ),
    );
  }
}
