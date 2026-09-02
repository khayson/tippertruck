import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../config/tt_style.dart';

/// Labeled checkout stepper — adapted from ticket-booking payment flows.
/// [current] is 1-based (1 = first step active).
class BookingStepBar extends StatelessWidget {
  final int current;
  final List<String> labels;

  const BookingStepBar({
    super.key,
    required this.current,
    this.labels = const ['Load', 'Deliver', 'Review', 'Pay'],
  });

  @override
  Widget build(BuildContext context) {
    final total = labels.length;

    return Column(
      children: [
        SizedBox(
          height: 28,
          child: Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                _Node(index: i, current: current),
                if (i < total - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < current - 1
                          ? AppTheme.tipperAmber
                          : TtStyle.line,
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < total; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: i == 0
                      ? TextAlign.left
                      : i == total - 1
                      ? TextAlign.right
                      : TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: i < current ? AppTheme.tipperAmber : AppTheme.slate,
                    fontWeight: i == current - 1
                        ? FontWeight.w800
                        : FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  final int index;
  final int current;

  const _Node({required this.index, required this.current});

  @override
  Widget build(BuildContext context) {
    final done = index < current - 1;
    final active = index == current - 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done || active ? AppTheme.tipperAmber : Colors.white,
        border: Border.all(
          color: done || active ? AppTheme.tipperAmber : TtStyle.line,
          width: 2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppTheme.tipperAmber.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : active
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
