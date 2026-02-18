import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../../auth/repositories/auth_repository.dart';

class JobRepository {
  final SupabaseClient _client;

  JobRepository(this._client);

  // ─── Create ──────────────────────────────────────
  // ─── Create ──────────────────────────────────────
  Future<String> createJob(Job job) async {
    final data = job.toMap();
    // Start status as accepted if created by hauler accepting a listing?
    // Or pending if created by host?
    // We'll rely on the job object passed in.
    
    final response = await _client.from('jobs').insert(data).select().single();
    return response['id'] as String;
  }

  // ─── Read ────────────────────────────────────────
  // ─── Read ────────────────────────────────────────
  Stream<List<Job>> fetchAvailableJobs() {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('status', JobStatus.open.name)
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

  // ─── Status Transitions ──────────────────────────
  Future<void> acceptJob(String jobId, String haulerUid, String haulerName) async {
    await _client.from('jobs').update({
      'hauler_uid': haulerUid,
      'hauler_name': haulerName,
      'status': JobStatus.assigned.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', jobId);
  }

  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    await _client.from('jobs').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', jobId);
  }

  Future<void> cancelJob(String jobId) async {
    await updateJobStatus(jobId, JobStatus.cancelled);
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
