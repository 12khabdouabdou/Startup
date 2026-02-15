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
      phoneNumber: data['phoneNumber'] as String?,
      displayName: data['displayName'] as String?,
      companyName: data['companyName'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == (data['role'] as String? ?? 'excavator'),
        orElse: () => UserRole.excavator,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => UserStatus.pending,
      ),
      createdAt: (data['createdAt'] is int)
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : DateTime.now(), // Firestore timestamp parsing deferred
      fcmToken: data['fcmToken'] as String?,
      licenseUrl: data['licenseUrl'] as String?,
      fleetSize: data['fleetSize'] as int?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'companyName': companyName,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'fcmToken': fcmToken,
      'licenseUrl': licenseUrl,
      'fleetSize': fleetSize,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}
