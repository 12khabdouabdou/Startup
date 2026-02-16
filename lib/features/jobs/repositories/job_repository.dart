import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../../auth/repositories/auth_repository.dart';

class JobRepository {
  final SupabaseClient _client;

  JobRepository(this._client);

  // ─── Create ──────────────────────────────────────
  Future<String> createJob(Job job) async {
    final response = await _client.from('jobs').insert({
      ...job.toMap(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }).select().single();
    return response['id'] as String;
  }

  // ─── Read ────────────────────────────────────────
  Stream<List<Job>> fetchAvailableJobs() {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('createdAt', ascending: false)
        .map((data) => data.map((json) => Job.fromMap(json, json['id'] as String)).toList());
  }

  Stream<List<Job>> fetchHaulerJobs(String haulerUid) {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('haulerUid', haulerUid)
        .order('createdAt', ascending: false)
        .map((data) => data.map((json) => Job.fromMap(json, json['id'] as String)).toList());
  }

  Stream<List<Job>> fetchHostJobs(String hostUid) {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('hostUid', hostUid)
        .order('createdAt', ascending: false)
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
      'haulerUid': haulerUid,
      'haulerName': haulerName,
      'status': JobStatus.accepted.name,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', jobId);
  }

  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    await _client.from('jobs').update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', jobId);
  }

  Future<void> cancelJob(String jobId) async {
    await updateJobStatus(jobId, JobStatus.cancelled);
  }

  // ─── Photo Verification ──────────────────────────
  Future<void> uploadPickupPhoto(String jobId, String photoUrl) async {
    await _client.from('jobs').update({
      'pickupPhotoUrl': photoUrl,
      'status': JobStatus.loaded.name,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', jobId);
  }

  Future<void> uploadDropoffPhoto(String jobId, String photoUrl) async {
    await _client.from('jobs').update({
      'dropoffPhotoUrl': photoUrl,
      'status': JobStatus.completed.name,
      'updatedAt': DateTime.now().toIso8601String(),
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
