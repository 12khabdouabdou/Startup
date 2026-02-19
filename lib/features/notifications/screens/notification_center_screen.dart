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
    final theme = Theme.of(context);

    return Scaffold(
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
            child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                tileColor: n.isRead ? null : theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
                leading: CircleAvatar(
                  backgroundColor: n.isRead
                      ? Colors.grey[300]
                      : theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Icon(
                    _iconForTitle(n.title),
                    color: n.isRead ? Colors.grey : theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(n.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                isThreeLine: true,
                onTap: () {
                  // Mark as read
                  if (!n.isRead) {
                    ref.read(notificationRepositoryProvider).markAsRead(n.id);
                  }
                  // Navigate if deep-link route is present
                  if (n.route != null && n.route!.isNotEmpty) {
                    context.push(n.route!);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  IconData _iconForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('job')) return Icons.work_outline;
    if (lower.contains('review')) return Icons.star_outline;
    if (lower.contains('message')) return Icons.chat_bubble_outline;
    if (lower.contains('listing')) return Icons.list_alt;
    if (lower.contains('approved')) return Icons.check_circle_outline;
    if (lower.contains('billing')) return Icons.receipt_long_outlined;
    return Icons.notifications_outlined;
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(dt);
  }
}
