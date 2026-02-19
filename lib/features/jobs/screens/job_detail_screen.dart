import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_model.dart';
import '../repositories/job_repository.dart';
import '../../listings/repositories/listing_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../profile/providers/profile_provider.dart';
import '../../messaging/repositories/chat_repository.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/geo_point.dart';
import '../../maps/widgets/job_route_map.dart';

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
      await ref.read(jobRepositoryProvider).acceptJob(job.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Job Accepted!')));
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
        title: const Text('Cancel Job?'),
        content: const Text('Are you sure you want to cancel or unassign this job?'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Cancelled')));
        context.pop();
      }
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
    final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 80);
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
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Job Progress')),
      body: jobStream.when(
        data: (job) {
          if (job == null) {
            return const Center(child: Text('Job not found'));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusBanner(status: job.status),
                
                if (job.pickupLocation != null && job.dropoffLocation != null)
                   SizedBox(
                     height: 200,
                     child: JobRouteMap(pickup: job.pickupLocation!, dropoff: job.dropoffLocation!),
                   ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                             _infoTile(Icons.category_outlined, 'Material', job.material ?? 'Fill Dirt'),
                             const Divider(height: 24),
                             _infoTile(Icons.scale_outlined, 'Quantity', '${job.quantity?.toStringAsFixed(0) ?? "?"} Loads'),
                             const Divider(height: 24),
                             _infoTile(Icons.attach_money, 'Earnings', '\$${job.priceOffer?.toStringAsFixed(0) ?? "0"}', valueColor: const Color(0xFF2E7D32)),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      const Text('Locations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _locationStep(Icons.circle, 'PICKUP', job.pickupAddress ?? 'N/A', Colors.blue),
                      _locationConnector(),
                      _locationStep(Icons.location_on, 'DROP-OFF', job.dropoffAddress ?? 'N/A', Colors.red),

                      const SizedBox(height: 32),

                      if (job.status == JobStatus.completed) ...[
                        const Text('Verification Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (job.pickupPhotoUrl != null) 
                               Expanded(child: _photoPreview('Pickup', job.pickupPhotoUrl!)),
                            if (job.pickupPhotoUrl != null && job.dropoffPhotoUrl != null) const SizedBox(width: 12),
                            if (job.dropoffPhotoUrl != null) 
                               Expanded(child: _photoPreview('Drop-off', job.dropoffPhotoUrl!)),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],

                      if (_isLoading) 
                        const Center(child: CircularProgressIndicator())
                      else
                        _buildActions(job),
                        
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[600])),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: valueColor)),
      ],
    );
  }

  Widget _locationStep(IconData icon, String label, String address, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500])),
              Text(address, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _locationConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 7),
      height: 24,
      width: 2,
      color: Colors.grey[200],
    );
  }

  Widget _photoPreview(String label, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, height: 120, width: double.infinity, fit: BoxFit.cover),
        ),
      ],
    );
  }

  Future<void> _launchExternalNavigation(double lat, double lng) async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    final wazeUrl = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');

    await showModalBottomSheet(
      context: context, 
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choose Navigation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('Google Maps'),
              onTap: () { Navigator.pop(context); launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication); },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.blueAccent),
              title: const Text('Waze'),
              onTap: () { Navigator.pop(context); launchUrl(wazeUrl, mode: LaunchMode.externalApplication); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(Job job) {
    final currentUser = ref.watch(userDocProvider).valueOrNull;
    if (currentUser == null) return const SizedBox();

    final isHost = currentUser.uid == job.hostUid;
    final isHauler = currentUser.uid == job.haulerUid;

    if (isHost) {
       return Column(
         children: [
           SizedBox(
             width: double.infinity,
             height: 56,
             child: OutlinedButton.icon(
               onPressed: () => _contactUser(job.haulerUid ?? '', job.listingId),
               icon: const Icon(Icons.chat_bubble_outline),
               label: const Text('Message Hauler'),
               style: OutlinedButton.styleFrom(
                 foregroundColor: const Color(0xFF2E7D32),
                 side: const BorderSide(color: Color(0xFF2E7D32)),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               ),
             ),
           ),
           if (job.status == JobStatus.pending || job.status == JobStatus.accepted) ...[
             const SizedBox(height: 12),
             SizedBox(
               width: double.infinity,
               child: TextButton.icon(
                 onPressed: () => _cancelJob(job),
                 icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                 label: const Text('Cancel Job', style: TextStyle(color: Colors.red)),
               ),
             ),
           ],
         ],
       );
    }

    if (isHauler) {
       Widget action;
       switch (job.status) {
         case JobStatus.accepted:
           action = _actionButton('Start Driving to Pickup', Icons.navigation, () => _advanceStatus(job, JobStatus.enRoute));
           break;
         case JobStatus.enRoute:
           action = _actionButton('Arrived at Pickup', Icons.location_on, () => _advanceStatus(job, JobStatus.atPickup));
           break;
         case JobStatus.atPickup:
           action = _actionButton('Material Loaded (Take Photo)', Icons.camera_alt, () => _takePhoto(job, isPickup: true), color: Colors.orange);
           break;
         case JobStatus.loaded:
           action = _actionButton('Depart to Drop-off', Icons.local_shipping, () => _advanceStatus(job, JobStatus.inTransit));
           break;
         case JobStatus.inTransit:
           action = _actionButton('Arrived at Drop-off', Icons.flag, () => _advanceStatus(job, JobStatus.atDropoff));
           break;
         case JobStatus.atDropoff:
           action = _actionButton('Job Complete (Take Photo)', Icons.camera_alt, () => _takePhoto(job, isPickup: false), color: Colors.orange);
           break;
         default:
           return const SizedBox();
       }

       return Column(
         children: [
           action,
           const SizedBox(height: 12),
           if (job.status == JobStatus.enRoute && job.pickupLocation != null)
             _navButton('Open Maps to Pickup', job.pickupLocation!),
           if (job.status == JobStatus.inTransit && job.dropoffLocation != null)
             _navButton('Open Maps to Drop-off', job.dropoffLocation!),
           const SizedBox(height: 12),
           OutlinedButton.icon(
             onPressed: () => _cancelJob(job),
             icon: const Icon(Icons.cancel_outlined),
             label: const Text('Unassign Me'),
             style: OutlinedButton.styleFrom(
               foregroundColor: Colors.red,
               side: const BorderSide(color: Colors.red),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
             ),
           ),
         ],
       );
    }

    return const SizedBox();
  }

  Widget _actionButton(String title, IconData icon, VoidCallback onPressed, {Color? color}) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _navButton(String title, GeoPoint loc) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () => _launchExternalNavigation(loc.latitude, loc.longitude),
        icon: const Icon(Icons.map_outlined),
        label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue[700],
          side: BorderSide(color: Colors.blue[700]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

final _jobStreamProvider = StreamProvider.autoDispose.family<Job?, String>((ref, jobId) {
  return ref.watch(jobRepositoryProvider).watchJob(jobId);
});

class _StatusBanner extends StatelessWidget {
  final JobStatus status;
  const _StatusBanner({required this.status});

  String get _label {
    switch (status) {
      case JobStatus.pending:   return 'WAITING FOR HAULER';
      case JobStatus.accepted:  return 'TRUCK ASSIGNED';
      case JobStatus.enRoute:   return 'EN ROUTE TO PICKUP';
      case JobStatus.atPickup:  return 'AT PICKUP SITE';
      case JobStatus.loaded:    return 'LOADED & DEPARTING';
      case JobStatus.inTransit: return 'IN TRANSIT TO DROP';
      case JobStatus.atDropoff: return 'AT DROP-OFF SITE';
      case JobStatus.completed: return 'HAUL COMPLETE';
      case JobStatus.cancelled: return 'CANCELLED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == JobStatus.completed;
    final color = isCompleted ? const Color(0xFF2E7D32) : Colors.orange[800]!;

    return Container(
      color: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Icon(isCompleted ? Icons.check_circle : Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 12),
          Text(_label, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        ],
      ),
    );
  }
}
