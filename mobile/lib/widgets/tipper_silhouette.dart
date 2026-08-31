import 'package:flutter/material.dart';

class TipperSilhouette extends StatelessWidget {
  final double size;
  final Color color;

  const TipperSilhouette({
    super.key,
    this.size = 120,
    this.color = const Color(0xFFD45A12),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.65),
      painter: _TipperPainter(color: color),
    );
  }
}

class _TipperPainter extends CustomPainter {
  final Color color;

  _TipperPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Tipper bed (trapezoidal, tilted back slightly)
    final bed = Path()
      ..moveTo(w * 0.08, h * 0.70)
      ..lineTo(w * 0.12, h * 0.18)
      ..lineTo(w * 0.58, h * 0.12)
      ..lineTo(w * 0.58, h * 0.70)
      ..close();
    canvas.drawPath(bed, paint);

    // Sand mound in bed
    final sandPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final sand = Path()
      ..moveTo(w * 0.14, h * 0.30)
      ..quadraticBezierTo(w * 0.35, h * 0.05, w * 0.56, h * 0.22)
      ..lineTo(w * 0.56, h * 0.30)
      ..lineTo(w * 0.14, h * 0.30)
      ..close();
    canvas.drawPath(sand, sandPaint);

    // Cab
    final cab = Path()
      ..moveTo(w * 0.58, h * 0.30)
      ..lineTo(w * 0.58, h * 0.70)
      ..lineTo(w * 0.82, h * 0.70)
      ..lineTo(w * 0.82, h * 0.38)
      ..lineTo(w * 0.72, h * 0.30)
      ..close();
    canvas.drawPath(cab, paint);

    // Windshield
    final glass = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final windshield = Path()
      ..moveTo(w * 0.72, h * 0.34)
      ..lineTo(w * 0.72, h * 0.50)
      ..lineTo(w * 0.80, h * 0.50)
      ..lineTo(w * 0.80, h * 0.40)
      ..close();
    canvas.drawPath(windshield, glass);

    // Chassis bar
    final chassis = Rect.fromLTWH(w * 0.06, h * 0.70, w * 0.80, h * 0.06);
    canvas.drawRect(chassis, paint);

    // Wheels
    final wheelPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final axlePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Rear wheel
    canvas.drawCircle(Offset(w * 0.22, h * 0.82), w * 0.07, wheelPaint);
    canvas.drawCircle(Offset(w * 0.22, h * 0.82), w * 0.03, axlePaint);

    // Front wheel
    canvas.drawCircle(Offset(w * 0.72, h * 0.82), w * 0.07, wheelPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.82), w * 0.03, axlePaint);
  }

  @override
  bool shouldRepaint(_TipperPainter old) => old.color != color;
}
