import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_model.freezed.dart';
part 'booking_model.g.dart';

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

@freezed
class BookingModel with _$BookingModel {
  const factory BookingModel({
    required String id,
    required String listingId,
    required String haulerId,
    required String recyclerId,
    required String developerId,
    required BookingStatus status,
    required DateTime? pickupDate,
    required DateTime? deliveryDate,
    required DateTime? completedDate,
    required double? price,
    required String? truckId,
    required double? pickupLat,
    required double? pickupLng,
    required double? deliveryLat,
    required double? deliveryLng,
    required String? routePolyline,
    required int? routeDistanceM,
    required int? routeDurationS,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BookingModel;

  factory BookingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingModelFromJson(json);
  
  factory BookingModel.empty() => BookingModel(
    id: '',
    listingId: '',
    haulerId: '',
    recyclerId: '',
    developerId: '',
    status: BookingStatus.assigned,
    pickupDate: null,
    deliveryDate: null,
    completedDate: null,
    price: null,
    truckId: null,
    pickupLat: null,
    pickupLng: null,
    deliveryLat: null,
    deliveryLng: null,
    routePolyline: null,
    routeDistanceM: null,
    routeDurationS: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
