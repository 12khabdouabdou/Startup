import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/repositories/auth_repository.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? route; // deep-link route, e.g. '/jobs/abc123'
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.route,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> data, String id) {
    return AppNotification(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      route: data['route'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] is String)
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class NotificationRepository {
  final SupabaseClient _client;
  NotificationRepository(this._client);

  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('userId', uid)
        .order('createdAt', ascending: false)
        .limit(50)
        .map((data) => data.map((json) => AppNotification.fromMap(json, json['id'] as String)).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update({'isRead': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead(String uid) async {
    await _client
        .from('notifications')
        .update({'isRead': true})
        .eq('userId', uid)
        .eq('isRead', false);
  }

  /// Create a local notification (for server-side, use Cloud Functions)
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? route,
  }) async {
    await _client.from('notifications').insert({
      'userId': userId,
      'title': title,
      'body': body,
      'route': route,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}

// ─── Providers ───────────────────────────────────

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final userNotificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUser?.id;
  if (uid == null) return Stream.value([]);
  return ref.watch(notificationRepositoryProvider).watchNotifications(uid);
});

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(userNotificationsProvider);
  return notifications.whenOrNull(data: (list) => list.where((n) => !n.isRead).length) ?? 0;
});
