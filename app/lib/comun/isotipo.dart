import 'package:flutter/widgets.dart';

import '../tema/colores.dart';

/// Isotipo de Moca: cuadrado azul redondeado con una «M» blanca de trazo
/// (ver diseno/estilo.md).
class Isotipo extends StatelessWidget {
  const Isotipo({super.key, required this.tamano});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(tamano), painter: _PintorIsotipo());
  }
}

class _PintorIsotipo extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // El diseño original mide 28 × 28.
    final k = size.width / 28;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(8 * k)),
      Paint()..color = Colores.marca,
    );
    final m = Path()
      ..moveTo(7 * k, 20 * k)
      ..lineTo(7 * k, 9 * k)
      ..lineTo(14 * k, 16 * k)
      ..lineTo(21 * k, 9 * k)
      ..lineTo(21 * k, 20 * k);
    canvas.drawPath(
      m,
      Paint()
        ..color = Colores.sobreMarca
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
