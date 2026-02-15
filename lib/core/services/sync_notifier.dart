import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';
import '../services/offline_queue.dart';
import '../utils/logger.dart';

enum SyncStatus { idle, syncing, success, failure }

class SyncNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() {
    // Listen to connectivity changes to trigger sync
    ref.listen(connectivityStreamProvider, (previous, next) {
      if (previous?.value == null) return; // ignore initial load?

      final wasOffline = previous?.value == ConnectivityStatus.offline;
      final isNowOnline = next.value == ConnectivityStatus.online;

      if (wasOffline && isNowOnline) {
        log.i('[SYNC] Connection restored. Triggering sync...');
        triggerSync();
      }
    });
    return SyncStatus.idle;
  }

  Future<void> triggerSync() async {
    if (state == SyncStatus.syncing) return;

    state = SyncStatus.syncing;
    try {
      final queue = ref.read(offlineQueueProvider);
      
      // Check if pending items
      if (queue.getPending().isEmpty) {
        state = SyncStatus.idle;
        return;
      }
      
      await queue.syncAll();
      state = SyncStatus.success;
      
      // Reset state after showing success briefly
      await Future.delayed(const Duration(seconds: 3));
      // Only reset if still success (don't overwrite if syncing again)
      if (state == SyncStatus.success) {
        state = SyncStatus.idle;
      }
    } catch (e, stack) {
      log.e('[SYNC] Sync failed', error: e, stackTrace: stack);
      state = SyncStatus.failure;
      // Reset after delay
      await Future.delayed(const Duration(seconds: 5));
      if (state == SyncStatus.failure) {
        state = SyncStatus.idle;
      }
    }
  }
}

final syncStatusProvider = NotifierProvider<SyncNotifier, SyncStatus>(SyncNotifier.new);
