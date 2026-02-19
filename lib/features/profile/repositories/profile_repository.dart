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

  /// Updates only user-editable profile fields.
  /// Internal fields (status, role, uid, rating, etc.) are explicitly excluded
  /// to provide defense-in-depth on top of RLS policies.
  Future<void> updateUser(
    String uid, {
    String? displayName,
    String? companyName,
    String? phoneNumber,
    int? fleetSize,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['display_name'] = displayName;
    if (companyName != null) data['company_name'] = companyName;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (fleetSize != null) data['fleet_size'] = fleetSize;

    if (data.isEmpty) return; // Nothing to update

    data['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('users').update(data).eq('uid', uid);
  }

  /// Submits an account deletion request for GDPR/Privacy compliance.
  /// The actual deletion is performed server-side by an admin or Edge Function.
  Future<void> requestAccountDeletion(String uid) async {
    await _client.from('notifications').insert({
      'user_id': uid,
      'title': 'Account Deletion Requested',
      'body':
          'Your account deletion request has been received. An admin will process it within 30 days.',
      'route': '/profile',
    });
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});
