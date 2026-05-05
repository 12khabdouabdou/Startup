import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/listing_bloc.dart';
import '../bloc/listing_event.dart';
import '../bloc/listing_state.dart';

class ListingsFeedScreen extends StatefulWidget {
  const ListingsFeedScreen({super.key});

  @override
  State<ListingsFeedScreen> createState() => _ListingsFeedScreenState();
}

class _ListingsFeedScreenState extends State<ListingsFeedScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    context.read<ListingBloc>().add(const ListingLoadAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.push('/map'),
          ),
        ],
      ),
      body: BlocBuilder<ListingBloc, ListingState>(
        builder: (context, state) {
          if (state is ListingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is ListingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ListingBloc>().add(const ListingLoadAll()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is ListingLoaded) {
            final listings = state.listings;
            
            if (listings.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64),
                    SizedBox(height: 16),
                    Text('No listings yet'),
                    Text('Create your first waste listing'),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ListingBloc>().add(const ListingLoadAll());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final listing = listings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => context.push('/listings/${listing.id}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo
                          if (listing.photos.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                listing.photos.first,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  height: 160,
                                  child: Icon(Icons.image_not_supported),
                                ),
                              ),
                          else
                            Container(
                              height: 160,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_getWasteTypeIcon(listing.wasteType), style: const TextStyle(fontSize: 48)),
                                    const SizedBox(height: 8),
                                    Text(_getWasteTypeName(listing.wasteType), style: Theme.of(context).textTheme.titleMedium),
                                  ],
                                ),
                              ),
                            ),
                          
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${listing.quantity} ${listing.unit} ${_getWasteTypeName(listing.wasteType)}',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    _buildStatusBadge(listing.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.secondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        listing.address,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (listing.estimatedMin != null && listing.estimatedMax != null)
                                      Text(
                                        '\$${listing.estimatedMin}–\$${listing.estimatedMax}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    Text(
                                      '${listing.photos.length} photo${listing.photos.length > 1 ? 's' : ''}',
                                      style: Theme.of(context).textTheme.bodySmall,
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
                },
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/listings/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Listing'),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
      case 'matched':
      case 'booked':
        color = Colors.orange;
      case 'completed':
        color = Colors.blue;
      case 'cancelled':
        color = Colors.red;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getWasteTypeName(String type) {
    return type.split('.').last.capitalize();
  }

  String _getWasteTypeIcon(String type) {
    switch (type) {
      case 'concrete': return '🧱';
      case 'wood': return '🪵';
      case 'metal': return '🔩';
      case 'soil': return '🏔️';
      case 'mixed': return '📦';
      case 'hazardous': return '🛢️';
      default: return '📄';
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Waste Type', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ['All', 'Concrete', 'Wood', 'Metal', 'Soil', 'Mixed', 'Hazardous']
                  .map((type) => FilterChip(
                        label: Text(type),
                        selected: _selectedFilter == type,
                        onSelected: (_) {
                          setState(() => _selectedFilter = type);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
