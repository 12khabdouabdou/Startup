import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/app_user.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;

  ProfileRepository(this._firestore);

  Stream<AppUser?> getUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // AppUser needs helper for Timestamp
        final data = snapshot.data()!;
        final roleStr = data['role'] as String? ?? 'excavator';
        final statusStr = data['status'] as String? ?? 'pending';
        // Handle timestamp
        DateTime created = DateTime.now();
        if (data['createdAt'] is Timestamp) {
          created = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is int) {
          created = DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int);
        }

        return AppUser(
          uid: uid,
          phoneNumber: data['phoneNumber'] as String?,
          displayName: data['displayName'] as String?,
          companyName: data['companyName'] as String?,
          role: UserRole.values.firstWhere((e) => e.name == roleStr, orElse: () => UserRole.excavator),
          status: UserStatus.values.firstWhere((e) => e.name == statusStr, orElse: () => UserStatus.pending),
          createdAt: created,
          fcmToken: data['fcmToken'] as String?,
          licenseUrl: data['licenseUrl'] as String?,
          fleetSize: data['fleetSize'] as int?,
        );
      }
      return null;
    });
  }

  Future<void> createUser(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'phoneNumber': user.phoneNumber,
      'displayName': user.displayName,
      'companyName': user.companyName,
      'role': user.role.name,
      'status': user.status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'fcmToken': user.fcmToken,
      'licenseUrl': user.licenseUrl,
      'fleetSize': user.fleetSize,
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(FirebaseFirestore.instance);
});
