
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../listings/models/listing_model.dart';
import '../../listings/widgets/listing_card.dart';
import '../../jobs/models/job_model.dart';
import '../../jobs/repositories/job_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/models/app_user.dart';

/// Provider: streams the current user's own listings
final myListingsProvider = StreamProvider.autoDispose<List<Listing>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value([]);

  return ref.watch(listingRepositoryProvider).fetchUserListings(user.id);
});

/// Provider: streams the hauler's assigned jobs
final myJobsProvider = StreamProvider.autoDispose<List<Job>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(jobRepositoryProvider).fetchHaulerJobs(user.id);
});

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDoc = ref.watch(userDocProvider).valueOrNull;

    if (userDoc == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Haulers see their jobs, others see their listings
    if (userDoc.role == UserRole.hauler) {
      return _HaulerActivityView();
    }
    return _HostActivityView();
  }
}

// ─── Hauler View: My Jobs ────────────────────────────

class _HaulerActivityView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myJobsProvider);

    return Column(
      children: [
        // Quick action bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/jobs/board'),
              icon: const Icon(Icons.search),
              label: const Text('Browse Available Jobs'),
            ),
          ),
        ),

        Expanded(
          child: jobsAsync.when(
            data: (jobs) {
              if (jobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No active jobs.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/jobs/board'),
                        icon: const Icon(Icons.search),
                        label: const Text('Find Jobs'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return _JobTile(job: job, onTap: () => context.push('/jobs/${job.id}', extra: job));
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}

// ─── Host View: My Listings ──────────────────────────

class _HostActivityView extends ConsumerWidget {
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
                Text('You haven\'t posted any listings yet.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/listings/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Listing'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
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
                  builder: (ctx) => AlertDialog(
                    title: const Text('Archive Listing?'),
                    content: const Text('This listing will be hidden from the feed.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Archive', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
              onDismissed: (_) {
                // Use Repository to archive
                ref.read(listingRepositoryProvider).archiveListing(listing.id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing archived')));
              },
              child: ListingCard(listing: listing, onTap: () {}),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
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
      case JobStatus.pending:   return Colors.grey;
      case JobStatus.accepted:  return Colors.blue;
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
      case JobStatus.pending:   return 'Pending';
      case JobStatus.accepted:  return 'Accepted';
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
