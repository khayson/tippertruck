import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/tt_style.dart';
import '../../models/config_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/sand_swatch.dart';
import '../../widgets/tt_page_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sandSectionKey = GlobalKey();

  static const _sandDescriptions = {
    'river-sand': 'Smooth, fine grain. Best for plastering and finishing.',
    'quarry-sand': 'Coarse grain. Strong for concrete and foundations.',
    'filling-sand': 'Laterite fill for backfilling and levelling.',
  };

  static const _sandImages = {
    'river-sand': 'assets/images/sand_river.jpg',
    'quarry-sand': 'assets/images/sand_quarry.jpg',
    'filling-sand': 'assets/images/sand_filling.jpg',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConfigProvider>().load();
    });
  }

  void _startBooking(SandType sand) {
    if (!context.read<ConnectivityProvider>().isOnline) return;
    context.read<BookingProvider>().beginBooking(sand);
    context.push(AppRoutes.bookingTruck);
  }

  void _scrollToSand() {
    final ctx = _sandSectionKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final config = context.watch<ConfigProvider>();
    final online = context.watch<ConnectivityProvider>().isOnline;
    final user = auth.user;
    final sands = config.config?.sandTypes ?? [];
    final letter = (user?.firstName.isNotEmpty == true)
        ? user!.firstName[0]
        : 'T';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppTheme.tipperAmber,
        onRefresh: () => config.load(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (config.fromCache) const OfflineBanner(),
                      TtPageHeader(
                        eyebrow: 'Tipper Truck',
                        title: 'Hello, ${user?.firstName ?? 'there'}',
                        subtitle: 'Sand delivered when the site needs it.',
                        trailing: TtAvatar(letter: letter),
                      ),
                      const SizedBox(height: 22),
                      _HeroBookCard(
                        enabled: online,
                        onTap: online ? _scrollToSand : null,
                      ),
                      const SizedBox(height: 28),
                      KeyedSubtree(
                        key: _sandSectionKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Choose sand', style: TtStyle.display(22)),
                            const SizedBox(height: 6),
                            Text(
                              'Tap a type to start booking',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.slate),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
            if (config.loading && sands.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (sands.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No sand types available.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                sliver: SliverList.separated(
                  itemCount: sands.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final sand = sands[index];
                    return _SandCard(
                      sand: sand,
                      description:
                          _sandDescriptions[sand.slug] ?? sand.description,
                      imageUrl: sand.imageUrl,
                      fallbackAsset: _sandImages[sand.slug],
                      enabled: online,
                      onTap: () => _startBooking(sand),
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shortcuts', style: TtStyle.display(22)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _Shortcut(
                            icon: Icons.receipt_long_rounded,
                            label: 'Orders',
                            onTap: () => context.go(AppRoutes.orders),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Shortcut(
                            icon: Icons.chat_bubble_rounded,
                            label: 'Chat',
                            onTap: () => context.go(AppRoutes.chat),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Shortcut(
                            icon: Icons.report_problem_outlined,
                            label: 'Issues',
                            onTap: () => context.push(AppRoutes.issues),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Shortcut(
                            icon: Icons.person_rounded,
                            label: 'Profile',
                            onTap: () => context.go(AppRoutes.profile),
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

class _HeroBookCard extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;

  const _HeroBookCard({required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          height: 168,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? const [
                      Color(0xFFE06A1A),
                      AppTheme.tipperAmber,
                      AppTheme.laterite,
                    ]
                  : [
                      AppTheme.slate.withValues(alpha: 0.45),
                      AppTheme.slate.withValues(alpha: 0.7),
                    ],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppTheme.tipperAmber.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -18,
                child: Image.asset(
                  'assets/images/tipper_hero.png',
                  width: 168,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.local_shipping_rounded,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 120, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOOK A\nTRUCK',
                      style: TtStyle.display(28, color: Colors.white),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        enabled ? 'Choose your sand below ↓' : 'Offline',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class _SandCard extends StatelessWidget {
  final SandType sand;
  final String description;
  final String? imageUrl;
  final String? fallbackAsset;
  final bool enabled;
  final VoidCallback onTap;

  const _SandCard({
    required this.sand,
    required this.description,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.enabled,
    required this.onTap,
  });

  Widget _image() {
    final networkUrl = imageUrl;
    if (networkUrl != null && networkUrl.isNotEmpty) {
      return Image.network(
        networkUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackImage(),
      );
    }
    return _fallbackImage();
  }

  Widget _fallbackImage() {
    if (fallbackAsset != null) {
      return Image.asset(
        fallbackAsset!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => SandSwatch(
          slug: sand.slug,
          height: 148,
          borderRadius: BorderRadius.zero,
        ),
      );
    }
    return SandSwatch(
      slug: sand.slug,
      height: 148,
      borderRadius: BorderRadius.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: TtStyle.paper,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: TtStyle.line),
            boxShadow: TtStyle.softLift,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: SizedBox(
                  height: 148,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _image(),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppTheme.ink.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sand.name, style: TtStyle.display(20)),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.slate, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: enabled
                            ? AppTheme.ink
                            : AppTheme.slate.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
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

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 92,
          decoration: BoxDecoration(
            color: TtStyle.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: TtStyle.line),
            boxShadow: TtStyle.softLift,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.tipperAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppTheme.laterite),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
