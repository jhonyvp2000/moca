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
  salio,
  microfono,
  cerrar,
  camara,
  qr,
  lapiz,
  ojo,
  ojoTachado,
  abajo,
  linterna,
  alerta,
  sinSenal,
  derecha,
  compartir,
  reproducir,
  detener;

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
      case Icono.salio:
        p
          ..moveTo(12, 5)
          ..lineTo(12, 19)
          ..moveTo(6, 13)
          ..lineTo(12, 19)
          ..lineTo(18, 13);
      case Icono.cerrar:
        p
          ..moveTo(6, 6)
          ..lineTo(18, 18)
          ..moveTo(18, 6)
          ..lineTo(6, 18);
      case Icono.camara:
        p
          ..moveTo(4, 8)
          ..lineTo(7, 8)
          ..lineTo(9, 5)
          ..lineTo(15, 5)
          ..lineTo(17, 8)
          ..lineTo(20, 8)
          ..lineTo(20, 19)
          ..lineTo(4, 19)
          ..close()
          ..addOval(Rect.fromCircle(center: const Offset(12, 13), radius: 3.5));
      case Icono.qr:
        p
          ..addRRect(RRect.fromLTRBR(4, 4, 10, 10, const Radius.circular(1)))
          ..addRRect(RRect.fromLTRBR(14, 4, 20, 10, const Radius.circular(1)))
          ..addRRect(RRect.fromLTRBR(4, 14, 10, 20, const Radius.circular(1)))
          ..moveTo(14, 14)
          ..lineTo(16, 14)
          ..lineTo(16, 16)
          ..moveTo(20, 14)
          ..lineTo(20, 20)
          ..lineTo(14, 20);
      case Icono.lapiz:
        p
          ..moveTo(4, 20)
          ..lineTo(8, 20)
          ..lineTo(19, 9)
          ..lineTo(15, 5)
          ..lineTo(4, 16)
          ..close()
          ..moveTo(13, 7)
          ..lineTo(17, 11);
      case Icono.ojo:
        _trazarOjo(p);
        p.addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 3));
      case Icono.ojoTachado:
        _trazarOjo(p);
        p
          ..moveTo(4, 4)
          ..lineTo(20, 20);
      case Icono.derecha:
        p
          ..moveTo(9, 6)
          ..lineTo(15, 12)
          ..lineTo(9, 18);
      case Icono.compartir:
        p
          ..moveTo(12, 15)
          ..lineTo(12, 4)
          ..moveTo(8, 8)
          ..lineTo(12, 4)
          ..lineTo(16, 8)
          ..moveTo(5, 13)
          ..lineTo(5, 19)
          ..lineTo(19, 19)
          ..lineTo(19, 13);
      case Icono.reproducir:
        p
          ..moveTo(8, 5)
          ..lineTo(19, 12)
          ..lineTo(8, 19)
          ..close();
      case Icono.detener:
        p.addRRect(RRect.fromLTRBR(7, 7, 17, 17, const Radius.circular(2)));
      case Icono.abajo:
        p
          ..moveTo(6, 9)
          ..lineTo(12, 15)
          ..lineTo(18, 9);
      case Icono.linterna:
        p
          ..moveTo(9, 2)
          ..lineTo(15, 2)
          ..lineTo(15, 7)
          ..lineTo(13, 10)
          ..lineTo(13, 22)
          ..lineTo(11, 22)
          ..lineTo(11, 10)
          ..lineTo(9, 7)
          ..close();
      case Icono.sinSenal:
        p
          ..moveTo(7, 18)
          ..lineTo(17, 18)
          ..arcToPoint(
            const Offset(18, 10.1),
            radius: const Radius.circular(4),
            clockwise: false,
          )
          ..arcToPoint(
            const Offset(6.5, 9),
            radius: const Radius.circular(6),
            clockwise: false,
          )
          ..arcToPoint(
            const Offset(7, 18),
            radius: const Radius.circular(4.5),
            clockwise: false,
          )
          ..close()
          ..moveTo(4, 4)
          ..lineTo(20, 20);
      case Icono.alerta:
        p
          ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 9))
          ..moveTo(12, 7.5)
          ..lineTo(12, 13)
          ..moveTo(12, 16.5)
          ..lineTo(12, 16.6);
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

void _trazarOjo(Path p) => p
  ..moveTo(2, 12)
  ..quadraticBezierTo(5.5, 5, 12, 5)
  ..quadraticBezierTo(18.5, 5, 22, 12)
  ..quadraticBezierTo(18.5, 19, 12, 19)
  ..quadraticBezierTo(5.5, 19, 2, 12)
  ..close();

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
