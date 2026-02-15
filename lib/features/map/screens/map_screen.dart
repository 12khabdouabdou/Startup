import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../listings/models/listing_model.dart';
import '../../listings/repositories/listing_repository.dart';
import 'package:go_router/go_router.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(activeListingsProvider);

    return listingsAsync.when(
      data: (listings) {
        // Filter only listings that have a valid address
        final located = listings.where((l) => l.address != null && l.address!.isNotEmpty).toList();

        if (located.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No listings with locations yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Map placeholder
            Container(
              height: 240,
              width: double.infinity,
              color: Colors.grey[200],
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 48, color: Colors.grey[500]),
                        const SizedBox(height: 8),
                        Text(
                          'Map View',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${located.length} listings nearby',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Google Maps integration requires API key.\nConfigure in android/app/src/main/AndroidManifest.xml',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Listing cards with locations below the map
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: located.length,
                itemBuilder: (context, index) {
                  final listing = located[index];
                  final isOffer = listing.type == ListingType.offering;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOffer ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.location_on,
                        color: isOffer ? Colors.green : Colors.orange,
                      ),
                    ),
                    title: Text(
                      '${listing.material.name[0].toUpperCase()}${listing.material.name.substring(1)} — ${listing.quantity.toStringAsFixed(0)} ${listing.unit.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(listing.address ?? ''),
                    trailing: Text(
                      listing.price <= 0 ? 'FREE' : '\$${listing.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: listing.price <= 0 ? Colors.green : null,
                      ),
                    ),
                    onTap: () {
                      context.push('/listings/${listing.id}', extra: listing);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
