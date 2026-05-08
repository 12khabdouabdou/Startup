class WastePost {
  final String id;
  final String developerId;
  final String wasteType;
  final double quantity;
  final String quantityUnit;
  final double? lat;
  final double? lng;
  final DateTime? pickupDateStart;
  final DateTime? pickupDateEnd;
  final List<String> photos;
  final String status;
  final double? price;
  final double commissionRate;
  final DateTime createdAt;

  const WastePost({
    required this.id,
    required this.developerId,
    required this.wasteType,
    required this.quantity,
    required this.quantityUnit,
    this.lat,
    this.lng,
    this.pickupDateStart,
    this.pickupDateEnd,
    this.photos = const [],
    required this.status,
    this.price,
    required this.commissionRate,
    required this.createdAt,
  });

  factory WastePost.fromJson(Map<String, dynamic> json) => WastePost(
    id: json['id'],
    developerId: json['developer_id'],
    wasteType: json['waste_type'],
    quantity: (json['quantity'] as num).toDouble(),
    quantityUnit: json['quantity_unit'],
    status: json['status'],
    price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.10,
    photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
    createdAt: DateTime.parse(json['created_at']),
  );
}
