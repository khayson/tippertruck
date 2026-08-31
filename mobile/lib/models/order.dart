class OrderDelivery {
  final String recipientName;
  final String recipientPhone;
  final String streetAddress;
  final String region;
  final String city;
  final String? landmark;
  final String? deliveryNote;

  const OrderDelivery({
    required this.recipientName,
    required this.recipientPhone,
    required this.streetAddress,
    required this.region,
    required this.city,
    this.landmark,
    this.deliveryNote,
  });

  factory OrderDelivery.fromJson(Map<String, dynamic> json) {
    return OrderDelivery(
      recipientName: json['recipient_name'] as String,
      recipientPhone: json['recipient_phone'] as String,
      streetAddress: json['street_address'] as String,
      region: json['region'] as String,
      city: json['city'] as String,
      landmark: json['landmark'] as String?,
      deliveryNote: json['delivery_note'] as String?,
    );
  }

  String get formattedAddress =>
      '$streetAddress, $city, $region${landmark != null && landmark!.isNotEmpty ? ' · $landmark' : ''}';
}

class OrderPayment {
  final String method;
  final String status;
  final String? network;
  final String? momoPhone;

  const OrderPayment({
    required this.method,
    required this.status,
    this.network,
    this.momoPhone,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      method: json['method'] as String,
      status: json['status'] as String,
      network: json['network'] as String?,
      momoPhone: json['momo_phone'] as String?,
    );
  }
}

class OrderSummary {
  final int id;
  final String orderRef;
  final String status;
  final String statusLabel;
  final int progressPercent;
  final String sandTypeName;
  final String truckTypeName;
  final String capacityLabel;
  final String priceGhs;
  final String deliveryFeeGhs;
  final String totalGhs;
  final OrderDelivery delivery;
  final OrderPayment? payment;
  final String createdAt;

  const OrderSummary({
    required this.id,
    required this.orderRef,
    required this.status,
    required this.statusLabel,
    required this.progressPercent,
    required this.sandTypeName,
    required this.truckTypeName,
    required this.capacityLabel,
    required this.priceGhs,
    required this.deliveryFeeGhs,
    required this.totalGhs,
    required this.delivery,
    this.payment,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final sand = json['sand_type'] as Map<String, dynamic>;
    final truck = json['truck_type'] as Map<String, dynamic>;
    return OrderSummary(
      id: json['id'] as int,
      orderRef: json['order_ref'] as String,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String,
      progressPercent: json['progress_percent'] as int,
      sandTypeName: sand['name'] as String,
      truckTypeName: truck['name'] as String,
      capacityLabel: truck['capacity_label'] as String? ?? '',
      priceGhs: json['price_ghs'] as String? ?? '0.00',
      deliveryFeeGhs: json['delivery_fee_ghs'] as String? ?? '0.00',
      totalGhs: json['total_ghs'] as String,
      delivery: OrderDelivery.fromJson(
        json['delivery'] as Map<String, dynamic>,
      ),
      payment: json['payment'] is Map<String, dynamic>
          ? OrderPayment.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String,
    );
  }

  bool get canDispatch => status == 'confirmed';
  bool get canDeliver => status == 'on_the_way';
  bool get isTerminal => status == 'delivered' || status == 'cancelled';
  bool get canCancel => status == 'confirmed';
}
