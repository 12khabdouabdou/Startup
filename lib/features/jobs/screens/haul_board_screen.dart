import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../repositories/job_repository.dart';
import '../../auth/repositories/auth_repository.dart';

class HaulBoardScreen extends ConsumerWidget {
  const HaulBoardScreen({super.key});

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
                children: const [
                  Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No open jobs available right now.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.location_on, color: Colors.white),
                  ),
                  title: Text(
                    '${job.pickupAddress ?? "Unknown"} \n→ ${job.dropoffAddress ?? "Unknown"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${job.material ?? "Material"} • ${job.quantity ?? 0} m³\n${job.notes ?? ""}',
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        job.priceOffer != null ? '\$${job.priceOffer}' : 'Open',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () => _showJobDetails(context, ref, job),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showJobDetails(BuildContext context, WidgetRef ref, Job job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Haul Job?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(Icons.upload, 'Pickup', job.pickupAddress),
              _infoRow(Icons.download, 'Dropoff', job.dropoffAddress),
              const Divider(),
              _infoRow(Icons.category, 'Material', job.material),
              _infoRow(Icons.scale, 'Quantity', '${job.quantity ?? 0} m³'),
              _infoRow(Icons.attach_money, 'Offer', job.priceOffer != null ? '\$${job.priceOffer}' : 'Negotiable'),
              const SizedBox(height: 8),
              const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(job.notes ?? "None"),
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
                    (user.userMetadata?['company_name'] as String?) ?? 
                    (user.userMetadata?['display_name'] as String?) ?? 
                    'Hauler'
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Accepted! check Activity tab.')));
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

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
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
