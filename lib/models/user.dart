enum UserType { customer, recycler, driver, admin }

enum WasteType {
  concrete,
  metal,
  wood,
  plastic,
  glass,
  drywall,
  asphalt,
  mixed,
  other,
}

enum OrderStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
}

class User {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserType userType;
  final String? companyName;
  final String? address;
  final String? profileImageUrl;
  final bool isVerified;
  final double rating;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.userType,
    this.companyName,
    this.address,
    this.profileImageUrl,
    this.isVerified = false,
    this.rating = 0.0,
    required this.createdAt,
    this.lastActiveAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      userType: UserType.values.firstWhere(
        (e) => e.name == json['userType'],
        orElse: () => UserType.customer,
      ),
      companyName: json['companyName'] as String?,
      address: json['address'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType.name,
      'companyName': companyName,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'isVerified': isVerified,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }
}
