import 'package:cloud_firestore/cloud_firestore.dart';

enum JobStatus {
  pending,    // Job created, waiting for hauler
  accepted,   // Hauler accepted
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
  final String? haulerUid;     // Hauler assigned to the job
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
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Job({
    required this.id,
    required this.listingId,
    required this.hostUid,
    this.haulerUid,
    this.haulerName,
    this.status = JobStatus.pending,
    this.pickupAddress,
    this.pickupLocation,
    this.dropoffAddress,
    this.dropoffLocation,
    this.pickupPhotoUrl,
    this.dropoffPhotoUrl,
    this.notes,
    this.quantity,
    this.material,
    required this.createdAt,
    this.updatedAt,
  });

  factory Job.fromMap(Map<String, dynamic> data, String id) {
    return Job(
      id: id,
      listingId: data['listingId'] as String? ?? '',
      hostUid: data['hostUid'] as String? ?? '',
      haulerUid: data['haulerUid'] as String?,
      haulerName: data['haulerName'] as String?,
      status: JobStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => JobStatus.pending,
      ),
      pickupAddress: data['pickupAddress'] as String?,
      pickupLocation: data['pickupLocation'] as GeoPoint?,
      dropoffAddress: data['dropoffAddress'] as String?,
      dropoffLocation: data['dropoffLocation'] as GeoPoint?,
      pickupPhotoUrl: data['pickupPhotoUrl'] as String?,
      dropoffPhotoUrl: data['dropoffPhotoUrl'] as String?,
      notes: data['notes'] as String?,
      quantity: (data['quantity'] as num?)?.toDouble(),
      material: data['material'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'hostUid': hostUid,
      'haulerUid': haulerUid,
      'haulerName': haulerName,
      'status': status.name,
      'pickupAddress': pickupAddress,
      'pickupLocation': pickupLocation,
      'dropoffAddress': dropoffAddress,
      'dropoffLocation': dropoffLocation,
      'pickupPhotoUrl': pickupPhotoUrl,
      'dropoffPhotoUrl': dropoffPhotoUrl,
      'notes': notes,
      'quantity': quantity,
      'material': material,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
