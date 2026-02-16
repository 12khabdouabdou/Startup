import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../listings/models/listing_model.dart';
import '../../listings/repositories/listing_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(activeListingsProvider);

    return listingsAsync.when(
      data: (listings) {
        // Filter listings with valid location data
        final located = listings.where((l) => l.location != null && l.location!.latitude != 0 && l.location!.longitude != 0).toList();

        // Default center (San Francisco for demo, or global view)
        // Ideally we'd get user location here
        final initialCenter = const LatLng(37.7749, -122.4194); 

        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: initialCenter,
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
                  markers: located.map((listing) {
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
                          shadows: const [
                            Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1, 1))
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Add Attribution for OSM compliance
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () {}, // Can launch URL if needed
                    ),
                  ],
                ),
              ],
            ),
            
            // List overlay or floating card if needed? 
            // The previous design had a list below the map. 
            // A full screen map is usually better, maybe with a bottom sheet or carousel?
            // For now, let's keep it simple: Full screen map.
            // If user wants list, they use the Home tab. 
            if (located.isEmpty)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No listings with location data found.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading map: $err')),
    );
  }
}
