import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;

  /// Fully rounded pill shape (auth / marketing CTAs).
  final bool pill;

  /// Ink fill instead of tipperAmber (matches auth mockups).
  final bool dark;

  /// Taller tap target and larger label (welcome CTAs).
  final bool large;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.pill = false,
    this.dark = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = large ? 64.0 : 56.0;
    final radius = BorderRadius.circular(pill ? 40 : (large ? 12 : 10));
    final labelStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: large ? 17 : 16,
      fontWeight: FontWeight.w700,
      color: outlined
          ? (dark ? AppTheme.ink : AppTheme.tipperAmber)
          : Colors.white,
    );
    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined
                  ? (dark ? AppTheme.ink : AppTheme.tipperAmber)
                  : Colors.white,
            ),
          )
        : Text(label, style: labelStyle);

    if (outlined) {
      final borderColor = dark ? AppTheme.ink : AppTheme.tipperAmber;
      return OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: borderColor,
          minimumSize: Size(double.infinity, height),
          side: BorderSide(color: borderColor, width: large ? 2 : 1.5),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: labelStyle,
        ),
        child: child,
      );
    }

    final fill = dark ? AppTheme.ink : AppTheme.tipperAmber;
    final pressed = dark ? const Color(0xFF2E2A24) : AppTheme.laterite;

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style:
          ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, height),
            shape: RoundedRectangleBorder(borderRadius: radius),
            textStyle: labelStyle,
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) return pressed;
              if (states.contains(WidgetState.disabled)) {
                return fill.withValues(alpha: 0.5);
              }
              return fill;
            }),
          ),
      child: child,
    );
  }
}
