import 'package:flutter/material.dart';

import '../config/app_theme.dart';

typedef SocialProviderCallback = Future<void> Function(String provider);

/// Google + Facebook square buttons matching the auth wireframe.
class SocialAuthButtons extends StatelessWidget {
  final String label;
  final List<String> providers;
  final bool enabled;
  final bool loading;
  final SocialProviderCallback onProviderPressed;

  const SocialAuthButtons({
    super.key,
    required this.label,
    required this.providers,
    required this.onProviderPressed,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE8E3D9))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.slate,
                  fontSize: 13,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE8E3D9))),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < providers.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              _SocialIconButton(
                provider: providers[i],
                enabled: enabled && !loading,
                onPressed: () => onProviderPressed(providers[i]),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final String provider;
  final bool enabled;
  final VoidCallback onPressed;

  const _SocialIconButton({
    required this.provider,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(provider);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E3D9)),
            color: enabled ? Colors.white : const Color(0xFFF5F2EC),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(meta.icon, color: meta.color, size: 28),
        ),
      ),
    );
  }

  ({IconData icon, Color color}) _metaFor(String provider) {
    return switch (provider) {
      'google' => (icon: Icons.g_mobiledata_rounded, color: const Color(0xFFDB4437)),
      'facebook' => (icon: Icons.facebook, color: const Color(0xFF1877F2)),
      _ => (icon: Icons.login, color: AppTheme.ink),
    };
  }
}
