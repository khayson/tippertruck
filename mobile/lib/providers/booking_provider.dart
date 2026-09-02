import 'package:flutter/foundation.dart';

import '../models/config_data.dart';

class BookingDraft {
  SandType? sandType;
  TruckType? truckType;
  String recipientName = '';
  String recipientPhone = '';
  String streetAddress = '';
  String region = '';
  String city = '';
  String landmark = '';
  String deliveryNote = '';
  bool saveAddress = false;
  String paymentMethod = 'momo';
  String momoName = '';
  String momoPhone = '';
  String momoNetwork = 'mtn';

  bool get hasSand => sandType != null;
  bool get hasTruck => truckType != null;
}

class BookingProvider extends ChangeNotifier {
  BookingDraft _draft = BookingDraft();

  BookingDraft get draft => _draft;

  void selectSand(SandType sand) {
    final sandChanged = _draft.sandType?.id != sand.id;
    _draft.sandType = sand;
    // Sand drives the price matrix row — a new sand must re-pick the truck.
    if (sandChanged) {
      _draft.truckType = null;
    }
    notifyListeners();
  }

  /// Fresh booking from Home — keep nothing from a prior abandoned truck/payment.
  /// Delivery fields are left so a saved/local address can still prefill later.
  void beginBooking(SandType sand) {
    final kept = BookingDraft()
      ..sandType = sand
      ..recipientName = _draft.recipientName
      ..recipientPhone = _draft.recipientPhone
      ..streetAddress = _draft.streetAddress
      ..region = _draft.region
      ..city = _draft.city
      ..landmark = _draft.landmark
      ..deliveryNote = _draft.deliveryNote
      ..saveAddress = _draft.saveAddress;
    _draft = kept;
    notifyListeners();
  }

  void selectTruck(TruckType truck) {
    _draft.truckType = truck;
    notifyListeners();
  }

  void setDelivery({
    required String recipientName,
    required String recipientPhone,
    required String streetAddress,
    required String region,
    required String city,
    String landmark = '',
    String deliveryNote = '',
    bool saveAddress = false,
  }) {
    _draft.recipientName = recipientName;
    _draft.recipientPhone = recipientPhone;
    _draft.streetAddress = streetAddress;
    _draft.region = region;
    _draft.city = city;
    _draft.landmark = landmark;
    _draft.deliveryNote = deliveryNote;
    _draft.saveAddress = saveAddress;
    notifyListeners();
  }

  void setPayment({
    required String method,
    String momoName = '',
    String momoPhone = '',
    String momoNetwork = 'mtn',
  }) {
    _draft.paymentMethod = method;
    _draft.momoName = momoName;
    _draft.momoPhone = momoPhone;
    _draft.momoNetwork = momoNetwork;
    notifyListeners();
  }

  String? basePriceGhs(ConfigData? config) {
    final sand = _draft.sandType;
    final truck = _draft.truckType;
    if (config == null || sand == null || truck == null) return null;
    for (final row in config.priceMatrix) {
      if (row.sandTypeId == sand.id && row.truckTypeId == truck.id) {
        return row.priceGhs;
      }
    }
    // Do not fall back to deprecated truck_types.price_ghs — that is not
    // sand×truck pricing and would show the wrong amount in the UI.
    return null;
  }

  void setRegion(String region) {
    _draft.region = region;
    notifyListeners();
  }

  String? surchargeGhs(ConfigData? config) =>
      surchargeForRegion(config, _draft.region);

  String? surchargeForRegion(ConfigData? config, String? region) {
    if (config == null || region == null || region.isEmpty) return null;
    for (final zone in config.deliveryZones) {
      if (zone.region == region) return zone.surchargeGhs;
    }
    return null;
  }

  /// Preview with an optional region override (live delivery form).
  String? previewTotalGhs(ConfigData? config, {String? regionOverride}) {
    final base = basePriceGhs(config);
    if (base == null) return null;
    final region = regionOverride ?? _draft.region;
    final fee = surchargeForRegion(config, region) ?? '0.00';
    final total = (double.tryParse(base) ?? 0) + (double.tryParse(fee) ?? 0);
    return total.toStringAsFixed(2);
  }

  Map<String, dynamic> toOrderPayload() {
    final payload = <String, dynamic>{
      'sand_type_id': _draft.sandType!.id,
      'truck_type_id': _draft.truckType!.id,
      'recipient_name': _draft.recipientName.trim(),
      'recipient_phone': _draft.recipientPhone.trim(),
      'street_address': _draft.streetAddress.trim(),
      'region': _draft.region,
      'city': _draft.city.trim(),
      'payment_method': _draft.paymentMethod,
    };
    if (_draft.landmark.trim().isNotEmpty) {
      payload['landmark'] = _draft.landmark.trim();
    }
    if (_draft.deliveryNote.trim().isNotEmpty) {
      payload['delivery_note'] = _draft.deliveryNote.trim();
    }
    if (_draft.paymentMethod == 'momo') {
      payload['momo_name'] = _draft.momoName.trim();
      payload['momo_phone'] = _draft.momoPhone.trim();
      payload['momo_network'] = _draft.momoNetwork;
    }
    return payload;
  }

  void clearDraft() {
    _draft = BookingDraft();
    notifyListeners();
  }
}
