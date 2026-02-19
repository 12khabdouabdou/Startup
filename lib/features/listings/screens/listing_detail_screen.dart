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
    final listing = this.listing ?? ModalRoute.of(context)?.settings.arguments as Listing?;

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final materialName = listing.material.name[0].toUpperCase() + listing.material.name.substring(1);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(materialName),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos Hero
            Stack(
              children: [
                if (listing.photos.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: listing.photos.length,
                      itemBuilder: (context, i) => Image.network(
                        listing.photos[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 48)),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: const Icon(Icons.terrain, size: 64, color: Colors.grey),
                  ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${listing.quantity.toStringAsFixed(0)} ${listing.unit.name.toUpperCase()}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(materialName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          Text(listing.type == ListingType.offering ? 'Available for Pickup' : 'Material Requested', 
                            style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
                      Text(
                        listing.price <= 0 ? 'FREE' : '\$${listing.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),

                  // Location Card
                  const Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(listing.address ?? 'No address provided', style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (listing.location != null)
                     ClipRRect(
                       borderRadius: BorderRadius.circular(12),
                       child: StaticMapPreview(center: listing.location!, height: 180),
                     ),
                  
                  const SizedBox(height: 32),

                  // Description
                  if (listing.description.isNotEmpty) ...[
                    const Text('Additional Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(listing.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                    const SizedBox(height: 32),
                  ],

                  // Poster Info
                  Consumer(builder: (context, ref, _) {
                    final owner = ref.watch(userProfileProvider(listing.hostUid)).valueOrNull;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                            child: Text(owner?.fullName[0].toUpperCase() ?? 'U', style: const TextStyle(color: Color(0xFF2E7D32))),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(owner?.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(owner?.companyName ?? 'Independent', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          if (owner?.isVerified ?? false) const Icon(Icons.verified, color: Colors.blue, size: 20),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 40),

                  // Action Buttons
                  Consumer(builder: (context, ref, _) {
                    final currentUser = ref.watch(authRepositoryProvider).currentUser;
                    final userDoc = ref.watch(userDocProvider).valueOrNull;
                    
                    if (currentUser == null) return const SizedBox();
                    
                    if (currentUser.id == listing.hostUid) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => ref.read(listingRepositoryProvider).archiveListing(listing.id).then((_) => context.pop()),
                          icon: const Icon(Icons.archive_outlined),
                          label: const Text('Archive Listing'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        if (userDoc?.role == UserRole.developer || userDoc?.role == UserRole.excavator) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                 final confirm = await showDialog<bool>(
                                   context: context,
                                   builder: (c) => AlertDialog(
                                     title: const Text('Book this material?'),
                                     content: const Text('This will create a haul request for drivers to pick up this material and deliver it to you.'),
                                     actions: [
                                       TextButton(onPressed: () => c.pop(false), child: const Text('Cancel')),
                                       TextButton(onPressed: () => c.pop(true), child: const Text('Book Now', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold))),
                                     ],
                                   ),
                                 );

                                 if (confirm == true && context.mounted) {
                                   try {
                                     await ref.read(jobRepositoryProvider).bookListing(listing.id);
                                     if (context.mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         const SnackBar(content: Text('✅ Material Booked! A driver will be matched shortly.')),
                                       );
                                       context.pop(); // Go back to feed
                                     }
                                   } catch (e) {
                                     if (context.mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                     }
                                   }
                                 }
                              },
                              icon: const Icon(Icons.bookmark_added_outlined),
                              label: const Text('Book Material', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                               final chatId = await ref.read(chatRepositoryProvider).getOrCreateChat(
                                 currentUid: currentUser.id,
                                 otherUid: listing.hostUid,
                                 listingId: listing.id,
                               );
                               if (context.mounted) context.push('/chat/$chatId');
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Message Seller', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2E7D32),
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
  }
}
