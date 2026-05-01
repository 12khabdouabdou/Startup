import 'user.dart';

class Recycler {
  final String id;
  final String userId;
  final String companyName;
  final String licenseNumber;
  final String address;
  final double lat;
  final double lng;
  final List<WasteType> acceptedWasteTypes;
  final double capacity;
  final double currentLoad;
  final String operatingHours;
  final List<String> facilityImages;
  final String? certificationUrl;
  final bool isActive;
  final double rating;
  final int totalReviews;
  final double pricePerTon;
  final DateTime createdAt;

  Recycler({
    required this.id,
    required this.userId,
    required this.companyName,
    required this.licenseNumber,
    required this.address,
    required this.lat,
    required this.lng,
    required this.acceptedWasteTypes,
    required this.capacity,
    required this.currentLoad,
    required this.operatingHours,
    this.facilityImages = const [],
    this.certificationUrl,
    this.isActive = true,
    this.rating = 0.0,
    this.totalReviews = 0,
    required this.pricePerTon,
    required this.createdAt,
  });

  factory Recycler.fromJson(Map<String, dynamic> json) {
    return Recycler(
      id: json['id'] as String,
      userId: json['userId'] as String,
      companyName: json['companyName'] as String,
      licenseNumber: json['licenseNumber'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      acceptedWasteTypes: (json['acceptedWasteTypes'] as List)
          .map((e) => WasteType.values.firstWhere(
                (w) => w.name == e,
                orElse: () => WasteType.mixed,
              ))
          .toList(),
      capacity: (json['capacity'] as num).toDouble(),
      currentLoad: (json['currentLoad'] as num).toDouble(),
      operatingHours: json['operatingHours'] as String,
      facilityImages: List<String>.from(json['facilityImages'] ?? []),
      certificationUrl: json['certificationUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      pricePerTon: (json['pricePerTon'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'companyName': companyName,
      'licenseNumber': licenseNumber,
      'address': address,
      'lat': lat,
      'lng': lng,
      'acceptedWasteTypes': acceptedWasteTypes.map((e) => e.name).toList(),
      'capacity': capacity,
      'currentLoad': currentLoad,
      'operatingHours': operatingHours,
      'facilityImages': facilityImages,
      'certificationUrl': certificationUrl,
      'isActive': isActive,
      'rating': rating,
      'totalReviews': totalReviews,
      'pricePerTon': pricePerTon,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  double get availableCapacity => capacity - currentLoad;
  double get capacityPercentage => (currentLoad / capacity) * 100;
}
