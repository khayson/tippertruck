import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../config/tt_style.dart';
import '../models/order.dart';
import 'status_badge.dart';

class TtOrderTile extends StatelessWidget {
  final OrderSummary order;
  final VoidCallback onTap;
  final String? meta;
  final Widget? footer;
  final bool showProgress;
  final bool showAddress;
  final bool featured;

  const TtOrderTile({
    super.key,
    required this.order,
    required this.onTap,
    this.meta,
    this.footer,
    this.showProgress = true,
    this.showAddress = false,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = TtStyle.statusColor(order.status);
    final isActive = !order.isTerminal;

    if (featured) {
      return _FeaturedTile(
        order: order,
        accent: accent,
        meta: meta,
        onTap: onTap,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: TtStyle.paper,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: TtStyle.line),
            boxShadow: TtStyle.softLift,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isActive
                            ? Icons.local_shipping_rounded
                            : order.status == 'delivered'
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderRef,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${order.sandTypeName} · ${order.truckTypeName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.slate),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(label: order.statusLabel, color: accent),
                  ],
                ),
                if (showAddress) ...[
                  const SizedBox(height: 10),
                  Text(
                    order.delivery.formattedAddress,
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: AppTheme.slate.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${order.delivery.city}, ${order.delivery.region}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.slate),
                      ),
                    ),
                    if (order.payment != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EEE4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          order.payment!.method == 'momo' ? 'MoMo' : 'COD',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                        ),
                      ),
                  ],
                ),
                if (showProgress && isActive) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: order.progressPercent / 100,
                            minHeight: 7,
                            backgroundColor: AppTheme.loadBarTrack,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${order.progressPercent}%',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'GHS ${order.totalGhs}',
                      style: AppTheme.moneyStyle.copyWith(
                        color: AppTheme.tipperAmber,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    if (meta != null)
                      Text(
                        meta!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.slate),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.slate.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                if (footer != null) ...[const SizedBox(height: 12), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedTile extends StatelessWidget {
  final OrderSummary order;
  final Color accent;
  final String? meta;
  final VoidCallback onTap;

  const _FeaturedTile({
    required this.order,
    required this.accent,
    required this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.ink,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('LIVE ORDER', style: TtStyle.eyebrow(color: accent)),
                    const Spacer(),
                    if (meta != null)
                      Text(
                        meta!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  order.orderRef,
                  style: TtStyle.display(26, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  '${order.sandTypeName} · ${order.truckTypeName}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: order.progressPercent / 100,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    color: accent,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatusBadge(label: order.statusLabel, color: accent),
                    const Spacer(),
                    Text(
                      '${order.progressPercent}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${order.delivery.city}, ${order.delivery.region}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ),
                    Text(
                      'Track',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.tipperAmber,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppTheme.tipperAmber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
