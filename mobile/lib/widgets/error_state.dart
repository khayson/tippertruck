import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../config/tt_style.dart';
import 'app_button.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: TtStyle.paper,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: TtStyle.line),
                boxShadow: TtStyle.softLift,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: const Color(0xFFB3261E).withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.ink, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 168,
                child: AppButton(
                  label: 'Try again',
                  onPressed: onRetry,
                  outlined: true,
                  dark: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
