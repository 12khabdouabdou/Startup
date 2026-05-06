enum BookingStatus {
  assigned,
  enRoutePickup,
  atPickupSite,
  pickedUp,
  enRouteDelivery,
  atDeliverySite,
  delivered,
  completed,
  cancelled,
}

class BookingModel {
  final String id;
  final String listingId;
  final String haulerId;
  final String recyclerId;
  final String developerId;
  final BookingStatus status;
  final DateTime? pickupDate;
  final DateTime? deliveryDate;
  final DateTime? completedDate;
  final double? price;
  final String? truckId;
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? routePolyline;
  final int? routeDistanceM;
  final int? routeDurationS;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.listingId,
    required this.haulerId,
    required this.recyclerId,
    required this.developerId,
    required this.status,
    this.pickupDate,
    this.deliveryDate,
    this.completedDate,
    this.price,
    this.truckId,
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
    this.routePolyline,
    this.routeDistanceM,
    this.routeDurationS,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      haulerId: json['hauler_id'] as String,
      recyclerId: json['recycler_id'] as String,
      developerId: json['developer_id'] as String,
      status: BookingStatus.values.byName(json['status'] as String),
      pickupDate: json['pickup_date'] != null
          ? DateTime.parse(json['pickup_date'] as String)
          : null,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'] as String)
          : null,
      price: json['price'] != null
          ? (json['price'] as num).toDouble()
          : null,
      truckId: json['truck_id'] as String?,
      pickupLat: json['pickup_lat'] != null
          ? (json['pickup_lat'] as num).toDouble()
          : null,
      pickupLng: json['pickup_lng'] != null
          ? (json['pickup_lng'] as num).toDouble()
          : null,
      deliveryLat: json['delivery_lat'] != null
          ? (json['delivery_lat'] as num).toDouble()
          : null,
      deliveryLng: json['delivery_lng'] != null
          ? (json['delivery_lng'] as num).toDouble()
          : null,
      routePolyline: json['route_polyline'] as String?,
      routeDistanceM: json['route_distance_m'] as int?,
      routeDurationS: json['route_duration_s'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'listing_id': listingId,
        'hauler_id': haulerId,
        'recycler_id': recyclerId,
        'developer_id': developerId,
        'status': status.name,
        'pickup_date': pickupDate?.toIso8601String(),
        'delivery_date': deliveryDate?.toIso8601String(),
        'completed_date': completedDate?.toIso8601String(),
        'price': price,
        'truck_id': truckId,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'delivery_lat': deliveryLat,
        'delivery_lng': deliveryLng,
        'route_polyline': routePolyline,
        'route_distance_m': routeDistanceM,
        'route_duration_s': routeDurationS,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static BookingModel empty() => BookingModel(
        id: '',
        listingId: '',
        haulerId: '',
        recyclerId: '',
        developerId: '',
        status: BookingStatus.assigned,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
