import 'package:flutter/material.dart';
import '../models/listing_model.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;

  const ListingCard({super.key, required this.listing, this.onTap});

  String get _materialLabel {
    switch (listing.material) {
      case FillMaterial.cleanFill: return 'Clean Fill';
      case FillMaterial.topsoil:   return 'Topsoil';
      case FillMaterial.gravel:    return 'Gravel';
      case FillMaterial.clay:      return 'Clay';
      case FillMaterial.mixed:     return 'Mixed';
      case FillMaterial.other:     return 'Other';
    }
  }

  IconData get _materialIcon {
    switch (listing.material) {
      case FillMaterial.cleanFill: return Icons.terrain;
      case FillMaterial.topsoil:   return Icons.grass;
      case FillMaterial.gravel:    return Icons.grain;
      case FillMaterial.clay:      return Icons.layers;
      case FillMaterial.mixed:     return Icons.shuffle;
      case FillMaterial.other:     return Icons.category;
    }
  }

  String get _priceLabel {
    if (listing.price <= 0) return 'FREE';
    return '\$${listing.price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isOffer = listing.type == ListingType.offering;
    final chipColor = isOffer ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Type chip + Price
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: chipColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isOffer ? 'OFFERING' : 'NEEDING',
                      style: TextStyle(
                        color: chipColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _priceLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: listing.price <= 0 ? Colors.green : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Material + Quantity
              Row(
                children: [
                  Icon(_materialIcon, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _materialLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${listing.quantity.toStringAsFixed(0)} ${listing.unit.name}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location
              if (listing.address != null && listing.address!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        listing.address!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              // Description preview
              if (listing.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  listing.description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Photo thumbnails
              if (listing.photos.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: listing.photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        listing.photos[i],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
