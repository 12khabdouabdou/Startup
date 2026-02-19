import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _client;
  NotificationRepository(this._client);

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((list) => list.map((e) => AppNotification.fromMap(e, e['id'])).toList());
  }

  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    String? route,
  }) async {
    await _client.from('notifications').insert({
      'user_id': targetUserId,
      'title': title,
      'body': body,
      'route': route,
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  Future<int> getUnreadCount(String userId) async {
    final response = await _client.from('notifications').select('*').eq('user_id', userId).eq('is_read', false).count();
    return response.count;
  }
  
  Future<void> markAllAsRead(String userId) async {
    await _client.from('notifications').update({'is_read': true}).eq('user_id', userId).eq('is_read', false);
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).watchNotifications(user.id);
});

final unreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final notifs = ref.watch(notificationsProvider).valueOrNull ?? [];
  return Stream.value(notifs.where((n) => !n.isRead).length);
});
