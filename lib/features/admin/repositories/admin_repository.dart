import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/app_user.dart';

class AdminRepository {
  final SupabaseClient _client;

  AdminRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  // Creates a Stream of all pending users
  Stream<List<AppUser>> fetchPendingUsers() {
    return _client
        .from('users')
        .stream(primaryKey: ['uid'])
        .eq('status', 'pending')
        .map((data) {
            return data.map((json) {
                return AppUser.fromMap(json, json['uid'] as String);
            }).toList();
        });
  }

  Future<void> approveUser(String uid) async {
    await _client.rpc('approve_user', params: {'target_uid': uid});
  }

  Future<void> rejectUser(String uid) async {
    await _client.rpc('reject_user', params: {'target_uid': uid});
  }

  /// Fetches a single user by UID — used as fallback for deep-linked admin routes.
  Future<AppUser?> fetchUserById(String uid) async {
    final response = await _client
        .from('users')
        .select()
        .eq('uid', uid)
        .maybeSingle();
    if (response == null) return null;
    return AppUser.fromMap(response, uid);
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});

final pendingUsersProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.fetchPendingUsers();
});
