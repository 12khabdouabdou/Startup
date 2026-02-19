import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';

part 'offline_queue.g.dart';

@HiveType(typeId: 0)
class QueuedAction extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String type;
  @HiveField(2)
  final String payload;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  int retryCount;
  @HiveField(5)
  String status; // 'pending', 'syncing', 'failed', 'completed'

  @HiveField(6)
  final String? parentId; // Optional grouping

  QueuedAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.status = 'pending',
    this.parentId,
  });
}

class OfflineQueue {
  static const String boxName = 'offline_queue';
  final Box<QueuedAction> box;

  OfflineQueue(this.box);

  Future<void> enqueue(String type, String payload, {String? parentId}) async {
    final action = QueuedAction(
      id: const Uuid().v4(),
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
      parentId: parentId,
    );
    await box.add(action);
    log.i('[QUEUE] Added action: ${action.id} ($type)');
  }

  List<QueuedAction> getPending() {
    return box.values
        .where((a) => a.status == 'pending' || a.status == 'failed')
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Stream<int> get pendingCount => Stream.periodic(const Duration(seconds: 1)).map(
        (_) => getPending().length,
      );

  Future<void> syncAll() async {
    final pending = getPending();
    if (pending.isEmpty) return;

    log.i('[QUEUE] Syncing ${pending.length} actions...');
    for (final action in pending) {
      if (action.status == 'syncing') continue;

      action.status = 'syncing';
      await action.save();

      try {
        await _processAction(action);
        action.status = 'completed';
        await action.save();
        // Or delete: await action.delete(); - Typically retain for audit log or delete after N days?
        // AC-2: "sync within 30s".
        // Mark completed -> remove later or immediately mark completed?
        // Task list says "markCompleted(String id) -> remove from box".
        await action.delete();
        log.i('[QUEUE] Completed action: ${action.id}');
      } catch (e, stack) {
        action.retryCount++;
        if (action.retryCount >= 3) {
          action.status = 'failed';
          log.e('[QUEUE] Failed action permanently: ${action.id}', error: e, stackTrace: stack);
        } else {
          action.status = 'pending'; // retry later
          log.w('[QUEUE] Retrying action later: ${action.id} (Attempt ${action.retryCount})');
        }
        await action.save();
      }
    }
  }

  Future<void> _processAction(QueuedAction action) async {
    // TODO: Implement actual processing logic or delegate to handlers
    log.d('[QUEUE] Processing fake action: ${action.type}');
    await Future.delayed(const Duration(seconds: 1)); // simulate work
    // throw Exception('Mock failure'); // Uncomment to test retry
  }
}

final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  // Requires initialization in main.dart
  final box = Hive.box<QueuedAction>(OfflineQueue.boxName);
  return OfflineQueue(box);
});
