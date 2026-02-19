import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../../auth/repositories/auth_repository.dart';

class JobRepository {
  final SupabaseClient _client;

  JobRepository(this._client);

  // ─── Create (Atomic Booking) ───────────────────
  Future<String> bookListing(String listingId) async {
    try {
      final response = await _client.rpc('book_listing', params: {
        'p_listing_id': listingId,
      });
      return response as String; // Returns the new Job ID
    } catch (e) {
      throw Exception('Failed to book listing: $e');
    }
  }

  // ─── Read ────────────────────────────────────────
  Stream<List<Job>> fetchAvailableJobs() {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('status', JobStatus.pending.name)
        .isFilter('hauler_uid', null)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Job.fromMap(json, json['id'] as String)).toList());
  }

  Stream<List<Job>> fetchHaulerJobs(String haulerUid) {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('hauler_uid', haulerUid)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Job.fromMap(json, json['id'] as String)).toList());
  }

  Stream<List<Job>> fetchHostJobs(String hostUid) {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('host_uid', hostUid)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Job.fromMap(json, json['id'] as String)).toList());
  }

  Stream<Job?> watchJob(String jobId) {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('id', jobId)
        .map((data) {
          if (data.isEmpty) return null;
          return Job.fromMap(data.first, data.first['id'] as String);
        });
  }

  // Helper to find job from listing
  Future<String?> fetchJobIdForListing(String listingId) async {
    final data = await _client
        .from('jobs')
        .select('id')
        .eq('listing_id', listingId)
        .maybeSingle();
    return data?['id'] as String?;
  }

  // ─── Status Transitions (Atomic Acceptance) ─────
  Future<void> acceptJob(String jobId) async {
    try {
      await _client.rpc('accept_job_gig', params: {
        'p_job_id': jobId,
      });
    } catch (e) {
      throw Exception('Failed to accept gig: $e');
    }
  }

  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    await _client.from('jobs').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', jobId);
  }

  Future<void> cancelJob(String jobId) async {
    // 1. Fetch job to get listing_id
    final data = await _client.from('jobs').select('listing_id').eq('id', jobId).maybeSingle();
    final listingId = data?['listing_id'] as String?;

    // 2. Cancel Job
    await updateJobStatus(jobId, JobStatus.cancelled);

    // 3. Re-activate Listing (if linked)
    if (listingId != null) {
      await _client.from('listings').update({
        'status': 'active', // Make it visible again
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', listingId);
    }
  }

  // ─── Photo Verification ──────────────────────────
  Future<void> uploadPickupPhoto(String jobId, String photoUrl) async {
    await _client.from('jobs').update({
      'pickup_photo_url': photoUrl,
      'status': JobStatus.loaded.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', jobId);
  }

  Future<void> uploadDropoffPhoto(String jobId, String photoUrl) async {
    await _client.from('jobs').update({
      'dropoff_photo_url': photoUrl,
      'status': JobStatus.completed.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', jobId);
  }
}

// ─── Providers ───────────────────────────────────────
final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(Supabase.instance.client);
});

final availableJobsProvider = StreamProvider.autoDispose<List<Job>>((ref) {
  return ref.watch(jobRepositoryProvider).fetchAvailableJobs();
});

final myActiveJobProvider = StreamProvider.autoDispose<Job?>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value(null);
  
  return ref.watch(jobRepositoryProvider)
      .fetchHaulerJobs(user.id)
      .map((jobs) {
        try {
          return jobs.firstWhere((j) => j.status != JobStatus.completed && j.status != JobStatus.cancelled);
        } catch (_) {
          return null;
        }
      });
});
