import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/job_model.dart';
import '../repositories/job_repository.dart';

class HaulerJobBoardScreen extends ConsumerWidget {
  const HaulerJobBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(availableJobsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Available Jobs')),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No jobs available right now.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Check back soon!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(availableJobsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: jobs.length,
              itemBuilder: (context, index) => _JobCard(
                job: jobs[index],
                onTap: () => context.push('/jobs/${jobs[index].id}', extra: jobs[index]),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;

  const _JobCard({required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('AVAILABLE', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                  const Spacer(),
                  Text(
                    '${job.quantity?.toStringAsFixed(0) ?? '?'} ${job.material ?? 'Material'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (job.pickupAddress != null) ...[
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(child: Text('Pickup: ${job.pickupAddress}', style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
              if (job.dropoffAddress != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.arrow_downward, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Expanded(child: Text('Dropoff: ${job.dropoffAddress}', style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
              if (job.notes != null && job.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(job.notes!, style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
