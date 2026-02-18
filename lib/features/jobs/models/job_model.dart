import '../../../core/models/geo_point.dart';

enum JobStatus {
  open,       // New: Job posted, waiting for hauler
  pending,    // Legacy: Job created with hauler (or pending approval)
  assigned,   // Hauler accepted / Assigned
  enRoute,    // Hauler driving to pickup
  atPickup,   // Hauler arrived at pickup
  loaded,     // Material loaded onto truck
  inTransit,  // Hauler driving to dropoff
  atDropoff,  // Hauler arrived at dropoff
  completed,  // Job done (both photos taken)
  cancelled,  // Job was cancelled
}

class Job {
  final String id;
  final String listingId;
  final String hostUid;        // Excavator/Developer who posted the listing
  final String? haulerUid;     // Hauler assigned to the job (nullable for open jobs)
  final String? haulerName;
  final JobStatus status;
  final String? pickupAddress;
  final GeoPoint? pickupLocation;
  final String? dropoffAddress;
  final GeoPoint? dropoffLocation;
  final String? pickupPhotoUrl;
  final String? dropoffPhotoUrl;
  final String? notes;
  final double? quantity;
  final String? material;
  final double? priceOffer;    // New: Price offered for the haul
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Job({
    required this.id,
    required this.listingId,
    required this.hostUid,
    this.haulerUid, // Allow null
    this.haulerName,
    this.status = JobStatus.open, // Default to open if not specified
    this.pickupAddress,
    this.pickupLocation,
    this.dropoffAddress,
    this.dropoffLocation,
    this.pickupPhotoUrl,
    this.dropoffPhotoUrl,
    this.notes,
    this.quantity,
    this.material,
    this.priceOffer,
    required this.createdAt,
    this.updatedAt,
  });

  factory Job.fromMap(Map<String, dynamic> data, String id) {
    GeoPoint? parseGeo(dynamic loc) {
      if (loc == null) return null;
      // Handle Map (GeoJSON) - Standard Supabase Return
      if (loc is Map) {
         if (loc['type'] == 'Point' && loc['coordinates'] is List) {
             final coords = loc['coordinates'] as List;
             if (coords.length >= 2) {
                 return GeoPoint(coords[1].toDouble(), coords[0].toDouble());
             }
         }
         // Fallback lat/long map
         if (loc['latitude'] != null) {
            return GeoPoint(
              (loc['latitude'] as num).toDouble(),
              (loc['longitude'] as num).toDouble(),
            );
         }
      }
      // Handle String (WKT) - POINT(lng lat) or POINT (lng lat)
      if (loc is String && loc.trim().toUpperCase().startsWith('POINT')) {
         try {
           final content = loc
               .trim()
               .toUpperCase()
               .replaceAll('POINT', '')
               .replaceAll('(', '')
               .replaceAll(')', '')
               .trim();
           
           // Split by any whitespace (multiple spaces, tabs, etc)
           final parts = content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
           
           if (parts.length >= 2) {
             final lng = double.parse(parts[0]);
             final lat = double.parse(parts[1]);
             return GeoPoint(lat, lng);
           }
         } catch (e) {
           // debugPrint('Error parsing WKT: $e');
         }
      }
      return null;
    }

    return Job(
      id: id,
      listingId: (data['listing_id'] ?? data['listingId']) as String? ?? '',
      hostUid: (data['host_uid'] ?? data['hostUid']) as String? ?? '',
      haulerUid: (data['hauler_uid'] ?? data['haulerUid']) as String?,
      haulerName: (data['hauler_name'] ?? data['haulerName']) as String?,
      status: JobStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'open'),
        orElse: () => JobStatus.open,
      ),
      pickupAddress: (data['pickup_address'] ?? data['pickupAddress']) as String?,
      pickupLocation: parseGeo((data['pickup_location'] ?? data['pickupLocation'])),
      dropoffAddress: (data['dropoff_address'] ?? data['dropoffAddress']) as String?,
      dropoffLocation: parseGeo((data['dropoff_location'] ?? data['dropoffLocation'])),
      pickupPhotoUrl: (data['pickup_photo_url'] ?? data['pickupPhotoUrl']) as String?,
      dropoffPhotoUrl: (data['dropoff_photo_url'] ?? data['dropoffPhotoUrl']) as String?,
      notes: data['notes'] as String?,
      quantity: (data['quantity'] as num?)?.toDouble(),
      material: data['material'] as String?,
      priceOffer: (data['price_offer'] as num?)?.toDouble(),
      createdAt: (data['created_at'] is String)
          ? DateTime.parse(data['created_at'] as String)
          : (data['createdAt'] is String)
              ? DateTime.parse(data['createdAt'] as String)
              : DateTime.now(),
      updatedAt: (data['updated_at'] is String)
          ? DateTime.parse(data['updated_at'] as String)
          : (data['updatedAt'] is String)
              ? DateTime.parse(data['updatedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    String? geoToWKT(GeoPoint? p) {
      if (p == null) return null;
      return 'POINT(${p.longitude} ${p.latitude})';
    }

    return {
      'listing_id': listingId,
      'host_uid': hostUid,
      'hauler_uid': haulerUid,
      'hauler_name': haulerName,
      'status': status.name,
      'pickup_address': pickupAddress,
      'pickup_location': geoToWKT(pickupLocation),
      'dropoff_address': dropoffAddress,
      'dropoff_location': geoToWKT(dropoffLocation),
      'pickup_photo_url': pickupPhotoUrl,
      'dropoff_photo_url': dropoffPhotoUrl,
      'notes': notes,
      'quantity': quantity,
      'material': material,
      'price_offer': priceOffer,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Job copyWith({
    String? id,
    String? listingId,
    String? hostUid,
    String? haulerUid,
    String? haulerName,
    JobStatus? status,
    String? pickupAddress,
    GeoPoint? pickupLocation,
    String? dropoffAddress,
    GeoPoint? dropoffLocation,
    String? pickupPhotoUrl,
    String? dropoffPhotoUrl,
    String? notes,
    double? quantity,
    String? material,
    double? priceOffer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Job(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      hostUid: hostUid ?? this.hostUid,
      haulerUid: haulerUid ?? this.haulerUid,
      haulerName: haulerName ?? this.haulerName,
      status: status ?? this.status,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupPhotoUrl: pickupPhotoUrl ?? this.pickupPhotoUrl,
      dropoffPhotoUrl: dropoffPhotoUrl ?? this.dropoffPhotoUrl,
      notes: notes ?? this.notes,
      quantity: quantity ?? this.quantity,
      material: material ?? this.material,
      priceOffer: priceOffer ?? this.priceOffer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
