import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/icono_trazo.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/comprobantes.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import '../../dominio/medicion.dart';

enum _Fase { abriendoCamara, sinPermiso, leyendo, ilegible }

/// «Tomar foto»: abre la cámara, lee el comprobante (simulado en el
/// prototipo) y pasa a S08, o muestra S17 si la foto salió borrosa.
class PantallaFoto extends ConsumerStatefulWidget {
  const PantallaFoto({super.key});

  @override
  ConsumerState<PantallaFoto> createState() => _EstadoFoto();
}

class _EstadoFoto extends ConsumerState<PantallaFoto> {
  _Fase _fase = _Fase.abriendoCamara;
  LecturaComprobante? _lectura;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tomarFoto());
  }

  Future<void> _tomarFoto() async {
    setState(() => _fase = _Fase.abriendoCamara);
    final resultado = await ref.read(camaraProvider).tomarFoto();
    if (!mounted) return;
    switch (resultado) {
      case FotoCancelada():
        context.pushReplacement(Rutas.registrar);
      case CamaraSinPermiso():
        setState(() => _fase = _Fase.sinPermiso);
      case FotoTomada(:final ruta):
        setState(() => _fase = _Fase.leyendo);
        final lectura = await ref.read(lectorFotoProvider).leer(ruta);
        if (!mounted) return;
        if (lectura.legible) {
          context.pushReplacement(Rutas.confirmarLectura, extra: lectura);
        } else {
          setState(() {
            _lectura = lectura;
            _fase = _Fase.ilegible;
            ref.read(medicionProvider).anotar(EventoMedicion.fotoIlegible);
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ilegible = _fase == _Fase.ilegible;
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.revisaLaLectura,
        alVolver: () => context.pop(),
      ),
      contenido: switch (_fase) {
        _Fase.abriendoCamara => const [_Esperando(Textos.abriendoCamara)],
        _Fase.leyendo => const [_Esperando(Textos.leyendoComprobante)],
        _Fase.sinPermiso => const [Aviso(texto: Textos.sinPermisoCamara)],
        _Fase.ilegible => _ilegible(_lectura!),
      },
      acciones: [
        if (ilegible) ...[
          FilledButton.icon(
            onPressed: _tomarFoto,
            icon: const IconoTrazo(Icono.camara, color: Colores.sobreMarca),
            label: const Text(Textos.tomarOtraFoto),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pushReplacement(
                    Rutas.confirmarLectura,
                    extra: _lectura,
                  ),
                  child: const Text(
                    Textos.completarAMano,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pushReplacement(Rutas.voz),
                  child: const Text(
                    Textos.decirloConVoz,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_fase == _Fase.sinPermiso)
          FilledButton(
            onPressed: () => context.pushReplacement(Rutas.escribir),
            child: const Text(Textos.escribirlo),
          ),
      ],
    );
  }

  /// S17 · Foto ilegible: lo que sí se leyó, «No se lee» en lo demás y
  /// consejos para repetir la foto.
  List<Widget> _ilegible(LecturaComprobante l) {
    Widget dato(String etiqueta, String? valor) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: Tipografia.texto.copyWith(color: Colores.textoSecundario),
            ),
          ),
          Text(
            valor ?? Textos.noSeLee,
            style: Tipografia.cifra(
              Tipografia.textoFuerte.copyWith(
                fontWeight: valor == null ? FontWeight.w600 : FontWeight.w700,
                color: valor == null
                    ? Colores.avisoTexto
                    : Colores.textoPrincipal,
              ),
            ),
          ),
        ],
      ),
    );

    Widget consejo(String texto) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const IconoTrazo(Icono.check, color: Colores.marca, tamano: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: Tipografia.texto)),
        ],
      ),
    );

    final ruta = l.rutaImagen;
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colores.avisoFondo,
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconoTrazo(Icono.alerta, color: Colores.avisoMarca),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    Textos.fotoBorrosa,
                    style: Tipografia.tituloTarjeta,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Textos.fotoBorrosaDetalle,
                    style: Tipografia.texto.copyWith(
                      color: Colores.avisoTextoFuerte,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Tarjeta(
        relleno: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 100,
              decoration: BoxDecoration(
                color: Colores.fondo,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colores.bordeCampo),
              ),
              clipBehavior: Clip.antiAlias,
              child: ruta != null && File(ruta).existsSync()
                  ? Image.file(File(ruta), fit: BoxFit.cover)
                  : const Center(
                      child: Text(Textos.foto, style: Tipografia.secundario),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  dato(
                    Textos.total,
                    l.totalCentimos == null
                        ? null
                        : formatearSolesComprobante(l.totalCentimos!),
                  ),
                  dato(Textos.aQuien, l.emisorNombre),
                  dato(
                    Textos.fecha,
                    l.fechaEmision == null
                        ? null
                        : formatearFechaLarga(l.fechaEmision!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Textos.paraQueSalgaBien,
              style: Tipografia.textoFuerte.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            consejo(Textos.consejoMesa),
            consejo(Textos.consejoCompleto),
            consejo(Textos.consejoSombra),
          ],
        ),
      ),
    ];
  }
}

class _Esperando extends StatelessWidget {
  const _Esperando(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const SizedBox.square(
            dimension: 40,
            child: CircularProgressIndicator(color: Colores.marca),
          ),
          const SizedBox(height: 16),
          Text(texto, style: Tipografia.texto, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
