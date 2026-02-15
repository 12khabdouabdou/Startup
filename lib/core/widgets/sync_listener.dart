import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_notifier.dart';

class SyncListener extends ConsumerWidget {
  final Widget child;

  const SyncListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SyncStatus>(syncStatusProvider, (previous, next) {
      if (previous == next) return;

      final messenger = ScaffoldMessenger.of(context);
      // Don't show SnackBar if not mounted, but context in build is risky?
      // ConsumerWidget build context is safe.
      
      // We hide previous bars
      messenger.clearSnackBars();

      if (next == SyncStatus.syncing) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Syncing offline actions...'),
            duration: Duration(seconds: 1),
          ),
        );
      } else if (next == SyncStatus.success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Synced ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (next == SyncStatus.failure) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Sync failed ❌'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                ref.read(syncStatusProvider.notifier).triggerSync();
              },
            ),
          ),
        );
      }
    });

    return child;
  }
}
