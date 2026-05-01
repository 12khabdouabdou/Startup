import 'user.dart';

class Driver {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String licenseNumber;
  final String vehicleNumber;
  final String vehicleType;
  final double vehicleCapacity;
  final bool isAvailable;
  final String? currentOrderId;
  final double lat;
  final double lng;
  final double rating;
  final int totalDeliveries;
  final double totalEarnings;
  final DateTime createdAt;

  Driver({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.vehicleCapacity,
    this.isAvailable = true,
    this.currentOrderId,
    required this.lat,
    required this.lng,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.totalEarnings = 0.0,
    required this.createdAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      licenseNumber: json['licenseNumber'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      vehicleType: json['vehicleType'] as String,
      vehicleCapacity: (json['vehicleCapacity'] as num).toDouble(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      currentOrderId: json['currentOrderId'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalDeliveries: json['totalDeliveries'] as int? ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'vehicleCapacity': vehicleCapacity,
      'isAvailable': isAvailable,
      'currentOrderId': currentOrderId,
      'lat': lat,
      'lng': lng,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'totalEarnings': totalEarnings,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
