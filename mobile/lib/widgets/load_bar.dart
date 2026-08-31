import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class LoadBar extends StatelessWidget {
  final double fraction;
  final Color? fillColor;
  final Color? trackColor;

  const LoadBar({
    super.key,
    required this.fraction,
    this.fillColor,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final clampedFraction = fraction.clamp(0.0, 1.0);
    return SizedBox(
      height: 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: CustomPaint(
          size: const Size(double.infinity, 9),
          painter: _LoadBarPainter(
            fraction: clampedFraction,
            fill: fillColor ?? AppTheme.tipperAmber,
            track: trackColor ?? AppTheme.loadBarTrack,
          ),
        ),
      ),
    );
  }
}

class _LoadBarPainter extends CustomPainter {
  final double fraction;
  final Color fill;
  final Color track;

  _LoadBarPainter({
    required this.fraction,
    required this.fill,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()..color = track;
    canvas.drawRect(Offset.zero & size, trackPaint);

    if (fraction > 0) {
      final fillPaint = Paint()..color = fill;
      canvas.drawRect(
        Offset.zero & Size(size.width * fraction, size.height),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LoadBarPainter old) =>
      old.fraction != fraction || old.fill != fill || old.track != track;
}
