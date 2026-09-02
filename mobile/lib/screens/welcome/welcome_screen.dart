import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../widgets/app_button.dart';
import '../../widgets/tipper_silhouette.dart';

/// Soft warm sand — tipper-flavoured stand-in for the reference sage wash.
const Color _welcomeWash = Color(0xFFD4C8B8);

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _welcomeWash,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _StripeBackdropPainter()),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: size.height * 0.02),
                      child: Image.asset(
                        'assets/images/tipper_hero.png',
                        width: size.width * 0.92,
                        height: size.height * 0.38,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => TipperSilhouette(
                          size: size.width * 0.7,
                          color: AppTheme.ink.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 1),
                    const _WelcomeHeadline(),
                    const Spacer(flex: 3),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Login',
                            outlined: true,
                            dark: true,
                            large: true,
                            onPressed: () => context.go(AppRoutes.login),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Get Started',
                            dark: true,
                            large: true,
                            onPressed: () => context.go(AppRoutes.register),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rotates daily so returning users see fresh, motivating copy.
class _WelcomeCopy {
  const _WelcomeCopy({
    required this.before,
    required this.accent,
    required this.after,
  });

  final String before;
  final String accent;
  final String after;

  static const List<_WelcomeCopy> pool = [
    _WelcomeCopy(
      before: 'Skip the quarry\nqueue — ',
      accent: 'order sand',
      after: '\nin minutes.',
    ),
    _WelcomeCopy(
      before: 'Book a tipper,\n',
      accent: 'track',
      after: ' every\nload to your site.',
    ),
    _WelcomeCopy(
      before: 'One fair price.\n',
      accent: 'Delivered',
      after: '\nstraight to your build.',
    ),
    _WelcomeCopy(
      before: 'Your next pour\nstarts with one\n',
      accent: 'tap',
      after: '.',
    ),
    _WelcomeCopy(
      before: 'From phone to\nsite — sand\n',
      accent: 'when you need it',
      after: '.',
    ),
    _WelcomeCopy(
      before: 'Build without\nthe haggling.\n',
      accent: 'Order today',
      after: '.',
    ),
    _WelcomeCopy(
      before: 'Reliable loads\nfor every site —\n',
      accent: 'book yours',
      after: ' now.',
    ),
  ];

  static _WelcomeCopy forToday([DateTime? now]) {
    final date = now ?? DateTime.now();
    final dayOfYear = date.difference(DateTime(date.year)).inDays;
    return pool[dayOfYear % pool.length];
  }
}

class _WelcomeHeadline extends StatelessWidget {
  const _WelcomeHeadline();

  @override
  Widget build(BuildContext context) {
    final copy = _WelcomeCopy.forToday();
    final base = GoogleFonts.archivoBlack(
      fontSize: 32,
      height: 1.18,
      letterSpacing: -0.6,
      color: AppTheme.ink,
    );

    final accentPainter = TextPainter(
      text: TextSpan(text: copy.accent, style: base),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: copy.before),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(copy.accent, style: base),
                CustomPaint(
                  size: Size(accentPainter.width, 8),
                  painter: _AccentUnderlinePainter(),
                ),
              ],
            ),
          ),
          TextSpan(text: copy.after),
        ],
      ),
    );
  }
}

class _AccentUnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.tipperAmber
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.2,
        size.width,
        size.height * 0.35,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StripeBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final stripeWidth = size.width * 0.14;
    final gap = size.width * 0.06;
    final startX = size.width * 0.28;
    final top = size.height * 0.05;
    final height = size.height * 0.85;
    final colors = [
      AppTheme.laterite.withValues(alpha: 0.18),
      AppTheme.ink.withValues(alpha: 0.10),
      AppTheme.laterite.withValues(alpha: 0.14),
    ];

    for (var i = 0; i < 3; i++) {
      final x = startX + i * (stripeWidth + gap);
      paint.color = colors[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, stripeWidth, height),
        const Radius.circular(18),
      );
      canvas.save();
      canvas.translate(x + stripeWidth / 2, top + height / 2);
      canvas.rotate(0.08);
      canvas.translate(-(x + stripeWidth / 2), -(top + height / 2));
      canvas.drawRRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
