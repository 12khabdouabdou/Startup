import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../repositories/notification_repository.dart';
import '../../auth/repositories/auth_repository.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    const forestGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              final uid = ref.read(authRepositoryProvider).currentUser?.id;
              if (uid != null) {
                ref.read(notificationRepositoryProvider).markAllAsRead(uid);
              }
            },
            child: const Text('Mark all read', style: TextStyle(color: forestGreen, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_none_outlined, size: 48, color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 24),
                  const Text('No notifications yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('We\'ll alert you when there\'s news! 🔔', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            color: forestGreen,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationTile(notification: n);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: forestGreen)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const forestGreen = Color(0xFF2E7D32);
    final isRead = notification.isRead;

    return ListTile(
      onTap: () {
        if (!isRead) {
          ref.read(notificationRepositoryProvider).markAsRead(notification.id);
        }
        if (notification.route != null && notification.route!.isNotEmpty) {
          context.push(notification.route!);
        }
      },
      tileColor: isRead ? null : forestGreen.withOpacity(0.04),
      leading: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRead ? Colors.grey[100] : forestGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconForTitle(notification.title),
              color: isRead ? Colors.grey[600] : forestGreen,
              size: 22,
            ),
          ),
          if (!isRead)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notification.body,
            style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _relativeTime(notification.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
      ),
      isThreeLine: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  IconData _iconForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('job') || lower.contains('driver')) return Icons.local_shipping_outlined;
    if (lower.contains('review')) return Icons.star_outline;
    if (lower.contains('message') || lower.contains('chat')) return Icons.chat_bubble_outline;
    if (lower.contains('listing') || lower.contains('material')) return Icons.category_outlined;
    if (lower.contains('approved') || lower.contains('verified')) return Icons.verified_user_outlined;
    if (lower.contains('billing') || lower.contains('payment')) return Icons.payments_outlined;
    return Icons.notifications_none_outlined;
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    if (diff.inDays < 7) return '${diff.inDays}D AGO';
    return DateFormat.MMMd().format(dt).toUpperCase();
  }
}
