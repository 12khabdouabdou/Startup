import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/job_model.dart';
import '../repositories/job_repository.dart';
import '../../listings/repositories/listing_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../profile/providers/profile_provider.dart';
import '../../messaging/repositories/chat_repository.dart';
import '../../../core/models/app_user.dart';
import '../../maps/widgets/job_route_map.dart';
import 'package:url_launcher/url_launcher.dart'; // Added for external nav

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  final Job? initialJob;

  const JobDetailScreen({super.key, required this.jobId, this.initialJob});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _isLoading = false;

  Future<void> _acceptJob(Job job) async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser!;
      final profile = ref.read(userDocProvider).valueOrNull;
      await ref.read(jobRepositoryProvider).acceptJob(
        job.id,
        user.id,
        profile?.displayName ?? 'Hauler',
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Accepted!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelJob(Job job) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this job request?'),
        actions: [
          TextButton(onPressed: () => c.pop(false), child: const Text('No')),
          TextButton(onPressed: () => c.pop(true), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(jobRepositoryProvider).cancelJob(job.id);
      await ref.read(listingRepositoryProvider).updateListing(job.listingId, {'status': 'active'});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Cancelled')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _advanceStatus(Job job, JobStatus nextStatus) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(jobRepositoryProvider).updateJobStatus(job.id, nextStatus);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _takePhoto(Job job, {required bool isPickup}) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() => _isLoading = true);
    try {
      final storage = ref.read(storageServiceProvider);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final label = isPickup ? 'pickup' : 'dropoff';
      final remotePath = 'jobs/${job.id}/${timestamp}_$label.jpg';

      final url = await storage.uploadFile(localPath: photo.path, remotePath: remotePath);
      if (url == null) throw Exception('Upload failed');

      final repo = ref.read(jobRepositoryProvider);
      if (isPickup) {
        await repo.uploadPickupPhoto(job.id, url);
      } else {
        await repo.uploadDropoffPhoto(job.id, url);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _contactUser(String otherUid, String? listingId) async {
    final currentUid = ref.read(authRepositoryProvider).currentUser?.id;
    if (currentUid == null) return;

    setState(() => _isLoading = true);
    try {
      final chatId = await ref.read(chatRepositoryProvider).getOrCreateChat(
        currentUid: currentUid,
        otherUid: otherUid,
        listingId: listingId,
      );
      if (mounted) {
        context.push('/chat/$chatId');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobStream = ref.watch(_jobStreamProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: jobStream.when(
        data: (job) {
          if (job == null) {
            return const Center(child: Text('Job not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusBanner(status: job.status),
                const SizedBox(height: 24),

                if (job.pickupLocation != null && job.dropoffLocation != null) ...[
                   JobRouteMap(pickup: job.pickupLocation!, dropoff: job.dropoffLocation!),
                   const SizedBox(height: 24),
                ],

                _InfoSection(title: 'Material', value: '${job.material ?? "N/A"} — ${job.quantity?.toStringAsFixed(0) ?? "?"} units'),
                const SizedBox(height: 12),
                if (job.pickupAddress != null)
                  _InfoSection(title: 'Pickup', value: job.pickupAddress!, icon: Icons.arrow_upward, iconColor: Colors.green),
                if (job.dropoffAddress != null) ...[
                  const SizedBox(height: 12),
                  _InfoSection(title: 'Dropoff', value: job.dropoffAddress!, icon: Icons.arrow_downward, iconColor: Colors.red),
                ],
                if (job.haulerName != null) ...[
                  const SizedBox(height: 12),
                  _InfoSection(title: 'Hauler', value: job.haulerName!),
                ],
                if (job.priceOffer != null) ...[
                   const SizedBox(height: 12),
                   _InfoSection(title: 'Offer', value: '\$${job.priceOffer!.toStringAsFixed(2)}', icon: Icons.attach_money, iconColor: Colors.amber),
                ],
                if (job.notes != null && job.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoSection(title: 'Notes', value: job.notes!),
                ],

                const SizedBox(height: 24),

                if (job.pickupPhotoUrl != null) ...[
                  const Text('Pickup Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(job.pickupPhotoUrl!, height: 150, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 150, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (job.dropoffPhotoUrl != null) ...[
                  const Text('Dropoff Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(job.dropoffPhotoUrl!, height: 150, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 150, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Divider(),
                const SizedBox(height: 16),

                _buildActions(job),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _launchExternalNavigation(double lat, double lng) async {
    await showModalBottomSheet(
      context: context, 
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Navigate with', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('Google Maps'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'), mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.blueAccent),
              title: const Text('Waze'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes'), mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(Job job) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentUser = ref.watch(userDocProvider).valueOrNull;
    if (currentUser == null) return const SizedBox();

    final isHost = currentUser.uid == job.hostUid;
    final isAssignedHauler = currentUser.uid == job.haulerUid;
    final isHaulerRole = currentUser.role == UserRole.hauler; // Potential hauler

    if (isHost) {
       if (job.status != JobStatus.completed && job.status != JobStatus.cancelled && job.haulerUid != null) {
          return Column(
            children: [
               SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _contactUser(job.haulerUid!, job.listingId),
                  icon: const Icon(Icons.chat),
                  label: const Text('Message Hauler'),
                ),
              ),
              const SizedBox(height: 10),
              if (job.status == JobStatus.open || job.status == JobStatus.pending)
                OutlinedButton.icon(
                  onPressed: () => _cancelJob(job),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Job Request'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          );
       }
       return const SizedBox();
    }

    if (isAssignedHauler) {
       Widget actionButton = const SizedBox();
       switch (job.status) {
        case JobStatus.assigned:
          actionButton = ElevatedButton.icon(
            onPressed: () => _advanceStatus(job, JobStatus.enRoute),
            icon: const Icon(Icons.navigation),
            label: const Text('Start Navigation'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          );
          break;
        case JobStatus.enRoute:
          actionButton = ElevatedButton.icon(
            onPressed: () => _advanceStatus(job, JobStatus.atPickup),
            icon: const Icon(Icons.location_on),
            label: const Text('Arrived at Pickup'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          );
          break;
        case JobStatus.atPickup:
          actionButton = ElevatedButton.icon(
            onPressed: () => _takePhoto(job, isPickup: true),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Pickup Photo'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          );
          break;
        case JobStatus.loaded:
          actionButton = ElevatedButton.icon(
             onPressed: () => _advanceStatus(job, JobStatus.inTransit),
             icon: const Icon(Icons.local_shipping),
             label: const Text('Depart to Dropoff'),
             style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          );
          break;
        case JobStatus.inTransit:
          actionButton = ElevatedButton.icon(
             onPressed: () => _advanceStatus(job, JobStatus.atDropoff),
             icon: const Icon(Icons.flag),
             label: const Text('Arrived at Dropoff'),
             style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          );
          break;
        case JobStatus.atDropoff:
          actionButton = ElevatedButton.icon(
            onPressed: () => _takePhoto(job, isPickup: false),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Dropoff Photo'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          );
          break;
        case JobStatus.completed:
           return Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 8),
                const Text('Job Completed!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/jobs/${job.id}/manifest', extra: {
                      'job': job,
                      'hostName': 'Host', 
                      'haulerName': 'You',
                    }),
                    icon: const Icon(Icons.description),
                    label: const Text('View Manifest'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
           );
        default:
          break;
       }

       return Column(
         children: [
            if ((job.status == JobStatus.assigned || job.status == JobStatus.enRoute) && job.pickupLocation != null) ...[
               SizedBox(
                 width: double.infinity,
                 child: OutlinedButton.icon(
                   onPressed: () => _launchExternalNavigation(job.pickupLocation!.latitude, job.pickupLocation!.longitude),
                   icon: const Icon(Icons.map_outlined),
                   label: const Text('Navigate to Pickup (Maps/Waze)'),
                 ),
               ),
               const SizedBox(height: 12),
            ] else if ((job.status == JobStatus.loaded || job.status == JobStatus.inTransit) && job.dropoffLocation != null) ...[
               SizedBox(
                 width: double.infinity,
                 child: OutlinedButton.icon(
                   onPressed: () => _launchExternalNavigation(job.dropoffLocation!.latitude, job.dropoffLocation!.longitude),
                   icon: const Icon(Icons.map_outlined),
                   label: const Text('Navigate to Dropoff (Maps/Waze)'),
                 ),
               ),
               const SizedBox(height: 12),
            ],
           SizedBox(width: double.infinity, child: actionButton),
           
           if (job.status == JobStatus.assigned || job.status == JobStatus.enRoute) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                   onPressed: () => _cancelJob(job),
                   icon: const Icon(Icons.cancel_outlined),
                   label: const Text('Cancel / Unassign'),
                   style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
           ],

           if (job.status != JobStatus.completed && job.status != JobStatus.cancelled) ...[
             const SizedBox(height: 12),
             SizedBox(
               width: double.infinity,
               child: OutlinedButton.icon(
                 onPressed: () => _contactUser(job.hostUid, job.listingId),
                 icon: const Icon(Icons.chat_bubble_outline),
                 label: const Text('Message Host'),
               ),
             ),
           ],
         ],
       );
    }

    // New: If Open Job and User is Hauler (and not already assigned)
    if (isHaulerRole && (job.status == JobStatus.open || job.status == JobStatus.pending) && job.haulerUid == null) {
      return SizedBox(
        width: double.infinity,
         child: ElevatedButton.icon(
            onPressed: () => _acceptJob(job),
            icon: const Icon(Icons.check_circle),
            label: const Text('Accept This Job'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
      );
    }
    
    return const SizedBox();
  }
}

final _jobStreamProvider = StreamProvider.autoDispose.family<Job?, String>((ref, jobId) {
  return ref.watch(jobRepositoryProvider).watchJob(jobId);
});

class _StatusBanner extends StatelessWidget {
  final JobStatus status;
  const _StatusBanner({required this.status});

  Color get _color {
    switch (status) {
      case JobStatus.open:      return Colors.green;
      case JobStatus.pending:   return Colors.grey;
      case JobStatus.assigned:  return Colors.blue;
      case JobStatus.enRoute:   return Colors.indigo;
      case JobStatus.atPickup:  return Colors.orange;
      case JobStatus.loaded:    return Colors.amber;
      case JobStatus.inTransit: return Colors.purple;
      case JobStatus.atDropoff: return Colors.deepOrange;
      case JobStatus.completed: return Colors.green;
      case JobStatus.cancelled: return Colors.red;
    }
  }

  String get _label {
    switch (status) {
      case JobStatus.open:      return 'Open for Hauler';
      case JobStatus.pending:   return 'Pending';
      case JobStatus.assigned:  return 'Hauler Assigned';
      case JobStatus.enRoute:   return 'En Route to Pickup';
      case JobStatus.atPickup:  return 'At Pickup Site';
      case JobStatus.loaded:    return 'Material Loaded';
      case JobStatus.inTransit: return 'In Transit to Dropoff';
      case JobStatus.atDropoff: return 'At Dropoff Site';
      case JobStatus.completed: return 'Job Completed';
      case JobStatus.cancelled: return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: _color),
          const SizedBox(width: 10),
          Text(_label, style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  const _InfoSection({required this.title, required this.value, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: iconColor ?? Colors.grey[600]),
          const SizedBox(width: 8),
        ],
        SizedBox(width: 80, child: Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
      ],
    );
  }
}
