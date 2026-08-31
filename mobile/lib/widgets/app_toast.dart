import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/app_theme.dart';

enum AppToastType { success, error, info }

/// Soft floating toast — glass card, accent rail, typography aligned with auth screens.
class AppToast {
  AppToast._();

  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (_) => _ToastHost(
        message: message,
        type: type,
        onDismiss: dismiss,
      ),
    );

    _current = entry;
    overlay.insert(entry);
    _timer = Timer(duration, dismiss);
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.error);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.info);

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }
}

class _ToastHost extends StatefulWidget {
  final String message;
  final AppToastType type;
  final VoidCallback onDismiss;

  const _ToastHost({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _fade = curve;
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(curve);
    _scale = Tween<double>(begin: 0.94, end: 1).animate(curve);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  ({Color rail, Color soft, IconData icon, String label}) get _meta =>
      switch (widget.type) {
        AppToastType.success => (
          rail: AppTheme.signal,
          soft: const Color(0xFF1E6B4C).withValues(alpha: 0.10),
          icon: Icons.check_rounded,
          label: 'Done',
        ),
        AppToastType.error => (
          rail: const Color(0xFFB3261E),
          soft: const Color(0xFFB3261E).withValues(alpha: 0.08),
          icon: Icons.priority_high_rounded,
          label: 'Alert',
        ),
        AppToastType.info => (
          rail: AppTheme.tipperAmber,
          soft: AppTheme.tipperAmber.withValues(alpha: 0.10),
          icon: Icons.bolt_rounded,
          label: 'Tipper',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final top = MediaQuery.paddingOf(context).top + 10;

    return Positioned(
      top: top,
      left: 18,
      right: 18,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8E3D9)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.ink.withValues(alpha: 0.14),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(width: 5, color: meta.rail),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: meta.soft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      meta.icon,
                                      color: meta.rail,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          meta.label.toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: meta.rail,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.1,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.message,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.ink,
                                                fontWeight: FontWeight.w600,
                                                height: 1.35,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: widget.onDismiss,
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: AppTheme.slate.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
