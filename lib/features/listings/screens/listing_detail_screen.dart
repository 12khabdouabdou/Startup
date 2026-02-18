import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/listing_model.dart';
import '../repositories/listing_repository.dart';
import '../../auth/repositories/auth_repository.dart';
// Job & User imports
import '../../jobs/repositories/job_repository.dart';
import '../../jobs/models/job_model.dart';
import '../../profile/providers/profile_provider.dart'; // for userDocProvider
import '../../../core/models/app_user.dart';
import '../../messaging/repositories/chat_repository.dart';
import '../../maps/widgets/static_map_preview.dart';

class ListingDetailScreen extends ConsumerWidget {
  final String listingId;
  final Listing? listing; // Optional passed listing

  const ListingDetailScreen({super.key, required this.listingId, this.listing});

  String _materialLabel(FillMaterial m) {
    switch (m) {
      case FillMaterial.cleanFill: return 'Clean Fill';
      case FillMaterial.topsoil:   return 'Topsoil';
      case FillMaterial.gravel:    return 'Gravel';
      case FillMaterial.clay:      return 'Clay';
      case FillMaterial.mixed:     return 'Mixed';
      case FillMaterial.other:     return 'Other';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Attempt to get listing from widget or ModalRoute arguments
    final listing = this.listing ?? ModalRoute.of(context)?.settings.arguments as Listing?;

    // If accessed via GoRouter extra:
    // GoRouter passes extra differently. We'll use a simple approach:
    // The listing can be passed via GoRouter's extra parameter.
    // For now, show a placeholder if listing is null.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Details'),
      ),
      body: listing == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Listing ID: $listingId',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Full detail view coming soon.\nFetch by ID will be implemented in next iteration.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photos
                  if (listing.photos.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        itemCount: listing.photos.length,
                        itemBuilder: (context, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(listing.photos[i], fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 48)),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (listing.type == ListingType.offering ? Colors.green : Colors.orange).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      listing.type == ListingType.offering ? 'OFFERING' : 'NEEDING',
                      style: TextStyle(
                        color: listing.type == ListingType.offering ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Material + Quantity
                  Text(
                    _materialLabel(listing.material),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${listing.quantity.toStringAsFixed(0)} ${listing.unit.name}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        listing.price <= 0 ? 'FREE' : '\$${listing.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: listing.price <= 0 ? Colors.green : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location
                  if (listing.address != null && listing.address!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(listing.address!, style: const TextStyle(fontSize: 15)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Map
                  if (listing.location != null && (listing.location!.latitude != 0 || listing.location!.longitude != 0)) ...[
                     StaticMapPreview(center: listing.location!, height: 180),
                     const SizedBox(height: 24),
                  ],

                  // Description
                  if (listing.description.isNotEmpty) ...[
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(listing.description, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 24),
                  ],

                  // Contact / Action / Job Request Button
                  SizedBox(
                    width: double.infinity,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final currentUid = ref.watch(authRepositoryProvider).currentUser?.id;
                        final userDoc = ref.watch(userDocProvider).valueOrNull;
                        
                        if (currentUid == null || userDoc == null) return const SizedBox();

                        final isOwner = currentUid == listing.hostUid;
                        final role = userDoc.role;

                        if (isOwner) {
                           return ElevatedButton.icon(
                             onPressed: () async {
                                 final confirm = await showDialog<bool>(
                                   context: context,
                                   builder: (c) => AlertDialog(
                                     title: const Text('Delete Listing?'),
                                     content: const Text('Are you sure you want to remove this listing?'),
                                     actions: [
                                       TextButton(onPressed: () => c.pop(false), child: const Text('Cancel')),
                                       TextButton(onPressed: () => c.pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                     ],
                                   ),
                                 );

                                 if (confirm == true) {
                                   await ref.read(listingRepositoryProvider).archiveListing(listing.id);
                                   if (context.mounted) {
                                     context.pop();
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing deleted')));
                                   }
                                 }
                             },
                             icon: const Icon(Icons.delete),
                             label: const Text('Delete Listing'),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: Colors.red,
                               foregroundColor: Colors.white,
                               padding: const EdgeInsets.symmetric(vertical: 14),
                             ),
                           );
                        } 
                        
                        // Not Owner: Show "Contact" and optionally "Post Job"
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                  final chatId = await ref.read(chatRepositoryProvider).getOrCreateChat(
                                    currentUid: currentUid,
                                    otherUid: listing.hostUid,
                                    listingId: listing.id,
                                  );
                                  if (context.mounted) context.push('/chat/$chatId');
                              },
                              icon: const Icon(Icons.chat),
                              label: const Text('Contact Poster'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                            
                            if (role == UserRole.developer || role == UserRole.excavator) ...[
                               const SizedBox(height: 12),
                               ElevatedButton.icon(
                                  onPressed: () {
                                     context.push('/jobs/create', extra: {
                                        'listingId': listing.id,
                                        'hostUid': currentUid, 
                                        'material': listing.material.name,
                                        'quantity': listing.quantity,
                                        // location isn't passed in extra but CreateJob fetches it via listingId
                                     });
                                  },
                                  icon: const Icon(Icons.local_shipping),
                                  label: const Text('Post Haul Request'),
                                  style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.blue[800],
                                     foregroundColor: Colors.white,
                                     padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                               ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
