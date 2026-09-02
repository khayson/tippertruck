import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/tt_style.dart';
import '../../models/order.dart';
import '../../providers/booking_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/booking_step_bar.dart';
import '../../widgets/error_state.dart';
import '../../widgets/tt_atmosphere.dart';

/// Celebration screen after place-order — MoMo and COD share layout, different copy.
class OrderSuccessScreen extends StatefulWidget {
  final int orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BookingProvider>().clearDraft();
      final orders = context.read<OrdersProvider>();
      if (orders.tracked?.id != widget.orderId) {
        orders.loadTracked(widget.orderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>();
    final order = orders.tracked?.id == widget.orderId ? orders.tracked : null;

    if (order == null) {
      return TtAtmosphere(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: orders.loading
              ? const Center(child: CircularProgressIndicator())
              : ErrorState(
                  message: 'Could not load your order.',
                  onRetry: () => context.read<OrdersProvider>().loadTracked(
                    widget.orderId,
                  ),
                ),
        ),
      );
    }

    return TtAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: _SuccessContent(order: order)),
      ),
    );
  }
}

class _SuccessContent extends StatefulWidget {
  final OrderSummary order;

  const _SuccessContent({required this.order});

  @override
  State<_SuccessContent> createState() => _SuccessContentState();
}

class _SuccessContentState extends State<_SuccessContent>
    with TickerProviderStateMixin {
  late final AnimationController _main;
  late final AnimationController _pulse;
  late final Animation<double> _ring;
  late final Animation<double> _badge;
  late final Animation<double> _check;
  late final Animation<double> _title;
  late final Animation<double> _body;
  late final Animation<double> _card;
  late final Animation<double> _actions;
  late final Animation<double> _sparkles;

  @override
  void initState() {
    super.initState();
    _main = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _ring = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    );
    _badge = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.08, 0.42, curve: Curves.easeOutBack),
    );
    _check = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.22, 0.55, curve: Curves.easeOutBack),
    );
    _title = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.38, 0.65, curve: Curves.easeOutCubic),
    );
    _body = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.45, 0.72, curve: Curves.easeOutCubic),
    );
    _card = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.52, 0.82, curve: Curves.easeOutCubic),
    );
    _actions = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.68, 1.0, curve: Curves.easeOutCubic),
    );
    _sparkles = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.18, 0.7, curve: Curves.easeOut),
    );

    _main.forward();
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _pulse.repeat();
    });
  }

  @override
  void dispose() {
    _main.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isMomo = order.payment?.method == 'momo';
    final title = isMomo ? 'Payment confirmed' : 'Order placed';
    final body = isMomo
        ? 'Your Mobile Money request is in. We will dispatch a tipper as soon as the load is ready.'
        : 'Cash on delivery is set. Have GHS ${order.totalGhs} ready for the driver when the sand arrives.';

    return AnimatedBuilder(
      animation: Listenable.merge([_main, _pulse]),
      builder: (context, _) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                children: [
                  Opacity(
                    opacity: _title.value.clamp(0.0, 1.0),
                    child: const BookingStepBar(
                      current: 5,
                      labels: ['Load', 'Deliver', 'Review', 'Done'],
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft spark bursts
                        ..._buildSparks(_sparkles.value),
                        // Expanding pulse ring
                        Transform.scale(
                          scale: 0.85 + (_pulse.value * 0.35),
                          child: Opacity(
                            opacity: (1 - _pulse.value) * 0.45 * _ring.value,
                            child: Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.signal,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Outer fade ring from entrance
                        Opacity(
                          opacity: (1 - _ring.value) * 0.5,
                          child: Transform.scale(
                            scale: 0.6 + _ring.value * 0.8,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.signal.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                        ),
                        // Badge
                        Transform.scale(
                          scale: _badge.value,
                          child: Opacity(
                            opacity: _badge.value.clamp(0.0, 1.0),
                            child: Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.signal.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: AppTheme.signal.withValues(alpha: 0.4),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.signal.withValues(
                                      alpha: 0.28 * _badge.value,
                                    ),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Transform.scale(
                                scale: _check.value,
                                child: Opacity(
                                  opacity: _check.value.clamp(0.0, 1.0),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 56,
                                    color: AppTheme.signal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FadeSlide(
                    progress: _title.value,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TtStyle.display(32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FadeSlide(
                    progress: _body.value,
                    dy: 16,
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.slate,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _FadeSlide(
                    progress: _card.value,
                    dy: 28,
                    child: _OrderCard(order: order, isMomo: isMomo),
                  ),
                ],
              ),
            ),
            _FadeSlide(
              progress: _actions.value,
              dy: 24,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: Column(
                  children: [
                    AppButton(
                      label: 'Track your order',
                      large: true,
                      onPressed: () =>
                          context.go('${AppRoutes.tracking}/${order.id}'),
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Back to home',
                      large: true,
                      outlined: true,
                      dark: true,
                      onPressed: () =>
                          AppRoutes.leaveToShell(context, AppRoutes.home),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildSparks(double t) {
    if (t <= 0) return const [];
    const seeds = [
      (0.15, -58.0, -42.0, AppTheme.tipperAmber),
      (0.28, 62.0, -36.0, AppTheme.signal),
      (0.4, -70.0, 18.0, AppTheme.laterite),
      (0.52, 68.0, 22.0, AppTheme.tipperAmber),
      (0.65, -40.0, 52.0, AppTheme.signal),
      (0.72, 48.0, 48.0, Color(0xFFE8A838)),
      (0.35, 0.0, -72.0, AppTheme.tipperAmber),
      (0.58, -18.0, 64.0, AppTheme.signal),
    ];

    return [
      for (final s in seeds)
        Builder(
          builder: (context) {
            final local = ((t - s.$1) / 0.35).clamp(0.0, 1.0);
            if (local <= 0) return const SizedBox.shrink();
            final rise = Curves.easeOut.transform(local);
            final fade = (1 - local);
            return Transform.translate(
              offset: Offset(s.$2 * rise, s.$3 * rise),
              child: Opacity(
                opacity: fade * 0.9,
                child: Transform.rotate(
                  angle: rise * math.pi,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: s.$4,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: s.$4.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
    ];
  }
}

class _FadeSlide extends StatelessWidget {
  final double progress;
  final double dy;
  final Widget child;

  const _FadeSlide({required this.progress, this.dy = 18, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    return Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, dy * (1 - t)), child: child),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderSummary order;
  final bool isMomo;

  const _OrderCard({required this.order, required this.isMomo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: TtStyle.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TtStyle.line),
        boxShadow: TtStyle.softLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORDER',
                      style: TtStyle.eyebrow(color: AppTheme.laterite),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.orderRef,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isMomo
                      ? AppTheme.tipperAmber.withValues(alpha: 0.14)
                      : AppTheme.signal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isMomo ? 'MoMo' : 'Cash on delivery',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isMomo ? AppTheme.laterite : AppTheme.signal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: TtStyle.line),
          const SizedBox(height: 14),
          _Row(
            label: 'Load',
            value: '${order.sandTypeName} · ${order.truckTypeName}',
          ),
          const SizedBox(height: 10),
          _Row(label: 'Deliver to', value: order.delivery.recipientName),
          const SizedBox(height: 4),
          Text(
            '${order.delivery.city}, ${order.delivery.region}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.slate),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: TtStyle.line),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                'GHS ${order.totalGhs}',
                style: TtStyle.display(22, color: AppTheme.tipperAmber),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.slate),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}
