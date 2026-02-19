import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../listings/models/listing_model.dart';
import '../services/routing_service.dart';
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
// ─── ACTIVE JOB MAP (Navigation Mode) ─────────────────────────────
class _ActiveJobMap extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<_ActiveJobMap> createState() => _ActiveJobMapState();
}

class _ActiveJobMapState extends ConsumerState<_ActiveJobMap> {
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  @override
  void didUpdateWidget(covariant _ActiveJobMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.job.pickupLocation != widget.job.pickupLocation ||
        oldWidget.job.dropoffLocation != widget.job.dropoffLocation) {
      _fetchRoute();
    }
  }

  Future<void> _fetchRoute() async {
    final pickup = widget.job.pickupLocation;
    final dropoff = widget.job.dropoffLocation;

    if (pickup == null || dropoff == null) return;

    setState(() => _isLoadingRoute = true);
    
    // For now, simple direct route implementation or use a real service
    // In a real app, this would call RoutingService().getRoute(...)
    // We will assume RoutingService is available via import
    // Note: Since RoutingService is not injected via Riverpod yet, we instantiate directly or use a provider if verified.
    // For simplicity in this fix, we instantiate the service directly here.
    
    try {
      final start = LatLng(pickup.latitude, pickup.longitude);
      final end = LatLng(dropoff.latitude, dropoff.longitude);
      
      final route = await RoutingService().getRoute(start, end);
      
      if (mounted) {
        setState(() {
          _routePoints = route;
          _isLoadingRoute = false;
        });
        
        // Fit bounds to show the whole route
        if (_routePoints.isNotEmpty) {
           // Simple bounds fitting (could be improved with CameraFit)
           // widget.mapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(_routePoints)));
           // Not calling automatically to avoid jarring jumps if user is panning.
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
        // Fallback to straight line if service fails
        // handled in build check
      }
    }
  }

  Future<void> _launchExternalNav() async {
    double? lat, lng;
    String label = '';
    
    // Determine destination based on job status
    if (widget.job.status == JobStatus.assigned || widget.job.status == JobStatus.enRoute) {
       lat = widget.job.pickupLocation?.latitude;
       lng = widget.job.pickupLocation?.longitude;
       label = 'Pickup';
    } else {
       lat = widget.job.dropoffLocation?.latitude;
       lng = widget.job.dropoffLocation?.longitude;
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
  Widget build(BuildContext context) {
    final pickup = widget.job.pickupLocation != null ? LatLng(widget.job.pickupLocation!.latitude, widget.job.pickupLocation!.longitude) : null;
    final dropoff = widget.job.dropoffLocation != null ? LatLng(widget.job.dropoffLocation!.latitude, widget.job.dropoffLocation!.longitude) : null;
    
    return Stack(
      children: [
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: pickup ?? dropoff ?? widget.currentLocation ?? const LatLng(0,0),
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fillexchange.app',
            ),
            // Route Polyline
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.0,
                    color: Colors.blue,
                  ),
                ],
              )
            else if (pickup != null && dropoff != null)
               // Fallback dotted line while loading or failed
               PolylineLayer(
                polylines: [
                  Polyline(
                    points: [pickup, dropoff],
                    strokeWidth: 4.0,
                    color: Colors.grey.withOpacity(0.5),
                    pattern: const StrokePattern.dotted(),
                  ),
                ],
              ),
              
            MarkerLayer(
              markers: [
                if (widget.currentLocation != null)
                  Marker(point: widget.currentLocation!, child: const Icon(Icons.airport_shuttle, color: Colors.blue, size: 30)),
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
          bottom: 24,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    // Status Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            widget.job.status == JobStatus.accepted || widget.job.status == JobStatus.enRoute ? 'ON DISPATCH: PICKUP' : 'ON DISPATCH: DROP-OFF',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const Spacer(),
                          Text(
                            'ID: ${widget.job.id.substring(0, 8).toUpperCase()}',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    // Job Details
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        '${widget.job.material} • ${widget.job.quantity?.toStringAsFixed(0)} Loads',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      subtitle: Text(
                         widget.job.status == JobStatus.accepted || widget.job.status == JobStatus.enRoute 
                            ? widget.job.pickupAddress ?? 'Heading to pickup...'
                            : widget.job.dropoffAddress ?? 'Heading to drop-off...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Container(
                         decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                         child: IconButton(
                           icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2E7D32)),
                           onPressed: () => context.push('/jobs/${widget.job.id}'),
                         ),
                      ),
                    ),
                    // Action Footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _launchExternalNav,
                              icon: const Icon(Icons.navigation_outlined, size: 20),
                              label: const Text('OPEN MAPS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                height: 50,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingRoute)
           const Positioned(
             top: 20, 
             right: 20, 
             child: CircularProgressIndicator()
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

  void _showListingPreview(BuildContext context, Listing listing) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black12,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (listing.photos.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(listing.photos.first, width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey[200]),
                    ),
                  )
                else
                  Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.terrain, color: Colors.grey)),
                  
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.material.name[0].toUpperCase() + listing.material.name.substring(1), 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      Text('${listing.quantity.toStringAsFixed(0)} ${listing.unit.name}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Text(listing.price <= 0 ? 'FREE' : '\$${listing.price.toStringAsFixed(0)}', 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
              ],
            ),
            const SizedBox(height: 16),
            if (listing.address != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(listing.address!, style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/listings/${listing.id}', extra: listing);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                child: const Text('View Full Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(activeListingsProvider);

    return listingsAsync.when(
      data: (listings) {
        final located = listings.where((l) => l.location != null).toList();
        
        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentLocation ?? const LatLng(30.0444, 31.2357), // Default to Cairo or 0,0
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
                       onTap: () => _showListingPreview(context, listing),
                       child: Icon(
                         Icons.location_on,
                         color: isOffer ? const Color(0xFF2E7D32) : Colors.orange,
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
