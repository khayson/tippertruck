import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../config/tt_style.dart';

class TtPageHeader extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;

  const TtPageHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: TtStyle.eyebrow(color: AppTheme.laterite),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                title,
                style: TtStyle.display(30, color: titleColor),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.slate,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class TtAvatar extends StatelessWidget {
  final String letter;
  final double size;

  const TtAvatar({super.key, required this.letter, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.ink, TtStyle.inkSoft],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: TtStyle.softLift,
      ),
      child: Text(
        letter.toUpperCase(),
        style: TtStyle.display(size * 0.38, color: Colors.white),
      ),
    );
  }
}
