import 'package:flutter/material.dart';

enum TruckType { dump, trailer, belly, sideReview }

class Truck {
  final String id;
  final String ownerUid;
  final String nickname;
  final String plateNumber;
  final TruckType type;
  final double capacityTons;
  final bool isActive;
  final DateTime createdAt;

  const Truck({
    required this.id,
    required this.ownerUid,
    required this.nickname,
    required this.plateNumber,
    required this.type,
    required this.capacityTons,
    this.isActive = true,
    required this.createdAt,
  });

  factory Truck.fromMap(Map<String, dynamic> data, String id) {
    return Truck(
      id: id,
      ownerUid: data['owner_uid'] as String,
      nickname: data['nickname'] as String? ?? 'Unnamed Truck',
      plateNumber: data['plate_number'] as String? ?? '',
      type: TruckType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'dump'),
        orElse: () => TruckType.dump,
      ),
      capacityTons: (data['capacity_tons'] as num?)?.toDouble() ?? 0.0,
      isActive: data['is_active'] as bool? ?? true,
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_uid': ownerUid,
      'nickname': nickname,
      'plate_number': plateNumber,
      'type': type.name,
      'capacity_tons': capacityTons,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
