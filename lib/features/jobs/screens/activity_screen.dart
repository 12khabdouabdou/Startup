
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../listings/models/listing_model.dart';
import '../../listings/widgets/listing_card.dart';
import '../../listings/repositories/listing_repository.dart';
import '../../jobs/models/job_model.dart';
import '../../jobs/repositories/job_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/models/app_user.dart';

// myListingsProvider is imported from listing_repository.dart

/// Provider: streams the hauler's assigned jobs
final myJobsProvider = StreamProvider.autoDispose<List<Job>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(jobRepositoryProvider).fetchHaulerJobs(user.id);
});

/// Provider: streams the host's jobs
final myHostJobsProvider = StreamProvider.autoDispose<List<Job>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(jobRepositoryProvider).fetchHostJobs(user.id);
});

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDocProvider).valueOrNull;
    if (user?.role == UserRole.hauler) {
       return _HaulerActivityView();
    }
    return _HostActivityView();
  }
}

class _HaulerActivityView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myJobsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Jobs')),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                   const SizedBox(height: 16),
                   const Text('No active jobs.', style: TextStyle(color: Colors.grey)),
                   const SizedBox(height: 12),
                   ElevatedButton(
                     onPressed: () => context.push('/jobs/board'),
                     child: const Text('Find Loads'),
                   ),
                 ],
               ),
             );
          }
          return ListView.builder(
             itemCount: jobs.length,
             itemBuilder: (context, index) {
               final job = jobs[index];
               return _JobTile(job: job, onTap: () => context.push('/jobs/${job.id}', extra: job));
             },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _HostActivityView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'My Listings'),
              Tab(text: 'Active Jobs'),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _HostListingsTab(),
                _HostJobsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HostListingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No listings yet.', style: TextStyle(color: Colors.grey)),
                ElevatedButton(
                  onPressed: () => context.push('/listings/create'),
                  child: const Text('Create Listing'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            return Dismissible(
              key: ValueKey(listing.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: Colors.red,
                child: const Icon(Icons.archive, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                 return await showDialog<bool>(
                   context: context,
                   builder: (c) => AlertDialog(
                     title: const Text('Archive?'),
                     actions: [
                       TextButton(onPressed: () => c.pop(false), child: const Text('Cancel')),
                       TextButton(onPressed: () => c.pop(true), child: const Text('Archive', style: TextStyle(color: Colors.red))),
                     ],
                   ),
                 );
              },
              onDismissed: (_) {
                ref.read(listingRepositoryProvider).archiveListing(listing.id);
              },
              child: ListingCard(listing: listing, onTap: () => context.push('/listings/${listing.id}', extra: listing)),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _HostJobsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myHostJobsProvider);

    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
           return const Center(child: Text('No active jobs.'));
        }
        return ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return _JobTile(job: job, onTap: () => context.push('/jobs/${job.id}'));
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ─── Shared Job Tile Widget ──────────────────────────

class _JobTile extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;

  const _JobTile({required this.job, this.onTap});

  Color get _statusColor {
    switch (job.status) {
      case JobStatus.open:      return Colors.green;
      case JobStatus.pending:   return Colors.grey;
      case JobStatus.assigned:  return Colors.blue;
      case JobStatus.enRoute:
      case JobStatus.atPickup:  return Colors.orange;
      case JobStatus.loaded:
      case JobStatus.inTransit: return Colors.purple;
      case JobStatus.atDropoff: return Colors.deepOrange;
      case JobStatus.completed: return Colors.green;
      case JobStatus.cancelled: return Colors.red;
    }
  }

  String get _statusLabel {
    switch (job.status) {
      case JobStatus.open:      return 'Open';
      case JobStatus.pending:   return 'Pending';
      case JobStatus.assigned:  return 'Assigned';
      case JobStatus.enRoute:   return 'En Route';
      case JobStatus.atPickup:  return 'At Pickup';
      case JobStatus.loaded:    return 'Loaded';
      case JobStatus.inTransit: return 'In Transit';
      case JobStatus.atDropoff: return 'At Dropoff';
      case JobStatus.completed: return 'Completed';
      case JobStatus.cancelled: return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _statusColor.withOpacity(0.15),
          child: Icon(Icons.local_shipping, color: _statusColor, size: 20),
        ),
        title: Text('${job.material ?? "Material"} — ${job.quantity?.toStringAsFixed(0) ?? "?"} units'),
        subtitle: Text(job.pickupAddress ?? 'No address'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
