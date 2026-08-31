import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../config/tt_style.dart';

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? TtStyle.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TtStyle.line),
        boxShadow: TtStyle.softLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: TtStyle.eyebrow(color: AppTheme.slate),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}
