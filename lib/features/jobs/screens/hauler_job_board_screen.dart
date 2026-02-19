import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../repositories/job_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/widgets/verified_badge.dart';

class HaulerJobBoardScreen extends ConsumerWidget {
  const HaulerJobBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(availableJobsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Available Gigs')),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 24),
                  const Text('No gigs nearby.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('We\'ll alert you when something pops up! 📢', 
                    style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return RefreshIndicator(
             onRefresh: () async => ref.invalidate(availableJobsProvider),
             child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _GigCard(job: jobs[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _GigCard extends ConsumerWidget {
  final Job job;
  const _GigCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = ref.watch(userProfileProvider(job.hostUid)).valueOrNull;
    final isNew = DateTime.now().difference(job.createdAt).inHours < 1;

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        job.material?.toUpperCase() ?? 'DIRT',
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    if (isNew)
                      const Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.amber, size: 16),
                          Text('URGENT', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PAYMENT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(
                            job.priceOffer != null ? '\$${job.priceOffer!.toStringAsFixed(0)}' : 'TBD',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('QUANTITY', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text('${job.quantity?.toStringAsFixed(0) ?? "0"} Loads', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                _locationRow(Icons.upload, 'Pickup', job.pickupAddress ?? 'N/A', Colors.blue),
                const SizedBox(height: 8),
                _locationRow(Icons.download, 'Drop-off', job.dropoffAddress ?? 'N/A', Colors.red),
              ],
            ),
          ),
          
          // Large Action Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => _confirmAcceptance(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                elevation: 0,
              ),
              child: const Text('Accept Gig ✓', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _confirmAcceptance(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept this gig?'),
        content: const Text('Once accepted, this job will be assigned to you.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(jobRepositoryProvider).acceptJob(job.id);
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('✅ Gig accepted! Navigate to pickup?')),
                   );
                   // Navigate to active job view
                   // context.push('/jobs/${job.id}');
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('❌ Gig already taken or error: $e')),
                   );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}
