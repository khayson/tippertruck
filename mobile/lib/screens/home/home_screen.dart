import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/config_provider.dart';
import '../../widgets/sand_swatch.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _sandDescriptions = {
    'river-sand': 'Smooth, fine grain. Best for plastering and finishing work.',
    'quarry-sand':
        'Coarse, angular grain. Strong for concrete, foundations and blockwork.',
    'filling-sand':
        'Laterite fill. Used for backfilling, compaction and levelling.',
  };

  static const _sandImages = {
    'river-sand': 'assets/images/sand_river.jpg',
    'quarry-sand': 'assets/images/sand_quarry.jpg',
    'filling-sand': 'assets/images/sand_filling.jpg',
  };

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final configProvider = context.watch<ConfigProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.bone,
      appBar: AppBar(
        title: const Text('Tipper Truck'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: authProvider.loading
                ? null
                : () => authProvider.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (configProvider.fromCache)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.tipperAmber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.tipperAmber.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, size: 16, color: AppTheme.laterite),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline. Showing saved data.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.laterite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              'Hello, ${user?.firstName ?? 'there'}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'What are you building today?',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.slate),
            ),
            const SizedBox(height: 28),
            if (configProvider.config != null)
              ...configProvider.config!.sandTypes.map(
                (sand) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 120,
                          child: _sandImages.containsKey(sand.slug)
                              ? Image.asset(
                                  _sandImages[sand.slug]!,
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => SandSwatch(
                                    slug: sand.slug,
                                    height: 120,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                )
                              : SandSwatch(
                                  slug: sand.slug,
                                  height: 120,
                                  borderRadius: BorderRadius.zero,
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sand.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _sandDescriptions[sand.slug] ??
                                    sand.description,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.slate,
                                      height: 1.4,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
