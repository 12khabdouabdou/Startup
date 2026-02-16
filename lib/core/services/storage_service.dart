import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final String _bucket = 'photos'; // User must create this bucket in Supabase

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

    try {
      // Supabase Storage upload
      await _client.storage.from(_bucket).upload(
        remotePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      
      // Get Public URL
      final publicUrl = _client.storage.from(_bucket).getPublicUrl(remotePath);
      log.i('[STORAGE] Upload success: $publicUrl');
      return publicUrl;
    } catch (e, stack) {
      log.e('[STORAGE] Upload failed', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<void> deleteFile(String remotePath) async {
    try {
      await _client.storage.from(_bucket).remove([remotePath]);
      log.i('[STORAGE] Deleted: $remotePath');
    } catch (e) {
      log.e('[STORAGE] Failed to delete: $remotePath', error: e);
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
