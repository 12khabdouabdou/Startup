import 'user.dart';

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final WasteType wasteType;
  final double estimatedWeight;
  final String? wasteDescription;
  final List<String> wasteImages;
  final DateTime scheduledDate;
  final OrderStatus status;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? assignedRecyclerId;
  final String? assignedRecyclerName;
  final double estimatedPrice;
  final PaymentStatus paymentStatus;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;
  final double? actualWeight;
  final double? finalPrice;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.wasteType,
    required this.estimatedWeight,
    this.wasteDescription,
    this.wasteImages = const [],
    required this.scheduledDate,
    required this.status,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedRecyclerId,
    this.assignedRecyclerName,
    required this.estimatedPrice,
    required this.paymentStatus,
    this.paymentId,
    required this.createdAt,
    this.completedAt,
    this.notes,
    this.actualWeight,
    this.finalPrice,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      pickupAddress: json['pickupAddress'] as String,
      pickupLat: (json['pickupLat'] as num).toDouble(),
      pickupLng: (json['pickupLng'] as num).toDouble(),
      wasteType: WasteType.values.firstWhere(
        (e) => e.name == json['wasteType'],
        orElse: () => WasteType.mixed,
      ),
      estimatedWeight: (json['estimatedWeight'] as num).toDouble(),
      wasteDescription: json['wasteDescription'] as String?,
      wasteImages: List<String>.from(json['wasteImages'] ?? []),
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      assignedDriverId: json['assignedDriverId'] as String?,
      assignedDriverName: json['assignedDriverName'] as String?,
      assignedRecyclerId: json['assignedRecyclerId'] as String?,
      assignedRecyclerName: json['assignedRecyclerName'] as String?,
      estimatedPrice: (json['estimatedPrice'] as num).toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentId: json['paymentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      notes: json['notes'] as String?,
      actualWeight: json['actualWeight'] != null
          ? (json['actualWeight'] as num).toDouble()
          : null,
      finalPrice: json['finalPrice'] != null
          ? (json['finalPrice'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'wasteType': wasteType.name,
      'estimatedWeight': estimatedWeight,
      'wasteDescription': wasteDescription,
      'wasteImages': wasteImages,
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': status.name,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'assignedRecyclerId': assignedRecyclerId,
      'assignedRecyclerName': assignedRecyclerName,
      'estimatedPrice': estimatedPrice,
      'paymentStatus': paymentStatus.name,
      'paymentId': paymentId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
      'actualWeight': actualWeight,
      'finalPrice': finalPrice,
    };
  }
}
