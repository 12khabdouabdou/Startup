import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../listings/models/listing_model.dart';
import '../../listings/repositories/listing_repository.dart';
import '../../jobs/models/job_model.dart';
import '../../jobs/repositories/job_repository.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../core/models/app_user.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = const LatLng(37.7749, -122.4194);
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _hasLocation = true;
      });
      _mapController.move(_currentCenter, 12.0);
    }
  }
  
  void _recenter() {
    if (_hasLocation) {
      _mapController.move(_currentCenter, 13.0);
    } else {
      _determinePosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDocProvider);
    final activeJobAsync = ref.watch(myActiveJobProvider);

    return Scaffold(
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));
          final isHauler = user.role == UserRole.hauler; // Or check capabilities

          return activeJobAsync.when(
            data: (activeJob) {
              // 1. If Active Job exists -> Show Navigation Mode
              if (activeJob != null) {
                return _ActiveJobMap(
                  job: activeJob,
                  mapController: _mapController,
                  currentLocation: _hasLocation ? _currentCenter : null,
                  onRecenter: _recenter,
                );
              }

              // 2. If Hauler -> Show Job Browser
              if (isHauler) {
                return _JobBrowserMap(
                  mapController: _mapController,
                  currentLocation: _hasLocation ? _currentCenter : null,
                  onRecenter: _recenter,
                );
              }

              // 3. Otherwise -> Show Listing Browser
              return _ListingBrowserMap(
                mapController: _mapController,
                currentLocation: _hasLocation ? _currentCenter : null,
                onRecenter: _recenter,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading jobs: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading profile: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

// ─── ACTIVE JOB MAP (Navigation Mode) ─────────────────────────────
class _ActiveJobMap extends ConsumerWidget {
  final Job job;
  final MapController mapController;
  final LatLng? currentLocation;
  final VoidCallback onRecenter;

  const _ActiveJobMap({
    required this.job,
    required this.mapController,
    required this.currentLocation,
    required this.onRecenter,
  });

  Future<void> _launchExternalNav(BuildContext context) async {
    double? lat, lng;
    String label = '';
    
    if (job.status == JobStatus.assigned || job.status == JobStatus.enRoute) {
       lat = job.pickupLocation?.latitude;
       lng = job.pickupLocation?.longitude;
       label = 'Pickup';
    } else {
       lat = job.dropoffLocation?.latitude;
       lng = job.dropoffLocation?.longitude;
       label = 'Dropoff';
    }

    if (lat == null || lng == null) return;

     showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Navigate to $label', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show route if we have both points? No, show markers regardless.
    final pickup = job.pickupLocation != null ? LatLng(job.pickupLocation!.latitude, job.pickupLocation!.longitude) : null;
    final dropoff = job.dropoffLocation != null ? LatLng(job.dropoffLocation!.latitude, job.dropoffLocation!.longitude) : null;
    
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: pickup ?? dropoff ?? currentLocation ?? const LatLng(0,0),
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fillexchange.app',
            ),
            if (pickup != null && dropoff != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [pickup, dropoff],
                    strokeWidth: 4.0,
                    color: Colors.blue.withOpacity(0.7),
                    pattern: const StrokePattern.dotted(),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (currentLocation != null)
                  Marker(point: currentLocation!, child: const Icon(Icons.airport_shuttle, color: Colors.blue, size: 30)),
                if (pickup != null)
                  Marker(point: pickup, child: const Icon(Icons.location_on, color: Colors.green, size: 40)),
                if (dropoff != null)
                  Marker(point: dropoff, child: const Icon(Icons.location_on, color: Colors.red, size: 40)),
              ],
            ),
             RichAttributionWidget(
                attributions: [TextSourceAttribution('OpenStreetMap contributors', onTap: () {})],
             ),
          ],
        ),
        
        // Navigation Overlay
        Positioned(
          bottom: 20,
          left: 20,
          right: 20, // Center buttons?
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                child: ListTile(
                  leading: Icon(Icons.info, color: Colors.blue[800]),
                  title: Text('Active Job: ${job.material}'),
                  subtitle: Text(job.status.name.toUpperCase()),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => context.push('/jobs/${job.id}'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _launchExternalNav(context),
                icon: const Icon(Icons.navigation),
                label: const Text('Start Navigation'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── JOB BROWSER MAP (Hauler Idle) ────────────────────────────────
class _JobBrowserMap extends ConsumerWidget {
  final MapController mapController;
  final LatLng? currentLocation;
  final VoidCallback onRecenter;

  const _JobBrowserMap({required this.mapController, required this.currentLocation, required this.onRecenter});

  void _showJobPreview(BuildContext context, WidgetRef ref, Job job) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${job.material}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${job.quantity} units • \$${job.priceOffer?.toStringAsFixed(2) ?? "?"} offer'),
            const SizedBox(height: 16),
             if (job.pickupAddress != null)
               Row(children: [const Icon(Icons.arrow_upward, size: 16, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text(job.pickupAddress!))]),
             const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                   Navigator.pop(ctx);
                   // Accept Job Logic
                   try {
                     final user = ref.read(authRepositoryProvider).currentUser!;
                     final profile = ref.read(userDocProvider).valueOrNull;
                     await ref.read(jobRepositoryProvider).acceptJob(job.id, user.id, profile?.displayName ?? 'Hauler');
                     if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Accepted!')));
                     // Map will auto-update because activeJobProvider streams update
                   } catch (e) {
                     if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                   }
                },
                child: const Text('Accept Job'),
              ),
            ),
            TextButton(
              onPressed: () { 
                Navigator.pop(ctx); 
                context.push('/jobs/${job.id}'); 
              },
              child: const Center(child: Text('View Details')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(availableJobsProvider);

    return jobsAsync.when(
      data: (jobs) {
        final locatedJobs = jobs.where((j) => j.pickupLocation != null).toList();
        
        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentLocation ?? const LatLng(0,0),
            initialZoom: 10.0,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fillexchange.app',
            ),
            MarkerLayer(
              markers: [
                if (currentLocation != null)
                  Marker(point: currentLocation!, child: const Icon(Icons.my_location, color: Colors.blue, size: 30)),
                ...locatedJobs.map((job) {
                  return Marker(
                    point: LatLng(job.pickupLocation!.latitude, job.pickupLocation!.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showJobPreview(context, ref, job),
                      child: const Icon(Icons.local_shipping, color: Colors.orange, size: 40),
                    ),
                  );
                }),
              ],
            ),
            RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors', onTap: () {})]),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ─── LISTING BROWSER MAP (Developer/Default) ─────────────────────
class _ListingBrowserMap extends ConsumerWidget {
  final MapController mapController;
  final LatLng? currentLocation;
  final VoidCallback onRecenter;

  const _ListingBrowserMap({required this.mapController, required this.currentLocation, required this.onRecenter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(activeListingsProvider);

    return listingsAsync.when(
      data: (listings) {
        final located = listings.where((l) => l.location != null).toList();
        
        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentLocation ?? const LatLng(0,0),
            initialZoom: 10.0,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fillexchange.app',
            ),
            MarkerLayer(
              markers: [
                 if (currentLocation != null)
                   Marker(point: currentLocation!, child: const Icon(Icons.my_location, color: Colors.blue, size: 30)),
                 ...located.map((listing) {
                   final isOffer = listing.type == ListingType.offering;
                   return Marker(
                     point: LatLng(listing.location!.latitude, listing.location!.longitude),
                     width: 40,
                     height: 40,
                     child: GestureDetector(
                       onTap: () => context.push('/listings/${listing.id}', extra: listing),
                       child: Icon(
                         Icons.location_on,
                         color: isOffer ? Colors.green : Colors.orange,
                         size: 40,
                       ),
                     ),
                   );
                 }),
              ],
            ),
            RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors', onTap: () {})]),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
