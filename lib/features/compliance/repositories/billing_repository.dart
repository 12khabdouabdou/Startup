import 'package:supabase_flutter/supabase_flutter.dart';
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
      createdAt: (data['createdAt'] is String)
          ? DateTime.parse(data['createdAt'] as String)
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
    'createdAt': createdAt.toIso8601String(),
  };
}

class BillingRepository {
  final SupabaseClient _client;
  BillingRepository(this._client);

  Future<String> createRecord(BillingRecord record) async {
    final response = await _client.from('billing').insert({
      ...record.toMap(),
      'createdAt': DateTime.now().toIso8601String(),
    }).select().single();
    return response['id'] as String;
  }

  /// Fetch all billing records for a user (as host or hauler)
  Stream<List<BillingRecord>> fetchUserBilling(String uid) {
    // Supabase OR query for hostUid OR haulerUid
    return _client
        .from('billing')
        .stream(primaryKey: ['id'])
        .or('hostUid.eq.$uid,haulerUid.eq.$uid')
        .order('createdAt', ascending: false)
        .map((data) => data.map((json) => BillingRecord.fromMap(json, json['id'] as String)).toList());
  }

  /// Calculate weekly summary
  Future<Map<String, dynamic>> getWeeklySummary(String uid) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekAgoIso = weekAgo.toIso8601String();

    // Fetch records for calculations (client-side aggregation)
    // Could be optimized with SQL functions later
    final records = await _client
        .from('billing')
        .select()
        .or('hostUid.eq.$uid,haulerUid.eq.$uid')
        .gt('createdAt', weekAgoIso);

    double totalSpent = 0;
    double totalEarned = 0;
    int jobCount = 0;

    for (var doc in (records as List)) {
      final amount = (doc['amount'] as num?)?.toDouble() ?? 0;
      if (doc['hostUid'] == uid) {
        totalSpent += amount;
      } else if (doc['haulerUid'] == uid) {
        totalEarned += amount;
      }
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
  return BillingRepository(Supabase.instance.client);
});

final userBillingProvider = StreamProvider.autoDispose<List<BillingRecord>>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(billingRepositoryProvider).fetchUserBilling(uid);
});
