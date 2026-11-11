import 'package:flutter/material.dart';

/// Los iconos con nombre de Moca. Desde la mejora 01 son los Material Icons
/// redondeados que vienen con Flutter, los mismos del resto del diseño (antes
/// eran trazos dibujados a mano, copiados de los mockups).
enum Icono {
  inicio(Icons.home_rounded),
  historial(Icons.format_list_bulleted_rounded),
  informes(Icons.bar_chart_rounded),
  moca(Icons.auto_awesome_rounded),
  mas(Icons.add_rounded),
  volver(Icons.arrow_back_rounded),
  borrar(Icons.backspace_outlined),
  check(Icons.check_rounded),
  entro(Icons.south_west_rounded),
  salio(Icons.north_east_rounded),
  microfono(Icons.mic_rounded),
  cerrar(Icons.close_rounded),
  camara(Icons.photo_camera_rounded),
  qr(Icons.qr_code_scanner_rounded),
  lapiz(Icons.edit_rounded),
  ojo(Icons.visibility_outlined),
  ojoTachado(Icons.visibility_off_outlined),
  abajo(Icons.expand_more_rounded),
  linterna(Icons.flashlight_on_rounded),
  alerta(Icons.error_outline_rounded),
  sinSenal(Icons.cloud_off_rounded),
  derecha(Icons.chevron_right_rounded),
  izquierda(Icons.chevron_left_rounded),
  compartir(Icons.ios_share_rounded),
  reproducir(Icons.play_arrow_rounded),
  detener(Icons.stop_rounded);

  const Icono(this.material);

  final IconData material;
}

class IconoTrazo extends StatelessWidget {
  const IconoTrazo(
    this.icono, {
    super.key,
    required this.color,
    this.tamano = 22,
    this.grosor = 2,
  });

  final Icono icono;
  final Color color;
  final double tamano;

  /// Sin uso desde la mejora 01; se queda para no tocar cada llamada.
  final double grosor;

  @override
  Widget build(BuildContext context) =>
      Icon(icono.material, color: color, size: tamano + 2);
}
