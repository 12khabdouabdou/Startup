import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/notification_repository.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCount = ref.watch(unreadCountProvider);

    return IconButton(
      icon: asyncCount.when(
        data: (count) => Badge(
          label: Text('$count'),
          isLabelVisible: count > 0,
          child: const Icon(Icons.notifications),
        ),
        loading: () => const Icon(Icons.notifications),
        error: (_, __) => const Icon(Icons.notifications_off),
      ),
      onPressed: () => context.push('/notifications'),
    );
  }
}
