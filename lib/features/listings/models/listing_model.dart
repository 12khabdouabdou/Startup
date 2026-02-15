import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingType { offering, needing }
enum FillMaterial { cleanFill, topsoil, gravel, clay, mixed, other }
enum VolumeUnit { cubicYards, tons }
enum ListingStatus { active, sold, archived, pending }

class Listing {
  final String id;
  final String hostUid;
  final ListingType type;
  final FillMaterial material;
  final double quantity;
  final VolumeUnit unit;
  final double price; // 0 for free
  final String currency; // 'USD' default
  final String description;
  final List<String> photos;
  final GeoPoint? location; // Firestore GeoPoint
  final String? address;
  final ListingStatus status;
  final DateTime createdAt;

  const Listing({
    required this.id,
    required this.hostUid,
    required this.type,
    required this.material,
    required this.quantity,
    required this.unit,
    this.price = 0.0,
    this.currency = 'USD',
    this.description = '',
    this.photos = const [],
    this.location,
    this.address,
    this.status = ListingStatus.active,
    required this.createdAt,
  });

  factory Listing.fromMap(Map<String, dynamic> data, String id) {
    return Listing(
      id: id,
      hostUid: data['hostUid'] as String,
      type: ListingType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'offering'),
        orElse: () => ListingType.offering,
      ),
      material: FillMaterial.values.firstWhere(
        (e) => e.name == (data['material'] as String? ?? 'other'),
        orElse: () => FillMaterial.other,
      ),
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: VolumeUnit.values.firstWhere(
        (e) => e.name == (data['unit'] as String? ?? 'cubicYards'),
        orElse: () => VolumeUnit.cubicYards,
      ),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      description: data['description'] as String? ?? '',
      photos: (data['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      location: data['location'] as GeoPoint?,
      address: data['address'] as String?,
      status: ListingStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'active'),
        orElse: () => ListingStatus.active,
      ),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostUid': hostUid,
      'type': type.name,
      'material': material.name,
      'quantity': quantity,
      'unit': unit.name,
      'price': price,
      'currency': currency,
      'description': description,
      'photos': photos,
      'location': location, // GeoPoint serializes automatically
      'address': address,
      'status': status.name,
      'createdAt': createdAt, // Timestamp serializes automatically if FieldValue not used here, but specific DateTime object is converted by SDK usually. Better to use FieldValue.serverTimestamp() for creation but for model -> map, DateTime is okay if converted.
    };
  }
}
