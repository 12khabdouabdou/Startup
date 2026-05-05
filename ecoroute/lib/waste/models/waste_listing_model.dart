import 'package:freezed_annotation/freezed_annotation.dart';

part 'waste_listing_model.freezed.dart';
part 'waste_listing_model.g.dart';

enum WasteType { concrete, wood, metal, soil, mixed, hazardous, other }

enum ListingStatus { active, matched, booked, completed, cancelled }

@freezed
class WasteListingModel with _$WasteListingModel {
  const factory WasteListingModel({
    required String id,
    required String developerId,
    required String projectId,
    required String siteId,
    required WasteType wasteType,
    required double quantity,
    required String unit,
    required String address,
    required double latitude,
    required double longitude,
    required DateTime availableFrom,
    required DateTime? availableTo,
    required ListingStatus status,
    required double? estimatedMin,
    required double? estimatedMax,
    required List<String> photos,
    required String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WasteListingModel;

  factory WasteListingModel.fromJson(Map<String, dynamic> json) =>
      _$WasteListingModelFromJson(json);
  
  factory WasteListingModel.empty() => WasteListingModel(
    id: '',
    developerId: '',
    projectId: '',
    siteId: '',
    wasteType: WasteType.other,
    quantity: 0,
    unit: 'tons',
    address: '',
    latitude: 0,
    longitude: 0,
    availableFrom: DateTime.now(),
    availableTo: null,
    status: ListingStatus.active,
    estimatedMin: null,
    estimatedMax: null,
    photos: [],
    description: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
