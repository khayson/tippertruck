import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../widgets/tipper_silhouette.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed background
          CustomPaint(
            painter: _WelcomeBackgroundPainter(),
            size: Size.infinite,
          ),

          // Dark gradient anchoring text to bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 0.6, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    AppTheme.ink.withValues(alpha: 0.55),
                    AppTheme.ink.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),

          // Hero image — centered in the upper portion
          Positioned(
            top: MediaQuery.of(context).size.height * 0.12,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/tipper_hero.png',
                width: 320,
                height: 320,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => TipperSilhouette(
                  size: 260,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),

          // Bottom content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(),

                  // Headline
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SAND,\nDELIVERED.',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'One price. No haggling\nat the gate.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.45,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.register),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Get Started'),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Secondary link
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      'I have an account',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Warm amber-to-laterite gradient base
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.tipperAmber, AppTheme.tipperAmber, AppTheme.laterite],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Stippled sand grain texture over the entire surface
    final rng = Random(42);
    final grainPaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 600; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.5 + rng.nextDouble() * 2.0;
      final alpha = 0.05 + rng.nextDouble() * 0.12;
      grainPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), r, grainPaint);
    }

    // Dark grain specks for depth
    for (var i = 0; i < 300; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.4 + rng.nextDouble() * 1.2;
      final alpha = 0.05 + rng.nextDouble() * 0.08;
      grainPaint.color = AppTheme.ink.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), r, grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
