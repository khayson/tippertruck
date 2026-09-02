import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

/// Shared visual language for client + operator surfaces.
class TtStyle {
  TtStyle._();

  static const Color wash = Color(0xFFD9CFC0);
  static const Color washDeep = Color(0xFFC9BBA8);
  static const Color paper = Color(0xFFFFFCF7);
  static const Color line = Color(0xFFE4DDD2);
  static const Color inkSoft = Color(0xFF2A2620);

  static TextStyle display(double size, {Color? color}) {
    return GoogleFonts.archivoBlack(
      fontSize: size,
      height: 1.02,
      letterSpacing: size >= 28 ? -0.8 : -0.4,
      color: color ?? AppTheme.ink,
    );
  }

  static TextStyle eyebrow({Color? color}) {
    return GoogleFonts.publicSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: color ?? AppTheme.slate,
    );
  }

  static List<BoxShadow> get softLift => [
    BoxShadow(
      color: AppTheme.ink.withValues(alpha: 0.07),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
    BoxShadow(
      color: AppTheme.ink.withValues(alpha: 0.03),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get dockShadow => [
    BoxShadow(
      color: AppTheme.ink.withValues(alpha: 0.16),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  static Color statusColor(String status) {
    return switch (status) {
      'confirmed' || 'open' => AppTheme.tipperAmber,
      'on_the_way' => const Color(0xFF1F5FAE),
      'delivered' || 'resolved' => AppTheme.signal,
      'cancelled' => const Color(0xFFB3261E),
      _ => AppTheme.slate,
    };
  }
}
