import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../listings/models/listing_model.dart';
import '../../listings/repositories/listing_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = const LatLng(37.7749, -122.4194); // Default SF
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
      // Move map if controller is ready, though initialCenter might handle it if rebuild happens fast enough
      // But MapOptions.initialCenter is only read once.
      // Better to use mapController.move
      _mapController.move(_currentCenter, 12.0); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch active listings
    final listingsAsync = ref.watch(activeListingsProvider);

    return Scaffold(
      body: listingsAsync.when(
        data: (listings) {
          final located = listings.where((l) => l.location != null).toList();

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 10.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fillexchange.app',
              ),
              MarkerLayer(
                markers: [
                  // Current Location Marker
                  if (_hasLocation)
                    Marker(
                      point: _currentCenter,
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                  
                  // Listings Markers
                  ...located.map((listing) {
                    final isOffer = listing.type == ListingType.offering;
                    return Marker(
                      point: LatLng(listing.location!.latitude, listing.location!.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                           // Show bottom sheet or navigate?
                           // Navigate for now
                           context.push('/listings/${listing.id}', extra: listing);
                        },
                        child: Icon(
                          Icons.location_on,
                          color: isOffer ? Colors.green : Colors.orange,
                          size: 40,
                          shadows: const [
                            Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1, 1))
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading map: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
