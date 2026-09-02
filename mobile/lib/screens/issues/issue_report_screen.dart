import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/api_exception.dart';
import '../../providers/config_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/issues_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/tt_atmosphere.dart';
import '../../widgets/tt_page_header.dart';

class IssueReportScreen extends StatefulWidget {
  final String? prefillType;

  const IssueReportScreen({super.key, this.prefillType});

  @override
  State<IssueReportScreen> createState() => _IssueReportScreenState();
}

class _IssueReportScreenState extends State<IssueReportScreen> {
  final _description = TextEditingController();
  String? _type;
  String? _typeError;
  String? _descError;

  @override
  void initState() {
    super.initState();
    _type = widget.prefillType;
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final online = context.read<ConnectivityProvider>().isOnline;
    if (!online) {
      AppToast.error(context, 'Connect to submit an issue.');
      return;
    }

    setState(() {
      _typeError = _type == null ? 'Select a type' : null;
      _descError = _description.text.trim().length < 10
          ? 'At least 10 characters'
          : null;
    });
    if (_typeError != null || _descError != null) return;

    try {
      await context.read<IssuesProvider>().submit(
        issueType: _type!,
        description: _description.text.trim(),
      );
      if (!mounted) return;
      AppToast.success(context, 'Issue submitted.');
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = context.watch<ConfigProvider>().config?.issueTypes ?? [];
    final submitting = context.watch<IssuesProvider>().submitting;

    return TtAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Report issue'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TtPageHeader(
                title: 'What went wrong?',
                subtitle: 'We’ll follow up from the admin desk.',
              ),
              const SizedBox(height: 20),
              Text(
                'Issue type',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map((t) {
                  final selected = _type == t.value;
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _type = t.value;
                      _typeError = null;
                    }),
                    selectedColor: AppTheme.tipperAmber.withValues(alpha: 0.18),
                  );
                }).toList(),
              ),
              if (_typeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _typeError!,
                    style: const TextStyle(
                      color: Color(0xFFB3261E),
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _description,
                label: 'Describe the issue',
                maxLines: 4,
                errorText: _descError,
                variant: AppTextFieldVariant.underline,
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Submit',
                dark: true,
                large: true,
                loading: submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
