import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/repositories/auth_repository.dart';

/// A billing record for a completed job
class BillingRecord {
  final String id;
  final String jobId;
  final String hostUid;
  final String haulerUid;
  final double amount;
  final String currency;
  final String material;
  final double quantity;
  final String status; // pending, paid, disputed
  final DateTime createdAt;

  const BillingRecord({
    required this.id,
    required this.jobId,
    required this.hostUid,
    required this.haulerUid,
    required this.amount,
    this.currency = 'USD',
    required this.material,
    required this.quantity,
    this.status = 'pending',
    required this.createdAt,
  });

  factory BillingRecord.fromMap(Map<String, dynamic> data, String id) {
    return BillingRecord(
      id: id,
      jobId: data['jobId'] as String? ?? '',
      hostUid: data['hostUid'] as String? ?? '',
      haulerUid: data['haulerUid'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      material: data['material'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'jobId': jobId,
    'hostUid': hostUid,
    'haulerUid': haulerUid,
    'amount': amount,
    'currency': currency,
    'material': material,
    'quantity': quantity,
    'status': status,
    'createdAt': createdAt,
  };
}

class BillingRepository {
  final FirebaseFirestore _firestore;
  BillingRepository(this._firestore);

  Future<String> createRecord(BillingRecord record) async {
    final ref = await _firestore.collection('billing').add({
      ...record.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Fetch all billing records for a user (as host or hauler)
  Stream<List<BillingRecord>> fetchUserBilling(String uid) {
    // We query both hostUid and haulerUid matches
    // Firestore doesn't support OR queries in a single query,
    // so we'll merge two streams
    final hostStream = _firestore
        .collection('billing')
        .where('hostUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => BillingRecord.fromMap(d.data(), d.id)).toList());

    final haulerStream = _firestore
        .collection('billing')
        .where('haulerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => BillingRecord.fromMap(d.data(), d.id)).toList());

    // Merge both streams
    return hostStream.asyncExpand((hostRecords) {
      return haulerStream.map((haulerRecords) {
        final allRecords = <BillingRecord>{...hostRecords, ...haulerRecords};
        final sorted = allRecords.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sorted;
      });
    });
  }

  /// Calculate weekly summary
  Future<Map<String, dynamic>> getWeeklySummary(String uid) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final hostSnap = await _firestore
        .collection('billing')
        .where('hostUid', isEqualTo: uid)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
        .get();

    final haulerSnap = await _firestore
        .collection('billing')
        .where('haulerUid', isEqualTo: uid)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
        .get();

    double totalSpent = 0;
    double totalEarned = 0;
    int jobCount = 0;

    for (var doc in hostSnap.docs) {
      totalSpent += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      jobCount++;
    }
    for (var doc in haulerSnap.docs) {
      totalEarned += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      jobCount++;
    }

    return {
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'jobCount': jobCount,
      'weekStart': weekAgo,
      'weekEnd': now,
    };
  }
}

// ─── Providers ───────────────────────────────────────

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(FirebaseFirestore.instance);
});

final userBillingProvider = StreamProvider.autoDispose<List<BillingRecord>>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(billingRepositoryProvider).fetchUserBilling(uid);
});
