import 'package:flutter/widgets.dart';

/// Íconos de trazo de los mockups (lienzo de 24 × 24, trazo redondeado).
enum Icono {
  inicio,
  historial,
  informes,
  moca,
  mas,
  volver,
  borrar,
  check,
  entro,
  microfono;

  void _trazar(Path p) {
    switch (this) {
      case Icono.inicio:
        p
          ..moveTo(3, 11)
          ..lineTo(12, 3)
          ..lineTo(21, 11)
          ..moveTo(5, 10)
          ..lineTo(5, 20)
          ..lineTo(19, 20)
          ..lineTo(19, 10);
      case Icono.historial:
        p
          ..moveTo(4, 6)
          ..lineTo(20, 6)
          ..moveTo(4, 12)
          ..lineTo(20, 12)
          ..moveTo(4, 18)
          ..lineTo(14, 18);
      case Icono.informes:
        p
          ..moveTo(5, 20)
          ..lineTo(5, 10)
          ..moveTo(12, 20)
          ..lineTo(12, 4)
          ..moveTo(19, 20)
          ..lineTo(19, 13);
      case Icono.moca:
        p
          ..addRRect(RRect.fromLTRBR(3, 3, 21, 21, const Radius.circular(5)))
          ..moveTo(8, 16)
          ..lineTo(8, 9)
          ..lineTo(12, 13)
          ..lineTo(16, 9)
          ..lineTo(16, 16);
      case Icono.mas:
        p
          ..moveTo(12, 5)
          ..lineTo(12, 19)
          ..moveTo(5, 12)
          ..lineTo(19, 12);
      case Icono.volver:
        p
          ..moveTo(15, 18)
          ..lineTo(9, 12)
          ..lineTo(15, 6);
      case Icono.check:
        p
          ..moveTo(5, 12)
          ..lineTo(9, 16)
          ..lineTo(19, 6);
      case Icono.entro:
        p
          ..moveTo(12, 19)
          ..lineTo(12, 5)
          ..moveTo(6, 11)
          ..lineTo(12, 5)
          ..lineTo(18, 11);
      case Icono.microfono:
        p
          ..addRRect(RRect.fromLTRBR(9, 3, 15, 14, const Radius.circular(3)))
          ..moveTo(5, 11)
          ..arcToPoint(
            const Offset(19, 11),
            radius: const Radius.circular(7),
            clockwise: false,
          )
          ..moveTo(12, 18)
          ..lineTo(12, 21);
      case Icono.borrar:
        p
          ..moveTo(4, 7)
          ..lineTo(20, 7)
          ..moveTo(10, 11)
          ..lineTo(10, 17)
          ..moveTo(14, 11)
          ..lineTo(14, 17)
          ..moveTo(6, 7)
          ..lineTo(7, 20)
          ..lineTo(17, 20)
          ..lineTo(18, 7)
          ..moveTo(9, 7)
          ..lineTo(9, 4)
          ..lineTo(15, 4)
          ..lineTo(15, 7);
    }
  }
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
  final double grosor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(tamano),
      painter: _PintorIcono(icono, color, grosor),
    );
  }
}

class _PintorIcono extends CustomPainter {
  _PintorIcono(this.icono, this.color, this.grosor);

  final Icono icono;
  final Color color;
  final double grosor;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.scale(k);
    final p = Path();
    icono._trazar(p);
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PintorIcono anterior) =>
      anterior.icono != icono ||
      anterior.color != color ||
      anterior.grosor != grosor;
}
