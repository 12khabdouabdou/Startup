import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';

class JobRepository {
  final FirebaseFirestore _firestore;

  JobRepository(this._firestore);

  // ─── Create ──────────────────────────────────────
  Future<String> createJob(Job job) async {
    final docRef = await _firestore.collection('jobs').add({
      ...job.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // ─── Read ────────────────────────────────────────
  Stream<List<Job>> fetchAvailableJobs() {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Job.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Job>> fetchHaulerJobs(String haulerUid) {
    return _firestore
        .collection('jobs')
        .where('haulerUid', isEqualTo: haulerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Job.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Job>> fetchHostJobs(String hostUid) {
    return _firestore
        .collection('jobs')
        .where('hostUid', isEqualTo: hostUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Job.fromMap(d.data(), d.id)).toList());
  }

  Stream<Job?> watchJob(String jobId) {
    return _firestore.collection('jobs').doc(jobId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Job.fromMap(snap.data()!, snap.id);
    });
  }

  // ─── Status Transitions ──────────────────────────
  Future<void> acceptJob(String jobId, String haulerUid, String haulerName) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'haulerUid': haulerUid,
      'haulerName': haulerName,
      'status': JobStatus.accepted.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelJob(String jobId) async {
    await updateJobStatus(jobId, JobStatus.cancelled);
  }

  // ─── Photo Verification ──────────────────────────
  Future<void> uploadPickupPhoto(String jobId, String photoUrl) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'pickupPhotoUrl': photoUrl,
      'status': JobStatus.loaded.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> uploadDropoffPhoto(String jobId, String photoUrl) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'dropoffPhotoUrl': photoUrl,
      'status': JobStatus.completed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

// ─── Providers ───────────────────────────────────────
final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(FirebaseFirestore.instance);
});

final availableJobsProvider = StreamProvider.autoDispose<List<Job>>((ref) {
  return ref.watch(jobRepositoryProvider).fetchAvailableJobs();
});
