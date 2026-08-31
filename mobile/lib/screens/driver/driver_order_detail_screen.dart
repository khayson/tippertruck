import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/tt_style.dart';
import '../../core/api_exception.dart';
import '../../providers/driver_orders_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/error_state.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tt_atmosphere.dart';

class DriverOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const DriverOrderDetailScreen({super.key, required this.orderId});

  @override
  State<DriverOrderDetailScreen> createState() =>
      _DriverOrderDetailScreenState();
}

class _DriverOrderDetailScreenState extends State<DriverOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverOrdersProvider>().loadOrder(widget.orderId);
    });
  }

  Future<void> _dispatch() async {
    final driver = context.read<DriverOrdersProvider>();
    try {
      await driver.dispatch(widget.orderId);
      if (!mounted) return;
      AppToast.success(context, 'Marked on the way.');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    }
  }

  Future<void> _deliver() async {
    final driver = context.read<DriverOrdersProvider>();
    try {
      await driver.deliver(widget.orderId);
      if (!mounted) return;
      AppToast.success(context, 'Marked delivered.');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverOrdersProvider>();
    final order = driver.selected;
    final accent = order == null
        ? AppTheme.tipperAmber
        : TtStyle.statusColor(order.status);

    return TtAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(order?.orderRef ?? 'Delivery'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: driver.loading && order == null
            ? const Center(child: CircularProgressIndicator())
            : driver.error != null && order == null
            ? ErrorState(
                message: driver.error!,
                onRetry: () => driver.loadOrder(widget.orderId),
              )
            : order == null
            ? const ErrorState(message: 'Order not found.')
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderRef, style: TtStyle.display(28)),
                    const SizedBox(height: 12),
                    StatusBadge(
                      label: order.statusLabel,
                      color: accent,
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: order.progressPercent / 100,
                        minHeight: 10,
                        backgroundColor: AppTheme.loadBarTrack,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SectionCard(
                      title: 'Load',
                      child: Text(
                        '${order.sandTypeName}\n'
                        '${order.truckTypeName} (${order.capacityLabel})',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SectionCard(
                      title: 'Delivery',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.delivery.recipientName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.delivery.recipientPhone,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.delivery.formattedAddress,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (order.delivery.deliveryNote != null &&
                              order.delivery.deliveryNote!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Note: ${order.delivery.deliveryNote}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.slate),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (order.canDispatch)
                      AppButton(
                        label: 'Mark on the way',
                        dark: true,
                        large: true,
                        loading: driver.actionLoading,
                        onPressed: _dispatch,
                      ),
                    if (order.canDeliver)
                      AppButton(
                        label: 'Mark delivered',
                        dark: true,
                        large: true,
                        loading: driver.actionLoading,
                        onPressed: _deliver,
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
