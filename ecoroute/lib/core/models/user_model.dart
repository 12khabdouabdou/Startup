class UserModel {
  final String id;
  final String email;
  final String role;
  final String? companyId;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.companyId,
    this.phoneNumber,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        companyId: json['company_id'] as String?,
        phoneNumber: json['phone_number'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'role': role,
        'company_id': companyId,
        'phone_number': phoneNumber,
        'avatar_url': avatarUrl,
        'created_at': createdAt?.toIso8601String(),
      };

  static UserModel empty() => const UserModel(id: '', email: '', role: 'developer');
}
