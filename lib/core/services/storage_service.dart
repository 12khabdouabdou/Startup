import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadFile({
    required String localPath,
    required String remotePath,
    Function(double)? onProgress,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      log.e('[STORAGE] File not found: $localPath');
      return null;
    }

    final ref = _storage.ref(remotePath);
    final task = ref.putFile(file);

    if (onProgress != null) {
      task.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress(progress);
        }
      });
    }

    try {
      await _uploadWithRetry(task);
      return await ref.getDownloadURL();
    } catch (e, stack) {
      log.e('[STORAGE] Upload failed', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<void> _uploadWithRetry(UploadTask task) async {
    // Firebase SDK handles retries internally for Connectivity losses.
    // But for explicit failures, we can wrap.
    // Actually, putFile task handles intermittent connection.
    // If it throws an error (e.g. cancelled or fatal), we might want to restart?
    // AC-7 says "Failed uploads retry automatically (max 3 retries)".
    // If Firebase SDK handles it (it does for network), we are good.
    // But if we want to restart the whole task on error...
    
    // Let's implement custom retry for robustness.
    int attempts = 0;
    while (attempts < 3) {
      try {
        await task;
        return;
      } catch (e) {
        attempts++;
        if (attempts >= 3) rethrow;
        log.w('[STORAGE] Retry attempt $attempts');
        await Future.delayed(Duration(seconds: 1 * attempts)); // Backoff
        // Resuming task or recreating? Recreating might be needed if task moved to failure state.
        // Task cannot be resumed if failed.
        // So we might need to modify method signature to recreate task inside loop.
        // But UploadTask is created from putFile.
        // Since `task` is passed here, we can't recreate it easily without reference to file/path.
        // I'll assume Firebase SDK is robust enough and just wrap the usage in higher level logic if needed.
        // BUT for this task, I'll refactor uploadFile to loop creation.
        throw e; // RETHROW for now to let uploadFile loop if I refactor.
      }
    }
  }

  Future<void> deleteFile(String remotePath) async {
    try {
      await _storage.ref(remotePath).delete();
      log.i('[STORAGE] Deleted: $remotePath');
    } catch (e) {
      log.e('[STORAGE] Failed to delete: $remotePath', error: e);
    }
  }
}

// Refactored Upload with Loop
class RobustStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
   
  Future<String?> uploadFile({
    required String localPath,
    required String remotePath,
    Function(double)? onProgress,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      log.e('[STORAGE] File not found: $localPath');
      return null;
    }

    int attempts = 0;
    while (attempts < 3) {
      try {
        final ref = _storage.ref(remotePath);
        final task = ref.putFile(file);

        if (onProgress != null) {
          task.snapshotEvents.listen((event) {
            if (event.totalBytes > 0) {
              onProgress(event.bytesTransferred / event.totalBytes);
            }
          });
        }

        await task;
        final url = await ref.getDownloadURL();
        log.i('[STORAGE] Upload success: $url');
        return url;
      } catch (e) {
        attempts++;
        log.w('[STORAGE] Upload failed (Attempt $attempts)', error: e);
        if (attempts >= 3) return null;
        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }
    return null;
  }
  
  Future<void> deleteFile(String remotePath) async {
    try {
      await _storage.ref(remotePath).delete();
      log.i('[STORAGE] Deleted: $remotePath');
    } catch (e) {
      log.e('[STORAGE] Failed to delete: $remotePath', error: e);
    }
  }
}

final storageServiceProvider = Provider<RobustStorageService>((ref) {
  return RobustStorageService();
});
