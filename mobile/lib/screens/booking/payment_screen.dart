import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/tt_style.dart';
import '../../core/api_exception.dart';
import '../../models/config_data.dart';
import '../../models/order.dart';
import '../../providers/booking_provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/booking_step_bar.dart';
import '../../widgets/tt_atmosphere.dart';

enum _PayPhase { form, processing }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'momo';
  final _momoName = TextEditingController();
  final _momoPhone = TextEditingController();
  String _network = 'mtn';
  bool _submitting = false;
  _PayPhase _phase = _PayPhase.form;
  int _processStep = 0;
  String? _nameError;
  String? _phoneError;
  Map<String, List<String>> _fieldErrors = {};
  OrderSummary? _placedOrder;
  String _processTotal = '—';

  bool get _isMomo => _method == 'momo';

  List<String> get _processLabels {
    if (_isMomo) {
      final net = _networkLabel;
      final phone = _momoPhone.text.trim();
      return [
        'Connecting to $net…',
        'Sending MoMo prompt to $phone…',
        'Waiting for wallet approval…',
        'Payment received — booking tipper…',
      ];
    }
    return [
      'Reserving your tipper…',
      'Confirming cash-on-delivery…',
      'Order booked successfully…',
    ];
  }

  String get _networkLabel {
    final networks =
        context.read<ConfigProvider>().config?.paymentNetworks ?? [];
    for (final n in networks) {
      if (n.value == _network) return n.label;
    }
    return _network.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    final draft = context.read<BookingProvider>().draft;
    _method = draft.paymentMethod;
    _momoName.text = draft.momoName.isEmpty
        ? draft.recipientName
        : draft.momoName;
    _momoPhone.text = draft.momoPhone.isEmpty
        ? draft.recipientPhone
        : draft.momoPhone;
    _network = draft.momoNetwork;
  }

  @override
  void dispose() {
    _momoName.dispose();
    _momoPhone.dispose();
    super.dispose();
  }

  void _selectMethod(String method) {
    if (_method == method || _submitting) return;
    setState(() {
      _method = method;
      _nameError = null;
      _phoneError = null;
      _fieldErrors = {};
    });
  }

  Future<void> _runSimulation() async {
    final steps = _processLabels.length;
    for (var i = 0; i < steps; i++) {
      if (!mounted) return;
      setState(() => _processStep = i);
      await Future<void>.delayed(
        Duration(milliseconds: _isMomo ? (i == 2 ? 1600 : 900) : 700),
      );
    }
  }

  Future<void> _placeOrder() async {
    if (_submitting) return;

    final online = context.read<ConnectivityProvider>().isOnline;
    if (!online) {
      AppToast.error(context, 'Connect to place an order.');
      return;
    }

    final booking = context.read<BookingProvider>();
    final draft = booking.draft;
    if (!draft.hasSand || !draft.hasTruck || draft.region.isEmpty) {
      AppToast.error(context, 'Your booking is incomplete. Start again.');
      AppRoutes.leaveToShell(context, AppRoutes.home);
      return;
    }

    if (_isMomo) {
      setState(() {
        _nameError = _momoName.text.trim().isEmpty ? 'Required' : null;
        final phone = _momoPhone.text.trim();
        _phoneError = (phone.length != 10 || !phone.startsWith('0'))
            ? 'Use a 10-digit number starting with 0'
            : null;
      });
      if (_nameError != null || _phoneError != null) return;
    }

    booking.setPayment(
      method: _method,
      momoName: _isMomo ? _momoName.text : '',
      momoPhone: _isMomo ? _momoPhone.text : '',
      momoNetwork: _isMomo ? _network : 'mtn',
    );
    final payload = booking.toOrderPayload();
    final previewTotal = booking.previewTotalGhs(
          context.read<ConfigProvider>().config,
        ) ??
        '—';

    setState(() {
      _submitting = true;
      _fieldErrors = {};
      _phase = _PayPhase.processing;
      _processStep = 0;
      _processTotal = previewTotal;
    });

    try {
      // Kick off the order while the first simulation steps play.
      final orderFuture = context.read<OrdersProvider>().placeOrder(payload);
      await _runSimulation();
      final order = await orderFuture;
      if (!mounted) return;

      _placedOrder = order;

      // Brief beat on the last step, then open the success screen.
      // clearDraft runs on the success screen — doing it here would rebuild
      // buried truck/delivery/summary routes and bounce to Home mid-transition.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      if (!context.mounted) return;
      GoRouter.of(context).go('${AppRoutes.bookingSuccess}/${order.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _PayPhase.form;
        _fieldErrors = e.fieldErrors;
      });
      AppToast.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _phase = _PayPhase.form);
      AppToast.error(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _apiError(String key) {
    final list = _fieldErrors[key];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final config = context.watch<ConfigProvider>().config;
    final draft = booking.draft;
    final total = booking.previewTotalGhs(config) ?? '—';
    final networks = config?.paymentNetworks ?? [];

    if (_phase == _PayPhase.form &&
        (!draft.hasSand || !draft.hasTruck || draft.region.isEmpty) &&
        _placedOrder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRoutes.leaveHomeIfCurrent(context);
      });
      return const TtAtmosphere(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_phase == _PayPhase.processing) {
      return PopScope(
        canPop: false,
        child: TtAtmosphere(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: _ProcessingView(
                isMomo: _isMomo,
                total: _processTotal,
                step: _processStep,
                labels: _processLabels,
              ),
            ),
          ),
        ),
      );
    }

    return TtAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Payment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => AppRoutes.popOrHome(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                children: [
                  const BookingStepBar(current: 4),
                  const SizedBox(height: 20),
                  _AmountHero(
                    total: total,
                    isMomo: _isMomo,
                    recipient: draft.recipientName,
                    place: '${draft.city}, ${draft.region}',
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'How will you pay?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MethodTile(
                          selected: _isMomo,
                          icon: Icons.phone_android_rounded,
                          title: 'Mobile Money',
                          subtitle: 'Pay now',
                          onTap: () => _selectMethod('momo'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MethodTile(
                          selected: !_isMomo,
                          icon: Icons.payments_outlined,
                          title: 'Cash',
                          subtitle: 'On delivery',
                          onTap: () => _selectMethod('cod'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _isMomo
                        ? _MomoPanel(
                            key: const ValueKey('momo'),
                            nameController: _momoName,
                            phoneController: _momoPhone,
                            network: _network,
                            networks: networks,
                            nameError: _nameError ?? _apiError('momo_name'),
                            phoneError: _phoneError ?? _apiError('momo_phone'),
                            onNetwork: (v) => setState(() => _network = v),
                          )
                        : const _CodPanel(key: ValueKey('cod')),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                decoration: BoxDecoration(
                  color: TtStyle.paper.withValues(alpha: 0.96),
                  border: const Border(top: BorderSide(color: TtStyle.line)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.ink.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isMomo
                          ? 'Demo: we simulate the MoMo prompt — no real charge.'
                          : 'You pay the driver — nothing is charged now.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.slate,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: _isMomo
                          ? 'Pay GHS $total'
                          : 'Confirm COD · GHS $total',
                      large: true,
                      loading: _submitting,
                      onPressed: _placeOrder,
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

class _ProcessingView extends StatelessWidget {
  final bool isMomo;
  final String total;
  final int step;
  final List<String> labels;

  const _ProcessingView({
    required this.isMomo,
    required this.total,
    required this.step,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        children: [
          const BookingStepBar(current: 4),
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.tipperAmber.withValues(alpha: 0.14),
              border: Border.all(
                color: AppTheme.tipperAmber.withValues(alpha: 0.4),
                width: 3,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(22),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.tipperAmber,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            isMomo ? 'Processing MoMo' : 'Placing order',
            style: TtStyle.display(28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'GHS $total',
            style: TtStyle.display(22, color: AppTheme.tipperAmber),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isMomo
                ? 'Simulated wallet prompt — approve automatically in demo.'
                : 'Confirming your cash-on-delivery booking.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.slate,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: TtStyle.paper,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: TtStyle.line),
              boxShadow: TtStyle.softLift,
            ),
            child: Column(
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _ProcessStepRow(
                    label: labels[i],
                    done: i < step,
                    active: i == step,
                  ),
                ],
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _ProcessStepRow extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;

  const _ProcessStepRow({
    required this.label,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppTheme.signal
        : active
        ? AppTheme.tipperAmber
        : AppTheme.slate.withValues(alpha: 0.45);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || active ? color.withValues(alpha: 0.15) : TtStyle.line,
            border: Border.all(color: color, width: 2),
          ),
          child: done
              ? Icon(Icons.check_rounded, size: 16, color: color)
              : active
              ? Padding(
                  padding: const EdgeInsets.all(5),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: done || active ? AppTheme.ink : AppTheme.slate,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountHero extends StatelessWidget {
  final String total;
  final bool isMomo;
  final String recipient;
  final String place;

  const _AmountHero({
    required this.total,
    required this.isMomo,
    required this.recipient,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: isMomo ? AppTheme.ink : TtStyle.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isMomo ? AppTheme.ink : TtStyle.line),
        boxShadow: TtStyle.softLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMomo ? 'PAY NOW' : 'PAY ON ARRIVAL',
            style: TtStyle.eyebrow(
              color: isMomo ? AppTheme.tipperAmber : AppTheme.laterite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'GHS $total',
            style: TtStyle.display(
              34,
              color: isMomo ? Colors.white : AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMomo
                ? 'Prompt will go to your MoMo wallet'
                : 'Have exact cash ready for the driver',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isMomo
                  ? Colors.white.withValues(alpha: 0.72)
                  : AppTheme.slate,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: isMomo
                ? Colors.white.withValues(alpha: 0.12)
                : TtStyle.line,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 18,
                color: isMomo
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$recipient · $place',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isMomo
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppTheme.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            color: TtStyle.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppTheme.tipperAmber : TtStyle.line,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.tipperAmber.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: selected ? AppTheme.tipperAmber : AppTheme.ink,
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 20,
                    color: selected ? AppTheme.tipperAmber : TtStyle.line,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomoPanel extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final String network;
  final List<PaymentNetwork> networks;
  final String? nameError;
  final String? phoneError;
  final ValueChanged<String> onNetwork;

  const _MomoPanel({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.network,
    required this.networks,
    required this.nameError,
    required this.phoneError,
    required this.onNetwork,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: TtStyle.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TtStyle.line),
        boxShadow: TtStyle.softLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MOMO WALLET',
            style: TtStyle.eyebrow(color: AppTheme.slate),
          ),
          const SizedBox(height: 6),
          Text(
            'We will send a payment prompt to this number.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.slate,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: nameController,
            label: 'Account name',
            errorText: nameError,
            variant: AppTextFieldVariant.underline,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: phoneController,
            label: 'MoMo number',
            keyboardType: TextInputType.phone,
            errorText: phoneError,
            variant: AppTextFieldVariant.underline,
          ),
          const SizedBox(height: 18),
          Text(
            'Network',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (networks.isEmpty)
            Text(
              'Networks loading…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.slate,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: networks.map((n) {
                final selected = network == n.value;
                return ChoiceChip(
                  label: Text(n.label),
                  selected: selected,
                  onSelected: (_) => onNetwork(n.value),
                  selectedColor: AppTheme.tipperAmber.withValues(alpha: 0.16),
                  labelStyle: TextStyle(
                    color: selected ? AppTheme.laterite : AppTheme.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected ? AppTheme.tipperAmber : TtStyle.line,
                  ),
                  backgroundColor: const Color(0xFFF3EEE4),
                  showCheckmark: false,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _CodPanel extends StatelessWidget {
  const _CodPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = const [
      (Icons.payments_rounded, 'Pay the driver in cash when sand is tipped.'),
      (Icons.receipt_long_rounded, 'Your order stays unpaid until delivery.'),
      (Icons.shield_outlined, 'No wallet details needed for this method.'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: TtStyle.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TtStyle.line),
        boxShadow: TtStyle.softLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CASH ON DELIVERY',
            style: TtStyle.eyebrow(color: AppTheme.slate),
          ),
          const SizedBox(height: 6),
          Text(
            'We book the truck now. Settlement happens at your gate.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.slate,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < tips.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.signal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(tips[i].$1, size: 18, color: AppTheme.signal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      tips[i].$2,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
