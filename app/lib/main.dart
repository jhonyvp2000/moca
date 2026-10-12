import 'package:flutter/material.dart';

// Entrega 0: solo comprueba que la app se instala y abre en el teléfono.
// El tema, los textos y las pantallas reales llegan desde la entrega 1.

void main() {
  runApp(const MocaApp());
}

class MocaApp extends StatelessWidget {
  const MocaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Moca',
      debugShowCheckedModeBanner: false,
      home: PantallaEntregaCero(),
    );
  }
}

class PantallaEntregaCero extends StatelessWidget {
  const PantallaEntregaCero({super.key});

  static const _fondo = Color(0xFFF3F6FB);
  static const _textoPrincipal = Color(0xFF0F1F3D);
  static const _textoSecundario = Color(0xFF4B5A75);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _fondo,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Isotipo(tamano: 72),
                SizedBox(height: 20),
                Text(
                  'Moca',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _textoPrincipal,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tú vendes. Moca hace las cuentas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, color: _textoPrincipal),
                ),
                SizedBox(height: 24),
                Text(
                  'Entrega 0: la app ya se instala en tu teléfono. '
                  'Las pantallas llegan desde la entrega 1.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: _textoSecundario),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      Paint()..color = const Color(0xFF1D4ED8),
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
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
