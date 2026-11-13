import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../textos/textos.dart';

/// Abre WhatsApp con el chat de la persona invitada y el mensaje listo:
/// de dónde bajar Moca, qué tocar y hasta cuándo vale (entrega 30).
Future<void> mandarInvitacionPorWhatsApp(
  BuildContext context,
  WidgetRef ref, {
  required String celular,
  required Rol rol,
  required DateTime venceEn,
  String? nombre,
}) async {
  final mensajes = ScaffoldMessenger.of(context);
  final negocio =
      ref.read(resumenInicioProvider).value?.nombreNegocio ?? 'mi negocio';
  final texto = Textos.mensajeDeInvitacion(
    nombre: (nombre == null || nombre.trim().isEmpty) ? null : nombre.trim(),
    negocio: negocio,
    rol: rol,
    celular: formatearCelular(celular),
    vence: formatearDiaYMes(venceEn),
    enlace: ref.read(enlaceDescargaProvider),
  );
  // Con %20 y no «+»: WhatsApp muestra los «+» tal cual.
  final enlace = 'https://wa.me/51$celular?text=${Uri.encodeComponent(texto)}';
  if (!await ref.read(abridorProvider).abrir(enlace)) {
    mensajes.showSnackBar(
      const SnackBar(content: Text(Textos.noSeAbrioWhatsApp)),
    );
  }
}
