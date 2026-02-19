
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
import '../../notifications/widgets/notification_bell.dart';

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
    const forestGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Hauls'),
        actions: const [NotificationBell(), SizedBox(width: 8)],
      ),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
                     child: Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey[300]),
                   ),
                   const SizedBox(height: 24),
                   const Text('No active hauls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Text('Ready to earn? Find a load nearby.', style: TextStyle(color: Colors.grey[600])),
                   const SizedBox(height: 24),
                   ElevatedButton(
                     onPressed: () => context.push('/jobs/board'),
                     style: ElevatedButton.styleFrom(backgroundColor: forestGreen, foregroundColor: Colors.white),
                     child: const Text('Global Job Board'),
                   ),
                 ],
               ),
             );
          }

          final active = jobs.where((j) => j.status != JobStatus.completed && j.status != JobStatus.cancelled).toList();
          final history = jobs.where((j) => j.status == JobStatus.completed || j.status == JobStatus.cancelled).toList();

          return CustomScrollView(
            slivers: [
              if (active.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text('ACTIVE DISPATCH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _JobCard(job: active[index]),
                    childCount: active.length,
                  ),
                ),
              ],
              if (history.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 32, 20, 12),
                    child: Text('RECENT HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _JobCard(job: history[index], isHistory: true),
                    childCount: history.length,
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: forestGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/jobs/board'),
        backgroundColor: forestGreen,
        icon: const Icon(Icons.search, color: Colors.white),
        label: const Text('FIND MORE LOADS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _HostActivityView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const forestGreen = Color(0xFF2E7D32);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Management'), 
          actions: const [NotificationBell(), SizedBox(width: 8)],
          bottom: TabBar(
              tabs: const [
                Tab(text: 'MY LISTINGS'),
                Tab(text: 'ACTIVE JOBS'),
              ],
              labelColor: forestGreen,
              unselectedLabelColor: Colors.grey[400],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
              indicatorColor: forestGreen,
              indicatorWeight: 3,
              dividerColor: Colors.grey[100],
          ),
        ),
        body: const TabBarView(
          children: [
            _HostListingsTab(),
            _HostJobsTab(),
          ],
        ),
      ),
    );
  }
}

class _HostListingsTab extends ConsumerWidget {
  const _HostListingsTab();

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
                Icon(Icons.post_add_outlined, size: 64, color: Colors.grey[200]),
                const SizedBox(height: 16),
                const Text('No active listings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/listings/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Post Material'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: listings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final listing = listings[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListingCard(listing: listing, onTap: () => context.push('/listings/${listing.id}', extra: listing)),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _HostJobsTab extends ConsumerWidget {
  const _HostJobsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myHostJobsProvider);

    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
           return Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[200]),
                 const SizedBox(height: 16),
                 const Text('No active job requests', style: TextStyle(color: Colors.grey)),
               ],
             ),
           );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: jobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _JobCard(job: jobs[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final bool isHistory;

  const _JobCard({required this.job, this.isHistory = false});

  Color get _statusColor {
    switch (job.status) {
      case JobStatus.pending:   return Colors.grey[600]!;
      case JobStatus.accepted:  return const Color(0xFF2E7D32);
      case JobStatus.enRoute:
      case JobStatus.atPickup:  return Colors.orange[800]!;
      case JobStatus.loaded:
      case JobStatus.inTransit: return Colors.blue[700]!;
      case JobStatus.atDropoff: return Colors.deepOrange;
      case JobStatus.completed: return const Color(0xFF2E7D32);
      case JobStatus.cancelled: return Colors.red;
      default: return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (job.status) {
      case JobStatus.pending:   return 'WAITING';
      case JobStatus.accepted:  return 'ASSIGNED';
      case JobStatus.enRoute:   return 'EN ROUTE';
      case JobStatus.atPickup:  return 'AT PICKUP';
      case JobStatus.loaded:    return 'LOADED';
      case JobStatus.inTransit: return 'IN TRANSIT';
      case JobStatus.atDropoff: return 'AT DROP';
      case JobStatus.completed: return 'COMPLETE';
      case JobStatus.cancelled: return 'CANCELLED';
      default: return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = isHistory ? 0.6 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            if (!isHistory) 
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: InkWell(
          onTap: () => context.push('/jobs/${job.id}', extra: job),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    job.status == JobStatus.completed ? Icons.check_circle_outline : Icons.local_shipping_outlined,
                    color: _statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${job.material ?? "Material"} • ${job.quantity?.toStringAsFixed(0) ?? "?"} Loads',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _statusLabel,
                              style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.pickupAddress ?? 'No address',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_money, size: 14, color: Colors.green[700]),
                          Text(
                            '${job.priceOffer?.toStringAsFixed(0) ?? "0"} EARNINGS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[700]),
                          ),
                          const Spacer(),
                          Text(
                            'ID: ${job.id.substring(0, 8).toUpperCase()}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[400], letterSpacing: 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
