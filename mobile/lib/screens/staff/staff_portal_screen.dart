import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_env.dart';
import '../../config/app_theme.dart';
import '../../config/tt_style.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_toast.dart';

/// Shown when an admin signs in on the mobile app.
class StaffPortalScreen extends StatelessWidget {
  const StaffPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final adminUrl = AppEnv.adminPortalUrl;

    return Scaffold(
      backgroundColor: AppTheme.bone,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin desk', style: TtStyle.display(30)),
              const SizedBox(height: 10),
              Text(
                'Orders, pricing, and users live in the Filament web panel — '
                'not in this app.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.slate,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.ink,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PORTAL URL',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.tipperAmber,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      adminUrl,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Copy admin URL',
                outlined: true,
                dark: true,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: adminUrl));
                  if (!context.mounted) return;
                  AppToast.success(context, 'Admin URL copied');
                },
              ),
              const Spacer(),
              AppButton(
                label: 'Log out',
                dark: true,
                large: true,
                loading: auth.loading,
                onPressed: () => auth.logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
