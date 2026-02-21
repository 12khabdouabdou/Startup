import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';
import 'storage_service.dart';
import '../../features/jobs/repositories/job_repository.dart';

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
  final StorageService storageService;
  final JobRepository jobRepository;

  OfflineQueue(this.box, this.storageService, this.jobRepository);

  // ─── Enqueue ─────────────────────────────────────────────────────────────

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

  /// Convenience: enqueue a photo upload that failed due to offline.
  /// Payload: { jobId, localPath, remotePath, isPickup }
  Future<void> enqueuePhotoUpload({
    required String jobId,
    required String localPath,
    required String remotePath,
    required bool isPickup,
  }) async {
    final payload = jsonEncode({
      'jobId': jobId,
      'localPath': localPath,
      'remotePath': remotePath,
      'isPickup': isPickup,
    });
    await enqueue('photo_upload', payload, parentId: jobId);
    log.i('[QUEUE] Enqueued offline photo upload for job $jobId (isPickup: $isPickup)');
  }

  // ─── Query ───────────────────────────────────────────────────────────────

  List<QueuedAction> getPending() {
    return box.values
        .where((a) => a.status == 'pending' || a.status == 'failed')
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Stream<int> get pendingCount => Stream.periodic(const Duration(seconds: 1)).map(
        (_) => getPending().length,
      );

  // ─── Sync ────────────────────────────────────────────────────────────────

  Future<void> syncAll() async {
    final pending = getPending();
    if (pending.isEmpty) return;

    log.i('[QUEUE] Syncing ${pending.length} pending actions...');
    for (final action in pending) {
      if (action.status == 'syncing') continue;

      action.status = 'syncing';
      await action.save();

      try {
        await _processAction(action);
        await action.delete();
        log.i('[QUEUE] Completed + removed action: ${action.id}');
      } catch (e, stack) {
        action.retryCount++;
        if (action.retryCount >= 3) {
          action.status = 'failed';
          log.e('[QUEUE] Permanently failed action: ${action.id}', error: e, stackTrace: stack);
        } else {
          action.status = 'pending';
          log.w('[QUEUE] Will retry action: ${action.id} (attempt ${action.retryCount})');
        }
        await action.save();
      }
    }
  }

  // ─── Processors ──────────────────────────────────────────────────────────

  Future<void> _processAction(QueuedAction action) async {
    switch (action.type) {
      case 'photo_upload':
        await _processPhotoUpload(action);
        break;
      default:
        log.w('[QUEUE] No handler for action type: ${action.type}');
        throw Exception('Unknown action type: ${action.type}');
    }
  }

  Future<void> _processPhotoUpload(QueuedAction action) async {
    log.d('[QUEUE] Processing photo_upload: ${action.id}');

    final Map<String, dynamic> data = jsonDecode(action.payload) as Map<String, dynamic>;
    final String jobId      = data['jobId'] as String;
    final String localPath  = data['localPath'] as String;
    final String remotePath = data['remotePath'] as String;
    final bool isPickup     = data['isPickup'] as bool;

    // 1. Upload local file to Supabase Storage
    final String? photoUrl = await storageService.uploadFile(
      localPath: localPath,
      remotePath: remotePath,
    );

    if (photoUrl == null) {
      throw Exception('[QUEUE] Storage upload returned null for job $jobId');
    }

    // 2. Persist URL + advance job status via repository
    if (isPickup) {
      await jobRepository.uploadPickupPhoto(jobId, photoUrl);
    } else {
      await jobRepository.uploadDropoffPhoto(jobId, photoUrl);
    }

    log.i('[QUEUE] Photo upload synced for job $jobId — url: $photoUrl');
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  final box            = Hive.box<QueuedAction>(OfflineQueue.boxName);
  final storageService = ref.read(storageServiceProvider);
  final jobRepository  = ref.read(jobRepositoryProvider);
  return OfflineQueue(box, storageService, jobRepository);
});
