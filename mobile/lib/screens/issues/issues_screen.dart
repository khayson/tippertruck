import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/tt_style.dart';
import '../../providers/issues_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tt_atmosphere.dart';
import '../../widgets/tt_page_header.dart';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IssuesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final issues = context.watch<IssuesProvider>();

    return TtAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Issues'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.issueReport),
          backgroundColor: AppTheme.ink,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Report'),
        ),
        body: RefreshIndicator(
          color: AppTheme.tipperAmber,
          onRefresh: () => issues.load(),
          child: issues.loading && issues.issues.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : issues.error != null && issues.issues.isEmpty
              ? ErrorState(message: issues.error!, onRetry: () => issues.load())
              : issues.issues.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    const EmptyState(
                      icon: Icons.report_problem_outlined,
                      title: 'No issues reported',
                      subtitle: 'Something wrong with a delivery? Tell us.',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: AppButton(
                        label: 'Report an issue',
                        dark: true,
                        onPressed: () => context.push(AppRoutes.issueReport),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 88),
                  itemCount: issues.issues.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const TtPageHeader(
                        eyebrow: 'Support',
                        title: 'Your issues',
                        subtitle: 'We follow up from the admin desk.',
                      );
                    }
                    final item = issues.issues[index - 1];
                    final accent = TtStyle.statusColor(item.status);
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TtStyle.paper,
                        borderRadius: BorderRadius.circular(20),
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
                                  item.issueTypeLabel,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              StatusBadge(label: item.status, color: accent),
                            ],
                          ),
                          if (item.orderRef != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.orderRef!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.slate),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(item.description),
                          if (item.adminResponse != null &&
                              item.adminResponse!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Response: ${item.adminResponse}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.signal),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
