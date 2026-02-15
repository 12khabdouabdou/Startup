import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/storage_service.dart';
import '../../profile/repositories/profile_repository.dart';

class VerificationService {
  final RobustStorageService _storageService;
  final ProfileRepository _profileService;

  VerificationService(this._storageService, this._profileService);

  Future<void> uploadLicense(String uid, XFile file) async {
    // 1. Upload to Storage
    final ext = file.path.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final remotePath = 'verification_docs/$uid/${timestamp}_license.$ext';
    
    final downloadUrl = await _storageService.uploadFile(
      localPath: file.path,
      remotePath: remotePath,
    );

    if (downloadUrl == null) {
      throw Exception('Failed to upload license document');
    }

    // 2. Update Firestore Profile
    await _profileService.updateUser(uid, {
      'licenseUrl': downloadUrl,
      // Status remains pending until Admin review
    });
  }
}

final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService(
    ref.watch(storageServiceProvider),
    ref.read(profileRepositoryProvider),
  );
});
