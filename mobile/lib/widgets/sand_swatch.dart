import 'dart:math';

import 'package:flutter/material.dart';

class SandSwatch extends StatelessWidget {
  final String slug;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SandSwatch({
    super.key,
    required this.slug,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        size: Size(width == double.infinity ? 300 : width, height),
        painter: _SandSwatchPainter(slug: slug),
      ),
    );
  }
}

class _SandGrainProfile {
  final Color baseColor;
  final Color grainColor;
  final double minRadius;
  final double maxRadius;
  final int grainCount;

  const _SandGrainProfile({
    required this.baseColor,
    required this.grainColor,
    required this.minRadius,
    required this.maxRadius,
    required this.grainCount,
  });
}

_SandGrainProfile _profileForSlug(String slug) {
  switch (slug) {
    case 'river-sand':
      return const _SandGrainProfile(
        baseColor: Color(0xFFD4C4A8),
        grainColor: Color(0xFF9E8C6C),
        minRadius: 0.6,
        maxRadius: 1.4,
        grainCount: 350,
      );
    case 'quarry-sand':
      return const _SandGrainProfile(
        baseColor: Color(0xFFBCB8AF),
        grainColor: Color(0xFF7A7770),
        minRadius: 0.8,
        maxRadius: 2.2,
        grainCount: 280,
      );
    case 'filling-sand':
      return const _SandGrainProfile(
        baseColor: Color(0xFFBF7B4A),
        grainColor: Color(0xFF8C4420),
        minRadius: 1.0,
        maxRadius: 2.6,
        grainCount: 240,
      );
    default:
      return const _SandGrainProfile(
        baseColor: Color(0xFFCCC0A8),
        grainColor: Color(0xFFA08E6E),
        minRadius: 0.7,
        maxRadius: 1.6,
        grainCount: 300,
      );
  }
}

class _SandSwatchPainter extends CustomPainter {
  final String slug;

  _SandSwatchPainter({required this.slug});

  @override
  void paint(Canvas canvas, Size size) {
    final profile = _profileForSlug(slug);
    final rng = Random(slug.hashCode);

    final basePaint = Paint()..color = profile.baseColor;
    canvas.drawRect(Offset.zero & size, basePaint);

    final grainPaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < profile.grainCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r =
          profile.minRadius +
          rng.nextDouble() * (profile.maxRadius - profile.minRadius);

      final alpha = 0.3 + rng.nextDouble() * 0.5;
      grainPaint.color = profile.grainColor.withValues(alpha: alpha);

      canvas.drawCircle(Offset(x, y), r, grainPaint);
    }
  }

  @override
  bool shouldRepaint(_SandSwatchPainter old) => old.slug != slug;
}
