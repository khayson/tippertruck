import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color tipperAmber = Color(0xFFD45A12);
  static const Color laterite = Color(0xFF8C3A17);
  static const Color ink = Color(0xFF191713);
  static const Color slate = Color(0xFF6B655C);
  static const Color bone = Color(0xFFF4F0E8);
  static const Color signal = Color(0xFF1E6B4C);

  static const Color cardSurface = Colors.white;
  static const Color loadBarTrack = Color(0xFFEFE7D9);

  @Deprecated('Use tipperAmber instead')
  static const Color primaryColor = tipperAmber;

  static TextStyle _archivo({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.archivo(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing ?? (size >= 24 ? -0.02 * size : null),
      color: color ?? ink,
    );
  }

  static TextStyle _publicSans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    Color? color,
    List<FontFeature>? fontFeatures,
  }) {
    return GoogleFonts.publicSans(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color ?? ink,
      fontFeatures: fontFeatures,
    );
  }

  static TextStyle get moneyStyle => _publicSans(
    size: 16,
    weight: FontWeight.w600,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  static TextStyle get tonnageStyle => _publicSans(
    size: 14,
    weight: FontWeight.w500,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: tipperAmber,
      brightness: Brightness.light,
    ).copyWith(primary: tipperAmber, surface: cardSurface);

    final textTheme = TextTheme(
      displayLarge: _archivo(size: 30, weight: FontWeight.w700),
      headlineSmall: _archivo(size: 24, weight: FontWeight.w700),
      titleLarge: _archivo(size: 19, weight: FontWeight.w600),
      titleMedium: _archivo(size: 19, weight: FontWeight.w600),
      bodyLarge: _publicSans(size: 16),
      bodyMedium: _publicSans(size: 14),
      bodySmall: _publicSans(size: 14),
      labelSmall: _publicSans(
        size: 11,
        weight: FontWeight.w500,
        letterSpacing: 0.08 * 11,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bone,
      textTheme: textTheme,
      cardTheme: const CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Color(0xFFE8E3D9), width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bone,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _archivo(size: 19, weight: FontWeight.w600, color: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDD8CE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDD8CE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: tipperAmber, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: _publicSans(size: 14, color: slate),
        hintStyle: _publicSans(size: 14, color: slate),
        errorStyle: _publicSans(size: 12, color: const Color(0xFFB3261E)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: tipperAmber,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: _publicSans(
                size: 16,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) return laterite;
                if (states.contains(WidgetState.disabled)) {
                  return tipperAmber.withValues(alpha: 0.5);
                }
                return tipperAmber;
              }),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: tipperAmber,
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: tipperAmber, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: _publicSans(size: 16, weight: FontWeight.w700),
            ).copyWith(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) return laterite;
                return tipperAmber;
              }),
              side: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return const BorderSide(color: laterite, width: 1.5);
                }
                return const BorderSide(color: tipperAmber, width: 1.5);
              }),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tipperAmber,
          textStyle: _publicSans(size: 14, weight: FontWeight.w600),
        ),
      ),
    );
  }
}
