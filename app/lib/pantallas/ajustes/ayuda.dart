import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/tarjeta.dart';
import '../../dominio/cuenta_real.dart';
import '../../dominio/equipo.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import '../historial/pantalla_detalle_movimiento.dart' show fechaYHora;

/// «Ayuda» en Ajustes (entrega 46): el estado de este teléfono en palabras
/// simples, la solución cuando algo está mal y «Pedir ayuda por WhatsApp»
/// con ese estado ya escrito. La ven todos, también sin cuenta.
class AyudaDelTelefono extends ConsumerWidget {
  const AyudaDelTelefono({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final situacion = ref.watch(situacionCuentaProvider).value;
    final permisos = ref.watch(permisosProvider).value ?? Permisos.delDueno;
    final negocio = ref.watch(resumenInicioProvider).value?.nombreNegocio ?? '';
    final datos = ref.watch(datosDeAyudaProvider).value;
    final instalada = ref.watch(versionInstaladaProvider);
    final soporte = ref.watch(versionPublicadaProvider).value?.$1.soporte;
    final estado = situacion?.estado;
    final celular = situacion?.celular;

    final cuenta = switch (estado) {
      EstadoCuenta.guardada when celular != null => Textos.unidoATuCuenta(
        formatearCelular(celular),
      ),
      EstadoCuenta.porConfirmar => Textos.porConfirmarAyuda,
      EstadoCuenta.cerradaEnOtro => Textos.abiertaEnOtroAyuda,
      EstadoCuenta.fueraDelNegocio => Textos.fueraAyuda,
      _ => Textos.sinCuentaAyuda,
    };
    final rol = Textos.nombreRol(permisos.rol);
    // Sin «Moca» delante: la versión completa ya va al pie de Ajustes.
    final version = instalada.conocida
        ? Textos.versionCorta(instalada.entrega, instalada.armado)
        : Textos.versionDeDesarrollo;
    final porSubir = datos?.porSubir ?? 0;
    final guardada = estado == EstadoCuenta.guardada;
    final actualizado = situacion?.actualizadoEn;

    final filas = <(String, String)>[
      (Textos.etiquetaCuentaAyuda, cuenta),
      (
        Textos.etiquetaNegocioAyuda,
        Textos.negocioYRol(negocio, rol, permisos.titular),
      ),
      if (guardada)
        (
          Textos.etiquetaServidor,
          porSubir > 0
              ? Textos.porSubirAyuda(porSubir)
              : actualizado == null
              ? Textos.sinActualizarAyuda
              : Textos.actualizadoAyuda(fechaYHora(actualizado.toLocal())),
        ),
      (Textos.etiquetaVersion, version),
    ];

    Future<void> pedirAyuda() async {
      final mensajes = ScaffoldMessenger.of(context);
      final texto = Textos.mensajeDeAyuda(
        version: version,
        cuenta: cuenta,
        negocio: negocio.isEmpty ? '—' : negocio,
        codigo: datos?.codigo,
        rol: permisos.titular ? '$rol (titular)' : rol,
        porSubir: porSubir,
      );
      final enlace =
          'https://wa.me/51$soporte?text=${Uri.encodeComponent(texto)}';
      if (!await ref.read(abridorProvider).abrir(enlace)) {
        mensajes.showSnackBar(
          const SnackBar(content: Text(Textos.noSeAbrioWhatsApp)),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                Textos.estadoDeEsteTelefono,
                style: Tipografia.textoFuerte,
              ),
              const SizedBox(height: 6),
              for (final (etiqueta, valor) in filas)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 84,
                        child: Text(etiqueta, style: Tipografia.secundario),
                      ),
                      Expanded(child: Text(valor, style: Tipografia.texto)),
                    ],
                  ),
                ),
              // La solución cuando algo está mal.
              if (estado == EstadoCuenta.cerradaEnOtro ||
                  estado == EstadoCuenta.fueraDelNegocio) ...[
                const SizedBox(height: 6),
                Text(
                  estado == EstadoCuenta.cerradaEnOtro
                      ? Textos.abiertaEnOtroQueHacer
                      : Textos.fueraQueHacer,
                  style: Tipografia.secundario.copyWith(
                    color: Colores.avisoTexto,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (soporte != null) ...[
          const SizedBox(height: Medidas.separacionTarjetas),
          OutlinedButton(
            onPressed: pedirAyuda,
            child: const Text(Textos.pedirAyudaWhatsApp),
          ),
        ],
      ],
    );
  }
}
