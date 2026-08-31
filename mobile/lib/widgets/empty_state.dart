import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../config/tt_style.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

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
              child: Icon(icon, size: 36, color: AppTheme.laterite),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TtStyle.display(22),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.slate,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
