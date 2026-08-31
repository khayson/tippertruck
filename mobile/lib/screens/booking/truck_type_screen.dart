import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/tt_style.dart';
import '../../models/config_data.dart';
import '../../providers/booking_provider.dart';
import '../../providers/config_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/booking_step_bar.dart';
import '../../widgets/tt_atmosphere.dart';

class TruckTypeScreen extends StatelessWidget {
  const TruckTypeScreen({super.key});

  String? _matrixPrice(ConfigData? config, SandType? sand, TruckType truck) {
    if (config == null || sand == null) return null;
    for (final row in config.priceMatrix) {
      if (row.sandTypeId == sand.id && row.truckTypeId == truck.id) {
        return row.priceGhs;
      }
    }
    return null;
  }

  /// Relative fill for the capacity meter (visual only — not volume math).
  double _capacityWeight(TruckType truck) {
    final slug = truck.slug.toLowerCase();
    if (slug.contains('large') || slug.contains('big')) return 1.0;
    if (slug.contains('medium') || slug.contains('mid')) return 0.68;
    return 0.4;
  }

  String _bestFor(TruckType truck) {
    final slug = truck.slug.toLowerCase();
    if (slug.contains('large') || slug.contains('big')) {
      return 'Big builds · foundations · bulk fills';
    }
    if (slug.contains('medium') || slug.contains('mid')) {
      return 'Most jobs · plaster + concrete mix';
    }
    return 'Small sites · touch-ups · tight access';
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final config = context.watch<ConfigProvider>().config;
    final sand = booking.draft.sandType;
    final trucks = config?.truckTypes ?? [];
    final selected = booking.draft.truckType;
    final selectedPrice =
        selected == null ? null : _matrixPrice(config, sand, selected);

    if (sand == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRoutes.leaveHomeIfCurrent(context);
      });
      return const TtAtmosphere(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final popular = trucks.where((t) => t.isPopular).toList();
    final tip = popular.isNotEmpty
        ? '${popular.first.name} is the usual pick for ${sand.name}.'
        : 'Prices update from the live ${sand.name} rate card.';

    return TtAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Truck size'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => AppRoutes.popOrHome(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                children: [
                  const BookingStepBar(current: 1),
                  const SizedBox(height: 18),
                  _SandHero(sand: sand),
                  const SizedBox(height: 22),
                  Text('How big a load?', style: TtStyle.display(30)),
                  const SizedBox(height: 8),
                  Text(
                    'Tap a size — price is ${sand.name} × truck from the server rate card. No client-side maths.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.slate,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SmartTip(text: tip),
                  const SizedBox(height: 20),
                  ...trucks.map((truck) {
                    final price = _matrixPrice(config, sand, truck);
                    final isSelected = selected?.id == truck.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TruckCard(
                        truck: truck,
                        priceGhs: price,
                        selected: isSelected,
                        capacityWeight: _capacityWeight(truck),
                        bestFor: _bestFor(truck),
                        onTap: () => booking.selectTruck(truck),
                      ),
                    );
                  }),
                ],
              ),
            ),
            _ContinueDock(
              selected: selected,
              priceGhs: selectedPrice,
              onContinue: selected == null
                  ? null
                  : () => context.push(AppRoutes.bookingDelivery),
            ),
          ],
        ),
      ),
    );
  }
}

class _SandHero extends StatelessWidget {
  final SandType sand;

  const _SandHero({required this.sand});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: TtStyle.softLift,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.tipperAmber.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.grain_rounded, color: AppTheme.tipperAmber),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOADING',
                  style: TtStyle.eyebrow(color: AppTheme.tipperAmber),
                ),
                const SizedBox(height: 4),
                Text(
                  sand.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sand.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartTip extends StatelessWidget {
  final String text;

  const _SmartTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.tipperAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.tipperAmber.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: AppTheme.laterite,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TruckCard extends StatelessWidget {
  final TruckType truck;
  final String? priceGhs;
  final bool selected;
  final double capacityWeight;
  final String bestFor;
  final VoidCallback onTap;

  const _TruckCard({
    required this.truck,
    required this.priceGhs,
    required this.selected,
    required this.capacityWeight,
    required this.bestFor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = selected ? Colors.white : AppTheme.ink;
    final muted = selected
        ? Colors.white.withValues(alpha: 0.7)
        : AppTheme.slate;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: selected ? AppTheme.ink : TtStyle.paper,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected ? AppTheme.tipperAmber : TtStyle.line,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.tipperAmber.withValues(alpha: 0.28),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : TtStyle.softLift,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.tipperAmber.withValues(alpha: 0.22)
                          : const Color(0xFFF3EEE4),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: selected
                          ? AppTheme.tipperAmber
                          : AppTheme.laterite,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                truck.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            if (truck.isPopular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.tipperAmber,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'POPULAR',
                                  style: TtStyle.eyebrow(color: Colors.white)
                                      .copyWith(fontSize: 9, letterSpacing: 1),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          truck.capacityLabel,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: selected ? 1 : 0.35,
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: selected ? AppTheme.tipperAmber : muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'CAPACITY',
                style: TtStyle.eyebrow(color: muted),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: capacityWeight),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: selected
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFE8E0D4),
                      color: AppTheme.tipperAmber,
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.handyman_outlined, size: 16, color: muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      bestFor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF3EEE4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      'BASE FOR ${truck.name.toUpperCase()}',
                      style: TtStyle.eyebrow(color: muted),
                    ),
                    const Spacer(),
                    Text(
                      priceGhs == null ? '—' : 'GHS $priceGhs',
                      style: AppTheme.moneyStyle.copyWith(
                        fontSize: 20,
                        color: AppTheme.tipperAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueDock extends StatelessWidget {
  final TruckType? selected;
  final String? priceGhs;
  final VoidCallback? onContinue;

  const _ContinueDock({
    required this.selected,
    required this.priceGhs,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
        decoration: BoxDecoration(
          color: TtStyle.paper.withValues(alpha: 0.96),
          border: const Border(top: BorderSide(color: TtStyle.line)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: selected == null
                  ? Text(
                      key: const ValueKey('empty'),
                      'Choose a truck size to continue',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.slate,
                      ),
                    )
                  : Row(
                      key: ValueKey(selected!.id),
                      children: [
                        Expanded(
                          child: Text(
                            '${selected!.name} · ${selected!.capacityLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          priceGhs == null ? '—' : 'GHS $priceGhs',
                          style: AppTheme.moneyStyle.copyWith(
                            fontSize: 18,
                            color: AppTheme.tipperAmber,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: selected == null
                  ? 'Select a truck'
                  : 'Continue with ${selected!.name}',
              dark: true,
              large: true,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
