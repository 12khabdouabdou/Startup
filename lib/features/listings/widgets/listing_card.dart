import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_model.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/widgets/verified_badge.dart';

class ListingCard extends ConsumerWidget {
  final Listing listing;
  final VoidCallback onTap;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerAsync = ref.watch(userProfileProvider(listing.hostUid));
    final owner = ownerAsync.value;
    final isVerified = owner?.isVerified ?? false;
    final ownerName = owner?.fullName ?? 'User';

    // Derived Title
    final displayTitle = '${listing.material.name[0].toUpperCase()}${listing.material.name.substring(1)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Type Badge
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: listing.photos.isNotEmpty
                      ? Image.network(
                          listing.photos.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[50],
                            child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[50],
                          child: Icon(Icons.terrain_outlined, size: 40, color: Colors.grey[200]),
                        ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: listing.type == ListingType.offering ? const Color(0xFF2E7D32) : Colors.orange[800],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                    ),
                    child: Text(
                      listing.type == ListingType.offering ? 'OFFERING' : 'REQUESTING',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTitle,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${listing.quantity.toStringAsFixed(0)} ${listing.unit.name.toUpperCase()}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        listing.price <= 0 ? 'FREE' : '\$${listing.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Location Row
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          listing.address ?? 'No Location',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF5F5F5)),
                  const SizedBox(height: 12),

                  // User Info
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'U', 
                          style: const TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ownerName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      if (isVerified) ...[
                         const SizedBox(width: 4),
                         const Icon(Icons.verified, size: 14, color: Color(0xFF2E7D32)),
                      ],
                      const Spacer(),
                      Text(
                        _timeAgo(listing.createdAt).toUpperCase(),
                        style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
