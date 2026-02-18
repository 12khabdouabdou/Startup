enum UserRole { excavator, developer, hauler, admin }
enum UserStatus { pending, approved, rejected, suspended }

class AppUser {
  final String uid;
  final String? phoneNumber;
  final String? displayName;
  final String? companyName;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final String? fcmToken;
  final String? licenseUrl;
  final int? fleetSize;
  final double rating;
  final int reviewCount;

  // Getters for compatibility
  String get id => uid;
  String? get phone => phoneNumber;
  String get fullName => displayName ?? companyName ?? 'User';

  const AppUser({
    required this.uid,
    this.phoneNumber,
    this.displayName,
    this.companyName,
    required this.role,
    this.status = UserStatus.pending,
    required this.createdAt,
    this.fcmToken,
    this.licenseUrl,
    this.fleetSize,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      phoneNumber: data['phone_number'] as String?,
      displayName: data['display_name'] as String?,
      companyName: data['company_name'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == (data['role'] as String? ?? 'excavator'),
        orElse: () => UserRole.excavator,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => UserStatus.pending,
      ),
      createdAt: (data['created_at'] is String)
          ? DateTime.parse(data['created_at'] as String)
          : (data['created_at'] is int)
              ? DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int)
              : DateTime.now(),
      fcmToken: data['fcm_token'] as String?,
      licenseUrl: data['license_url'] as String?,
      fleetSize: data['fleet_size'] as int?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['review_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone_number': phoneNumber,
      'display_name': displayName,
      'company_name': companyName,
      'role': role.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'fcm_token': fcmToken,
      'license_url': licenseUrl,
      'fleet_size': fleetSize,
      'rating': rating,
      'review_count': reviewCount,
    };
  }
}
