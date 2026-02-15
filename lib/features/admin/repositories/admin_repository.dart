import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/app_user.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository(this._firestore);
  
  // Creates a Stream of all pending users
  Stream<List<AppUser>> fetchPendingUsers() {
    return _firestore
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
            return snapshot.docs.map((doc) {
                // To reuse fromMap, we need to handle potential missing fields or use AppUser.fromMap
                return AppUser.fromMap(doc.data(), doc.id);
            }).toList();
        });
  }

  Future<void> approveUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({'status': 'approved'});
  }
  
  Future<void> rejectUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({'status': 'rejected'});
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(FirebaseFirestore.instance);
});

final pendingUsersProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.fetchPendingUsers();
});
