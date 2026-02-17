import '../../../core/models/geo_point.dart';

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
    // Handle location: generic map or check for lat/long keys if we flatten it
    // For now assuming it's stored as jsonb or we extract it
    // Start with basic map check
    GeoPoint? loc;
    if (data['location'] != null) {
      if (data['location'] is Map) {
         final l = data['location'];
         // PostGIS / GeoJSON returns coordinates usually
         // or if we simply stored a map
         if (l['latitude'] != null && l['longitude'] != null) {
             loc = GeoPoint(l['latitude'], l['longitude']);
         }
      }
    }

    return Listing(
      id: id,
      hostUid: (data['owner_id'] ?? data['hostUid']) as String, // Support both for safety, prefer owner_id
      type: ListingType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'offering'),
        orElse: () => ListingType.offering,
      ),
      material: FillMaterial.values.firstWhere(
        (e) => e.name == (data['material'] as String? ?? 'other'), // material is text
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
      location: loc,
      address: data['address'] as String?,
      status: ListingStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'active'),
        orElse: () => ListingStatus.active,
      ),
      createdAt: (data['created_at'] is String)
          ? DateTime.parse(data['created_at'] as String)
          : (data['createdAt'] is String) // Fallback
              ? DateTime.parse(data['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': hostUid, // Mapped to owner_id
      'type': type.name,
      'material': material.name,
      'quantity': quantity,
      'unit': unit.name,
      'price': price,
      'currency': currency,
      'description': description,
      'photos': photos,
      // Store location as JSONB for now or flattened
      'location': location != null ? {'latitude': location!.latitude, 'longitude': location!.longitude} : null,
      'address': address,
      'status': status.name,
      'created_at': createdAt.toIso8601String(), // Mapped to created_at
    };
  }
}

// Simple GeoPoint replacement class if we remove cloud_firestore dependency entirely
// But wait, Listing model imported cloud_firestore. We need to remove that import too.
// I will create a local GeoPoint class or use latlong2 LatLng.
// Let's check imports in the next step. I'll define a simple class here or use LatLng.
// StartLine 41 of original file.
