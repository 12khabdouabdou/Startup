import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/app_user.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Stream<AppUser?> getUser(String uid) {
    return _client
        .from('users')
        .stream(primaryKey: ['uid'])
        .eq('uid', uid)
        .map((data) {
          if (data.isNotEmpty) {
            return AppUser.fromMap(data.first, uid);
          }
          return null;
        });
  }

  Future<void> createUser(AppUser user) async {
    // Upsert to handle potential race conditions or re-auths
    await _client.from('users').upsert({
      'uid': user.id, 
      'phone_number': user.phone,
      'display_name': user.displayName,
      'company_name': user.companyName,
      'role': user.role.name,
      'status': user.status.name,
      'created_at': DateTime.now().toIso8601String(),
      'fcm_token': user.fcmToken,
      'license_url': user.licenseUrl,
      'fleet_size': user.fleetSize,
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _client.from('users').update(data).eq('uid', uid);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});
