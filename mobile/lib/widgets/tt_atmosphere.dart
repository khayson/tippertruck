import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../config/tt_style.dart';

/// Warm sand wash + soft diagonal grain — same family as Welcome.
class TtAtmosphere extends StatelessWidget {
  final Widget child;
  final bool showStripes;

  const TtAtmosphere({
    super.key,
    required this.child,
    this.showStripes = true,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8DFD2),
            AppTheme.bone,
            Color(0xFFEFE8DC),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showStripes)
            const Positioned.fill(
              child: CustomPaint(painter: _GrainPainter()),
            ),
          child,
        ],
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TtStyle.washDeep.withValues(alpha: 0.07)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    for (var x = -size.height; x < size.width + size.height; x += 42) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
