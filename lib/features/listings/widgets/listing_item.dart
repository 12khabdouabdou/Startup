import 'package:flutter/material.dart';
import '../models/listing_model.dart';

class ListingItem extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const ListingItem({
    super.key,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = listing.type == ListingType.offering ? Colors.green : Colors.orange;
    final typeLabel = listing.type == ListingType.offering ? 'OFFERING' : 'NEEDING';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    listing.price <= 0 ? 'FREE' : '\$${listing.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: listing.price <= 0 ? Colors.green : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                listing.material.name.toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${listing.quantity.toStringAsFixed(0)} ${listing.unit.name}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              if (listing.address != null && listing.address!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
