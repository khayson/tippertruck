import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/tt_style.dart';
import '../../core/api_exception.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/error_state.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tt_atmosphere.dart';

class TrackingScreen extends StatefulWidget {
  final int orderId;

  const TrackingScreen({super.key, required this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Timer? _timer;
  DateTime? _startedAt;
  bool _cancelling = false;
  bool _polling = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<OrdersProvider>().loadTracked(widget.orderId);
      if (!mounted) return;
      _startedAt = DateTime.now();
      _schedulePoll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _schedulePoll();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  void _schedulePoll() {
    if (!mounted) return;
    _timer?.cancel();
    final order = context.read<OrdersProvider>().tracked;
    if (order == null || order.isTerminal) {
      _pulse.stop();
      return;
    }
    if (!_pulse.isAnimating) _pulse.repeat(reverse: true);

    final elapsed = _startedAt == null
        ? Duration.zero
        : DateTime.now().difference(_startedAt!);
    final interval = elapsed.inMinutes >= 5
        ? const Duration(seconds: 30)
        : const Duration(seconds: 8);

    _timer = Timer(interval, () async {
      if (!mounted) return;
      setState(() => _polling = true);
      await context.read<OrdersProvider>().pollTracked(widget.orderId);
      if (!mounted) return;
      setState(() => _polling = false);
      _schedulePoll();
    });
  }

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await context.read<OrdersProvider>().cancelTracked(widget.orderId);
      if (!mounted) return;
      AppToast.success(context, 'Order cancelled.');
      _timer?.cancel();
      _pulse.stop();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  String _headline(OrderSummary order) {
    return switch (order.status) {
      'confirmed' => 'Tipper confirmed',
      'on_the_way' => 'On the road to you',
      'delivered' => 'Sand delivered',
      'cancelled' => 'Order cancelled',
      _ => order.statusLabel,
    };
  }

  String _subhead(OrderSummary order) {
    return switch (order.status) {
      'confirmed' =>
        'We are staging your ${order.sandTypeName.toLowerCase()} load.',
      'on_the_way' =>
        'Driver is heading to ${order.delivery.city}.',
      'delivered' => 'Thanks for ordering with Tipper Truck.',
      'cancelled' => 'This load will not be dispatched.',
      _ => 'Live status from the yard.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>();
    final order = orders.tracked?.id == widget.orderId ? orders.tracked : null;
    final accent = order == null
        ? AppTheme.tipperAmber
        : TtStyle.statusColor(order.status);

    return TtAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Tracking'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                AppRoutes.leaveToShell(context, AppRoutes.orders),
          ),
          actions: [
            if (order != null && !order.isTerminal)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(
                            alpha: 0.12 + (_pulse.value * 0.1),
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _polling ? 'Updating' : 'Live',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
        body: orders.loading && order == null
            ? const Center(child: CircularProgressIndicator())
            : orders.error != null && order == null
            ? ErrorState(
                message: orders.error!,
                onRetry: () => orders.loadTracked(widget.orderId),
              )
            : order == null
            ? const ErrorState(message: 'Order not found.')
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                      children: [
                        _HeroPanel(
                          order: order,
                          accent: accent,
                          headline: _headline(order),
                          subhead: _subhead(order),
                          pulse: _pulse,
                        ),
                        const SizedBox(height: 18),
                        _Timeline(status: order.status, accent: accent),
                        const SizedBox(height: 14),
                        _DetailCard(
                          icon: Icons.inventory_2_outlined,
                          title: 'Load',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${order.sandTypeName} · ${order.truckTypeName}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (order.capacityLabel.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  order.capacityLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppTheme.slate),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    'TOTAL',
                                    style: TtStyle.eyebrow(
                                      color: AppTheme.slate,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'GHS ${order.totalGhs}',
                                    style: AppTheme.moneyStyle.copyWith(
                                      fontSize: 20,
                                      color: AppTheme.tipperAmber,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DetailCard(
                          icon: Icons.place_outlined,
                          title: 'Delivery',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.delivery.recipientName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.delivery.recipientPhone,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.slate),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.delivery.formattedAddress,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(height: 1.35),
                              ),
                            ],
                          ),
                        ),
                        if (order.payment != null) ...[
                          const SizedBox(height: 12),
                          _DetailCard(
                            icon: order.payment!.method == 'momo'
                                ? Icons.phone_android_rounded
                                : Icons.payments_outlined,
                            title: 'Payment',
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    order.payment!.method == 'momo'
                                        ? 'Mobile Money'
                                        : 'Cash on delivery',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                StatusBadge(
                                  label: order.payment!.status,
                                  color: order.payment!.status == 'paid' ||
                                          order.payment!.status == 'pending'
                                      ? AppTheme.signal
                                      : AppTheme.slate,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                      child: Column(
                        children: [
                          if (order.canCancel) ...[
                            AppButton(
                              label: 'Cancel order',
                              outlined: true,
                              dark: true,
                              loading: _cancelling,
                              onPressed: _cancel,
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'History',
                                  outlined: true,
                                  onPressed: () => AppRoutes.leaveToShell(
                                    context,
                                    AppRoutes.orders,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppButton(
                                  label: 'New order',
                                  dark: true,
                                  onPressed: () => AppRoutes.leaveToShell(
                                    context,
                                    AppRoutes.home,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final OrderSummary order;
  final Color accent;
  final String headline;
  final String subhead;
  final Animation<double> pulse;

  const _HeroPanel({
    required this.order,
    required this.accent,
    required this.headline,
    required this.subhead,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            order.orderRef,
            style: TtStyle.eyebrow(color: accent),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 120,
            height: 120,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: order.progressPercent / 100,
                    accent: accent,
                    glow: order.isTerminal ? 0 : pulse.value,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${order.progressPercent}',
                          style: TtStyle.display(32, color: Colors.white),
                        ),
                        Text(
                          '%',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: TtStyle.display(26, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            subhead,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          StatusBadge(label: order.statusLabel, color: accent),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final double glow;

  _ProgressRingPainter({
    required this.progress,
    required this.accent,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    final sweep = (progress.clamp(0.0, 1.0)) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      paint,
    );

    if (glow > 0) {
      final halo = Paint()
        ..color = accent.withValues(alpha: 0.18 * glow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        halo,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.glow != glow;
  }
}

class _Timeline extends StatelessWidget {
  final String status;
  final Color accent;

  const _Timeline({required this.status, required this.accent});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        'Confirmed',
        'Order accepted at the yard',
        Icons.verified_rounded,
      ),
      (
        'On the way',
        'Tipper left for delivery',
        Icons.local_shipping_rounded,
      ),
      (
        'Delivered',
        'Sand tipped at your site',
        Icons.flag_rounded,
      ),
    ];

    final active = switch (status) {
      'confirmed' => 0,
      'on_the_way' => 1,
      'delivered' => 2,
      'cancelled' => -1,
      _ => -1,
    };

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
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 19),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 2,
                    height: 18,
                    color: active >= i ? accent : TtStyle.line,
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active >= i
                        ? accent.withValues(alpha: 0.15)
                        : const Color(0xFFF3EEE4),
                    border: Border.all(
                      color: active >= i ? accent : TtStyle.line,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    active > i
                        ? Icons.check_rounded
                        : steps[i].$3,
                    size: 18,
                    color: active >= i ? accent : AppTheme.slate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].$1,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: active >= i
                                    ? AppTheme.ink
                                    : AppTheme.slate,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[i].$2,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.slate),
                        ),
                      ],
                    ),
                  ),
                ),
                if (active == i)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'NOW',
                      style: TtStyle.eyebrow(color: accent).copyWith(
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (status == 'cancelled') ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFB3261E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'This order was cancelled and will not move further.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB3261E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _DetailCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: TtStyle.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TtStyle.line),
        boxShadow: TtStyle.softLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.laterite),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TtStyle.eyebrow(color: AppTheme.slate),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
