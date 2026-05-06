enum WasteType { concrete, wood, metal, soil, mixed, hazardous, other }

enum ListingStatus { active, matched, booked, completed, cancelled }

class WasteListingModel {
  final String id;
  final String developerId;
  final String projectId;
  final String siteId;
  final WasteType wasteType;
  final double quantity;
  final String unit;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime availableFrom;
  final DateTime? availableTo;
  final ListingStatus status;
  final double? estimatedMin;
  final double? estimatedMax;
  final List<String> photos;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  WasteListingModel({
    required this.id,
    required this.developerId,
    required this.projectId,
    required this.siteId,
    required this.wasteType,
    required this.quantity,
    required this.unit,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.availableFrom,
    this.availableTo,
    required this.status,
    this.estimatedMin,
    this.estimatedMax,
    this.photos = const [],
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WasteListingModel.fromJson(Map<String, dynamic> json) {
    return WasteListingModel(
      id: json['id'] as String,
      developerId: json['developer_id'] as String,
      projectId: json['project_id'] as String,
      siteId: json['site_id'] as String,
      wasteType: WasteType.values.byName(json['waste_type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      availableFrom: DateTime.parse(json['available_from'] as String),
      availableTo: json['available_to'] != null
          ? DateTime.parse(json['available_to'] as String)
          : null,
      status: ListingStatus.values.byName(json['status'] as String),
      estimatedMin: json['estimated_min'] != null
          ? (json['estimated_min'] as num).toDouble()
          : null,
      estimatedMax: json['estimated_max'] != null
          ? (json['estimated_max'] as num).toDouble()
          : null,
      photos: (json['photos'] as List?)?.cast<String>() ?? [],
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'developer_id': developerId,
        'project_id': projectId,
        'site_id': siteId,
        'waste_type': wasteType.name,
        'quantity': quantity,
        'unit': unit,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'available_from': availableFrom.toIso8601String(),
        'available_to': availableTo?.toIso8601String(),
        'status': status.name,
        'estimated_min': estimatedMin,
        'estimated_max': estimatedMax,
        'photos': photos,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static WasteListingModel empty() => WasteListingModel(
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
