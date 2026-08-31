import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/tt_style.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/tt_order_tile.dart';
import '../../widgets/tt_page_header.dart';

enum _OrderFilter { all, active, delivered, cancelled }

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  _OrderFilter _filter = _OrderFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersProvider>().loadHistory();
    });
  }

  String _relative(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }

  List<OrderSummary> _filtered(List<OrderSummary> all) {
    return switch (_filter) {
      _OrderFilter.all => all,
      _OrderFilter.active =>
        all.where((o) => !o.isTerminal).toList(growable: false),
      _OrderFilter.delivered =>
        all.where((o) => o.status == 'delivered').toList(growable: false),
      _OrderFilter.cancelled =>
        all.where((o) => o.status == 'cancelled').toList(growable: false),
    };
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>();
    final all = orders.orders;
    final active = all.where((o) => !o.isTerminal).toList();
    final delivered = all.where((o) => o.status == 'delivered').length;
    final filtered = _filtered(all);
    final featured = active.isNotEmpty ? active.first : null;
    final list = featured == null
        ? filtered
        : filtered.where((o) => o.id != featured.id).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.tipperAmber,
          onRefresh: () => orders.loadHistory(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TtPageHeader(
                        eyebrow: 'History',
                        title: 'Your orders',
                        subtitle: all.isEmpty
                            ? 'Every load from confirmed through delivery.'
                            : '${all.length} total · ${active.length} active',
                      ),
                      if (orders.fromCache) ...[
                        const SizedBox(height: 14),
                        const OfflineBanner(),
                      ],
                      if (all.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _StatsRow(
                          active: active.length,
                          delivered: delivered,
                          total: all.length,
                        ),
                        const SizedBox(height: 16),
                        _FilterRow(
                          selected: _filter,
                          onChanged: (f) => setState(() => _filter = f),
                          activeCount: active.length,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (orders.loading && all.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (orders.error != null && all.isEmpty)
                SliverFillRemaining(
                  child: ErrorState(
                    message: orders.error!,
                    onRetry: () => orders.loadHistory(),
                  ),
                )
              else if (all.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                    subtitle: 'Book a truck from Home to get started.',
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.filter_list_rounded,
                    title: 'Nothing here',
                    subtitle: 'No orders match this filter.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (featured != null &&
                          (_filter == _OrderFilter.all ||
                              _filter == _OrderFilter.active)) ...[
                        TtOrderTile(
                          order: featured,
                          featured: true,
                          meta: _relative(featured.createdAt),
                          onTap: () => context.push(
                            '${AppRoutes.tracking}/${featured.id}',
                          ),
                        ),
                        if (list.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            _filter == _OrderFilter.all
                                ? 'Earlier orders'
                                : 'Other active',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        TtOrderTile(
                          order: list[i],
                          meta: _relative(list[i].createdAt),
                          onTap: () => context.push(
                            '${AppRoutes.tracking}/${list[i].id}',
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int active;
  final int delivered;
  final int total;

  const _StatsRow({
    required this.active,
    required this.delivered,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Active',
            value: '$active',
            color: AppTheme.tipperAmber,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Delivered',
            value: '$delivered',
            color: AppTheme.signal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'All',
            value: '$total',
            color: AppTheme.ink,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: TtStyle.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TtStyle.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TtStyle.eyebrow(color: AppTheme.slate),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TtStyle.display(24, color: color),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _OrderFilter selected;
  final ValueChanged<_OrderFilter> onChanged;
  final int activeCount;

  const _FilterRow({
    required this.selected,
    required this.onChanged,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (_OrderFilter.all, 'All', null),
      (_OrderFilter.active, 'Active', activeCount > 0 ? activeCount : null),
      (_OrderFilter.delivered, 'Delivered', null),
      (_OrderFilter.cancelled, 'Cancelled', null),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.$2),
                    if (item.$3 != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: selected == item.$1
                              ? Colors.white.withValues(alpha: 0.25)
                              : AppTheme.tipperAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${item.$3}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: selected == item.$1,
                onSelected: (_) => onChanged(item.$1),
                selectedColor: AppTheme.ink,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected == item.$1 ? Colors.white : AppTheme.ink,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: selected == item.$1 ? AppTheme.ink : TtStyle.line,
                ),
                backgroundColor: TtStyle.paper,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
