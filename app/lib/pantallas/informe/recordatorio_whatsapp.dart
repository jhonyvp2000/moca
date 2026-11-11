import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/historial.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../textos/textos.dart';

/// El mensaje para recordarle a un cliente lo que debe (entrega 45), con
/// sus ventas a crédito: lo que falta, las fechas y lo ya pagado en partes.
String mensajeDeRecordatorio({
  required String negocio,
  required String? cliente,
  required List<FilaHistorial> ventas,
}) {
  final ordenadas = [...ventas]..sort((a, b) => a.fecha.compareTo(b.fecha));
  final falta = ordenadas.fold(0, (s, f) => s + f.montoCentimos);
  final unaConPartes =
      ordenadas.length == 1 && ordenadas.single.pagadoEnPartesCentimos > 0;
  return Textos.recordatorioDeuda(
    cliente: cliente,
    negocio: negocio,
    falta: formatearSolesComprobante(falta),
    total: unaConPartes
        ? formatearSolesComprobante(ordenadas.single.totalConPartesCentimos)
        : null,
    fechas: [for (final f in ordenadas) formatearDiaYMes(f.fecha)],
  );
}

/// Abre WhatsApp con el mensaje listo. Con el celular del cliente va
/// directo a su chat; sin él, el dueño elige el contacto (entrega 45). Al
/// abrirse queda la fecha del recordatorio, solo para mostrarla (entrega 53).
Future<void> recordarPorWhatsApp(
  BuildContext context,
  WidgetRef ref, {
  required String? cliente,
  required List<FilaHistorial> ventas,
}) async {
  final mensajes = ScaffoldMessenger.of(context);
  final repo = ref.read(repositorioHistorialProvider);
  final texto = mensajeDeRecordatorio(
    negocio:
        ref.read(resumenInicioProvider).value?.nombreNegocio ?? 'mi negocio',
    cliente: cliente,
    ventas: ventas,
  );
  final celular = ventas.map((f) => f.celular).nonNulls.firstOrNull;
  // Con %20 y no «+».
  final enlace =
      'https://wa.me/${celular == null ? '' : celularParaWhatsApp(celular)}'
      '?text=${Uri.encodeComponent(texto)}';
  if (!await ref.read(abridorProvider).abrir(enlace)) {
    mensajes.showSnackBar(
      const SnackBar(content: Text(Textos.noSeAbrioWhatsApp)),
    );
    return;
  }
  for (final id in {...ventas.map((f) => f.contraparteId).nonNulls}) {
    await repo.marcarRecordado(id);
  }
}
