import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/tt_style.dart';
import '../../providers/booking_provider.dart';
import '../../providers/config_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/booking_step_bar.dart';
import '../../widgets/tt_atmosphere.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final config = context.watch<ConfigProvider>().config;
    final draft = booking.draft;

    if (!draft.hasSand || !draft.hasTruck || draft.region.isEmpty) {
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

    final base = booking.basePriceGhs(config);
    final feeRaw = booking.surchargeGhs(config) ?? '0.00';
    final feeVal = double.tryParse(feeRaw) ?? 0;
    final total = booking.previewTotalGhs(config);
    final feeLabel = feeVal <= 0 ? 'FREE' : 'GHS $feeRaw';

    return TtAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Summary'),
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
                  const BookingStepBar(current: 3),
                  const SizedBox(height: 18),
                  Text('Review order', style: TtStyle.display(30)),
                  const SizedBox(height: 8),
                  Text(
                    'Everything look right? Next step is payment.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.slate,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hero total
                  _TotalHero(
                    totalGhs: total,
                    sand: draft.sandType!.name,
                    truck: draft.truckType!.name,
                  ),
                  const SizedBox(height: 14),

                  // Load
                  _SummaryCard(
                    eyebrow: 'Load',
                    onEdit: () => context.go(AppRoutes.bookingTruck),
                    child: Row(
                      children: [
                        _IconWell(
                          icon: Icons.grain_rounded,
                          tone: AppTheme.tipperAmber.withValues(alpha: 0.14),
                          iconColor: AppTheme.laterite,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                draft.sandType!.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${draft.truckType!.name} · ${draft.truckType!.capacityLabel}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.slate),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Delivery
                  _SummaryCard(
                    eyebrow: 'Delivery',
                    onEdit: () => context.pop(),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.person_rounded,
                          title: draft.recipientName,
                          subtitle: draft.recipientPhone,
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: TtStyle.line),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.place_rounded,
                          title: draft.streetAddress,
                          subtitle:
                              '${draft.city}, ${draft.region}'
                              '${draft.landmark.isNotEmpty ? '\nNear ${draft.landmark}' : ''}',
                        ),
                        if (draft.deliveryNote.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: TtStyle.line),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.sticky_note_2_outlined,
                            title: 'Note',
                            subtitle: draft.deliveryNote,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Receipt
                  _ReceiptCard(
                    baseGhs: base,
                    feeLabel: feeLabel,
                    feeFree: feeVal <= 0,
                    totalGhs: total,
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
                decoration: BoxDecoration(
                  color: TtStyle.paper.withValues(alpha: 0.96),
                  border: const Border(top: BorderSide(color: TtStyle.line)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.ink.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: AppButton(
                  label: 'Proceed to payment',
                  dark: true,
                  large: true,
                  onPressed: () => context.push(AppRoutes.bookingPayment),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalHero extends StatelessWidget {
  final String? totalGhs;
  final String sand;
  final String truck;

  const _TotalHero({
    required this.totalGhs,
    required this.sand,
    required this.truck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE06A1A),
            AppTheme.tipperAmber,
            AppTheme.laterite,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tipperAmber.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -24,
            child: Icon(
              Icons.local_shipping_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PREVIEW TOTAL',
                style: TtStyle.eyebrow(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 8),
              Text(
                totalGhs == null ? 'GHS —' : 'GHS $totalGhs',
                style: TtStyle.display(36, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$sand · $truck',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String eyebrow;
  final Widget child;
  final VoidCallback? onEdit;

  const _SummaryCard({
    required this.eyebrow,
    required this.child,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
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
              Expanded(
                child: Text(
                  eyebrow.toUpperCase(),
                  style: TtStyle.eyebrow(color: AppTheme.slate),
                ),
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.laterite,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(48, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _IconWell extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final Color iconColor;

  const _IconWell({
    required this.icon,
    required this.tone,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: iconColor),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconWell(
          icon: icon,
          tone: AppTheme.ink.withValues(alpha: 0.06),
          iconColor: AppTheme.ink,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.slate,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final String? baseGhs;
  final String feeLabel;
  final bool feeFree;
  final String? totalGhs;

  const _ReceiptCard({
    required this.baseGhs,
    required this.feeLabel,
    required this.feeFree,
    required this.totalGhs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(22),
        boxShadow: TtStyle.softLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRICE BREAKDOWN',
            style: TtStyle.eyebrow(color: AppTheme.tipperAmber),
          ),
          const SizedBox(height: 14),
          _moneyRow(
            context,
            'Sand + truck',
            baseGhs == null ? '—' : 'GHS $baseGhs',
          ),
          const SizedBox(height: 10),
          _moneyRow(
            context,
            'Delivery fee',
            feeLabel,
            accent: feeFree ? const Color(0xFF7DCEA0) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(height: 1, color: Colors.white12),
          ),
          Row(
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                totalGhs == null ? 'GHS —' : 'GHS $totalGhs',
                style: TtStyle.display(26, color: AppTheme.tipperAmber),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Server confirms the final total when you place the order.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white54,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(
    BuildContext context,
    String label,
    String value, {
    Color? accent,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTheme.moneyStyle.copyWith(
            color: accent ?? Colors.white,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
