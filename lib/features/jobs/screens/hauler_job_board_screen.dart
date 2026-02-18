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
      appBar: AppBar(title: const Text('Haul Requests')),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No haul requests available.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }
          return RefreshIndicator(
             onRefresh: () async => ref.invalidate(availableJobsProvider),
             child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _JobRequestTile(job: jobs[index]);
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

class _JobRequestTile extends ConsumerWidget {
  final Job job;
  const _JobRequestTile({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine host info
    final hostAsync = ref.watch(userProfileProvider(job.hostUid));
    final host = hostAsync.value;
    final isVerified = host?.isVerified ?? false;
    final hostName = host?.fullName ?? 'Unknown User';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showJobDetails(context, ref, job, hostName, isVerified),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Host Info + Price
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: host?.companyName != null ? null : null, // Todo: Logo
                    child: Text(hostName[0].toUpperCase(), style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Text(hostName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (isVerified) const VerifiedBadge(size: 14),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      job.priceOffer != null ? '\$${job.priceOffer}' : 'Open Offer',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Route
              Row(
                children: [
                  const Icon(Icons.circle, size: 12, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(job.pickupAddress ?? 'Unknown Pickup', maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(left: 5),
                height: 16,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey[300]!, width: 2)),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 12, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(job.dropoffAddress ?? 'Unknown Dropoff', maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 12),
              // Material Info
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(job.material ?? 'Dirt'),
                  const SizedBox(width: 16),
                  Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${job.quantity?.toStringAsFixed(1) ?? "0"} m³'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobDetails(BuildContext context, WidgetRef ref, Job job, String hostName, bool isVerified) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Haul Job?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Posted by: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(hostName),
                  if (isVerified) const VerifiedBadge(size: 16),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(Icons.upload, 'Pickup', job.pickupAddress),
              _detailRow(Icons.download, 'Dropoff', job.dropoffAddress),
              const Divider(),
              _detailRow(Icons.category, 'Material', job.material),
              _detailRow(Icons.scale, 'Quantity', '${job.quantity ?? 0} m³'),
              _detailRow(Icons.attach_money, 'Offer', job.priceOffer != null ? '\$${job.priceOffer}' : 'Negotiable'),
              const SizedBox(height: 8),
              if (job.notes?.isNotEmpty == true) ...[
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(job.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final user = ref.read(authRepositoryProvider).currentUser;
                if (user != null) {
                  await ref.read(jobRepositoryProvider).acceptJob(
                    job.id, 
                    user.id, 
                    user.companyName ?? user.displayName ?? 'Hauler'
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Accepted!')));
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Accept Job'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value ?? 'N/A'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
