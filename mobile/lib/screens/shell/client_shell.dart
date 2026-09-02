import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/tt_style.dart';
import '../../providers/connectivity_provider.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/tt_atmosphere.dart';

class ClientShell extends StatelessWidget {
  final Widget child;
  final String location;

  const ClientShell({super.key, required this.child, required this.location});

  static const _tabs = [
    AppRoutes.home,
    AppRoutes.orders,
    AppRoutes.chat,
    AppRoutes.profile,
  ];

  int get _index {
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i] || location.startsWith('${_tabs[i]}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityProvider>().isOnline;

    return TtAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            if (!online)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: OfflineBanner(
                    message: 'No connection. Booking and chat are paused.',
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: _TipperDock(
          index: _index,
          onTap: (i) {
            if (i == _index) return;
            context.go(_tabs[i]);
          },
        ),
      ),
    );
  }
}

/// Kept for screens that still import displayBlack from this file.
TextStyle displayBlack(double size, {Color? color}) =>
    TtStyle.display(size, color: color);

class _TipperDock extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _TipperDock({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
      (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.ink,
            borderRadius: BorderRadius.circular(28),
            boxShadow: TtStyle.dockShadow,
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = index == i;
              final item = items[i];
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.tipperAmber
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.$2 : item.$1,
                          size: 22,
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
