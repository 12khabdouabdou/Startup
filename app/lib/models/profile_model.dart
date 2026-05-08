class Profile {
  final String id;
  final String role;
  final String? fullName;
  final String? phone;
  final String? companyName;
  final String verificationStatus;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
    this.companyName,
    required this.verificationStatus,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'],
    role: json['role'],
    fullName: json['full_name'],
    phone: json['phone'],
    companyName: json['company_name'],
    verificationStatus: json['verification_status'],
    createdAt: DateTime.parse(json['created_at']),
  );
}
