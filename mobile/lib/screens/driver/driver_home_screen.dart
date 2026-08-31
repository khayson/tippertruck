import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/tt_style.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_orders_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/tt_atmosphere.dart';
import '../../widgets/tt_order_tile.dart';
import '../../widgets/tt_page_header.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverOrdersProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driver = context.watch<DriverOrdersProvider>();
    final active = driver.orders
        .where((o) => o.canDispatch || o.canDeliver)
        .length;

    return TtAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.tipperAmber,
            onRefresh: () => driver.loadOrders(),
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
                          eyebrow: 'Operator',
                          title: 'My runs',
                          subtitle:
                              'Hi ${auth.user?.firstName ?? 'operator'} — '
                              '$active active load${active == 1 ? '' : 's'} today.',
                          trailing: IconButton(
                            tooltip: 'Log out',
                            onPressed: () => auth.logout(),
                            style: IconButton.styleFrom(
                              backgroundColor: TtStyle.paper,
                              side: const BorderSide(color: TtStyle.line),
                            ),
                            icon: const Icon(Icons.logout_rounded),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppTheme.ink, TtStyle.inkSoft],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: TtStyle.softLift,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.tipperAmber.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.local_shipping_rounded,
                                  color: AppTheme.tipperAmber,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Open a job to mark on the way or delivered.',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        height: 1.35,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (driver.loading && driver.orders.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (driver.error != null && driver.orders.isEmpty)
                  SliverFillRemaining(
                    child: ErrorState(
                      message: driver.error!,
                      onRetry: () => driver.loadOrders(),
                    ),
                  )
                else if (driver.orders.isEmpty)
                  const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'No assigned deliveries',
                      subtitle:
                          'New jobs appear here when an admin assigns them.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
                    sliver: SliverList.separated(
                      itemCount: driver.orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final order = driver.orders[index];
                        return TtOrderTile(
                          order: order,
                          showAddress: true,
                          onTap: () => context.push(
                            '${AppRoutes.driverOrder}/${order.id}',
                          ),
                          footer: (order.canDispatch || order.canDeliver)
                              ? AppButton(
                                  label: order.canDispatch
                                      ? 'Open · mark on the way'
                                      : 'Open · mark delivered',
                                  dark: true,
                                  onPressed: () => context.push(
                                    '${AppRoutes.driverOrder}/${order.id}',
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
