class SandType {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String? icon;

  const SandType({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.icon,
  });

  factory SandType.fromJson(Map<String, dynamic> json) {
    return SandType(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String?,
    );
  }
}

class TruckType {
  final int id;
  final String name;
  final String slug;
  final String capacityLabel;
  final String priceGhs;
  final bool isPopular;

  const TruckType({
    required this.id,
    required this.name,
    required this.slug,
    required this.capacityLabel,
    required this.priceGhs,
    required this.isPopular,
  });

  factory TruckType.fromJson(Map<String, dynamic> json) {
    return TruckType(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      capacityLabel: json['capacity_label'] as String,
      priceGhs: json['price_ghs'] as String,
      isPopular: json['is_popular'] as bool,
    );
  }
}

class PriceMatrixEntry {
  final int sandTypeId;
  final int truckTypeId;
  final String priceGhs;

  const PriceMatrixEntry({
    required this.sandTypeId,
    required this.truckTypeId,
    required this.priceGhs,
  });

  factory PriceMatrixEntry.fromJson(Map<String, dynamic> json) {
    return PriceMatrixEntry(
      sandTypeId: json['sand_type_id'] as int,
      truckTypeId: json['truck_type_id'] as int,
      priceGhs: json['price_ghs'] as String,
    );
  }
}

class DeliveryZone {
  final String region;
  final String surchargeGhs;

  const DeliveryZone({required this.region, required this.surchargeGhs});

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      region: json['region'] as String,
      surchargeGhs: json['surcharge_ghs'] as String,
    );
  }
}

class IssueType {
  final String value;
  final String label;

  const IssueType({required this.value, required this.label});

  factory IssueType.fromJson(Map<String, dynamic> json) {
    return IssueType(
      value: json['value'] as String,
      label: json['label'] as String,
    );
  }
}

class PaymentNetwork {
  final String value;
  final String label;

  const PaymentNetwork({required this.value, required this.label});

  factory PaymentNetwork.fromJson(Map<String, dynamic> json) {
    return PaymentNetwork(
      value: json['value'] as String,
      label: json['label'] as String,
    );
  }
}

class ConfigData {
  final List<SandType> sandTypes;
  final List<TruckType> truckTypes;
  final List<PriceMatrixEntry> priceMatrix;
  final List<DeliveryZone> deliveryZones;
  final List<String> regions;
  final List<IssueType> issueTypes;
  final List<PaymentNetwork> paymentNetworks;
  final String configVersion;

  const ConfigData({
    required this.sandTypes,
    required this.truckTypes,
    required this.priceMatrix,
    required this.deliveryZones,
    required this.regions,
    required this.issueTypes,
    required this.paymentNetworks,
    required this.configVersion,
  });

  factory ConfigData.fromJson(Map<String, dynamic> json) {
    return ConfigData(
      sandTypes: (json['sand_types'] as List<dynamic>)
          .map((e) => SandType.fromJson(e as Map<String, dynamic>))
          .toList(),
      truckTypes: (json['truck_types'] as List<dynamic>)
          .map((e) => TruckType.fromJson(e as Map<String, dynamic>))
          .toList(),
      priceMatrix: (json['price_matrix'] as List<dynamic>)
          .map((e) => PriceMatrixEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveryZones: (json['delivery_zones'] as List<dynamic>)
          .map((e) => DeliveryZone.fromJson(e as Map<String, dynamic>))
          .toList(),
      regions: (json['regions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      issueTypes: (json['issue_types'] as List<dynamic>)
          .map((e) => IssueType.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentNetworks: (json['payment_networks'] as List<dynamic>)
          .map((e) => PaymentNetwork.fromJson(e as Map<String, dynamic>))
          .toList(),
      configVersion: json['config_version'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sand_types': sandTypes
          .map(
            (e) => {
              'id': e.id,
              'name': e.name,
              'slug': e.slug,
              'description': e.description,
              'icon': e.icon,
            },
          )
          .toList(),
      'truck_types': truckTypes
          .map(
            (e) => {
              'id': e.id,
              'name': e.name,
              'slug': e.slug,
              'capacity_label': e.capacityLabel,
              'price_ghs': e.priceGhs,
              'is_popular': e.isPopular,
            },
          )
          .toList(),
      'price_matrix': priceMatrix
          .map(
            (e) => {
              'sand_type_id': e.sandTypeId,
              'truck_type_id': e.truckTypeId,
              'price_ghs': e.priceGhs,
            },
          )
          .toList(),
      'delivery_zones': deliveryZones
          .map((e) => {'region': e.region, 'surcharge_ghs': e.surchargeGhs})
          .toList(),
      'regions': regions,
      'issue_types': issueTypes
          .map((e) => {'value': e.value, 'label': e.label})
          .toList(),
      'payment_networks': paymentNetworks
          .map((e) => {'value': e.value, 'label': e.label})
          .toList(),
      'config_version': configVersion,
    };
  }
}
