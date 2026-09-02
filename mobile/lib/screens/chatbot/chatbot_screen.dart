import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/tt_style.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../providers/connectivity_provider.dart';
import '../../widgets/app_toast.dart';

class _ChatMessage {
  final String text;
  final bool fromUser;
  final List<_QuickReply> quickReplies;

  const _ChatMessage({
    required this.text,
    required this.fromUser,
    this.quickReplies = const [],
  });
}

class _QuickReply {
  final String label;
  final String message;
  final String? issueType;

  const _QuickReply({
    required this.label,
    required this.message,
    this.issueType,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Hi — ask about sand types, truck prices, or your delivery.',
      fromUser: false,
      quickReplies: [
        _QuickReply(label: 'Prices', message: 'How much is a medium truck?'),
        _QuickReply(
          label: 'Sand types',
          message: 'What sand types do you have?',
        ),
        _QuickReply(label: 'Delivery', message: 'How long does delivery take?'),
      ],
    ),
  ];
  int _unmatchedCount = 0;
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text, {String? issueType}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;

    if (issueType != null) {
      context.push('${AppRoutes.issueReport}?type=$issueType');
      return;
    }

    final online = context.read<ConnectivityProvider>().isOnline;
    if (!online) {
      setState(() {
        _messages.add(_ChatMessage(text: trimmed, fromUser: true));
        _messages.add(
          const _ChatMessage(
            text:
                'You’re offline. Try again when connected — or open Issues to report a problem.',
            fromUser: false,
            quickReplies: [
              _QuickReply(label: 'Report issue', message: '__open_issues__'),
            ],
          ),
        );
      });
      _input.clear();
      return;
    }

    if (trimmed == '__open_issues__') {
      context.push(AppRoutes.issues);
      return;
    }

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(text: trimmed, fromUser: true));
      _input.clear();
    });
    _scrollToEnd();

    try {
      final api = context.read<ApiClient>();
      final data = await api.post(
        '/chatbot/message',
        data: {'message': trimmed, 'unmatched_count': _unmatchedCount},
      );
      final replies = <_QuickReply>[];
      final raw = data['quick_replies'] as List<dynamic>? ?? [];
      for (final item in raw) {
        final map = item as Map<String, dynamic>;
        replies.add(
          _QuickReply(
            label: map['label'] as String? ?? 'Ask',
            message: map['message'] as String? ?? map['label'] as String? ?? '',
            issueType: map['issue_type'] as String?,
          ),
        );
      }
      final suggested = data['suggested_issue_type'] as String?;
      if (suggested != null && !replies.any((r) => r.issueType == suggested)) {
        replies.insert(
          0,
          _QuickReply(
            label: 'Report issue',
            message: 'I want to report an issue',
            issueType: suggested,
          ),
        );
      }

      setState(() {
        _unmatchedCount = data['unmatched_count'] as int? ?? 0;
        _messages.add(
          _ChatMessage(
            text: data['reply'] as String? ?? '…',
            fromUser: false,
            quickReplies: replies,
          ),
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
      setState(() {
        _messages.add(
          _ChatMessage(text: 'Sorry — ${e.message}', fromUser: false),
        );
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityProvider>().isOnline;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 14,
              left: 22,
              right: 22,
              bottom: 20,
            ),
            decoration: BoxDecoration(
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
                  color: AppTheme.tipperAmber.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipper assist',
                  style: TtStyle.display(28, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  online
                      ? 'Prices and FAQs, live from the yard'
                      : 'Offline — limited answers',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _Bubble(
                  message: msg,
                  onQuickReply: (r) {
                    if (r.message == '__open_issues__') {
                      context.push(AppRoutes.issues);
                      return;
                    }
                    _send(r.message, issueType: r.issueType);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: TtStyle.paper,
                border: const Border(top: BorderSide(color: TtStyle.line)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.ink.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !_sending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: online
                            ? 'Ask about sand or prices…'
                            : 'Offline',
                        filled: true,
                        fillColor: const Color(0xFFF3EEE4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : () => _send(_input.text),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.ink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _ChatMessage message;
  final ValueChanged<_QuickReply> onQuickReply;

  const _Bubble({required this.message, required this.onQuickReply});

  @override
  Widget build(BuildContext context) {
    final align = message.fromUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bg = message.fromUser ? AppTheme.ink : TtStyle.paper;
    final fg = message.fromUser ? Colors.white : AppTheme.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.fromUser ? 18 : 4),
                bottomRight: Radius.circular(message.fromUser ? 4 : 18),
              ),
              border: message.fromUser ? null : Border.all(color: TtStyle.line),
              boxShadow: TtStyle.softLift,
            ),
            child: Text(
              message.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: fg),
            ),
          ),
          if (message.quickReplies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: message.fromUser
                  ? WrapAlignment.end
                  : WrapAlignment.start,
              children: message.quickReplies.map((r) {
                return ActionChip(
                  label: Text(r.label),
                  onPressed: () => onQuickReply(r),
                  backgroundColor: AppTheme.tipperAmber.withValues(alpha: 0.12),
                  labelStyle: const TextStyle(
                    color: AppTheme.laterite,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
