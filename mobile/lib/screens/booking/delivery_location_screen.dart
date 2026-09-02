import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/tt_style.dart';
import '../../models/config_data.dart';
import '../../providers/booking_provider.dart';
import '../../providers/config_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/booking_step_bar.dart';
import '../../widgets/tt_atmosphere.dart';

/// Local UX hints only — city is still free text; server validates region.
const _cityHints = <String, List<String>>{
  'Greater Accra': [
    'Accra',
    'Tema',
    'Madina',
    'Kasoa',
    'Spintex',
    'East Legon',
  ],
  'Central': ['Cape Coast', 'Winneba', 'Kasoa', 'Mankessim'],
  'Ashanti': ['Kumasi', 'Ejisu', 'Obuasi'],
  'Eastern': ['Koforidua', 'Nkawkaw', 'Akim Oda'],
  'Western': ['Takoradi', 'Tarkwa', 'Sekondi'],
  'Volta': ['Ho', 'Hohoe', 'Keta'],
  'Northern': ['Tamale', 'Savelugu'],
};

class DeliveryLocationScreen extends StatefulWidget {
  const DeliveryLocationScreen({super.key});

  @override
  State<DeliveryLocationScreen> createState() => _DeliveryLocationScreenState();
}

class _DeliveryLocationScreenState extends State<DeliveryLocationScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _landmark = TextEditingController();
  final _note = TextEditingController();
  final _scroll = ScrollController();

  String? _region;
  bool _saveAddress = false;
  Map<String, String>? _saved;
  bool _showNotes = false;
  String? _phoneError;
  String? _nameError;
  String? _streetError;
  String? _cityError;
  String? _regionError;

  @override
  void initState() {
    super.initState();
    final draft = context.read<BookingProvider>().draft;
    _name.text = draft.recipientName;
    _phone.text = draft.recipientPhone;
    _street.text = draft.streetAddress;
    _city.text = draft.city;
    _landmark.text = draft.landmark;
    _note.text = draft.deliveryNote;
    _region = draft.region.isEmpty ? null : draft.region;
    _saveAddress = draft.saveAddress;
    _showNotes = draft.deliveryNote.isNotEmpty || draft.landmark.isNotEmpty;

    for (final c in [_name, _phone, _street, _city, _landmark, _note]) {
      c.addListener(_onFieldChanged);
    }
    _loadSavedAddress();
  }

  void _onFieldChanged() {
    if (!mounted) return;
    setState(() {
      _liveValidateSoft();
      if (_landmark.text.trim().isNotEmpty || _note.text.trim().isNotEmpty) {
        _showNotes = true;
      }
    });
  }

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final street = prefs.getString('saved_street');
    if (street == null || !mounted) return;
    final saved = {
      'name': prefs.getString('saved_name') ?? '',
      'phone': prefs.getString('saved_phone') ?? '',
      'street': street,
      'city': prefs.getString('saved_city') ?? '',
      'region': prefs.getString('saved_region') ?? '',
      'landmark': prefs.getString('saved_landmark') ?? '',
    };
    setState(() => _saved = saved);

    // Auto-apply only when the draft is empty.
    if (_street.text.isEmpty && _name.text.isEmpty) {
      _applySaved(saved, announce: false);
    }
  }

  void _applySaved(Map<String, String> saved, {bool announce = true}) {
    setState(() {
      _name.text = saved['name'] ?? '';
      _phone.text = saved['phone'] ?? '';
      _street.text = saved['street'] ?? '';
      _city.text = saved['city'] ?? '';
      _region = (saved['region']?.isNotEmpty == true) ? saved['region'] : null;
      _landmark.text = saved['landmark'] ?? '';
      _saveAddress = true;
      _showNotes = (_landmark.text).isNotEmpty;
      _clearHardErrors();
    });
    if (_region != null) {
      context.read<BookingProvider>().setRegion(_region!);
    }
    if (announce && mounted) {
      // Soft haptic when user taps Use saved.
      HapticFeedback.selectionClick();
    }
  }

  void _clearForm() {
    setState(() {
      _name.clear();
      _phone.clear();
      _street.clear();
      _city.clear();
      _landmark.clear();
      _note.clear();
      _region = null;
      _saveAddress = false;
      _clearHardErrors();
    });
    context.read<BookingProvider>().setRegion('');
  }

  void _clearHardErrors() {
    _nameError = null;
    _phoneError = null;
    _streetError = null;
    _cityError = null;
    _regionError = null;
  }

  /// Soft live checks — don't yell Required until submit.
  void _liveValidateSoft() {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      _phoneError = null;
    } else if (!RegExp(r'^0\d{0,9}$').hasMatch(phone)) {
      _phoneError = 'Must start with 0 and be digits only';
    } else if (phone.length > 10) {
      _phoneError = 'Max 10 digits';
    } else if (phone.length == 10) {
      _phoneError = null;
    } else {
      _phoneError =
          '${10 - phone.length} more digit${10 - phone.length == 1 ? '' : 's'}';
    }
  }

  bool get _recipientOk {
    final phone = _phone.text.trim();
    return _name.text.trim().isNotEmpty &&
        phone.length == 10 &&
        phone.startsWith('0') &&
        RegExp(r'^0\d{9}$').hasMatch(phone);
  }

  bool get _addressOk =>
      _street.text.trim().isNotEmpty &&
      _city.text.trim().isNotEmpty &&
      _region != null;

  bool get _formReady => _recipientOk && _addressOk;

  int get _stepsDone {
    var n = 0;
    if (_recipientOk) n++;
    if (_addressOk) n++;
    if (_landmark.text.trim().isNotEmpty || _note.text.trim().isNotEmpty) n++;
    return n;
  }

  String get _ctaLabel {
    if (!_recipientOk) {
      if (_name.text.trim().isEmpty) return 'Enter recipient name';
      return 'Enter a valid phone';
    }
    if (_region == null) return 'Choose a delivery region';
    if (_street.text.trim().isEmpty) return 'Add street address';
    if (_city.text.trim().isEmpty) return 'Add city / town';
    return 'Continue to summary';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _street, _city, _landmark, _note]) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  bool _validateHard() {
    setState(() {
      _nameError = _name.text.trim().isEmpty ? 'Required' : null;
      _streetError = _street.text.trim().isEmpty ? 'Required' : null;
      _cityError = _city.text.trim().isEmpty ? 'Required' : null;
      _regionError = _region == null ? 'Select a region' : null;
      final phone = _phone.text.trim();
      if (phone.length != 10 || !phone.startsWith('0')) {
        _phoneError = 'Use a 10-digit number starting with 0';
      } else {
        _phoneError = null;
      }
    });
    return _formReady;
  }

  Future<void> _continue() async {
    if (!_validateHard()) {
      await _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      return;
    }

    final booking = context.read<BookingProvider>();
    booking.setDelivery(
      recipientName: _name.text,
      recipientPhone: _phone.text,
      streetAddress: _street.text,
      region: _region!,
      city: _city.text,
      landmark: _landmark.text,
      deliveryNote: _note.text,
      saveAddress: _saveAddress,
    );

    if (_saveAddress) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_name', _name.text.trim());
      await prefs.setString('saved_phone', _phone.text.trim());
      await prefs.setString('saved_street', _street.text.trim());
      await prefs.setString('saved_city', _city.text.trim());
      await prefs.setString('saved_region', _region!);
      await prefs.setString('saved_landmark', _landmark.text.trim());
    }

    if (!mounted) return;
    context.push(AppRoutes.bookingSummary);
  }

  void _selectRegion(String region) {
    HapticFeedback.selectionClick();
    setState(() {
      _region = region;
      _regionError = null;
      // Suggest a city if empty and we have hints.
      final hints = _cityHints[region];
      if ((_city.text.trim().isEmpty) && hints != null && hints.isNotEmpty) {
        // Don't auto-fill city — only show chips. Keep city empty.
      }
    });
    context.read<BookingProvider>().setRegion(region);
  }

  List<DeliveryZone> _sortedZones(ConfigData? config) {
    final zones = [...?config?.deliveryZones];
    zones.sort((a, b) {
      final fa = double.tryParse(a.surchargeGhs) ?? 0;
      final fb = double.tryParse(b.surchargeGhs) ?? 0;
      return fa.compareTo(fb);
    });
    return zones;
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final config = configProvider.config;
    final booking = context.watch<BookingProvider>();
    final draft = booking.draft;
    final zones = _sortedZones(config);
    final base = booking.basePriceGhs(config);
    final fee = booking.surchargeForRegion(config, _region);
    final total = booking.previewTotalGhs(config, regionOverride: _region);
    final cityHints = _region == null
        ? const <String>[]
        : (_cityHints[_region!] ?? const <String>[]);

    if (!draft.hasTruck) {
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

    return TtAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Delivery'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => AppRoutes.popOrHome(context),
          ),
          actions: [
            if (_name.text.isNotEmpty || _street.text.isNotEmpty)
              TextButton(onPressed: _clearForm, child: const Text('Clear')),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                children: [
                  const BookingStepBar(current: 2),
                  const SizedBox(height: 16),
                  _SmartHeader(
                    sand: draft.sandType?.name ?? '—',
                    truck: draft.truckType?.name ?? '—',
                    stepsDone: _stepsDone,
                    recipientOk: _recipientOk,
                    addressOk: _addressOk,
                  ),
                  if (_saved != null) ...[
                    const SizedBox(height: 14),
                    _SavedAddressCard(
                      saved: _saved!,
                      onUse: () => _applySaved(_saved!),
                      onDismiss: () => setState(() => _saved = null),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text('Where to?', style: TtStyle.display(30)),
                  const SizedBox(height: 8),
                  Text(
                    'Form updates the fee as you pick a region.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.slate,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // —— Recipient ——
                  _DynamicSection(
                    index: 1,
                    title: 'Recipient',
                    complete: _recipientOk,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _name,
                          label: 'Full name',
                          errorText: _nameError,
                          variant: AppTextFieldVariant.underline,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _phone,
                          label: 'Phone',
                          hint: '0241234567',
                          keyboardType: TextInputType.phone,
                          errorText: _phoneError,
                          variant: AppTextFieldVariant.underline,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // —— Region (smart fee cards) ——
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 280),
                    opacity: _recipientOk ? 1 : 0.55,
                    child: _DynamicSection(
                      index: 2,
                      title: 'Region & fee',
                      complete: _region != null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pick where we’re delivering — fees update live.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.slate),
                          ),
                          const SizedBox(height: 12),
                          ...zones.map((zone) {
                            final selected = _region == zone.region;
                            final feeVal =
                                double.tryParse(zone.surchargeGhs) ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _RegionFeeTile(
                                region: zone.region,
                                feeGhs: zone.surchargeGhs,
                                free: feeVal <= 0,
                                selected: selected,
                                onTap: () => _selectRegion(zone.region),
                              ),
                            );
                          }),
                          if (_regionError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _regionError!,
                                style: const TextStyle(
                                  color: Color(0xFFB3261E),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // —— Address ——
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 280),
                    opacity: _region != null ? 1 : 0.45,
                    child: IgnorePointer(
                      ignoring: _region == null,
                      child: _DynamicSection(
                        index: 3,
                        title: 'Street details',
                        complete: _addressOk,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              controller: _street,
                              label: 'Street address',
                              errorText: _streetError,
                              variant: AppTextFieldVariant.underline,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _city,
                              label: 'City / town',
                              errorText: _cityError,
                              variant: AppTextFieldVariant.underline,
                              textInputAction: TextInputAction.next,
                            ),
                            if (cityHints.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Quick pick',
                                style: TtStyle.eyebrow(color: AppTheme.slate),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: cityHints.map((c) {
                                  final selected =
                                      _city.text.trim().toLowerCase() ==
                                      c.toLowerCase();
                                  return ActionChip(
                                    label: Text(c),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _city.text = c;
                                        _cityError = null;
                                      });
                                    },
                                    backgroundColor: selected
                                        ? AppTheme.ink
                                        : const Color(0xFFF3EEE4),
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppTheme.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    side: BorderSide(
                                      color: selected
                                          ? AppTheme.ink
                                          : TtStyle.line,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // —— Optional extras ——
                  if (!_showNotes)
                    TextButton.icon(
                      onPressed: () => setState(() => _showNotes = true),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add landmark or note'),
                    )
                  else
                    _DynamicSection(
                      index: 4,
                      title: 'Extras',
                      complete:
                          _landmark.text.trim().isNotEmpty ||
                          _note.text.trim().isNotEmpty,
                      optional: true,
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _landmark,
                            label: 'Landmark (optional)',
                            variant: AppTextFieldVariant.underline,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _note,
                            label: 'Delivery note (optional)',
                            hint: 'Gate code, call on arrival…',
                            maxLines: 3,
                            variant: AppTextFieldVariant.underline,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  _SaveAddressTile(
                    value: _saveAddress,
                    onChanged: (v) => setState(() => _saveAddress = v),
                  ),
                ],
              ),
            ),

            // Live price + CTA dock
            _LiveDock(
              baseGhs: base,
              feeGhs: fee,
              totalGhs: total,
              region: _region,
              ctaLabel: _ctaLabel,
              onContinue: _continue,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartHeader extends StatelessWidget {
  final String sand;
  final String truck;
  final int stepsDone;
  final bool recipientOk;
  final bool addressOk;

  const _SmartHeader({
    required this.sand,
    required this.truck,
    required this.stepsDone,
    required this.recipientOk,
    required this.addressOk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.ink, TtStyle.inkSoft],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: TtStyle.softLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR LOAD',
                      style: TtStyle.eyebrow(color: AppTheme.tipperAmber),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sand · $truck',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Text(
                '$stepsDone/3',
                style: TtStyle.display(22, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _CheckPill(label: 'Recipient', done: recipientOk),
              const SizedBox(width: 8),
              _CheckPill(label: 'Address', done: addressOk),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckPill extends StatelessWidget {
  final String label;
  final bool done;

  const _CheckPill({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? AppTheme.signal.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: done ? const Color(0xFF7DCEA0) : Colors.white54,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  final Map<String, String> saved;
  final VoidCallback onUse;
  final VoidCallback onDismiss;

  const _SavedAddressCard({
    required this.saved,
    required this.onUse,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final line =
        '${saved['street']}, ${saved['city']}${saved['region']!.isNotEmpty ? ' · ${saved['region']}' : ''}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TtStyle.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TtStyle.line),
        boxShadow: TtStyle.softLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bookmark_rounded, color: AppTheme.laterite),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saved on this phone',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            line,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.slate),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Use saved address',
              dark: true,
              onPressed: onUse,
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicSection extends StatelessWidget {
  final int index;
  final String title;
  final bool complete;
  final bool optional;
  final Widget child;

  const _DynamicSection({
    required this.index,
    required this.title,
    required this.complete,
    required this.child,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: TtStyle.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: complete
              ? AppTheme.signal.withValues(alpha: 0.35)
              : TtStyle.line,
          width: complete ? 1.5 : 1,
        ),
        boxShadow: TtStyle.softLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: complete ? AppTheme.signal : AppTheme.ink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: complete
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : Text(
                        '$index',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TtStyle.eyebrow(color: AppTheme.slate),
                ),
              ),
              if (optional)
                Text(
                  'OPTIONAL',
                  style: TtStyle.eyebrow(color: AppTheme.tipperAmber),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RegionFeeTile extends StatelessWidget {
  final String region;
  final String feeGhs;
  final bool free;
  final bool selected;
  final VoidCallback onTap;

  const _RegionFeeTile({
    required this.region,
    required this.feeGhs,
    required this.free,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.ink : const Color(0xFFF3EEE4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.ink : TtStyle.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppTheme.tipperAmber : AppTheme.slate,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  region,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selected ? Colors.white : AppTheme.ink,
                  ),
                ),
              ),
              Text(
                free ? 'FREE' : '+ GHS $feeGhs',
                style: AppTheme.moneyStyle.copyWith(
                  color: selected
                      ? (free ? const Color(0xFF7DCEA0) : AppTheme.tipperAmber)
                      : (free ? AppTheme.signal : AppTheme.laterite),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveAddressTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SaveAddressTile({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: value
                ? AppTheme.tipperAmber.withValues(alpha: 0.10)
                : TtStyle.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: value
                  ? AppTheme.tipperAmber.withValues(alpha: 0.35)
                  : TtStyle.line,
            ),
          ),
          child: Row(
            children: [
              Icon(
                value ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: value ? AppTheme.laterite : AppTheme.ink,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save this address',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'On this phone only — next booking is faster',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppTheme.slate),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                activeThumbColor: AppTheme.tipperAmber,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveDock extends StatelessWidget {
  final String? baseGhs;
  final String? feeGhs;
  final String? totalGhs;
  final String? region;
  final String ctaLabel;
  final VoidCallback onContinue;

  const _LiveDock({
    required this.baseGhs,
    required this.feeGhs,
    required this.totalGhs,
    required this.region,
    required this.ctaLabel,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
        decoration: BoxDecoration(
          color: TtStyle.paper.withValues(alpha: 0.96),
          border: const Border(top: BorderSide(color: TtStyle.line)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        region == null
                            ? 'Pick a region for delivery fee'
                            : 'Preview total',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.slate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalGhs == null ? 'GHS —' : 'GHS $totalGhs',
                        style: TtStyle.display(24, color: AppTheme.tipperAmber),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Load ${baseGhs ?? '—'}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.slate),
                    ),
                    Text(
                      region == null
                          ? 'Fee —'
                          : 'Fee ${feeGhs == null || (double.tryParse(feeGhs!) ?? 0) <= 0 ? 'FREE' : feeGhs}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.slate,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: ctaLabel,
              dark: true,
              large: true,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
