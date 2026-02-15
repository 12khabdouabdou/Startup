import 'package:cloud_firestore/cloud_firestore.dart';
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
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class NotificationRepository {
  final FirebaseFirestore _firestore;
  NotificationRepository(this._firestore);

  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppNotification.fromMap(d.data(), d.id)).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String uid) async {
    final batch = _firestore.batch();
    final unread = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Create a local notification (for server-side, use Cloud Functions)
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? route,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'route': route,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// ─── Providers ───────────────────────────────────

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(FirebaseFirestore.instance);
});

final userNotificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(notificationRepositoryProvider).watchNotifications(uid);
});

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(userNotificationsProvider);
  return notifications.whenOrNull(data: (list) => list.where((n) => !n.isRead).length) ?? 0;
});
