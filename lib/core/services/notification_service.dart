import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'push_notification_service.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Manages user notification preferences stored in the `users` table.
/// The actual push delivery is handled by [PushNotificationService].
class NotificationService {
  final SupabaseClient _supabase;
  NotificationService(this._supabase);

  Future<void> initialize() async {
    _log.i('NotificationService: Ready (backed by PushNotificationService).');
    // Real push initialization is in PushNotificationService (called from main.dart)
  }

  /// Loads notification preferences from the `users` table.
  /// Falls back to all-enabled defaults if no prefs found.
  Future<Map<String, bool>> getSettings(String uid) async {
    try {
      final data = await _supabase
          .from('users')
          .select('notif_new_listings, notif_job_updates, notif_messages')
          .eq('uid', uid)
          .maybeSingle();

      if (data == null) return _defaults();

      return {
        'newListings': data['notif_new_listings'] as bool? ?? true,
        'jobUpdates': data['notif_job_updates'] as bool? ?? true,
        'messages': data['notif_messages'] as bool? ?? true,
      };
    } catch (e) {
      _log.e('Failed to load notification settings: $e');
      return _defaults();
    }
  }

  /// Persists notification preferences to the `users` table.
  Future<void> updateSettings(String uid, Map<String, bool> settings) async {
    try {
      await _supabase.from('users').update({
        'notif_new_listings': settings['newListings'] ?? true,
        'notif_job_updates': settings['jobUpdates'] ?? true,
        'notif_messages': settings['messages'] ?? true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('uid', uid);
      _log.i('Notification settings saved for $uid');
    } catch (e) {
      _log.e('Failed to save notification settings: $e');
    }
  }

  Map<String, bool> _defaults() => {
    'newListings': true,
    'jobUpdates': true,
    'messages': true,
  };
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(Supabase.instance.client);
});
