import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/repositories/auth_repository.dart';

/// A billing record for a completed job.
/// Records are created server-side by the `trg_create_billing_on_complete` trigger.
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
      // Fix: Use snake_case to match Supabase column names
      jobId: data['job_id'] as String? ?? '',
      hostUid: data['host_uid'] as String? ?? '',
      haulerUid: data['hauler_uid'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      material: data['material'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['created_at'] is String)
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class BillingRepository {
  final SupabaseClient _client;
  BillingRepository(this._client);

  // NOTE: createRecord() has been intentionally removed.
  // Billing records are now created automatically by the server-side
  // PostgreSQL trigger `trg_create_billing_on_complete` when a job is
  // marked 'completed'. This prevents client-side billing fraud (CRITICAL-2).

  /// Fetch all billing records for a user (as host or hauler)
  Future<List<BillingRecord>> fetchUserBilling(String uid) async {
    // Fix: Use correct snake_case column names in OR filter
    final response = await _client
        .from('billing')
        .select()
        .or('host_uid.eq.$uid,hauler_uid.eq.$uid')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => BillingRecord.fromMap(json, json['id'] as String))
        .toList();
  }

  /// Calculate weekly summary using server-side aggregation via RPC
  /// Falls back to client-side filter if RPC not available
  Future<Map<String, dynamic>> getWeeklySummary(String uid) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final records = await _client
        .from('billing')
        .select()
        .or('host_uid.eq.$uid,hauler_uid.eq.$uid')
        .gte('created_at', weekAgo.toIso8601String());

    double totalSpent = 0;
    double totalEarned = 0;
    int jobCount = 0;

    for (var doc in (records as List)) {
      final amount = (doc['amount'] as num?)?.toDouble() ?? 0;
      if (doc['host_uid'] == uid) {
        totalSpent += amount;
      } else if (doc['hauler_uid'] == uid) {
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

final userBillingProvider = FutureProvider.autoDispose<List<BillingRecord>>((ref) async {
  final uid = ref.watch(authRepositoryProvider).currentUser?.id;
  if (uid == null) return [];
  return ref.watch(billingRepositoryProvider).fetchUserBilling(uid);
});
