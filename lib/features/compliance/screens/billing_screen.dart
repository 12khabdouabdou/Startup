import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/billing_repository.dart';
import '../../auth/repositories/auth_repository.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  Map<String, dynamic>? _summary;
  bool _loadingSummary = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.id;
    if (uid == null) return;
    final summary = await ref.read(billingRepositoryProvider).getWeeklySummary(uid);
    if (mounted) setState(() { _summary = summary; _loadingSummary = false; });
  }

  @override
  Widget build(BuildContext context) {
    final billingAsync = ref.watch(userBillingProvider);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    const forestGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Finance & Earnings')),
      body: Column(
        children: [
          // Weekly Summary Cards
          if (_loadingSummary)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: forestGreen)),
            )
          else if (_summary != null)
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [forestGreen, forestGreen.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                   BoxShadow(color: forestGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                   const Text('WEEKLY PERFORMANCE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceAround,
                     children: [
                        _dashboardStat('Earned', currencyFormat.format(_summary!['totalEarned'])),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _dashboardStat('Spent', currencyFormat.format(_summary!['totalSpent'])),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _dashboardStat('Jobs', '${_summary!['jobCount']}'),
                     ],
                   ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Text('RECENT TRANSACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                 TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 12, color: forestGreen))),
              ],
            ),
          ),

          // Billing Records List
          Expanded(
            child: billingAsync.when(
              data: (records) {
                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[200]),
                        const SizedBox(height: 16),
                        Text('No transactions found.', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final isExpense = record.hostUid == ref.read(authRepositoryProvider).currentUser?.id;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isExpense ? Colors.red : forestGreen).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isExpense ? Icons.arrow_outward : Icons.arrow_downward,
                              color: isExpense ? Colors.red : forestGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${record.material} — ${record.quantity.toStringAsFixed(0)} Loads',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(dateFormat.format(record.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isExpense ? "-" : "+"}${currencyFormat.format(record.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isExpense ? Colors.red[700] : forestGreen,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  record.status.toUpperCase(),
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: forestGreen)),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
